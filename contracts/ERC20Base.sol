// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.4.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.4.0/access/Ownable.sol";

abstract contract ERC20Base is ERC20, Ownable {
    // 1000000 tokens with 18 decimals.
    uint256 public constant DECIMALS = 1e18; // 10**18
    uint256 public constant MAX_SUPPLY = 1000000 * DECIMALS;

    constructor(string memory n, string memory s, address initialOwner) ERC20(n, s) Ownable(initialOwner) {}

}
