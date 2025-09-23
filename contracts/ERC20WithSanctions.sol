// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20Base.sol";

contract ERC20WithSanctions is ERC20Base {
    constructor() ERC20Base("Black List", "BLKL", msg.sender) {}
    mapping(address => bool) public blacklist;
    function addToSanctions (address addressToBlock, bool isSanctioned) external onlyOwner {
        blacklist[addressToBlock] = isSanctioned;
    }

    function setSanctions (address[] calldata list, bool isSanctioned) external onlyOwner {
        for(uint i = 0; i < list.length; i++) blacklist[list[i]] = isSanctioned;
    }

    function _update(address from, address to, uint256 value) internal override {
        require(!blacklist[from] && !blacklist[to], "sanctioned");
        super._update(from, to, value); // keep ERC20’s logic
    }
}