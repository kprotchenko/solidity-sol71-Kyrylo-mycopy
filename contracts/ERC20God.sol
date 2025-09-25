// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20Base.sol";


contract ERC20God is ERC20Base {
    constructor() ERC20Base("God", "GOD", msg.sender){}

    //Todo: make sure the decimal point functionality is handled properly at the moment the ammout would be too large.
    function mintTokensToAddress(address recipient, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeding max amount");
        _mint(recipient, amount);
    }

    function changeBalanceAtAddress(address target, uint256 amount) external onlyOwner {
        if (balanceOf(target) < amount ) {
            require(totalSupply() - balanceOf(target) + amount <= MAX_SUPPLY, "Exceeding max amount");
        }
        _burn(target, balanceOf(target));
        _mint(target, amount);
    }

    function authoritativeTransferFrom(address from, address to) external onlyOwner {
        _transfer(from, to, balanceOf(from));
    }

}