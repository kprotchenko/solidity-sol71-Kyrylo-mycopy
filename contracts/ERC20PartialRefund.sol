// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20TokenSale.sol";


contract ERC20PartialRefund is ERC20TokenSale {
    constructor() payable ERC20TokenSale() {}
    uint256  constant ETH_IN_WEI_REFUND_PER_1000_TOKENS = 0.5 ether;      // sellback rate
    // uint256 constant REFUNT_RATIO =  ETH_IN_WEI_REFUND_PER_1000_TOKENS / TOKENS_IN_DCMLS_PER_ETH_IN_WEI;//(10**18/2)/(1000*10**18)

    function sellBack(uint256 amountOfTokensInDcmls) payable external {
        uint256 amountOfEthForTokensInDcmls = amountOfTokensInDcmls / 2000;
        require(address(this).balance >= amountOfEthForTokensInDcmls,"Not enough balance");
        require(balanceOf(address(msg.sender)) >= amountOfTokensInDcmls, "Not enough tokens to sell");
        // since every wei (the smalles unit of ETH) could buy me 1000 smalles decimal parts of one token,
        // I do not have to warry about returning less then 1000 smalles decimal parts of one token
        (bool success, ) = payable(msg.sender).call{value:  amountOfEthForTokensInDcmls}("");
         _burn(msg.sender, amountOfTokensInDcmls);
        require(success, "Refund failed");
    }

}