// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { chainLink } from "../test/chainLink.sol";
import { console } from "hardhat/console.sol";
import "../structs/structs.sol";


interface IShopPayment {
    function purchaseProduct(
        uint256 id,
        bool isAffiliate,
        uint256 amount,
        uint80 roundId
    ) external payable;

    function purchaseProductFor(
        address receiver, 
        uint256 id, 
        bool isAffiliate, 
        uint256 amount, 
        uint80 roundId
    ) external payable;

    function getProduct(uint256 productId) external view returns (Product memory);
}

contract DroplinkedPaymentProxy is Ownable{
    error oldPrice();
    constructor() Ownable(msg.sender) {}
    chainLink public priceFeed = new chainLink();
    uint heartBeat = 120;
    struct PurchaseData {
        uint id;
        uint amount;
        bool isAffiliate;
        address shopAddress;
    }

    function getLatestPrice(uint80 roundId) internal view returns (uint, uint) {
        (, int256 price, , uint256 timestamp, ) = priceFeed.getRoundData(
            roundId
        );
        return (uint(price), timestamp);
    }

    function toNativePrice(uint value, uint ratio) private pure returns (uint) {
        return (1e24 * value) / ratio;
    }


    function transferTBDValues(uint[] memory tbdValues, address[] memory tbdReceivers, uint ratio, address currency) private returns(uint){
        uint currentValue = 0;
        for (uint i = 0; i < tbdReceivers.length; i++) {
            uint value = currency == address(0) ? toNativePrice(tbdValues[i], ratio) : tbdValues[i];
            currentValue += value;
            if (currency != address(0)) {
                IERC20(currency).transferFrom(msg.sender, tbdReceivers[i], value);
            } else {
                payable(tbdReceivers[i]).transfer(value);
            }
        }
        return currentValue;
    }

    function droplinkedPurchase(uint[] memory tbdValues, address[] memory tbdReceivers, PurchaseData[] memory cartItems, address currency, uint80 roundId) external payable {
        uint ratio = 0;
        if (currency == address(0)){
            uint256 timestamp;
            (ratio, timestamp) = getLatestPrice(roundId);
            if (ratio == 0) revert("Chainlink Contract not found");
            if (block.timestamp > timestamp && block.timestamp - timestamp > 2 * heartBeat) revert oldPrice();
        }
        console.log("Before transfer");
        transferTBDValues(tbdValues, tbdReceivers, ratio, currency);
        console.log("transfered tbd values");
        // note: we can't have multiple products with different payment methods in the same purchase!
        for(uint i = 0; i < cartItems.length; i++){
            uint id = cartItems[i].id;
            bool isAffiliate = cartItems[i].isAffiliate;
            uint amount = cartItems[i].amount;
            console.log("id: %s, amount: %s, isAffiliate: %s", id, amount, isAffiliate);
            IShopPayment cartItemShop = IShopPayment(cartItems[i].shopAddress);
            console.log("test0");
            Product memory product = cartItemShop.getProduct(id);
            console.log("test1");
            uint finalPrice = product.paymentInfo.price * amount;
            console.log("final price: %s", finalPrice);
            if (currency != address(0)){
                IERC20(currency).transferFrom(msg.sender, address(this), finalPrice);
                IERC20(currency).approve(cartItems[i].shopAddress, finalPrice);
            } else {
                finalPrice = toNativePrice(finalPrice, ratio);
            }
            IShopPayment(cartItems[i].shopAddress).purchaseProductFor{value: finalPrice}(msg.sender, id, isAffiliate, amount, roundId);
        }
    }
}