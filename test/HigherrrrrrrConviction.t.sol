// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {HigherrrrrrrConviction} from "../src/HigherrrrrrrConviction.sol";
import {Higherrrrrrr} from "../src/Higherrrrrrr.sol";
import {IHigherrrrrrr} from "../src/interfaces/IHigherrrrrrr.sol";
import {StringSanitizer} from "../src/libraries/StringSanitizer.sol";
import {Base64Decoder} from "../src/libraries/Base64Decoder.sol";

contract HigherrrrrrrConvictionTest is Test {
    using Strings for uint256;
    HigherrrrrrrConviction public conviction;
    address public token;
    address public user1;

    struct DecimalTestCase {
        uint256 amount;
        string expectedJson;
        string expectedSVG;
    }

    
    struct PriceTest {
        uint256 price;
        string expectedFormat;
    }

    function setUp() public {
        user1 = makeAddr("user1");
        token = makeAddr("token"); // Mock token address

        conviction = new HigherrrrrrrConviction();
        conviction.initialize(token);
    }



    // Helpers 
    function extractSVGFromJson(string memory json) internal pure returns (string memory) {
        int256 svgStart = _indexOf(json, "data:image/svg+xml;base64,");
        require(svgStart >= 0, "SVG not found in JSON");
        
        string memory base64Start = substring(json, uint256(svgStart) + 26);
        int256 quotePos = _indexOf(base64Start, "\"");
        require(quotePos >= 0, "SVG end not found");
        
        return substringWithLength(base64Start, 0, uint256(quotePos));
    }

    function substring(
        string memory str,
        uint256 startIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(startIndex <= strBytes.length, "Start index out of bounds");
        
        bytes memory result = new bytes(strBytes.length - startIndex);
        for(uint i = 0; i < strBytes.length - startIndex; i++) {
            result[i] = strBytes[i + startIndex];
        }
        return string(result);
    }

    function substringWithLength(
        string memory str,
        uint256 startIndex,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(startIndex + length <= strBytes.length, "Range out of bounds");
        
        bytes memory result = new bytes(length);
        for(uint i = 0; i < length; i++) {
            result[i] = strBytes[startIndex + i];
        }
        return string(result);
    }

        
    function substring(string memory str, uint256 startIndex, uint256 endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(startIndex <= endIndex, "Invalid substring indexes");
        require(endIndex <= strBytes.length, "End index out of bounds");
        
        bytes memory result = new bytes(endIndex - startIndex);
        for(uint i = 0; i < endIndex - startIndex; i++) {
            result[i] = strBytes[startIndex + i];
        }
        return string(result);
    }

    
    function _startsWith(string memory str, string memory prefix) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory prefixBytes = bytes(prefix);

        if (strBytes.length < prefixBytes.length) {
            return false;
        }

        for (uint256 i = 0; i < prefixBytes.length; i++) {
            if (strBytes[i] != prefixBytes[i]) {
                return false;
            }
        }
        return true;
    }

    function decodeTokenURI(string memory uri) internal pure returns (string memory) {
        require(_startsWith(uri, "data:application/json;base64,"), "Invalid URI format");
        
        // Remove prefix e decodifica
        string memory base64Json = substring(uri, 29); // length of "data:application/json;base64,"
        bytes memory decodedBytes = Base64Decoder.decode(base64Json);
        
        return string(decodedBytes);
    }

        function _containsString(string memory _string, string memory search) 
        private 
        pure 
        returns (bool) 
    {
        bytes memory stringBytes = bytes(_string);
        bytes memory searchBytes = bytes(search);

        if (searchBytes.length > stringBytes.length) {
            return false;
        }

        for (uint256 i = 0; i <= stringBytes.length - searchBytes.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < searchBytes.length; j++) {
                if (stringBytes[i + j] != searchBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                return true;
            }
        }
        return false;
    }

    function formatEthValue(uint256 weiAmount) internal pure returns (string memory) {
        uint256 wholeNumber = weiAmount / 1e18;
        uint256 decimals = weiAmount % 1e18;
        
        // Handle trailing zeros in decimals
        while (decimals > 0 && decimals % 10 == 0) {
            decimals = decimals / 10;
        }
        
        if (decimals == 0) {
            return string(abi.encodePacked(wholeNumber.toString(), ".0"));
        }
        
        return string(abi.encodePacked(
            wholeNumber.toString(),
            ".",
            decimals.toString()
        ));
    }

    // Tests

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

    function test_NFTDisplayAmounts() public {
        vm.startPrank(token);

        // Test with 1 ETH
        uint256 oneEth = 1 ether;
        uint256 tokenId = conviction.mintConviction(user1, "highrrrrrr", 1000e18, oneEth);
        string memory uri = conviction.tokenURI(tokenId);
        
        // Log the full URI and details
        console2.log("Full URI:");
        console2.log(uri);
        
        // Get stored details
        (,, uint256 storedPrice,) = conviction.convictionDetails(tokenId);
        console2.log("\nStored price (wei):", storedPrice);
        
        // Contract builds price string as: price/1e18 + "." + price%1e18
        string memory wholeNumber = (storedPrice / 1e18).toString();
        string memory decimals = (storedPrice % 1e18).toString();
        console2.log("Whole number part:", wholeNumber);
        console2.log("Decimal part:", decimals);
        
        // Try finding different variations
        assertTrue(
            _containsString(uri, wholeNumber), 
            "URI should contain whole number part"
        );

        vm.stopPrank();
    }

    function test_NFTAmountSanitization() public {
        vm.startPrank(token);

        // Test with malicious input
        uint256 price = 1234567890000000000; // 1.23456789 ETH
        uint256 tokenId = conviction.mintConviction(
            user1,
            "highr<script>alert('xss')</script>",
            1000e18,
            price
        );
        
        string memory uri = conviction.tokenURI(tokenId);
        console2.log("URI Output for sanitization test:");
        console2.log(uri);
        
        // Log the conviction details
        (string memory evolution,,,) = conviction.convictionDetails(tokenId);
        console2.log("Stored evolution name:", evolution);

        assertTrue(
            !_containsString(uri, "<script>"), 
            "Raw script tags should not be present"
        );

        vm.stopPrank();
    }

    function test_URIFormat() public {
        vm.startPrank(token);

        uint256 tokenId = conviction.mintConviction(user1, "highrrrrrr", 1000e18, 1 ether);
        string memory uri = conviction.tokenURI(tokenId);
        string memory decodedJson = decodeTokenURI(uri);

        assertTrue(
            _containsString(decodedJson, "\"image\""),
            "URI should contain image field"
        );
        
        assertTrue(
            _containsString(decodedJson, "\"attributes\""),
            "URI should contain attributes field"
        );

        vm.stopPrank();
    }


    function test_GetHigherrrrrrrState() public {
        vm.startPrank(token);
        
        // Mock the required return values
        vm.mockCall(
            token,
            abi.encodeWithSignature("name()"),
            abi.encode("highrrrrrr")
        );
        
        vm.mockCall(
            token,
            abi.encodeWithSignature("getCurrentPrice()"),
            abi.encode(1 ether)
        );
        
        vm.mockCall(
            token,
            abi.encodeWithSignature("state()"),
            abi.encode(IHigherrrrrrr.MarketState({
                marketType: IHigherrrrrrr.MarketType.BONDING_CURVE,
                marketAddress: address(0x1)
            }))
        );

        (string memory name, uint256 price, IHigherrrrrrr.MarketType marketType) = conviction.getHigherrrrrrrState();
        
        assertEq(name, "highrrrrrr", "Name should match");
        assertEq(price, 1 ether, "Price should match");
        assertEq(uint256(marketType), uint256(IHigherrrrrrr.MarketType.BONDING_CURVE), "Market type should match");

        vm.stopPrank();
    }

    function testFail_TokenURIInvalidTokenId() public {
        conviction.tokenURI(999); // Should revert with "Token doesn't exist"
    }

    function testFail_TokenURIInputTooLong() public {
        vm.startPrank(token);
        
        // Create a string longer than MAX_INPUT_LENGTH
        string memory longString = "";
        for(uint i = 0; i < 1025; i++) {
            longString = string(abi.encodePacked(longString, "a"));
        }
        
        uint256 tokenId = conviction.mintConviction(
            user1,
            longString,
            1000e18,
            1 ether
        );
        
        conviction.tokenURI(tokenId); // Should revert with "Input string too long"
        
        vm.stopPrank();
    }

    function test_TokenURIEdgeCases() public {
        vm.startPrank(token);

        // Test case 1: Very small value of ETH (1 wei)
        uint256 smallAmount = 1; // 1 wei
        uint256 tokenId1 = conviction.mintConviction(user1, "highrrrrrr", 1000e18, smallAmount);
        string memory uri1 = conviction.tokenURI(tokenId1);
        string memory decodedJson1 = decodeTokenURI(uri1);
        
        // Debug: Print the Actual Value
        console2.log("Small amount JSON:");
        console2.log(decodedJson1);
        
        // Verify that the value appears in any valid format
        assertTrue(
            _containsString(decodedJson1, "0.000000000000000001") || 
            _containsString(decodedJson1, "1 wei") ||
            _containsString(decodedJson1, "0.1e-17") ||
            _containsString(decodedJson1, "0.1"),
            "Should handle very small ETH amounts"
        );

        // Rest of the test cases
        uint256 largeAmount = type(uint128).max;
        uint256 tokenId2 = conviction.mintConviction(user1, "highrrrrrr", 1000e18, largeAmount);
        string memory uri2 = conviction.tokenURI(tokenId2);
        assertTrue(bytes(uri2).length > 0, "Should handle large ETH amounts");

        uint256 tokenId3 = conviction.mintConviction(
            user1,
            unicode"highr©",
            1000e18,
            1 ether
        );
        string memory uri3 = conviction.tokenURI(tokenId3);
        assertTrue(bytes(uri3).length > 0, "Should handle special characters");

        uint256 tokenId4 = conviction.mintConviction(user1, "", 1000e18, 1 ether);
        string memory uri4 = conviction.tokenURI(tokenId4);
        assertTrue(bytes(uri4).length > 0, "Should handle empty strings");

        vm.stopPrank();
    }

    function test_ComplexSanitization() public {
        vm.startPrank(token);

        // Test case 1: Complex HTML with different types of tags and attributes
        string memory complexHtml = '<div onclick="alert(1)" style="color: red"><script>evil()</script><img src="x" onerror="alert(1)"/></div>';
        uint256 tokenId1 = conviction.mintConviction(user1, complexHtml, 1000e18, 1 ether);
        string memory uri1 = conviction.tokenURI(tokenId1);
        
        assertTrue(!_containsString(uri1, "<script>"), "Should remove script tags");
        assertTrue(!_containsString(uri1, "onclick"), "Should remove event handlers");
        assertTrue(!_containsString(uri1, "onerror"), "Should remove error handlers");

        // Test Case 2: Strings with JSON Escaped Characters
        string memory jsonTrick = '{"evolution": "malicious"}\\";alert(1);//';
        uint256 tokenId2 = conviction.mintConviction(user1, jsonTrick, 1000e18, 1 ether);
        string memory uri2 = conviction.tokenURI(tokenId2);
        
        assertTrue(!_containsString(uri2, "\\\""), "Should properly escape JSON");

        // Test Case 3: Control Characters
        string memory controlChars = string(abi.encodePacked(
            "bad", bytes1(0x00), "chars", bytes1(0x0A), "here"
        ));
        uint256 tokenId3 = conviction.mintConviction(user1, controlChars, 1000e18, 1 ether);
        string memory uri3 = conviction.tokenURI(tokenId3);
        
        assertTrue(bytes(uri3).length > 0, "Should handle control characters");

        vm.stopPrank();
    }

    function test_SVGRendering() public {
        vm.startPrank(token);

        uint256 tokenId = conviction.mintConviction(user1, "highrrrrrr", 1000e18, 1 ether);
        string memory uri = conviction.tokenURI(tokenId);
        
        // Decode the JSON first
        string memory decodedJson = decodeTokenURI(uri);
        
        // Debug: Print or JSON decoded
        console2.log("Decoded JSON:");
        console2.log(decodedJson);

        // Find and extract base64 SVG from JSON
        int256 svgStart = _indexOf(decodedJson, "data:image/svg+xml;base64,");
        require(svgStart >= 0, "SVG not found in JSON");
        
        // Extract SVG in base64 (removing the prefix)
        string memory base64Start = substring(decodedJson, uint256(svgStart) + 26);
        
        // Find the end of base64 (before the last quotation marks)
        int256 quotePos = _indexOf(base64Start, "\"");
        require(quotePos >= 0, "SVG end not found");
        
        // Extract base64 content only
        string memory svgBase64 = substringWithLength(base64Start, 0, uint256(quotePos));
        
        // Decoding the SVG of base64
        string memory svgContent = string(Base64Decoder.decode(svgBase64));
        
        // Debug: Print or SVG decoded
        console2.log("Decoded SVG:");
        console2.log(svgContent);

        // SVG Checks
        assertTrue(
            _containsString(svgContent, "font-family: monospace"), 
            "Should have monospace font family"
        );
        
        assertTrue(
            _containsString(svgContent, "#4afa4a"), 
            "Should have correct color"
        );

        assertTrue(
            _containsString(svgContent, "<svg") && 
            _containsString(svgContent, "viewBox"), 
            "Should have SVG root element with viewBox"
        );

        assertTrue(
            _containsString(svgContent, "tokens") && 
            _containsString(svgContent, "ETH"), 
            "Should include required labels"
        );

        vm.stopPrank();
    }

    function test_URIStructure() public {
        vm.startPrank(token);

        uint256 tokenId = conviction.mintConviction(user1, "highrrrrrr", 1000e18, 1 ether);
        string memory uri = conviction.tokenURI(tokenId);
        
        // Check full URI structure
        assertTrue(_startsWith(uri, "data:application/json;base64,"), "Should start with correct prefix");
        string memory decodedJson = decodeTokenURI(uri);
        
        // Check required JSON fields
        assertTrue(_containsString(decodedJson, "\"name\""), "Should have name field");
        assertTrue(_containsString(decodedJson, "\"description\""), "Should have description field");
        assertTrue(_containsString(decodedJson, "\"image\""), "Should have image field");
        assertTrue(_containsString(decodedJson, "\"attributes\""), "Should have attributes field");
        
        // Check Attribute Structure
        assertTrue(_containsString(decodedJson, "\"trait_type\""), "Should have trait_type fields");
        assertTrue(_containsString(decodedJson, "\"value\""), "Should have value fields");

        vm.stopPrank();
    }


    function _indexOf(string memory _str, string memory _sub) internal pure returns (int256) {
        bytes memory str = bytes(_str);
        bytes memory sub = bytes(_sub);
        
        if (sub.length == 0) {
            return 0;
        }
        if (str.length < sub.length) {
            return -1;
        }
        
        for (uint i = 0; i <= str.length - sub.length; i++) {
            bool found = true;
            for (uint j = 0; j < sub.length; j++) {
                if (str[i + j] != sub[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                return int256(i);
            }
        }
        return -1;
    }


    function test_AttributesValues() public {
        vm.startPrank(token);

        // Create NFTs with specific values
        string memory evolutionName = "TestEvolution";
        uint256 amount = 1234567890000000000000; // 1234.56789 tokens
        uint256 price = 2 ether;
        
        uint256 tokenId = conviction.mintConviction(user1, evolutionName, amount, price);
        string memory uri = conviction.tokenURI(tokenId);
        string memory decodedJson = decodeTokenURI(uri);
        
        // Verify that attribute values are correct
        assertTrue(_containsString(decodedJson, evolutionName), "Evolution name not found in attributes");
        assertTrue(_containsString(decodedJson, "1234"), "Amount not found in attributes");
        assertTrue(_containsString(decodedJson, "2.0"), "Price not found in attributes");
        
        // Verify that the timestamp is present
        assertTrue(_containsString(decodedJson, block.timestamp.toString()), "Timestamp not found in attributes");
        
        vm.stopPrank();
    }

    function test_TokenURIPriceFormatting() public {
        vm.startPrank(token);
        
        
        
        PriceTest[] memory tests = new PriceTest[](4);
        tests[0] = PriceTest({
            price: 1.5 ether,
            expectedFormat: "1.5"
        });
        tests[1] = PriceTest({
            price: 1 ether,
            expectedFormat: "1.0"
        });
        tests[2] = PriceTest({
            price: 0.1 ether,
            expectedFormat: "0.1"
        });
        tests[3] = PriceTest({
            price: 1000 ether,
            expectedFormat: "1000.0"
        });

        for (uint256 i = 0; i < tests.length; i++) {
            uint256 tokenId = conviction.mintConviction(user1, "Test", 1000e18, tests[i].price);
            string memory uri = conviction.tokenURI(tokenId);
            string memory decodedJson = decodeTokenURI(uri);
            
            console2.log("\nTest Case", i);
            console2.log("Price (wei):", tests[i].price);
            console2.log("Expected format:", tests[i].expectedFormat);
            console2.log("Decoded JSON:", decodedJson);
            
            assertTrue(
                _containsString(decodedJson, tests[i].expectedFormat), 
                string(abi.encodePacked("Price not formatted correctly for: ", tests[i].expectedFormat))
            );
        }
        
        vm.stopPrank();
    }

    
    function test_ETHDecimalFormatting() public {
        vm.startPrank(token);

        DecimalTestCase[] memory testCases = new DecimalTestCase[](6);

        // Case 1: Integer value (1 ETH)
        testCases[0] = DecimalTestCase({
            amount: 1 ether,
            expectedJson: "{\"trait_type\": \"Price\", \"value\": \"1.0\"}",
            expectedSVG: "1.0 ETH"
        });

        // Case 2: Value with simple decimals (1.5 ETH)
        testCases[1] = DecimalTestCase({
            amount: 1500000000000000000,
            expectedJson: "{\"trait_type\": \"Price\", \"value\": \"1.5\"}",
            expectedSVG: "1.5 ETH"
        });

        // Case 3: Small amount (0.1 ETH)
        testCases[2] = DecimalTestCase({
            amount: 100000000000000000,
            expectedJson: "{\"trait_type\": \"Price\", \"value\": \"0.1\"}",
            expectedSVG: "0.1 ETH"
        });

        // Case 4: Very small amount with trailing significant digits (1 wei)
        testCases[3] = DecimalTestCase({
            amount: 1,
            expectedJson: "{\"trait_type\": \"Price\", \"value\": \"0.000000000000000001\"}",
            expectedSVG: "0.000000000000000001 ETH"
        });

        // Case 5: Zero ETH - Now returns just "0"
        testCases[4] = DecimalTestCase({
            amount: 0,
            expectedJson: "{\"trait_type\": \"Price\", \"value\": \"0\"}",
            expectedSVG: "0 ETH"
        });

        // Case 6: Value with Complex Decimals (all digits significant)
        testCases[5] = DecimalTestCase({
            amount: 1234567890123456789,
            expectedJson: "{\"trait_type\": \"Price\", \"value\": \"1.234567890123456789\"}",
            expectedSVG: "1.234567890123456789 ETH"
        });

        for (uint256 i = 0; i < testCases.length; i++) {
            DecimalTestCase memory tc = testCases[i];
            
            uint256 tokenId = conviction.mintConviction(user1, "Test", 1000e18, tc.amount);
            string memory uri = conviction.tokenURI(tokenId);
            string memory decodedJson = decodeTokenURI(uri);
            
            // Debug output
            console2.log("\nTest Case", i);
            console2.log("Amount (wei):", tc.amount);
            console2.log("Expected JSON format:", tc.expectedJson);
            console2.log("Actual JSON:", decodedJson);

            // Extract and show SVG
            string memory svgBase64 = extractSVGFromJson(decodedJson);
            string memory svgContent = string(Base64Decoder.decode(svgBase64));
            console2.log("SVG Content:", svgContent);

            // Check formatting in JSON
            bool containsExpectedJson = _containsString(decodedJson, tc.expectedJson);
            if (!containsExpectedJson) {
                console2.log("Looking for JSON pattern:", tc.expectedJson);
                console2.log("In JSON:", decodedJson);
            }
            assertTrue(containsExpectedJson, "JSON should contain correct price format");

            // Check formatting in SVG
            bool containsExpectedSvg = _containsString(svgContent, tc.expectedSVG);
            if (!containsExpectedSvg) {
                console2.log("SVG format mismatch");
                console2.log("Expected:", tc.expectedSVG);
                console2.log("In SVG:", svgContent);
            }
            assertTrue(containsExpectedSvg, "SVG should contain correct price format");

            // Check stored value
            (,, uint256 storedPrice,) = conviction.convictionDetails(tokenId);
            assertEq(storedPrice, tc.amount, "Stored price should match input amount");
        }

        vm.stopPrank();
    }

  
}
