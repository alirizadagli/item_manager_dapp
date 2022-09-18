// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import './ItemManager.sol';

contract Item {
    uint public priceInWei;
    uint public pricePaid;
    uint public index;

    ItemManager parentContract;

    constructor(ItemManager _parentContract, uint _priceInWei, uint _index) {
        priceInWei = _priceInWei;
        parentContract = _parentContract;
        index = _index;
    }

    receive() external payable {
     require(pricePaid == 0, "Item is paid already");
     require(priceInWei == msg.value, "Only full payments allowed");
     pricePaid += msg.value;
     (bool succes,) =   address(parentContract).call{value: msg.value}(abi.encodeWithSignature("triggerPayment(uint256)", index));
     require(succes, "The transaction wasn't successful, cancelling.");
    }

    fallback() external {}
}
