// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.4.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.4.0/access/Ownable.sol";

abstract contract ERC20Base is ERC20, Ownable {
    constructor(string memory n, string memory s, address initialOwner) ERC20(n, s) Ownable(initialOwner) {}
    // 1000000 tokens with 18 decimals.
    uint8    constant TOKEN_DECIMALS = 18;
    uint256  constant MAX_SUPPLY     = 1_000_000 * 10**TOKEN_DECIMALS;

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
