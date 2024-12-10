// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IHigherrrrrrr} from "./IHigherrrrrrr.sol";

interface IHigherrrrrrrConviction {
    struct ConvictionDetails {
        string evolution;
        string imageURI;
        uint256 amount;
        uint256 price;
        uint256 timestamp;
    }

    function initialize(address _higherrrrrrr) external;

    function mintConviction(address to, string memory evolution, string memory imageURI, uint256 amount, uint256 price)
        external
        returns (uint256);

    function getHigherrrrrrrState()
        external
        view
        returns (string memory currentName, uint256 currentPrice, IHigherrrrrrr.MarketType marketType);

    function convictionDetails(uint256 tokenId)
        external
        view
        returns (string memory evolution, string memory imageURI, uint256 amount, uint256 price, uint256 timestamp);

    function higherrrrrrr() external view returns (IHigherrrrrrr);
}
