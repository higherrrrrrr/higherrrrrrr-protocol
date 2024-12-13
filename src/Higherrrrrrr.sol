// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC721TokenReceiver} from "forge-std/interfaces/IERC721.sol";
import {ReentrancyGuard} from "solady/src/utils/ReentrancyGuard.sol";
import {ERC20} from "solady/src/tokens/ERC20.sol";
import {Initializable} from "solady/src/utils/Initializable.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";

import {BondingCurve} from "./libraries/BondingCurve.sol";
import {IHigherrrrrrr} from "./interfaces/IHigherrrrrrr.sol";
import {IHigherrrrrrrConviction} from "./interfaces/IHigherrrrrrrConviction.sol";
import {INonfungiblePositionManager} from "./interfaces/INonfungiblePositionManager.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "./interfaces/IUniswapV3Pool.sol";
import {IWETH} from "./interfaces/IWETH.sol";

/*
    higherrrrrrr
*/
contract Higherrrrrrr is IHigherrrrrrr, IERC721TokenReceiver, ERC20, ReentrancyGuard, Initializable {
    using SafeTransferLib for address;
    using FixedPointMathLib for uint256;

    /// @dev Internal Token Constants
    uint256 internal constant PRIMARY_MARKET_SUPPLY = 800_000_000e18; // 800M tokens
    uint256 internal constant SECONDARY_MARKET_SUPPLY = 200_000_000e18; // 200M tokens
    uint160 internal constant POOL_SQRT_PRICE_X96_WETH_0 = 400950665883918763141200546267337;
    uint160 internal constant POOL_SQRT_PRICE_X96_TOKEN_0 = 15655546353934715619853339;
    int24 internal constant LP_TICK_LOWER = -887200;
    int24 internal constant LP_TICK_UPPER = 887200;

    // Public Token Constants
    uint16 public constant CONVICTION_THRESHOLD = 1000; // 0.1% = 1/1000
    uint64 public constant MIN_ORDER_SIZE = 0.0000001 ether;
    uint256 public constant MAX_TOTAL_SUPPLY = 1_000_000_000e18; // 1B tokens

    // @dev Internal Fee Constants
    uint16 public constant LP_FEE = 500;
    uint16 public constant PROTOCOL_FEE_BPS = 3_000; // 30%
    uint16 public constant TRADING_FEE_BPS = 100; // 1%

    /// @dev Tokens
    IWETH public WETH;
    address public convictionNFT;

    /// @dev Fees
    address public protocolFeeRecipient;
    address public creatorFeeRecipient;

    /// @dev Evolution Storage
    uint16 internal constant MAX_NAME_LENGTH = 1024;
    string internal baseName;
    string internal baseImageURI;
    string internal baseSymbol;
    PriceLevel[] public priceLevels;
    uint256 public numPriceLevels;

    /// @dev Market Mechanics
    bool internal isWETHToken1;
    MarketType public marketType;
    TokenType public tokenType;

    /// @dev Uniswap V3
    INonfungiblePositionManager public nonfungiblePositionManager;
    ISwapRouter public swapRouter;
    address public poolAddress;
    uint256 public positionId;

    /// @dev Fees
    uint256 public availableTradingFees;

    /// @notice Initializes a new Higherrrrrrr token
    /// @param _weth The WETH token address
    /// @param _convictionNFT The address of the conviction NFT contract
    /// @param _nonfungiblePositionManager The Uniswap V3 position manager address
    /// @param _swapRouter The Uniswap V3 router address
    /// @param _name The token name
    /// @param _symbol The token symbol
    /// @param _tokenType The type of token (REGULAR or TEXT_EVOLUTION)
    /// @param _tokenURI The basic token URI for the Conviction NFT
    /// @param _priceLevels The price levels and names
    /// @param _protocolFeeRecipient The address to receive fees
    /// @param _creatorFeeRecipient The address of the creator
    function initialize(
        /// @dev Constants from Factory
        address _weth,
        address _convictionNFT,
        address _nonfungiblePositionManager,
        address _swapRouter,
        /// @dev ERC20
        string memory _name,
        string memory _symbol,
        /// @dev Evolution
        TokenType _tokenType,
        string memory _tokenURI,
        PriceLevel[] calldata _priceLevels,
        /// @dev Fees
        address _protocolFeeRecipient,
        address _creatorFeeRecipient
    ) public initializer {
        // ==== Checks =====================================================
        if (_weth == address(0)) revert AddressZero("weth");
        if (_nonfungiblePositionManager == address(0)) revert AddressZero("nonfungiblePositionManager");
        if (_swapRouter == address(0)) revert AddressZero("swapRouter");
        if (_protocolFeeRecipient == address(0)) revert AddressZero("protocolFeeRecipient");
        if (_creatorFeeRecipient == address(0)) revert AddressZero("creatorFeeRecipient");

        if (_priceLevels.length == 0) revert InvalidPriceLevels();
        for (uint256 i = _priceLevels.length; i != 0;) {
            unchecked {
                if (bytes(_priceLevels[--i].name).length > MAX_NAME_LENGTH) {
                    revert InvalidPriceLevels();
                }
            }
        }

        // ==== Effects ====================================================

        baseName = _name;
        baseSymbol = _symbol;

        WETH = IWETH(_weth);
        protocolFeeRecipient = _protocolFeeRecipient;
        creatorFeeRecipient = _creatorFeeRecipient;

        // Market
        nonfungiblePositionManager = INonfungiblePositionManager(_nonfungiblePositionManager);
        swapRouter = ISwapRouter(_swapRouter);
        marketType = MarketType.BONDING_CURVE;
        tokenType = _tokenType;
        isWETHToken1 = address(_weth) >= address(this);

        // Token metadata
        baseImageURI = _tokenURI;
        numPriceLevels = _priceLevels.length;
        priceLevels = _priceLevels;

        // Conviction NFT
        convictionNFT = _convictionNFT;
        IHigherrrrrrrConviction(convictionNFT).initialize(address(this));

        // ==== Interactions ===============================================
        // Determine the token0, token1, and sqrtPriceX96 values for the Uniswap V3 pool
        address token0;
        address token1;
        uint160 sqrtPriceX96;
        if (isWETHToken1) {
            token0 = address(this);
            token1 = address(WETH);
            sqrtPriceX96 = POOL_SQRT_PRICE_X96_TOKEN_0;
        } else {
            token0 = address(WETH);
            token1 = address(this);
            sqrtPriceX96 = POOL_SQRT_PRICE_X96_WETH_0;
        }
        // Create and initialize the Uniswap V3 pool
        poolAddress =
            nonfungiblePositionManager.createAndInitializePoolIfNecessary(token0, token1, LP_FEE, sqrtPriceX96);
    }

    /// ============================================
    /// ERC20 Functions
    /// ============================================

    /// @notice Dynamic name for evolution tokens
    function name() public view virtual override returns (string memory) {
        if (tokenType == TokenType.REGULAR) return baseName;

        (, PriceLevel memory currentLevel) = getCurrentPriceLevel();
        return currentLevel.name;
    }

    function symbol() public view virtual override returns (string memory) {
        return baseSymbol;
    }

    /// @dev Prevents the token from being transferred to the Uniswap V3 pool when bonding
    function _beforeTokenTransfer(address, address to, uint256) internal virtual override {
        if (marketType == MarketType.BONDING_CURVE && to == poolAddress) {
            revert InvalidMarketType();
        }
    }

    /// @dev Emits a HigherrrrrrTokenTransfer event
    function _afterTokenTransfer(address from, address to, uint256 value) internal virtual override {
        emit HigherrrrrrTokenTransfer(from, to, value, balanceOf(from), balanceOf(to), totalSupply());
    }

    /// ============================================
    /// Conviction NFT
    /// ============================================

    /// @dev Mints a Conviction NFT for a given order size
    function _mintConvictionNFT(address recipient, uint256 trueOrderSize) internal {
        (uint256 currentPrice, PriceLevel memory currentLevel) = getCurrentPriceLevel();

        // Mint Conviction NFT
        IHigherrrrrrrConviction(convictionNFT).mintConviction(
            recipient, currentLevel.name, currentLevel.imageURI, trueOrderSize, currentPrice
        );
    }

    /// ============================================
    /// View Functions
    /// ============================================

    /// @notice Helper function to get current price from Uniswap pool
    function getCurrentPrice() public view returns (uint256) {
        if (marketType == MarketType.BONDING_CURVE) {
            // Calculate current price from bonding curve
            return (1 ether * 1e18) / BondingCurve.getEthBuyQuote(totalSupply(), 1 ether); // Price in wei per token
        }

        // Uniswap pool price calculation
        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(poolAddress).slot0();

        // Convert sqrtPriceX96 to actual price
        if (isWETHToken1) {
            // price = price
            return (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) * 1e18) >> 192;
        } else {
            // price = 1/price
            return ((2 ** 192) * 1e18) / (uint256(sqrtPriceX96) * uint256(sqrtPriceX96));
        }
    }

    /// @notice Returns all price levels metadata structs
    function getPriceLevels() external view returns (PriceLevel[] memory) {
        return priceLevels;
    }

    /// @notice Returns the current price level
    /// @return currentPrice The current price in ETH
    /// @return currentLevel The current price level
    function getCurrentPriceLevel()
        public
        view
        override
        returns (uint256 currentPrice, PriceLevel memory currentLevel)
    {
        currentPrice = getCurrentPrice();

        if (currentPrice == 0) {
            currentLevel = PriceLevel(0, baseName, baseImageURI);
            return (currentPrice, currentLevel);
        }

        // Find the highest price level that's below current price
        uint256 highestQualifyingPrice = 0;
        PriceLevel storage level;

        for (uint256 i = 0; i < numPriceLevels;) {
            level = priceLevels[i];
            if (currentPrice >= level.price && level.price > highestQualifyingPrice) {
                highestQualifyingPrice = level.price;
                currentLevel = level;
            }
            unchecked {
                ++i;
            }
        }

        return (currentPrice, currentLevel);
    }

    /// @notice Returns current market type and address
    function state() external view returns (MarketState memory) {
        return MarketState({
            marketType: marketType,
            marketAddress: marketType == MarketType.BONDING_CURVE ? address(this) : poolAddress
        });
    }

    /// ============================================
    /// Modifiers
    /// ============================================

    modifier onlyBondingMarket() {
        if (marketType == MarketType.UNISWAP_POOL) revert InvalidMarketType();
        _;
    }

    modifier onlyUniswapMarket() {
        if (marketType == MarketType.BONDING_CURVE) revert InvalidMarketType();
        _;
    }

    /// ============================================
    /// Bonding Curve Dynamics
    /// ============================================

    /// @notice The number of tokens that can be bought from a given amount of ETH.
    ///         This will revert if the market has graduated to the Uniswap V3 pool.
    function getEthBuyQuote(uint256 ethOrderSize) public view onlyBondingMarket returns (uint256) {
        return BondingCurve.getEthBuyQuote(totalSupply(), ethOrderSize);
    }

    /// @notice The number of tokens for selling a given amount of ETH.
    ///         This will revert if the market has graduated to the Uniswap V3 pool.
    function getEthSellQuote(uint256 ethOrderSize) public view onlyBondingMarket returns (uint256) {
        return BondingCurve.getEthSellQuote(totalSupply(), ethOrderSize);
    }

    /// @notice The amount of ETH needed to buy a given number of tokens.
    ///         This will revert if the market has graduated to the Uniswap V3 pool.
    function getTokenBuyQuote(uint256 tokenOrderSize) public view onlyBondingMarket returns (uint256) {
        return BondingCurve.getTokenBuyQuote(totalSupply(), tokenOrderSize);
    }

    /// @notice The amount of ETH that can be received for selling a given number of tokens.
    ///         This will revert if the market has graduated to the Uniswap V3 pool.
    function getTokenSellQuote(uint256 tokenOrderSize) public view onlyBondingMarket returns (uint256) {
        return BondingCurve.getTokenSellQuote(totalSupply(), tokenOrderSize);
    }

    /// @dev Validates a bonding curve buy order and if necessary, recalculates the order data if the size is greater than the remaining supply
    function _validateBondingCurveBuy(uint256 minOrderSize)
        internal
        returns (uint256 totalCost, uint256 trueOrderSize, uint256 fee, uint256 refund, bool startMarket)
    {
        // Set the total cost to the amount of ETH sent
        totalCost = msg.value;

        // Calculate the fee
        fee = calculateTradingFee(totalCost);

        // Calculate the amount of ETH remaining for the order
        uint256 remainingEth = totalCost - fee;

        // Get quote for the number of tokens that can be bought with the amount of ETH remaining
        trueOrderSize = BondingCurve.getEthBuyQuote(totalSupply(), remainingEth);

        // Ensure the order size is greater than the minimum order size
        if (trueOrderSize < minOrderSize) revert SlippageBoundsExceeded();

        // Calculate the maximum number of tokens that can be bought
        uint256 maxRemainingTokens = PRIMARY_MARKET_SUPPLY - totalSupply();

        // Start the market if the order size equals the number of remaining tokens
        startMarket = trueOrderSize >= maxRemainingTokens;

        // If the order size is greater than the maximum number of remaining tokens:
        if (trueOrderSize > maxRemainingTokens) {
            // Reset the order size to the number of remaining tokens
            trueOrderSize = maxRemainingTokens;

            // Calculate the amount of ETH needed to buy the remaining tokens
            uint256 ethNeeded = BondingCurve.getTokenBuyQuote(totalSupply(), trueOrderSize);

            // Recalculate the fee with the updated order size
            fee = calculateTradingFee(ethNeeded);

            // Recalculate the total cost with the updated order size and fee
            totalCost = ethNeeded + fee;

            // Refund any excess ETH
            if (msg.value > totalCost) {
                refund = msg.value - totalCost;
            }
        }
    }

    /// @dev Handles a bonding curve sell order
    function _handleBondingCurveSell(uint256 tokensToSell, uint256 minPayoutSize) private returns (uint256 payout) {
        // Get quote for the number of ETH that can be received for the number of tokens to sell
        payout = BondingCurve.getTokenSellQuote(totalSupply(), tokensToSell);

        // Ensure the payout is greater than the minimum payout size
        if (payout < minPayoutSize) revert SlippageBoundsExceeded();

        // Ensure the payout is greater than the minimum order size
        if (payout < MIN_ORDER_SIZE) revert InsufficientFunds();

        // Burn the tokens from the seller
        _burn(msg.sender, tokensToSell);

        return payout;
    }

    /// @dev Graduates the market to a Uniswap V3 pool.
    function _graduateMarket() internal {
        // ==== Effects ===============================================
        // Update the market type
        marketType = MarketType.UNISWAP_POOL;

        // Convert the bonding curve's accumulated ETH to WETH
        uint256 ethLiquidity = address(this).balance;
        WETH.deposit{value: ethLiquidity}();
        // Approve the nonfungible position manager to transfer the WETH
        address(WETH).safeApprove(address(nonfungiblePositionManager), ethLiquidity);

        // Mint the secondary market supply to this contract
        _mint(address(this), SECONDARY_MARKET_SUPPLY);
        // Approve the nonfungible position manager to transfer the WETH and tokens
        this.approve(address(nonfungiblePositionManager), SECONDARY_MARKET_SUPPLY);

        // Determine the token order
        address token0;
        address token1;
        uint256 amount0;
        uint256 amount1;
        uint160 desiredSqrtPriceX96;
        if (isWETHToken1) {
            token0 = address(this);
            token1 = address(WETH);
            amount0 = SECONDARY_MARKET_SUPPLY;
            amount1 = ethLiquidity;
            desiredSqrtPriceX96 = POOL_SQRT_PRICE_X96_TOKEN_0;
        } else {
            token0 = address(WETH);
            token1 = address(this);
            amount0 = ethLiquidity;
            amount1 = SECONDARY_MARKET_SUPPLY;
            desiredSqrtPriceX96 = POOL_SQRT_PRICE_X96_WETH_0;
        }

        {
            // Get the current and desired price of the pool
            (uint160 currentSqrtPriceX96,,,,,,) = IUniswapV3Pool(poolAddress).slot0();

            // ==== Interactions ============================================
            // If the current price is not the desired price, set the desired price
            if (currentSqrtPriceX96 != desiredSqrtPriceX96) {
                bool swap0To1 = currentSqrtPriceX96 > desiredSqrtPriceX96;
                IUniswapV3Pool(poolAddress).swap(address(this), swap0To1, 100, desiredSqrtPriceX96, "");
            }
        }

        // Mint the liquidity position to this contract.
        uint256 depositedWETH;
        uint256 depositedTokens;
        (positionId,, depositedWETH, depositedTokens) = nonfungiblePositionManager.mint(
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: LP_FEE,
                tickLower: LP_TICK_LOWER,
                tickUpper: LP_TICK_UPPER,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            })
        );

        if (isWETHToken1) {
            (depositedWETH, depositedTokens) = (depositedTokens, depositedWETH);
        }

        {
            uint256 ethDust = ethLiquidity - depositedWETH;
            if (ethDust != 0) {
                WETH.withdraw(ethDust);
                availableTradingFees += ethDust;
            }

            uint256 tokenDust = SECONDARY_MARKET_SUPPLY - depositedTokens;
            if (tokenDust != 0) {
                this.transfer(protocolFeeRecipient, tokenDust);
            }
        }

        emit HigherrrrrrMarketGraduated(
            address(this), poolAddress, depositedWETH, depositedTokens, positionId, marketType
        );
    }

    /// ====================================================
    /// Uniswap V3 Pool Functions
    /// ====================================================

    /// @dev For receiving the Uniswap V3 LP NFT on market graduation.
    function onERC721Received(address, address, uint256, bytes calldata) external view returns (bytes4) {
        if (msg.sender != poolAddress) revert Unauthorized();

        return this.onERC721Received.selector;
    }

    /// @dev No-op to allow a swap on the pool to set the correct initial price, if needed
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {}

    /// @dev Handles a Uniswap V3 sell order
    function _handleUniswapSell(uint256 tokensToSell, uint256 minPayoutSize, uint160 sqrtPriceLimitX96)
        private
        returns (uint256 payout)
    {
        // ==== Effects ===============================================
        // Transfer the tokens from the seller to this contract
        this.transferFrom(msg.sender, address(this), tokensToSell);

        // Approve the swap router to spend the tokens
        this.approve(address(swapRouter), tokensToSell);

        // ==== Interactions ============================================
        // Execute the swap
        payout = swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(this),
                tokenOut: address(WETH),
                fee: LP_FEE,
                recipient: address(this),
                amountIn: tokensToSell,
                amountOutMinimum: minPayoutSize,
                sqrtPriceLimitX96: sqrtPriceLimitX96
            })
        );

        // Withdraw the ETH from the contract
        WETH.withdraw(payout); // effect: address(this).balance += payout

        return payout;
    }

    /// ====================================================
    /// Buy, Sell, and Burn Logic
    /// ====================================================

    receive() external payable {
        if (msg.sender == address(WETH)) return;

        buy(msg.sender, msg.sender, "", MarketType.BONDING_CURVE, 0, 0);
    }

    /// @notice Purchases tokens using ETH, either from the bonding curve or Uniswap V3 pool
    /// @param recipient The address to receive the purchased tokens
    /// @param refundRecipient The address to receive any excess ETH
    /// @param comment A comment associated with the buy order
    /// @param expectedMarketType The expected market type (0 = BONDING_CURVE, 1 = UNISWAP_POOL)
    /// @param minOrderSize The minimum tokens to prevent slippage
    /// @param sqrtPriceLimitX96 The price limit for Uniswap V3 pool swaps, ignored if market is bonding curve.
    function buy(
        address recipient,
        address refundRecipient,
        string memory comment,
        MarketType expectedMarketType,
        uint256 minOrderSize,
        uint160 sqrtPriceLimitX96
    ) public payable nonReentrant returns (uint256 trueOrderSize) {
        // ==== Checks =====================================================
        // Ensure the market type is expected
        if (marketType != expectedMarketType) revert InvalidMarketType();

        // Ensure the order size is greater than the minimum order size
        if (msg.value < MIN_ORDER_SIZE) revert InsufficientFunds();

        // Ensure the recipient is not the zero address
        if (recipient == address(0)) revert AddressZero("recipient");

        // ==== Interactions ===============================================
        uint256 totalCost;
        uint256 fee;

        if (marketType == MarketType.BONDING_CURVE) {
            bool shouldGraduateMarket;
            uint256 refund;
            // Validate the order data
            (totalCost, trueOrderSize, fee, refund, shouldGraduateMarket) = _validateBondingCurveBuy(minOrderSize);

            // Mint the tokens to the recipient
            _mint(recipient, trueOrderSize);

            if (refund != 0) {
                refundRecipient.safeTransferETH(refund);
            }

            // Start the market if this is the final bonding market buy order.
            if (shouldGraduateMarket) {
                _graduateMarket();
            }
        } else {
            // Calculate the fee
            fee = calculateTradingFee(msg.value);

            // Calculate the remaining ETH
            totalCost = msg.value - fee;

            // Convert the ETH to WETH and approve the swap router
            WETH.deposit{value: totalCost}();
            WETH.approve(address(swapRouter), totalCost);

            // Execute the swap
            trueOrderSize = swapRouter.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: address(WETH),
                    tokenOut: address(this),
                    fee: LP_FEE,
                    recipient: recipient,
                    amountIn: totalCost,
                    amountOutMinimum: minOrderSize,
                    sqrtPriceLimitX96: sqrtPriceLimitX96
                })
            );
        }

        // Handle the fees
        availableTradingFees += fee;

        emit HigherrrrrrTokenBuy(
            msg.sender,
            recipient,
            msg.value,
            fee,
            totalCost,
            trueOrderSize,
            balanceOf(recipient),
            comment,
            totalSupply(),
            marketType
        );

        // Check if purchase qualifies for Conviction NFT (>0.1% of total supply)
        if (trueOrderSize >= (MAX_TOTAL_SUPPLY / CONVICTION_THRESHOLD)) {
            _mintConvictionNFT(recipient, trueOrderSize);
        }

        return trueOrderSize;
    }

    /// @notice Sells tokens for ETH, either to the bonding curve or Uniswap V3 pool
    /// @param tokensToSell The number of tokens to sell
    /// @param recipient The address to receive the ETH payout
    /// @param comment A comment associated with the sell order
    /// @param expectedMarketType The expected market type (0 = BONDING_CURVE, 1 = UNISWAP_POOL)
    /// @param minPayoutSize The minimum ETH payout to prevent slippage
    /// @param sqrtPriceLimitX96 The price limit for Uniswap V3 pool swaps, ignored if market is bonding curve
    function sell(
        uint256 tokensToSell,
        address recipient,
        string memory comment,
        MarketType expectedMarketType,
        uint256 minPayoutSize,
        uint160 sqrtPriceLimitX96
    ) external nonReentrant returns (uint256 truePayoutSize) {
        // ==== Checks =====================================================
        // Ensure the market type is expected
        if (marketType != expectedMarketType) revert InvalidMarketType();
        // Ensure the sender has enough liquidity to sell
        if (tokensToSell > balanceOf(msg.sender)) revert InsufficientFunds();
        // Ensure the recipient is not the zero address
        if (recipient == address(0)) revert AddressZero("recipient");

        // ==== Effects ===============================================
        // Calculate the fee
        uint256 fee = calculateTradingFee(truePayoutSize);
        // Calculate the payout after the fee
        uint256 payoutAfterFee = truePayoutSize - fee;

        // Interactions

        // ==== Interactions ===============================================
        if (marketType == MarketType.BONDING_CURVE) {
            truePayoutSize = _handleBondingCurveSell(tokensToSell, minPayoutSize);
        } else {
            truePayoutSize = _handleUniswapSell(tokensToSell, minPayoutSize, sqrtPriceLimitX96);
        }

        emit HigherrrrrrTokenSell(
            msg.sender,
            recipient,
            truePayoutSize,
            fee,
            payoutAfterFee,
            tokensToSell,
            balanceOf(recipient),
            comment,
            totalSupply(),
            marketType
        );

        // Handle the fees
        availableTradingFees += fee;
        // Send the payout to the recipient
        recipient.safeTransferETH(payoutAfterFee);

        return truePayoutSize;
    }

    /// @notice Burns tokens after the market has graduated to Uniswap V3
    /// @param tokensToBurn The number of tokens to burn
    function burn(uint256 tokensToBurn) external onlyUniswapMarket {
        _burn(msg.sender, tokensToBurn);
    }

    /// ====================================================
    /// Fees
    /// ====================================================

    /// @dev Transfer creator fees to a new address
    function transferCreatorFeeRecipient(address newCreatorFeeRecipient) external {
        if (msg.sender != creatorFeeRecipient) revert Unauthorized();
        creatorFeeRecipient = newCreatorFeeRecipient;
    }

    /// @dev Calculates the fee split for a given amount and basis points.
    function calculateFeeSplit(uint256 amount) public pure returns (uint256 protocolFee, uint256 creatorFee) {
        protocolFee = amount.mulDivUp(PROTOCOL_FEE_BPS, 10_000); // round up
        creatorFee = amount - protocolFee;
    }

    /// @notice Returns the total collectable fees from both trading and liquidity
    /// @return protocolETH The amount of ETH collectable by the protocol
    /// @return creatorETH The amount of ETH collectable by the creator
    /// @return protocolTokens The amount of tokens collectable by the protocol
    /// @return creatorTokens The amount of tokens collectable by the creator
    function collectable()
        public
        view
        returns (uint256 protocolETH, uint256 creatorETH, uint256 protocolTokens, uint256 creatorTokens)
    {
        (uint256 ptETH, uint256 ctETH, uint256 ptTokens, uint256 ctTokens) = collectableTradingFees();

        uint256 plpETH = 0;
        uint256 clpETH = 0;
        uint256 plpTokens = 0;
        uint256 clpTokens = 0;
        if (marketType == MarketType.UNISWAP_POOL) {
            (plpETH, clpETH, plpTokens, clpTokens) = collectableLiquidityFees();
        }

        protocolETH = plpETH + ptETH;
        creatorETH = clpETH + ctETH;
        protocolTokens = plpTokens + ptTokens;
        creatorTokens = clpTokens + ctTokens;
    }

    /// @notice Returns the collectable fees from liquidity provision
    /// @return protocolETH The amount of ETH collectable by the protocol
    /// @return creatorETH The amount of ETH collectable by the creator
    /// @return protocolTokens The amount of tokens collectable by the protocol
    /// @return creatorTokens The amount of tokens collectable by the creator
    function collectableLiquidityFees()
        public
        view
        onlyUniswapMarket
        returns (uint256 protocolETH, uint256 creatorETH, uint256 protocolTokens, uint256 creatorTokens)
    {
        (,,,,,,,,,, uint128 ethAmount, uint128 tokenAmount) = nonfungiblePositionManager.positions(positionId);

        if (isWETHToken1) {
            (ethAmount, tokenAmount) = (tokenAmount, ethAmount);
        }

        (protocolETH, creatorETH) = calculateFeeSplit(ethAmount);
        (protocolTokens, creatorTokens) = calculateFeeSplit(tokenAmount);
    }

    /// @notice Returns the collectable fees from trading
    /// @return protocolETH The amount of ETH collectable by the protocol
    /// @return creatorETH The amount of ETH collectable by the creator
    /// @return protocolTokens The amount of tokens collectable by the protocol
    /// @return creatorTokens The amount of tokens collectable by the creator
    function collectableTradingFees()
        public
        view
        returns (uint256 protocolETH, uint256 creatorETH, uint256 protocolTokens, uint256 creatorTokens)
    {
        (protocolETH, creatorETH) = calculateFeeSplit(availableTradingFees);
        return (protocolETH, creatorETH, protocolTokens, creatorTokens);
    }

    /// @notice Collects all fees from both trading and liquidity
    /// @return protocolETH The amount of ETH collected by the protocol
    /// @return creatorETH The amount of ETH collected by the creator
    /// @return protocolTokens The amount of tokens collected by the protocol
    /// @return creatorTokens The amount of tokens collected by the creator
    function collect()
        public
        returns (uint256 protocolETH, uint256 creatorETH, uint256 protocolTokens, uint256 creatorTokens)
    {
        uint256 lpETH = 0;
        uint256 lpTokens = 0;

        if (marketType == MarketType.UNISWAP_POOL) {
            (lpETH, lpTokens) = _pullLiquidityFees();
        }

        (protocolETH, creatorETH) = calculateFeeSplit(availableTradingFees + lpETH);
        (protocolTokens, creatorTokens) = calculateFeeSplit(lpTokens);

        /// ==== Effects ===============================================
        availableTradingFees = 0;

        // ==== Interactions ============================================
        _distributeFees(protocolETH, creatorETH, protocolTokens, creatorTokens);
    }

    /// @notice Collects fees from trading only
    /// @return protocolETH The amount of ETH collected by the protocol
    /// @return creatorETH The amount of ETH collected by the creator
    /// @return protocolTokens The amount of tokens collected by the protocol
    /// @return creatorTokens The amount of tokens collected by the creator
    function collectTradingFees()
        public
        returns (uint256 protocolETH, uint256 creatorETH, uint256 protocolTokens, uint256 creatorTokens)
    {
        (protocolETH, creatorETH) = calculateFeeSplit(availableTradingFees);

        // ==== Effects ===============================================
        availableTradingFees = 0;

        // ==== Interactions ============================================
        _distributeFees(protocolETH, creatorETH, protocolTokens, creatorTokens);
    }

    /// @notice Collects fees from liquidity provision only
    /// @return protocolETH The amount of ETH collected by the protocol
    /// @return creatorETH The amount of ETH collected by the creator
    /// @return protocolTokens The amount of tokens collected by the protocol
    /// @return creatorTokens The amount of tokens collected by the creator
    function collectLiquidityFees()
        public
        onlyUniswapMarket
        returns (uint256 protocolETH, uint256 creatorETH, uint256 protocolTokens, uint256 creatorTokens)
    {
        (uint256 ethAmount, uint256 tokenAmount) = _pullLiquidityFees();

        (protocolETH, creatorETH) = calculateFeeSplit(ethAmount);
        (protocolTokens, creatorTokens) = calculateFeeSplit(tokenAmount);

        // ==== Interactions ============================================
        _distributeFees(protocolETH, creatorETH, protocolTokens, creatorTokens);
    }

    /// @dev Calculates the fee for a given amount and basis points.
    function calculateTradingFee(uint256 amount) public pure returns (uint256 protocolFee) {
        protocolFee = amount.mulDivUp(TRADING_FEE_BPS, 10_000); // round up
    }

    /// @dev Pulls liquidity and converts WETH to ETH
    function _pullLiquidityFees() internal returns (uint256 collectedETH, uint256 collectedTokens) {
        (collectedETH, collectedTokens) = nonfungiblePositionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: positionId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        if (isWETHToken1) {
            (collectedETH, collectedTokens) = (collectedTokens, collectedETH);
        }

        if (collectedETH > 0) {
            WETH.withdraw(collectedETH);
        }
    }

    function _distributeFees(uint256 protocolETH, uint256 creatorETH, uint256 protocolTokens, uint256 creatorTokens)
        internal
    {
        if (protocolTokens != 0) {
            this.transfer(protocolFeeRecipient, protocolTokens);
            emit HigherrrrrrTokenFees(protocolFeeRecipient, address(this), protocolTokens);
        }

        if (creatorTokens != 0) {
            this.transfer(creatorFeeRecipient, creatorTokens);
            emit HigherrrrrrTokenFees(creatorFeeRecipient, address(this), creatorTokens);
        }

        if (protocolETH != 0) {
            protocolFeeRecipient.safeTransferETH(protocolETH);
            emit HigherrrrrrTokenFees(protocolFeeRecipient, address(0), protocolETH);
        }

        if (creatorETH != 0) {
            creatorFeeRecipient.safeTransferETH(creatorETH);
            emit HigherrrrrrTokenFees(creatorFeeRecipient, address(0), creatorETH);
        }
    }
}
