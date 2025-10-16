// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {InterestRateModel} from "../src/utils/InterestRateModel.sol";

contract InterestRateTest is Test {
    InterestRateModel irm;

    function setUp() public {
        irm = new InterestRateModel(5e16); // 5%
    }

    function testGetBorrowApr() public {
        assertEq(irm.getBorrowAprWad(), 5e16);
        irm.setBorrowAprWad(1e17);
        assertEq(irm.getBorrowAprWad(), 1e17);
    }
}
