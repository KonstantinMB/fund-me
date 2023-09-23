// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { Test, console } from "forge-std/Test.sol"; // this contract has all test utilities we need to run/create our tests
import { FundMe } from "../../src/FundMe.sol";
import { DeployFundMe } from "../../script/DeployFundMe.sol";
import { FundFundMe, WithdrawFundMe } from "../../script/Interactions.s.sol";

contract FundMeITest is Test {

	FundMe fundMe;
	// Foundry's makeAddr function helps us create a fake address for our tests:
	address FAKE_ADDRESS = makeAddr("FAKE_ADDRESS");
	uint256 constant SEND_VALUE = 0.1 ether;
	uint256 constant STARTING_BALANCE = 10 ether;
	uint256 constant GAS_PRICE = 1;

	function setUp() external {

		DeployFundMe deploy = new DeployFundMe();
		fundMe = deploy.run();
		// in order to give the fake account some ETH, we can use Foundry's deal function:
		vm.deal(FAKE_ADDRESS, STARTING_BALANCE);
	}

	// function testUserCanFundInteractions() public {

	// 	uint256 fundMeBalanceBefore = address(fundMe).balance;
	// 	FundFundMe fundFundMe = new FundFundMe();
	// 	vm.prank(FAKE_ADDRESS);
	// 	vm.deal(FAKE_ADDRESS, 1e18);
	// 	fundFundMe.fundFundMe(address(FAKE_ADDRESS));

	// 	address funder = fundMe.getFunder(0);
	// 	assertEq(funder, FAKE_ADDRESS);
	// 	assertEq(fundMeBalanceBefore, address(fundMe).balance - 1e18);
	// }

	function testUserCanWithdrawInteractions() public {

		FundFundMe fundFundMe = new FundFundMe();
		fundFundMe.fundFundMe(address(fundMe));
		
		WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
		withdrawFundMe.withdrawFundMe(address(fundMe));

		assert(address(fundMe).balance == 0);
	}

}