// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20Base.sol";

contract ERC20TokenSale is ERC20Base {
    constructor() payable ERC20Base("Token Sale", "TS", msg.sender) {}
    uint256 constant TOKENS_IN_DCMLS_PER_ETH_IN_WEI = 1000 * 10**TOKEN_DECIMALS;
    uint256 constant ETH_IN_WEI_PER_1000_TOKENS_IN_DCMLS   = 1 ether;        // buy price (1 wei for 1000 tokens)
    function pay() payable external {
        uint256 tokens = (msg.value * TOKENS_IN_DCMLS_PER_ETH_IN_WEI) / ETH_IN_WEI_PER_1000_TOKENS_IN_DCMLS;
        require(tokens + totalSupply() <= MAX_SUPPLY, "Max supply reached");
        _mint(msg.sender, tokens);
    }
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdrowAmmount(address payable to, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount,"Not enough balance");
        (bool success, ) = to.call{value: amount}("");
        require(success, "withdraw failed");
    }
}