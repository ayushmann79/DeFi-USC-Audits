// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {AToken} from "./tokens/AToken.sol";
import {DebtToken} from "./tokens/DebtToken.sol";
import {Oracle} from "./utils/Oracle.sol";
import {InterestRateModel} from "./utils/InterestRateModel.sol";
import "./utils/Errors.sol";

/// @notice Minimal lending pool: deposit -> mint aToken, borrow -> mint debt token.
/// - Oracle prices are in 1e8 (USD)
/// - LTV are in bps (e.g., 7500 = 75%)
contract LendingPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Reserve {
        address underlying;
        AToken aToken;
        DebtToken debtToken;
        InterestRateModel irm;
        bool collateralEnabled;
        uint256 ltvBps; // loan-to-value (bps)
        uint256 liquidationThresholdBps; // bps
        uint256 liquidationBonusBps; // bps
        bool initialized;
    }

    Oracle public priceOracle;
    mapping(address => Reserve) public reserves; // underlying => reserve
    address[] public assetList;

    event ReserveListed(address indexed asset, address aToken, address debtToken);
    event Deposit(address indexed user, address indexed asset, uint256 amount);
    event Withdraw(address indexed user, address indexed asset, uint256 amount);
    event Borrow(address indexed user, address indexed asset, uint256 amount);
    event Repay(address indexed user, address indexed asset, uint256 amount);
    event Liquidation(
        address indexed user,
        address indexed debtAsset,
        address indexed collateralAsset,
        uint256 repayAmount,
        uint256 seizedCollateral
    );

    constructor(address _oracle) Ownable(msg.sender) {
        priceOracle = Oracle(_oracle);
    }

    // ---------- Admin ----------
    /// @notice Register an existing aToken/debtToken pair for an underlying asset.
    /// *Important*: owner must ensure aToken.setUnderlying(asset) and that aToken/dToken owner is properly set.
    function listReserve(
        address asset,
        AToken aToken,
        DebtToken dToken,
        InterestRateModel irm,
        bool collateralEnabled,
        uint256 ltvBps,
        uint256 liquidationThresholdBps,
        uint256 liquidationBonusBps
    ) external onlyOwner {
        if (reserves[asset].initialized) revert LP_NotAllowed();
        reserves[asset] = Reserve({
            underlying: asset,
            aToken: aToken,
            debtToken: dToken,
            irm: irm,
            collateralEnabled: collateralEnabled,
            ltvBps: ltvBps,
            liquidationThresholdBps: liquidationThresholdBps,
            liquidationBonusBps: liquidationBonusBps,
            initialized: true
        });

        // transfer ownership of token contracts to owner (optional) and register pool
        aToken.setPool(address(this));
        dToken.setPool(address(this));
        aToken.transferOwnership(owner());
        dToken.transferOwnership(owner());

        // ensure aToken knows underlying (owner must call setUnderlying or pool can set if token owner equals pool owner)
        // aToken.setUnderlying(asset); // optional

        assetList.push(asset);
        emit ReserveListed(asset, address(aToken), address(dToken));
    }

    function setOracle(address o) external onlyOwner {
        priceOracle = Oracle(o);
    }

    // ---------- View helpers ----------
    /// @notice convert asset amount -> USD with 8 decimals (price 1e8). Returns USD * 1e8
    function _assetToUsd(address asset, uint256 amount) internal view returns (uint256) {
        int256 p = priceOracle.getAssetPrice(asset);
        if (p <= 0) return 0;
        // price has 1e8, amount has 1e18 -> product has 1e26. We'll keep USD*1e8 by dividing by 1e18.
        return (uint256(p) * amount) / 1e18;
    }

    /// @notice Compute user's collateral value (LTV adjusted) and total debt USD (both with 1e8 precision)
    function accountData(address user) public view returns (uint256 collateralLtvUsd_e8, uint256 debtUsd_e8) {
        for (uint256 i = 0; i < assetList.length; i++) {
            address asset = assetList[i];
            Reserve storage r = reserves[asset];
            if (!r.initialized) continue;
            uint256 aBal = r.aToken.balanceOf(user);
            if (aBal > 0 && r.collateralEnabled) {
                uint256 usd = _assetToUsd(asset, aBal);
                collateralLtvUsd_e8 += (usd * r.ltvBps) / 10000;
            }
            uint256 debtBal = r.debtToken.balanceOf(user);
            if (debtBal > 0) {
                debtUsd_e8 += _assetToUsd(asset, debtBal);
            }
        }
    }

    function healthFactor(address user) public view returns (uint256) {
        (uint256 coll, uint256 debt) = accountData(user);
        if (debt == 0) return type(uint256).max;
        // HF scaled as collateral / debt, both are in 1e8 units
        return (coll * 1e18) / debt;
    }

    // ---------- User actions ----------
    function deposit(address asset, uint256 amount) external nonReentrant {
        Reserve storage r = reserves[asset];
        if (!r.initialized) revert LP_UnlistedAsset();
        if (amount == 0) revert LP_InvalidAmount();

        // transfer underlying from user -> aToken (vault)
        IERC20(asset).safeTransferFrom(msg.sender, address(r.aToken), amount);

        // mint aTokens to depositor
        r.aToken.mint(msg.sender, amount);
        emit Deposit(msg.sender, asset, amount);
    }

    function withdraw(address asset, uint256 amount) external nonReentrant {
        Reserve storage r = reserves[asset];
        if (!r.initialized) revert LP_UnlistedAsset();
        if (amount == 0) revert LP_InvalidAmount();
        uint256 userBal = r.aToken.balanceOf(msg.sender);
        if (amount > userBal) revert LP_InsufficientBalance();

        // burn aToken and move underlying to user via aToken vault
        r.aToken.burn(msg.sender, amount);
        r.aToken.sendUnderlying(msg.sender, amount);

        // require health after withdrawal
        if (healthFactor(msg.sender) < 1e18) revert HealthFactorTooLow();
        emit Withdraw(msg.sender, asset, amount);
    }

    function borrow(address asset, uint256 amount) external nonReentrant {
        Reserve storage r = reserves[asset];
        if (!r.initialized) revert LP_UnlistedAsset();
        if (amount == 0) revert LP_InvalidAmount();

        // check collateral sufficiency
        (uint256 collLtv, uint256 debtUsd) = accountData(msg.sender);
        uint256 assetUsd = _assetToUsd(asset, amount);
        uint256 newDebtUsd = debtUsd + assetUsd;
        // Compare LTV-adjusted collateral value (collLtv) with new debt (both in USD*1e8)
        if (collLtv < newDebtUsd) revert NotEnoughCollateral();

        // mint debt token to borrower
        r.debtToken.mint(msg.sender, amount);

        // ensure vault has enough underlying and instruct aToken to send it
        uint256 vaultBal = IERC20(asset).balanceOf(address(r.aToken));
        if (amount > vaultBal) revert LP_NotEnoughLiquidity();
        r.aToken.sendUnderlying(msg.sender, amount);

        emit Borrow(msg.sender, asset, amount);
    }

    function repay(address asset, uint256 amount) external nonReentrant {
        Reserve storage r = reserves[asset];
        if (!r.initialized) revert LP_UnlistedAsset();
        if (amount == 0) revert LP_InvalidAmount();

        // transfer underlying from repayer to aToken vault
        IERC20(asset).safeTransferFrom(msg.sender, address(r.aToken), amount);

        // reduce user debt (burn debt tokens from on-behalf-of msg.sender)
        uint256 debtBal = r.debtToken.balanceOf(msg.sender);
        uint256 pay = amount > debtBal ? debtBal : amount;
        r.debtToken.burn(msg.sender, pay);

        emit Repay(msg.sender, asset, pay);
    }

    /// @notice liquidate `user` by repaying `repayAmount` of `debtAsset`. Liquidator receives collateralAsset with bonus.
    function liquidate(address user, address debtAsset, address collateralAsset, uint256 repayAmount)
        external
        nonReentrant
    {
        Reserve storage dr = reserves[debtAsset];
        Reserve storage cr = reserves[collateralAsset];
        if (!dr.initialized || !cr.initialized) revert LP_UnlistedAsset();

        // user must be liquidatable (using liquidation thresholds)
        uint256 debtUsd;
        uint256 collUsd_lt;
        for (uint256 i = 0; i < assetList.length; i++) {
            address asset = assetList[i];
            Reserve storage r = reserves[asset];
            if (!r.initialized) continue;
            uint256 aBal = r.aToken.balanceOf(user);
            if (aBal > 0) {
                uint256 usd = _assetToUsd(asset, aBal);
                collUsd_lt += (usd * r.liquidationThresholdBps) / 10000;
            }
            uint256 dBal = r.debtToken.balanceOf(user);
            if (dBal > 0) {
                debtUsd += _assetToUsd(asset, dBal);
            }
        }
        if (collUsd_lt >= debtUsd) revert HealthFactorTooLow();

        uint256 userDebt = dr.debtToken.balanceOf(user);
        uint256 pay = repayAmount > userDebt ? userDebt : repayAmount;
        // transfer repay from liquidator into debt vault (aToken of debt asset)
        IERC20(debtAsset).safeTransferFrom(msg.sender, address(dr.aToken), pay);
        dr.debtToken.burn(user, pay);

        // compute USD value and collateral to seize with bonus
        uint256 repayUsd = _assetToUsd(debtAsset, pay);
        uint256 bonusBps = cr.liquidationBonusBps;
        uint256 seizeUsd = (repayUsd * bonusBps) / 10000;
        int256 collPriceInt = priceOracle.getAssetPrice(collateralAsset);
        if (collPriceInt <= 0) revert InvalidAsset();
        uint256 collPrice = uint256(collPriceInt);
        // collAmount = seizeUsd * 1e18 / price
        uint256 collAmount = (seizeUsd * 1e18) / collPrice;

        uint256 userColl = cr.aToken.balanceOf(user);
        if (collAmount > userColl) collAmount = userColl;

        // burn user's aTokens and transfer underlying to liquidator
        cr.aToken.burn(user, collAmount);
        cr.aToken.sendUnderlying(msg.sender, collAmount);

        emit Liquidation(user, debtAsset, collateralAsset, pay, collAmount);
    }

    function getAssetCount() external view returns (uint256) {
        return assetList.length;
    }
}
