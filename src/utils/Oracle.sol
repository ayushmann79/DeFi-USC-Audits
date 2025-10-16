// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Simple price oracle (dev/test). Prices in USD with 8 decimals (like Chainlink).
contract Oracle is Ownable {
    mapping(address => int256) public prices; // price * 1e8

    event PriceUpdated(address indexed asset, int256 price);

    constructor() Ownable(msg.sender) {}

    function setPrice(address asset, int256 price) external onlyOwner {
        prices[asset] = price;
        emit PriceUpdated(asset, price);
    }

    /// @notice price with 8 decimals. returns 0 if unknown.
    function getAssetPrice(address asset) external view returns (int256) {
        return prices[asset];
    }
}
