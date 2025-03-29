//SPDX-License-Identifier: MIT

//1.Deploy mocks when we are on a local anvil chain
//2. keep track of contract address across diff chains
//sepolia ETH/USD
//Manniet ETH/USD

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script{
    //if we are on a local anvil, we deploy mocks
    //otherwise, grab the exisiting address from the live network
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed;//ETH?USD price feed address
    }

    constructor()
    {
        if(block.chainid == 11155111)//block.chainid is uint type global variable which returns the chain-id of the active chain
        {
            activeNetworkConfig = getSepoliaEthConfig();
        }
        else if(block.chainid == 1)
        {
            activeNetworkConfig = getMannietEthConfig();
        }
        else{
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {//why use memory in here??
        //pricefeed address
         NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed:0x694AA1769357215DE4FAC081bf1f309aDC325306});
         return sepoliaConfig;
    }
    
    function getMannietEthConfig() public pure returns (NetworkConfig memory) {//why use memory in here??
        //pricefeed address
         NetworkConfig memory mannietConfig = NetworkConfig({priceFeed:0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
         return mannietConfig;
    }
    
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        //price feed address

        //prevent from re-deploying
        if(activeNetworkConfig.priceFeed != address(0))// address(0) = (0x0000000000000000000000000000000000000000). the default value of ethereum address
        {
            return activeNetworkConfig;// if already set, then return the exisiting config
            //other wise deploy the anvil config
        }
        
        //1. Deploy the mocks
        //2. Return the mock addresss

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });

        return anvilConfig;
    }
}       