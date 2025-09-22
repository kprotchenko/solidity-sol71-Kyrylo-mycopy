// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@4.9.6/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.9.6/access/Ownable.sol";

abstract contract ERC20Base is ERC20, Ownable {
    // 1000000 tokens with 18 decimals.
    uint256 public constant MAX_SUPPLY = 1000000 * 10**18;

    constructor(string memory n, string memory s) ERC20(n, s) {}
}
