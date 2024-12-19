// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {LibClone} from "solady/utils/LibClone.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

import {Higherrrrrrr} from "./Higherrrrrrr.sol";
import {IHigherrrrrrr} from "./interfaces/IHigherrrrrrr.sol";
import {IHigherrrrrrrConviction} from "./interfaces/IHigherrrrrrrConviction.sol";

contract HigherrrrrrrFactory {
    using SafeTransferLib for address;
    using FixedPointMathLib for uint256;

    error ZeroAddress();

    event NewToken(
        address indexed token, address indexed conviction, string name, string symbol, IHigherrrrrrr.TokenType tokenType
    );

    // Keep individual immutable addresses
    address public immutable feeRecipient;
    address public immutable weth;
    address public immutable nonfungiblePositionManager;
    address public immutable swapRouter;
    address public immutable tokenImplementation;
    address public immutable convictionImplementation;

    constructor(
        address _feeRecipient,
        address _weth,
        address _nonfungiblePositionManager,
        address _swapRouter,
        address _tokenImplementation,
        address _convictionImplementation
    ) {
        if (
            _feeRecipient == address(0) || _weth == address(0) || _nonfungiblePositionManager == address(0)
                || _swapRouter == address(0)
        ) revert ZeroAddress();

        feeRecipient = _feeRecipient;
        weth = _weth;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        swapRouter = _swapRouter;

        // Deploy the Conviction NFT implementation once
        tokenImplementation = _tokenImplementation;
        convictionImplementation = _convictionImplementation;
    }

    function createHigherrrrrrr(
        string calldata _name,
        string calldata _symbol,
        string calldata _baseTokenURI,
        IHigherrrrrrr.TokenType _tokenType,
        IHigherrrrrrr.PriceLevel[] calldata _priceLevels
    ) external payable returns (address token, address conviction) {
        bytes32 salt = keccak256(abi.encodePacked(_name, _symbol, _baseTokenURI, _tokenType, block.timestamp));

        // ==== Effects ====================================================
        conviction = LibClone.cloneDeterministic(convictionImplementation, salt);
        token = LibClone.cloneDeterministic(tokenImplementation, salt);
        IHigherrrrrrr(token).initialize(
            /// Constants from Factory
            weth,
            nonfungiblePositionManager,
            swapRouter,
            /// Conviction NFT
            conviction,
            /// Fees
            feeRecipient,
            /// ERC20
            _name,
            _symbol,
            /// Evolution
            _tokenType,
            _baseTokenURI,
            _priceLevels
        );
        IHigherrrrrrrConviction(conviction).initialize(token);

        emit NewToken(token, conviction, _name, _symbol, _tokenType);

        if (msg.value > 0) {
            IHigherrrrrrr(token).buy{value: msg.value}(
                msg.sender, msg.sender, "Hello World", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0
            );
        }
    }
}
