// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// We will use this file to:
// 1. Deploy mock when we are on a local anvil chain
// 2. Keep track of the contract address accros different chains
// Sepolia ETH/USD
// Mainnet ETH/USD

import { Script } from "../forge-std/Script.sol";
import { MockV3Aggregator } from "../test/mock/MockV3Aggregator.sol";

contract HelperConfig is Script {

	// If we are on a local anvil, we deploy mocks
	// Otherwise, grab the existing address from the live network
	NetworkConfig public activeNetworkConfig;

	uint8 public constant DECIMALS = 8;
	int256 public constant INITIAL_PRICE = 2000e8;

	struct NetworkConfig {
		address priceFeed; //ETH/USD price feed address
	}

	constructor() {
		if (block.chainid == 11155111) {
			activeNetworkConfig = getSepoliaEthConfig();
		} else if(block.chainid == 1) {
			activeNetworkConfig = getMainnetEthConfig();
		} else {
			activeNetworkConfig = getOrCreateAnvilConfig();
		}
	}

	function getSepoliaEthConfig() public pure returns(NetworkConfig memory) {
		// price feed address
		NetworkConfig memory sepoliaConfig = NetworkConfig({
			priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
		});

		return sepoliaConfig;
	}

	function getMainnetEthConfig() public pure returns(NetworkConfig memory) {
		// price feed address
		NetworkConfig memory mainnetEthConfig = NetworkConfig({
			priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
		});

		return mainnetEthConfig;
	}

	function getOrCreateAnvilConfig() public returns(NetworkConfig memory) {

		// This if-statement guarantees us that we won't create a new mock if one already exists:
		if (activeNetworkConfig.priceFeed != address(0)) { // have we set some address to the priceFeed
			return activeNetworkConfig; // if yes, return the already set address
		}

		// 1. Deploy the mocks
		vm.startBroadcast();
		MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
		vm.stopBroadcast();
		// 2. Return the mock address
		NetworkConfig memory anvilConfig = NetworkConfig({
			priceFeed: address(mockPriceFeed)
		});
		return anvilConfig;
	}

}