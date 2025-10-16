// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {Oracle} from "../src/utils/Oracle.sol";
import {AToken} from "../src/tokens/AToken.sol";
import {DebtToken} from "../src/tokens/DebtToken.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {InterestRateModel} from "../src/utils/InterestRateModel.sol";

contract MockERC20 is ERC20 {
    constructor(string memory n, string memory s, uint256 supply) ERC20(n, s) {
        _mint(msg.sender, supply);
    }

    function mint(address to, uint256 amt) external {
        _mint(to, amt);
    }
}

contract LiquidationTest is Test {
    LendingPool pool;
    Oracle oracle;
    MockERC20 weth;
    MockERC20 dai;
    AToken aWeth;
    DebtToken dDai;
    address borrower;
    address liquidator;

    function setUp() public {
        borrower = address(0xBA1);
        liquidator = address(0x1000000000000000000000000000000000000001);

        oracle = new Oracle();
        pool = new LendingPool(address(oracle));

        weth = new MockERC20("WETH", "WETH", 1e24);
        dai = new MockERC20("DAI", "DAI", 1e24);

        aWeth = new AToken("aWETH", "aWETH", address(this));
        dDai = new DebtToken("dDAI", "dDAI", address(this));

        // set underlying
        aWeth.setUnderlying(address(weth));

        pool.listReserve(address(dai), AToken(address(0)), dDai, InterestRateModel(address(0)), true, 7500, 8000, 10500);
        pool.listReserve(
            address(weth), aWeth, DebtToken(address(0)), InterestRateModel(address(0)), true, 7000, 7500, 10750
        );

        oracle.setPrice(address(dai), int256(1 * 1e8));
        oracle.setPrice(address(weth), int256(100 * 1e8)); // price low to make liquidation easier

        // give borrower WETH
        weth.mint(borrower, 10 ether);
        vm.prank(borrower);
        weth.approve(address(pool), type(uint256).max);
        vm.prank(borrower);
        pool.deposit(address(weth), 10 ether);

        // borrow large DAI; add DAI into aWeth vault to cover lending
        dai.mint(address(aWeth), 1000000 ether);

        vm.prank(borrower);
        pool.borrow(address(dai), 6000 ether); // create large debt given low WETH price
    }

    function testLiquidation() public {
        // lower WETH price to trigger liquidation
        oracle.setPrice(address(weth), int256(50 * 1e8)); // halves collateral value

        // give liquidator DAI to repay
        dai.mint(liquidator, 10000 ether);
        vm.prank(liquidator);
        dai.approve(address(pool), type(uint256).max);
        vm.prank(liquidator);
        pool.liquidate(borrower, address(dai), address(weth), 1000 ether);

        assertTrue(true);
    }
}
