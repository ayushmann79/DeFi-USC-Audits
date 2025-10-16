// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Oracle} from "../src/utils/Oracle.sol";

contract OracleTest is Test {
    Oracle oracle;

    function setUp() public {
        oracle = new Oracle();
    }

    function testSetAndGetPrice() public {
        oracle.setPrice(address(0x1), int256(123 * 1e8));
        assertEq(oracle.getAssetPrice(address(0x1)), int256(123 * 1e8));
    }
}
