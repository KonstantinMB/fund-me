// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { Script } from "forge-std/Script.sol";
import { FundMe } from "../src/FundMe.sol";
import { HelperConfig } from "./HelperConfig.sol";

contract DeployFundMe is Script {

	function run() external returns(FundMe) {

		// !!! Before startBroadcast == NOT IN a real transaction
		HelperConfig helperConfig = new HelperConfig();
		(address ethUsdPriceFeed) = helperConfig.activeNetworkConfig();

		vm.startBroadcast();
		// !!! After startBroadcast == IN a real transaction
		FundMe fundMe = new FundMe(ethUsdPriceFeed);
		vm.stopBroadcast();
		return fundMe;
	}
}