// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Simple AToken: minted/burned by LendingPool for depositors 1:1.
/// Acts as vault for underlying tokens. Pool mints/burns and can instruct this contract to send underlying.
contract AToken is ERC20, Ownable {
    address public pool; // authorized minter/burner (LendingPool)
    address public underlying; // underlying ERC20 token held as vault

    constructor(string memory name_, string memory symbol_, address initialOwner)
        ERC20(name_, symbol_)
        Ownable(initialOwner)
    {}

    /// @notice Owner sets underlying token address (should be done once)
    function setUnderlying(address u) external onlyOwner {
        require(u != address(0), "underlying=0");
        underlying = u;
    }

    function setPool(address p) external onlyOwner {
        require(p != address(0), "pool=0");
        pool = p;
    }

    modifier onlyPool() {
        require(msg.sender == pool, "only pool");
        _;
    }

    function mint(address to, uint256 amount) external onlyPool {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyPool {
        _burn(from, amount);
    }

    /// @notice Called by pool to send underlying tokens from this contract to recipient.
    /// The aToken contract must hold the underlying tokens prior to this call.
    function sendUnderlying(address to, uint256 amount) external onlyPool {
        require(underlying != address(0), "underlying not set");
        uint256 bal = IERC20(underlying).balanceOf(address(this));
        require(bal >= amount, "insufficient vault");
        bool ok = IERC20(underlying).transfer(to, amount);
        require(ok, "transfer failed");
    }
}
