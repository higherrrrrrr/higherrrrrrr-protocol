// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IHigherrrrrrr} from "./interfaces/IHigherrrrrrr.sol";
import {IHigherrrrrrrConviction} from "./interfaces/IHigherrrrrrrConviction.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {StringSanitizer} from "./libraries/StringSanitizer.sol";

contract HigherrrrrrrConviction is IHigherrrrrrrConviction, ERC721, Ownable {
    using Strings for uint256;

    uint256 private _nextTokenId;
    IHigherrrrrrr public higherrrrrrr;
    bool private initialized;

    // Add constants for text limits
    uint256 private constant MAX_INPUT_LENGTH = 1024;
    uint256 private constant SVG_TEXT_LENGTH = 100;

    mapping(uint256 => ConvictionDetails) public convictionDetails;

    constructor() ERC721("Higherrrrrrr Conviction", "CONVICTION") Ownable(msg.sender) {}

    function initialize(address _higherrrrrrr) external {
        require(!initialized, "Already initialized");
        require(_higherrrrrrr != address(0), "Invalid Higherrrrrrr address");

        higherrrrrrr = IHigherrrrrrr(_higherrrrrrr);
        _transferOwnership(_higherrrrrrr);
        initialized = true;
    }

    function mintConviction(address to, string memory evolution, string memory imageURI, uint256 amount, uint256 price)
        external
        returns (uint256 tokenId)
    {
        require(msg.sender == address(higherrrrrrr), "Only Higherrrrrrr");

        tokenId = _nextTokenId++;
        convictionDetails[tokenId] = ConvictionDetails({
            evolution: evolution,
            imageURI: imageURI,
            amount: amount,
            price: price,
            timestamp: block.timestamp
        });

        _mint(to, tokenId);
        return tokenId;
    }

    // Add function to read Higherrrrrrr contract state
    function getHigherrrrrrrState()
        public
        view
        returns (string memory currentName, uint256 currentPrice, IHigherrrrrrr.MarketType marketType)
    {
        (IHigherrrrrrr.MarketState memory state) = higherrrrrrr.state();
        IHigherrrrrrr.PriceLevel memory currentLevel;
        (currentPrice, currentLevel) = higherrrrrrr.getCurrentPriceLevel();
        currentName = currentLevel.name;
        marketType = state.marketType;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token doesn't exist");
        require(bytes(convictionDetails[tokenId].evolution).length <= MAX_INPUT_LENGTH, "Input string too long");

        ConvictionDetails memory details = convictionDetails[tokenId];

        // Format price in ETH (assuming price is in wei)
        string memory priceInEth =
            string(abi.encodePacked((details.price / 1e18).toString(), ".", (details.price % 1e18).toString()));

        string memory imageURI;
        if (higherrrrrrr.tokenType() == IHigherrrrrrr.TokenType.IMAGE_EVOLUTION) {
            imageURI = details.imageURI;
        } else {
            // Sanitize strings for SVG context
            string memory sanitizedEvolution = StringSanitizer.sanitize(details.evolution, 1);
            string memory sanitizedAmount = StringSanitizer.sanitize((details.amount / 1e18).toString(), 1);
            string memory sanitizedPrice = StringSanitizer.sanitize(priceInEth, 1);
            string memory sanitizedTimestamp = StringSanitizer.sanitize(details.timestamp.toString(), 1);

            // Create SVG with sanitized values and text overflow handling
            string memory svg = string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">',
                    "<style>",
                    "text { font-family: monospace; fill: #4afa4a; text-anchor: middle; }",
                    ".left { text-anchor: start; }",
                    ".right { text-anchor: end; }",
                    ".evolution { inline-size: 360px; overflow-wrap: break-word; white-space: pre-wrap; }",
                    "</style>",
                    '<rect width="400" height="400" fill="#000000"/>',
                    '<foreignObject x="20" y="120" width="360" height="80">',
                    '<div xmlns="http://www.w3.org/1999/xhtml" style="font-family: monospace; color: #4afa4a; font-size: 24px; text-align: center; overflow-wrap: break-word;">',
                    sanitizedEvolution,
                    "</div>",
                    "</foreignObject>",
                    '<text x="200" y="240" font-size="20">',
                    sanitizedAmount,
                    " tokens</text>",
                    '<text x="20" y="380" font-size="16" class="left">',
                    sanitizedPrice,
                    " ETH</text>",
                    '<text x="380" y="380" font-size="16" class="right">',
                    sanitizedTimestamp,
                    "</text>",
                    "</svg>"
                )
            );
            imageURI = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
        }

        // Sanitize strings for JSON context
        string memory sanitizedEvolutionJson = StringSanitizer.sanitize(details.evolution, 2);
        string memory sanitizedAmountJson = StringSanitizer.sanitize((details.amount / 1e18).toString(), 2);
        string memory sanitizedPriceJson = StringSanitizer.sanitize(priceInEth, 2);
        string memory sanitizedTimestampJson = StringSanitizer.sanitize(details.timestamp.toString(), 2);
        string memory sanitizedTokenId = StringSanitizer.sanitize(tokenId.toString(), 2);

        // Create metadata with sanitized values
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        "{",
                        '"name": "Higherrrrrrr Conviction #',
                        sanitizedTokenId,
                        '",',
                        '"description": "A record of conviction in Higherrrrrrr",',
                        '"attributes": [',
                        '{"trait_type": "Evolution", "value": "',
                        sanitizedEvolutionJson,
                        '"},',
                        '{"trait_type": "Amount", "value": "',
                        sanitizedAmountJson,
                        '"},',
                        '{"trait_type": "Price", "value": "',
                        sanitizedPriceJson,
                        '"},',
                        '{"trait_type": "Timestamp", "value": "',
                        sanitizedTimestampJson,
                        '"}',
                        "],",
                        '"image": "',
                        imageURI,
                        '"',
                        "}"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
