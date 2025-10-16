    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AccessControl is Ownable {
    address public guardian;

    event GuardianUpdated(address indexed guardian);

    constructor(address initialOwner) Ownable(initialOwner) {
        // Optionally, you can also set guardian = initialOwner at deploy
    }

    function setGuardian(address g) external onlyOwner {
        guardian = g;
        emit GuardianUpdated(g);
    }

    modifier onlyGuardianOrOwner() {
        require(msg.sender == owner() || msg.sender == guardian, "Not guardian or owner");
        _;
    }
}
