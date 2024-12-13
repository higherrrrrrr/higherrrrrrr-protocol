// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Base64} from "solady/src/utils/Base64.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {HigherrrrrrrConviction} from "../src/HigherrrrrrrConviction.sol";
import {IHigherrrrrrr} from "../src/interfaces/IHigherrrrrrr.sol";
import {StringSanitizer} from "../src/libraries/StringSanitizer.sol";

struct Attribute {
    string trait_type;
    string value;
}

struct TokenURI {
    Attribute[] attributes;
    string description;
    string image;
    string name;
}

contract HigherrrrrrrConvictionTest is Test {
    using stdJson for string;

    HigherrrrrrrConviction public conviction;
    address public token;
    address public user1;

    function setUp() public {
        user1 = makeAddr("user1");
        token = makeAddr("token"); // Mock token address

        conviction = new HigherrrrrrrConviction();
        conviction.initialize(token);
    }

    function parseTokenURI(string memory uri) internal pure returns (TokenURI memory tokenData) {
        bytes memory decodedUri = Base64.decode(LibString.slice(uri, 29));
        bytes memory parsedUri = string(decodedUri).parseRaw("$");
        tokenData = abi.decode(parsedUri, (TokenURI));
    }

    struct PriceTestCase {
        uint256 price;
        string expectedFormat;
    }

    function test_TokenURIGeneration_PriceAttribute() public {
        vm.startPrank(token);
        vm.mockCall(
            address(token),
            abi.encodeWithSelector(bytes4(keccak256("tokenType()"))),
            abi.encode(IHigherrrrrrr.TokenType.TEXT_EVOLUTION)
        );

        PriceTestCase[] memory tests = new PriceTestCase[](4);
        tests[0] = PriceTestCase({price: 1.5 ether, expectedFormat: "1.5"});
        tests[1] = PriceTestCase({price: 1 ether, expectedFormat: "1.0"});
        tests[2] = PriceTestCase({price: 0.1 ether, expectedFormat: "0.1"});
        tests[3] = PriceTestCase({price: 1 wei, expectedFormat: "0.000000000000000001"});

        for (uint256 i = 0; i < tests.length; i++) {
            uint256 tokenId = conviction.mintConviction(user1, "highrrrrrr", "", 1000e18, tests[i].price);
            TokenURI memory data = parseTokenURI(conviction.tokenURI(tokenId));
            bool containsPriceAttribute = false;

            for (uint256 j = 0; j < data.attributes.length; j++) {
                Attribute memory attr = data.attributes[j];

                if (LibString.eq(attr.trait_type, "Price")) {
                    containsPriceAttribute = true;
                    assertEq(attr.value, tests[i].expectedFormat);
                }
            }

            assertEq(containsPriceAttribute, true);
        }

        vm.stopPrank();
    }
}
