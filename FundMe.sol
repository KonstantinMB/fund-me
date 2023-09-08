// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { PriceConverterLib } from "./PriceConverterLib.sol";

error NotOwner();

contract FundMe {

    using PriceConverterLib for uint256; // here we are attaching all uint256 variables to this library and all of them will have access to it and its functions

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;

    mapping(address funder => uint256 fundedAmount) public mappingToAmountToFunder;

    address public immutable i_owner;

    constructor() {
        // minimumRequiredAmount = 2; // will be updated immidiately upon contract deployment
        i_owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value.getConverstionRate() >= MINIMUM_USD, "Not enough ETH has been sent :'( ! "); // 1 ETH
        funders.push(msg.sender);
        mappingToAmountToFunder[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {

        for (uint funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            mappingToAmountToFunder[funder] = 0;
        }

        //reset funders array
        funders = new address[](0);

        // Withdrawing the ACTUAL funds form the account:

        // There are 3 ways to withdraw funds: transfer, send, call

        //TRANSFER:
        // the 'this' keyword refers to the whole contract
        // msg.sender is of type: address
        // payable(msg.sender) is of type: payable address
        payable(msg.sender).transfer(address(this).balance); // throws an error if it fails, reverting the transaction

        //SEND:
        bool sendSuccess = payable(msg.sender).send(address(this).balance); // returns boolean and won't revert the transaction
        require(sendSuccess, "Sending of funds failed!"); // making this statement, we make sure to revert the transaction in case the transaction fails: sendSuccess = false

        //CALL:
        (bool callSuccess,) = payable(msg.sender).call{ value: address(this).balance }(""); //leaving call("") blank like so makes sure we don't call any function
        // we only care about the callSuccess, so we can not declare the returnedData by using: (bool callSuccess,)
        require(callSuccess, "Call failed!"); // making this statement, we make sure to revert the transaction in case the transaction fails: callSuccess = false
    }

    modifier onlyOwner() {
        // _; - if the underscore is before the require statement, this means that the function will be run and then the modifier logic will be executed
        // We want only the owner of the contract to call this function and be able to withdraw funds:
        // require(msg.sender == i_owner, "Sender is not owner of contract");
        if (msg.sender != i_owner) { // this way of throwing errors saves us GAS as we don't have to store the string message we used to with the above line
            revert NotOwner();
        }
        _; // add whatever else there is in the function
    }

    // What happens if someone sends this contract some ETH without calling the fund function? For this we have special functions:
    // receive();
    receive() external payable {
        fund();
    }
    // fallback();
    fallback() external payable {
        fund();
    }
}