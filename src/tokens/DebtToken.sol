// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Simple variable debt token representation minted/burned by pool
/// This is a basic ERC20 debt token — you might want to disable transfers in production.
contract DebtToken is ERC20, Ownable {
    address public pool;

    constructor(string memory name_, string memory symbol_, address initialOwner)
        ERC20(name_, symbol_)
        Ownable(initialOwner)
    {}

    function setPool(address p) external onlyOwner {
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
}
