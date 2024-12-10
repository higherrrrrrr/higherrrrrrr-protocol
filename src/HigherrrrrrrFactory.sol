// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Higherrrrrrr} from "./Higherrrrrrr.sol";
import {IHigherrrrrrr} from "./interfaces/IHigherrrrrrr.sol";
import {IHigherrrrrrrConviction} from "./interfaces/IHigherrrrrrrConviction.sol";

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
    address public immutable tokenImplementation;
    address public immutable convictionImplementation;

    constructor(
        address _feeRecipient,
        address _weth,
        address _nonfungiblePositionManager,
        address _swapRouter,
        address _bondingCurve,
        address _tokenImplementation,
        address _convictionImplementation
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
        tokenImplementation = _tokenImplementation;
        convictionImplementation = _convictionImplementation;
    }

    function createHigherrrrrrr(
        string calldata name,
        string calldata symbol,
        string calldata uri,
        IHigherrrrrrr.TokenType _tokenType,
        IHigherrrrrrr.PriceLevel[] calldata levels
    ) external payable returns (address token, address conviction) {
        // Clone the Conviction NFT implementation
        bytes32 salt = keccak256(abi.encodePacked(token, block.timestamp));
        conviction = Clones.cloneDeterministic(convictionImplementation, salt);

        // Deploy token
        token = Clones.cloneDeterministic(tokenImplementation, salt);

        IHigherrrrrrr(token).initialize{value: msg.value}(
            feeRecipient,
            weth,
            nonfungiblePositionManager,
            swapRouter,
            bondingCurve,
            _tokenType,
            uri,
            name,
            symbol,
            levels,
            conviction
        );

        // Initialize the Conviction NFT clone
        IHigherrrrrrrConviction(conviction).initialize(token);

        emit NewToken(token, conviction);
    }

    function sweep() external {}
}
