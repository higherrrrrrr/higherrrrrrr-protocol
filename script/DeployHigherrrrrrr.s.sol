// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {Higherrrrrrr} from "../src/Higherrrrrrr.sol";
import {HigherrrrrrrConviction} from "../src/HigherrrrrrrConviction.sol";
import {HigherrrrrrrFactory} from "../src/HigherrrrrrrFactory.sol";
import {IHigherrrrrrr} from "../src/interfaces/IHigherrrrrrr.sol";

contract DeployHigherrrrrrr is Script {
    // Base mainnet addresses (with correct checksums)
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant UNISWAP_V3_POSITION_MANAGER = 0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1;
    address constant UNISWAP_V3_ROUTER = 0x2626664c2603336E57B271c5C0b26F421741e481;

    address constant MULTISIG = 0xb28E6b4e296Ef139Bc245c9bc8771998dD9A1d6A;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Factory with fake multisig
        Higherrrrrrr higherTokenImpl = new Higherrrrrrr();
        HigherrrrrrrConviction higherConvictionImpl = new HigherrrrrrrConviction();
        HigherrrrrrrFactory factory = new HigherrrrrrrFactory(
            MULTISIG,
            WETH,
            UNISWAP_V3_POSITION_MANAGER,
            UNISWAP_V3_ROUTER,
            address(higherTokenImpl),
            address(higherConvictionImpl)
        );

        console2.log("Deployed contracts:");
        console2.log("Higherrrrrrr:", address(higherTokenImpl));
        console2.log("HigherrrrrrrConviction:", address(higherConvictionImpl));
        console2.log("Factory:", address(factory));
        console2.log("Fee Recipient:", MULTISIG);

        vm.stopBroadcast();
    }
}
