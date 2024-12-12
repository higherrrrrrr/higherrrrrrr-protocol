// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";
import {Higherrrrrrr} from "./Higherrrrrrr.sol";
import {IHigherrrrrrr} from "./interfaces/IHigherrrrrrr.sol";
import {IHigherrrrrrrConviction} from "./interfaces/IHigherrrrrrrConviction.sol";

contract HigherrrrrrrFactory {
    using SafeTransferLib for address;
    using FixedPointMathLib for uint256;

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

    address[] public tokens;

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
        string calldata _name,
        string calldata _symbol,
        string calldata _uri,
        IHigherrrrrrr.TokenType _tokenType,
        IHigherrrrrrr.PriceLevel[] calldata _levels,
        address _creatorFeeRecipient
    ) external payable returns (address token, address conviction) {
        bytes32 salt = keccak256(abi.encodePacked(token, block.timestamp));

        // Clone the Conviction NFT implementation
        conviction = Clones.cloneDeterministic(convictionImplementation, salt);
        // Deploy token
        token = Clones.cloneDeterministic(tokenImplementation, salt);

        IHigherrrrrrr(token).initialize{value: msg.value}(
            weth,
            feeRecipient,
            _creatorFeeRecipient,
            nonfungiblePositionManager,
            swapRouter,
            bondingCurve,
            _tokenType,
            _uri,
            _name,
            _symbol,
            _levels,
            conviction
        );

        // Initialize the Conviction NFT clone
        IHigherrrrrrrConviction(conviction).initialize(token);

        tokens.push(token);

        emit NewToken(token, conviction);
    }

    function collectAllFees() external {
        uint256 tokenCount = tokens.length;
        for (uint256 i = 0; i < tokenCount;) {
            IHigherrrrrrr(tokens[i]).collect();
            unchecked {
                ++i;
            }
        }
    }

    function collectFees(address[] calldata _tokens) public {
        uint256 tokenCount = _tokens.length;

        for (uint256 i = 0; i < tokenCount;) {
            IHigherrrrrrr(_tokens[i]).collect();
            unchecked {
                ++i;
            }
        }
    }
}
