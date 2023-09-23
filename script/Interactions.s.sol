pragma solidity ^0.8.18;

import { Script, console } from "forge-std/Script.sol";
import { DevOpsTools } from "foundry-devops/src/DevOpsTools.sol";
import { FundMe } from "../src/FundMe.sol";

contract FundFundMe is Script {

	uint256 constant SEND_VALUE = 0.01 ether;

	function fundFundMe(address mostRecentlyDepolyed) public  {

		vm.startBroadcast();
		// We wrap the mostRecentlyDepolyed address with payable as we know that we'll be sending ETH with it:
		FundMe(payable(mostRecentlyDepolyed)).fund{value: SEND_VALUE}();
		console.log("the end");
		vm.stopBroadcast();
	}

	function run() external {

		address mostRecentlyDepolyed = DevOpsTools.get_most_recent_deployment(
			"FundMe",
			block.chainid
		);		
		fundFundMe(mostRecentlyDepolyed);
	}
}

contract WithdrawFundMe is Script {

	function withdrawFundMe(address mostRecentlyDepolyed) public  {
		vm.startBroadcast();
		FundMe(payable(mostRecentlyDepolyed)).withdraw();
		vm.stopBroadcast();
	}
	 
	function run() external {

		address mostRecentlyDepolyed = DevOpsTools.get_most_recent_deployment(
			"FundMe",
			block.chainid
		);
		withdrawFundMe(mostRecentlyDepolyed);
	}
}