// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {HigherrrrrrrFactory} from "../src/HigherrrrrrrFactory.sol";
import {BondingCurve} from "../src/BondingCurve.sol";
import {IHigherrrrrrr} from "../src/interfaces/IHigherrrrrrr.sol";

contract DeployHigherrrrrrr is Script {
    // Base mainnet addresses (with correct checksums)
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant UNISWAP_V3_POSITION_MANAGER = 0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1;
    address constant UNISWAP_V3_ROUTER = 0x2626664c2603336E57B271c5C0b26F421741e481;

    // Fake multisig address (derived from test private key + 1)
    address constant FAKE_MULTISIG = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Fund our fake multisig for testing
        vm.deal(FAKE_MULTISIG, 100 ether);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy BondingCurve
        BondingCurve bondingCurve = new BondingCurve();

        // Deploy Factory with fake multisig
        HigherrrrrrrFactory factory = new HigherrrrrrrFactory(
            FAKE_MULTISIG, // Using our fake multisig
            WETH,
            UNISWAP_V3_POSITION_MANAGER,
            UNISWAP_V3_ROUTER,
            address(bondingCurve)
        );

        // Create example price levels for testing
        IHigherrrrrrr.PriceLevel[] memory levels = new IHigherrrrrrr.PriceLevel[](3);
        levels[0] = IHigherrrrrrr.PriceLevel({price: 0.01 ether, name: "higherrrrrrr"});
        levels[1] = IHigherrrrrrr.PriceLevel({price: 0.1 ether, name: "HIGHERRRRRRR"});
        levels[2] = IHigherrrrrrr.PriceLevel({price: 1 ether, name: "HIGHERRRRRRR MOON"});

        // Deploy a test token with 1 ETH initial liquidity
        (address token, address conviction) =
            factory.createHigherrrrrrr{value: 1 ether}("Higherrrrrrr", "HIGH", "ipfs://your-token-uri", levels);

        console.log("Deployed contracts:");
        console.log("BondingCurve:", address(bondingCurve));
        console.log("Factory:", address(factory));
        console.log("Test Token:", token);
        console.log("Conviction NFT:", conviction);
        console.log("Fee Recipient (Fake Multisig):", FAKE_MULTISIG);

        vm.stopBroadcast();
    }
}
