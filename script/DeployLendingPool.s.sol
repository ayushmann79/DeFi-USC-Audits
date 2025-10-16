// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Oracle} from "../src/utils/Oracle.sol";
import {InterestRateModel} from "../src/utils/InterestRateModel.sol";
import {AToken} from "../src/tokens/AToken.sol";
import {DebtToken} from "../src/tokens/DebtToken.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {ERC20Mock} from "../test/mocks/ERC20Mock.sol";

contract DeployLendingPoolScript is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy oracle
        Oracle oracle = new Oracle();

        // Deploy lending pool
        LendingPool lendingPool = new LendingPool(address(oracle));

        // Deploy interest rate model (check your ctor!)
        InterestRateModel irm = new InterestRateModel(0); // <-- adjust parameter as per your actual contract

        // Deploy mock tokens
        ERC20Mock dai = new ERC20Mock("Mock DAI", "DAI");
        ERC20Mock usdc = new ERC20Mock("Mock USDC", "USDC");

        dai.mint(msg.sender, 1_000_000 ether);
        usdc.mint(msg.sender, 1_000_000 ether);

        // Deploy aTokens and dTokens
        AToken aDai = new AToken("Aave DAI", "aDAI", address(lendingPool));
        DebtToken dDai = new DebtToken("Debt DAI", "dDAI", address(lendingPool));

        AToken aUsdc = new AToken("Aave USDC", "aUSDC", address(lendingPool));
        DebtToken dUsdc = new DebtToken("Debt USDC", "dUSDC", address(lendingPool));

        // List reserves (pass contracts, not addresses!)
        lendingPool.listReserve(address(dai), aDai, dDai, irm, true, 7500, 8000, 10500);

        lendingPool.listReserve(address(usdc), aUsdc, dUsdc, irm, true, 7500, 8000, 10500);

        vm.stopBroadcast();
    }
}
