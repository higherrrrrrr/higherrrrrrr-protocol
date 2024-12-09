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

    address constant FAKE_MULTISIG = 0xb28E6b4e296Ef139Bc245c9bc8771998dD9A1d6A;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy BondingCurve
        BondingCurve bondingCurve = new BondingCurve();

        // Deploy Factory with fake multisig
        HigherrrrrrrFactory factory = new HigherrrrrrrFactory(
            FAKE_MULTISIG,
            WETH,
            UNISWAP_V3_POSITION_MANAGER,
            UNISWAP_V3_ROUTER,
            address(bondingCurve)
        );

        console.log("Deployed contracts:");
        console.log("BondingCurve:", address(bondingCurve));
        console.log("Factory:", address(factory));
        console.log("Fee Recipient (Fake Multisig):", FAKE_MULTISIG);

        vm.stopBroadcast();
    }
}
