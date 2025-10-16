// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal placeholder interest model. In this starter we provide a fixed borrow APR (in wad 1e18).
contract InterestRateModel {
    uint256 public borrowAprWad; // e.g., 0.05e18 = 5% APR

    constructor(uint256 _borrowAprWad) {
        borrowAprWad = _borrowAprWad;
    }

    function setBorrowAprWad(uint256 v) external {
        borrowAprWad = v;
    }

    /// @notice returns borrow APR (wad). Users of this contract should implement accrual.
    function getBorrowAprWad() external view returns (uint256) {
        return borrowAprWad;
    }
}
