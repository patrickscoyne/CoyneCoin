// contracts/CToken.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "contracts/ERC20.sol";

contract CToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("CoyneCoin", "COY") {
        _mint(address(this), initialSupply);
    }
}