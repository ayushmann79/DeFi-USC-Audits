// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
//import {LendingPool} from "../src/LendingPool.sol";

//import {DebtToken} from "../src/tokens/DebtToken.sol";
import {InterestRateModel} from "../src/utils/InterestRateModel.sol";

contract SetupMarketsScript is Script {
    function run() external {
        vm.startBroadcast();

        // Example usage:
        // LendingPool pool = LendingPool(<pool address>);
        // AToken aToken = AToken(<aToken address>);
        // DebtToken debtToken = DebtToken(<debtToken address>);
        // InterestRateModel irm = InterestRateModel(<irm address>);
        // pool.listReserve(addressOfUnderlying, aToken, debtToken, irm, true, 7500, 8000, 10500);

        vm.stopBroadcast();
    }
}
