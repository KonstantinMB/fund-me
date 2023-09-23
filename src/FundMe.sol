// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { PriceConverterLib } from "./PriceConverterLib.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {

    using PriceConverterLib for uint256; // here we are attaching all uint256 variables to this library and all of them will have access to it and its functions

    address[] private s_funders;

    mapping(address funder => uint256 fundedAmount) private s_mappingAmountToFunder;

    AggregatorV3Interface private s_priceFeed;

    uint256 public constant MINIMUM_USD = 5e18;

    address private immutable i_owner;

    constructor(address priceFeed) {

        // minimumRequiredAmount = 2; // will be updated immidiately upon contract deployment
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(msg.value.getConverstionRate(s_priceFeed) >= MINIMUM_USD, "Not enough ETH has been sent :'( ! "); // 1 ETH
        s_funders.push(msg.sender);
        s_mappingAmountToFunder[msg.sender] += msg.value;
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for( uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_mappingAmountToFunder[funder] = 0;
        }
        s_funders = new address[](0);
        
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Sending of funds failed!");
    }

    function withdraw() public onlyOwner {

        for (uint funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_mappingAmountToFunder[funder] = 0;
        }

        //reset funders array
        s_funders = new address[](0);

        // Withdrawing the ACTUAL funds form the account:

        // There are 3 ways to withdraw funds: transfer, send, call

        //TRANSFER:
        // the 'this' keyword refers to the whole contract
        // msg.sender is of type: address
        // payable(msg.sender) is of type: payable address
        // payable(msg.sender).transfer(address(this).balance); // throws an error if it fails, reverting the transaction

        //SEND:
        bool sendSuccess = payable(msg.sender).send(address(this).balance); // returns boolean and won't revert the transaction
        require(sendSuccess, "Sending of funds failed!"); // making this statement, we make sure to revert the transaction in case the transaction fails: sendSuccess = false

        //CALL:
        // (bool callSuccess,) = payable(msg.sender).call{ value: address(this).balance }(""); //leaving call("") blank like so makes sure we don't call any function
        // we only care about the callSuccess, so we can not declare the returnedData by using: (bool callSuccess,)
        // require(callSuccess, "Call failed!"); // making this statement, we make sure to revert the transaction in case the transaction fails: callSuccess = false
    }

    modifier onlyOwner() {
        // _; - if the underscore is before the require statement, this means that the function will be run and then the modifier logic will be executed
        // We want only the owner of the contract to call this function and be able to withdraw funds:
        // require(msg.sender == i_owner, "Sender is not owner of contract");
        if (msg.sender != i_owner) { // this way of throwing errors saves us GAS as we don't have to store the string message we used to with the above line
            revert FundMe__NotOwner();
        }
        _; // add whatever else there is in the function
    }

    function getVersion() public view returns(uint256) {
        return s_priceFeed.version();
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

    /**
    * View / Pure functions (Getters)
    */
    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_mappingAmountToFunder[fundingAddress];
    }

    function getFunder(
        uint256 index
    ) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}