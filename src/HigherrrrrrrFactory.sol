// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IHigherrrrrrr} from "./interfaces/IHigherrrrrrr.sol";
import {Higherrrrrrr} from "./Higherrrrrrr.sol";
import {HigherrrrrrrConviction} from "./HigherrrrrrrConviction.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract HigherrrrrrrFactory {
    error Unauthorized();
    error ZeroAddress();

    event NewToken(address indexed token, address indexed conviction);

    // Keep individual immutable addresses
    address public immutable feeRecipient;
    address public immutable weth;
    address public immutable nonfungiblePositionManager;
    address public immutable swapRouter;
    address public immutable bondingCurve;
    address public immutable convictionImplementation;

    constructor(
        address _feeRecipient,
        address _weth,
        address _nonfungiblePositionManager,
        address _swapRouter,
        address _bondingCurve
    ) {
        if (
            _feeRecipient == address(0) || _weth == address(0) || _nonfungiblePositionManager == address(0)
                || _swapRouter == address(0) || _bondingCurve == address(0)
        ) revert ZeroAddress();

        feeRecipient = _feeRecipient;
        weth = _weth;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        swapRouter = _swapRouter;
        bondingCurve = _bondingCurve;

        // Deploy the Conviction NFT implementation once
        convictionImplementation = address(new HigherrrrrrrConviction()); // no constructor params needed
    }

    function createHigherrrrrrr(
        string calldata name,
        string calldata symbol,
        string calldata uri,
        IHigherrrrrrr.PriceLevel[] calldata levels
    ) external payable returns (address token, address conviction) {
        // Deploy token
        token = address(new Higherrrrrrr(feeRecipient, weth, nonfungiblePositionManager, swapRouter));

        // Clone the Conviction NFT implementation
        bytes32 salt = keccak256(abi.encodePacked(token, block.timestamp));
        conviction = Clones.cloneDeterministic(convictionImplementation, salt);

        // Initialize the Conviction NFT clone
        HigherrrrrrrConviction(conviction).initialize(token);

        // Initialize the token
        IHigherrrrrrr(token).initialize{value: msg.value}(bondingCurve, uri, name, symbol, levels, conviction);

        emit NewToken(token, conviction);
    }
}
