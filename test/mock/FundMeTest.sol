// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { Test, console } from "forge-std/Test.sol"; // this contract has all test utilities we need to run/create our tests
import { FundMe } from "../../src/FundMe.sol";
import { DeployFundMe } from "../../script/DeployFundMe.sol";

contract FundMeTest is Test {

	FundMe fundMe;
	// Foundry's makeAddr function helps us create a fake address for our tests:
	address FAKE_ADDRESS = makeAddr("FAKE_ADDRESS");
	uint256 constant SEND_VALUE = 0.1 ether;
	uint256 constant STARTING_BALANCE = 10 ether;

	function setUp() external {
		DeployFundMe deployFundMe = new DeployFundMe();
		fundMe = deployFundMe.run();
		// in order to give the fake account some ETH, we can use Foundry's deal function:
		vm.deal(FAKE_ADDRESS, STARTING_BALANCE);
	}

	// Creates an address and funds the contract:
	modifier funded() {
		// we can use Foundry's prank() function to spcify the address for the next call:
		vm.prank(FAKE_ADDRESS); // a.k.a. the next TX will be send by the fake account
		fundMe.fund{value: SEND_VALUE}(); 
		_;
	}

	function testPriceFeedVersionAccuracy() public {
		uint256 version = fundMe.getVersion();
		assertEq(version, 4);
	}

	function testFundFails() public {
		vm.expectRevert(); //putting this, I am telling Foundry that the next line will revert!
		fundMe.fund();
	}

	function testFundSucceeds() public funded {

		uint256 amountFunded = fundMe.getAddressToAmountFunded(FAKE_ADDRESS);
		assertEq(amountFunded, SEND_VALUE);
	}

	function testAddsFunderToArrayOfFunders() public funded {

		address funder = fundMe.getFunder(0);
		assertEq(funder, FAKE_ADDRESS);
	}

	function testOnlyOwnerCanWithdraw() public funded {

		vm.expectRevert();
		vm.prank(FAKE_ADDRESS);
		fundMe.withdraw();
	}
	
	function testWithdrawSuccessfully() public funded {

		// Arrange
		uint256 startingOwnerBalance = fundMe.getOwner().balance;
		uint256 startingFundMeBalance = address(fundMe).balance;

		// Act
		vm.prank(fundMe.getOwner());
		fundMe.withdraw();

		// Assert
		uint256 endingOwnerBalance = fundMe.getOwner().balance;
		uint256 endingFundMeBalance = address(fundMe).balance;
		assertEq(endingFundMeBalance, 0);
		assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
	}

	function testWithdrawSuccessfullyFromMultipleFunders() public funded {
		// total gas used: 492988
		
		// Arrange
		uint160 numberOfFunders = 10; // 🚨🚨🚨 If we want to use numbers for addresses, we need to first cast to uint160 and then to uint256 if needed
		// meaning something like this 👉 uint256 numAddress = uint256(uint160(msg.sender));
		uint160 startingFunderIndex = 1;
		for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
			// vm.prank(new address)
			// vm.deal(new address)
			// but in stead of all of these, we can use the Foundry's hoax function
			hoax(address(i), SEND_VALUE);
			// we need to also fund the fundMe
			fundMe.fund{value: SEND_VALUE}();
		}

		console.log("Balances before withdrawing: ");
		uint256 startingOwnerBalance = fundMe.getOwner().balance;
		console.log(startingOwnerBalance);
		uint256 startingFundMeBalance = address(fundMe).balance;
		console.log(startingFundMeBalance);

		// Act
		vm.startPrank(fundMe.getOwner()); //using start/stop prank makes it clearer where this prank address will be used!
		fundMe.withdraw();
		vm.stopPrank();

		// Assert
		assert(address(fundMe).balance == 0);
		console.log("Balances after withdrawing: ");
		console.log(fundMe.getOwner().balance);
		console.log(address(fundMe).balance);
		assert(startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance);
	}

	function testCheaperWithdrawSuccessfullyFromMultipleFunders() public funded {
		//total gas of execution: 489640

		// Arrange
		uint160 numberOfFunders = 10;
		uint160 startingFunderIndex = 1;
		for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
			hoax(address(i), SEND_VALUE);
			fundMe.fund{value: SEND_VALUE}();
		}

		console.log("Balances before withdrawing: ");
		uint256 startingOwnerBalance = fundMe.getOwner().balance;
		uint256 startingFundMeBalance = address(fundMe).balance;

		// Act
		vm.startPrank(fundMe.getOwner());
		fundMe.cheaperWithdraw();
		vm.stopPrank();

		// Assert
		assert(address(fundMe).balance == 0);
		assert(startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance);
	}

}	