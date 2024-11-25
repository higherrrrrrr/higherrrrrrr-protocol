// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {HigherrrrrrrConviction} from "../src/HigherrrrrrrConviction.sol";
import {Higherrrrrrr} from "../src/Higherrrrrrr.sol";
import {StringSanitizer} from "../src/libraries/StringSanitizer.sol";

contract HigherrrrrrrConvictionTest is Test {
    HigherrrrrrrConviction public conviction;
    address public token;
    address public user1;

    function setUp() public {
        user1 = makeAddr("user1");
        token = makeAddr("token"); // Mock token address

        conviction = new HigherrrrrrrConviction();
        conviction.initialize(token);
    }

    function test_Initialize() public {
        assertEq(address(conviction.higherrrrrrr()), token);
        assertEq(conviction.owner(), token);
    }

    function testFail_ReinitializeConviction() public {
        conviction.initialize(address(0x1));
    }

    function test_MintConviction() public {
        vm.startPrank(token);

        uint256 tokenId = conviction.mintConviction(user1, "highrrrrrr", 1000e18, 0.1 ether);

        assertEq(conviction.ownerOf(tokenId), user1);

        // Check conviction details
        (string memory evolution, uint256 amount, uint256 price, uint256 timestamp) =
            conviction.convictionDetails(tokenId);
        assertEq(evolution, "highrrrrrr");
        assertEq(amount, 1000e18);
        assertEq(price, 0.1 ether);
        assertEq(timestamp, block.timestamp);

        vm.stopPrank();
    }

    function testFail_UnauthorizedMint() public {
        vm.startPrank(user1);
        conviction.mintConviction(user1, "highrrrrrr", 1000e18, 0.1 ether);
        vm.stopPrank();
    }

    function test_TokenURIGeneration() public {
        vm.startPrank(token);

        uint256 tokenId = conviction.mintConviction(user1, "highrrrrrr", 1000e18, 0.1 ether);

        string memory uri = conviction.tokenURI(tokenId);
        assertTrue(bytes(uri).length > 0);

        vm.stopPrank();
    }
}
