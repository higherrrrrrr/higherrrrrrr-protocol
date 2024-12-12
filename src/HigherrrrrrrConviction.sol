// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Base64} from "solady/src/utils/Base64.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {ERC721} from "solady/src/tokens/ERC721.sol";
import {Initializable} from "solady/src/utils/Initializable.sol";

import {IHigherrrrrrrConviction} from "./interfaces/IHigherrrrrrrConviction.sol";
import {IHigherrrrrrr} from "./interfaces/IHigherrrrrrr.sol";
import {StringSanitizer} from "./libraries/StringSanitizer.sol";

contract HigherrrrrrrConviction is IHigherrrrrrrConviction, ERC721, Ownable, Initializable {
    using LibString for uint256;

    uint256 public totalSupply;
    IHigherrrrrrr public higherrrrrrr;

    mapping(uint256 => ConvictionDetails) public convictionDetails;

    function initialize(address _higherrrrrrr) external initializer {
        _setOwner(_higherrrrrrr);

        totalSupply = 0;
        higherrrrrrr = IHigherrrrrrr(_higherrrrrrr);
    }

    function name() public view override returns (string memory) {
        return IERC20(address(higherrrrrrr)).name();
    }

    function symbol() public pure override returns (string memory) {
        return "CONVICTION";
    }

    function mintConviction(
        address to,
        string memory currentName,
        string memory currentImageURI,
        uint256 amount,
        uint256 currentPrice
    ) external onlyOwner returns (uint256 tokenId) {
        tokenId = totalSupply++;

        convictionDetails[tokenId] = ConvictionDetails({
            name: currentName,
            imageURI: currentImageURI,
            amount: amount,
            price: currentPrice,
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
        if (tokenId >= totalSupply || _ownerOf(tokenId) == address(0)) {
            revert TokenDoesNotExist();
        }

        ConvictionDetails storage details = convictionDetails[tokenId];

        // Format price in ETH (assuming price is in wei)
        string memory priceInEth =
            string(abi.encodePacked((details.price / 1e18).toString(), ".", (details.price % 1e18).toString()));

        string memory imageURI;
        if (higherrrrrrr.tokenType() == IHigherrrrrrr.TokenType.IMAGE_EVOLUTION) {
            imageURI = details.imageURI;
        } else {
            // Create SVG with sanitized values and text overflow handling
            bytes memory svg = abi.encodePacked(
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
                StringSanitizer.sanitizeSVG(details.name),
                "</div>",
                "</foreignObject>",
                '<text x="200" y="240" font-size="20">',
                StringSanitizer.sanitizeSVG((details.amount / 1e18).toString()),
                " tokens</text>",
                '<text x="20" y="380" font-size="16" class="left">',
                StringSanitizer.sanitizeSVG(priceInEth),
                " ETH</text>",
                '<text x="380" y="380" font-size="16" class="right">',
                StringSanitizer.sanitizeSVG(details.timestamp.toString()),
                "</text>",
                "</svg>"
            );
            imageURI = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(svg)));
        }

        // Create metadata with sanitized values
        string memory json = Base64.encode(
            abi.encodePacked(
                "{",
                '"name": "Higherrrrrrr Conviction #',
                StringSanitizer.sanitizeJSON(tokenId.toString()),
                '",',
                '"description": "A record of conviction in Higherrrrrrr",',
                '"attributes": [',
                '{"trait_type": "Evolution", "value": "',
                StringSanitizer.sanitizeJSON(details.name),
                '"},',
                '{"trait_type": "Amount", "value": "',
                StringSanitizer.sanitizeJSON((details.amount / 1e18).toString()),
                '"},',
                '{"trait_type": "Price", "value": "',
                StringSanitizer.sanitizeJSON(priceInEth),
                '"},',
                '{"trait_type": "Timestamp", "value": "',
                StringSanitizer.sanitizeJSON(details.timestamp.toString()),
                '"}',
                "],",
                '"image": "',
                imageURI,
                '"',
                "}"
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
