// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@4.9.6/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.9.6/access/Ownable.sol";

abstract contract ERC20Base is ERC20, Ownable {
    // 18 decimals by default in OZ ERC20.
    uint256 public constant MAX_SUPPLY = 1_000_000 * 10**18;

    constructor(string memory n, string memory s) ERC20(n, s) {}
}
