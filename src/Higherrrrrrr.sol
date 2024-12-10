// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ERC20Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IHigherrrrrrr} from "./interfaces/IHigherrrrrrr.sol";
import {INonfungiblePositionManager} from "./interfaces/INonfungiblePositionManager.sol";
import {IUniswapV3Pool} from "./interfaces/IUniswapV3Pool.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {BondingCurve} from "./BondingCurve.sol";
import {HigherrrrrrrConviction} from "./HigherrrrrrrConviction.sol";

/*
    higherrrrrrr
*/
contract Higherrrrrrr is IHigherrrrrrr, Initializable, ERC20Upgradeable, ReentrancyGuardUpgradeable, IERC721Receiver {
    uint256 public constant MAX_TOTAL_SUPPLY = 1_000_000_000e18; // 1B tokens
    uint256 internal constant PRIMARY_MARKET_SUPPLY = 800_000_000e18; // 800M tokens
    uint256 internal constant SECONDARY_MARKET_SUPPLY = 200_000_000e18; // 200M tokens
    uint256 public constant TOTAL_FEE_BPS = 100; // 1%
    uint256 public constant MIN_ORDER_SIZE = 0.0000001 ether;
    uint160 internal constant POOL_SQRT_PRICE_X96_WETH_0 = 400950665883918763141200546267337;
    uint160 internal constant POOL_SQRT_PRICE_X96_TOKEN_0 = 15655546353934715619853339;
    uint24 internal constant LP_FEE = 500;
    int24 internal constant LP_TICK_LOWER = -887200;
    int24 internal constant LP_TICK_UPPER = 887200;

    address public immutable WETH;
    address public immutable nonfungiblePositionManager;
    address public immutable swapRouter;
    address public immutable feeRecipient;

    BondingCurve public bondingCurve;
    MarketType public marketType;
    TokenType public tokenType;
    string public tokenURI;
    address public poolAddress;

    PriceLevel[] public priceLevels;
    uint256 public numPriceLevels;

    address public convictionNFT;
    uint256 public constant CONVICTION_THRESHOLD = 1000; // 0.1% = 1/1000

    constructor(address _feeRecipient, address _weth, address _nonfungiblePositionManager, address _swapRouter) {
        if (_feeRecipient == address(0)) revert AddressZero();
        if (_weth == address(0)) revert AddressZero();
        if (_nonfungiblePositionManager == address(0)) revert AddressZero();
        if (_swapRouter == address(0)) revert AddressZero();

        feeRecipient = _feeRecipient;
        WETH = _weth;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        swapRouter = _swapRouter;
    }

    /// @notice Initializes a new Higherrrrrrr token
    /// @param _bondingCurve The address of the bonding curve module
    /// @param _tokenURI The ERC20 token URI
    /// @param _name The token name
    /// @param _symbol The token symbol
    /// @param _priceLevels The price levels and names
    function initialize(
        address _bondingCurve,
        TokenType _tokenType,
        string memory _tokenURI,
        string memory _name,
        string memory _symbol,
        PriceLevel[] calldata _priceLevels,
        address _convictionNFT
    ) public payable initializer {
        // Validate the creation parameters
        if (_bondingCurve == address(0)) revert AddressZero();

        // Initialize base contract state
        __ERC20_init(_name, _symbol);
        __ReentrancyGuard_init();

        // Initialize token and market state
        marketType = MarketType.BONDING_CURVE;
        tokenType = _tokenType;
        tokenURI = _tokenURI;
        bondingCurve = BondingCurve(_bondingCurve);

        // Initialize price levels
        if (_priceLevels.length == 0) revert NoPriceLevels();

        // Store price levels without sorting
        numPriceLevels = _priceLevels.length;
        priceLevels = _priceLevels;

        // Determine the token0, token1, and sqrtPriceX96 values for the Uniswap V3 pool
        address token0 = WETH < address(this) ? WETH : address(this);
        address token1 = WETH < address(this) ? address(this) : WETH;
        uint160 sqrtPriceX96 = token0 == WETH ? POOL_SQRT_PRICE_X96_WETH_0 : POOL_SQRT_PRICE_X96_TOKEN_0;

        // Create and initialize the Uniswap V3 pool
        poolAddress = INonfungiblePositionManager(nonfungiblePositionManager).createAndInitializePoolIfNecessary(
            token0, token1, LP_FEE, sqrtPriceX96
        );

        // Execute the initial buy order if any ETH was sent
        if (msg.value > 0) {
            buy(msg.sender, msg.sender, "", MarketType.BONDING_CURVE, 0, 0);
        }

        convictionNFT = _convictionNFT;
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
    ) public payable nonReentrant returns (uint256) {
        // Ensure the market type is expected
        if (marketType != expectedMarketType) revert InvalidMarketType();

        // Ensure the order size is greater than the minimum order size
        if (msg.value < MIN_ORDER_SIZE) revert EthAmountTooSmall();

        // Ensure the recipient is not the zero address
        if (recipient == address(0)) revert AddressZero();

        // Initialize variables to store the total cost, true order size, fee, refund, and whether the market should graduate
        uint256 totalCost;
        uint256 trueOrderSize;
        uint256 fee;
        uint256 refund;
        bool shouldGraduateMarket;

        if (marketType == MarketType.UNISWAP_POOL) {
            // Calculate the fee
            fee = _calculateFee(msg.value, TOTAL_FEE_BPS);

            // Calculate the remaining ETH
            totalCost = msg.value - fee;

            // Handle the fees
            _disperseFees(fee, address(0));

            // Convert the ETH to WETH and approve the swap router
            IWETH(WETH).deposit{value: totalCost}();
            IWETH(WETH).approve(swapRouter, totalCost);

            // Set up the swap parameters
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: WETH,
                tokenOut: address(this),
                fee: LP_FEE,
                recipient: recipient,
                amountIn: totalCost,
                amountOutMinimum: minOrderSize,
                sqrtPriceLimitX96: sqrtPriceLimitX96
            });

            // Execute the swap
            trueOrderSize = ISwapRouter(swapRouter).exactInputSingle(params);
        }

        if (marketType == MarketType.BONDING_CURVE) {
            // Validate the order data
            (totalCost, trueOrderSize, fee, refund, shouldGraduateMarket) = _validateBondingCurveBuy(minOrderSize);

            // Mint the tokens to the recipient
            _mint(recipient, trueOrderSize);

            // Handle the fees
            _disperseFees(fee, address(0));

            // Refund any excess ETH
            if (refund > 0) {
                (bool success,) = refundRecipient.call{value: refund}("");
                if (!success) revert EthTransferFailed();
            }
        }

        // Start the market if this is the final bonding market buy order.
        if (shouldGraduateMarket) {
            _graduateMarket();
        }

        // Check if purchase qualifies for Conviction NFT (>0.1% of total supply)
        if (trueOrderSize >= (MAX_TOTAL_SUPPLY / CONVICTION_THRESHOLD) && convictionNFT != address(0)) {
            (uint256 currentPrice, PriceLevel memory currentLevel) = getCurrentPriceLevel();

            // Mint Conviction NFT
            HigherrrrrrrConviction(convictionNFT).mintConviction(
                recipient, currentLevel.name, currentLevel.imageURI, trueOrderSize, currentPrice
            );
        }

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
    ) external nonReentrant returns (uint256) {
        // Ensure the market type is expected
        if (marketType != expectedMarketType) revert InvalidMarketType();

        // Ensure the sender has enough liquidity to sell
        if (tokensToSell > balanceOf(msg.sender)) {
            revert InsufficientLiquidity();
        }

        // Ensure the recipient is not the zero address
        if (recipient == address(0)) revert AddressZero();

        // Initialize the true payout size
        uint256 truePayoutSize;

        if (marketType == MarketType.UNISWAP_POOL) {
            truePayoutSize = _handleUniswapSell(tokensToSell, minPayoutSize, sqrtPriceLimitX96);
        }

        if (marketType == MarketType.BONDING_CURVE) {
            truePayoutSize = _handleBondingCurveSell(tokensToSell, minPayoutSize);
        }

        // Calculate the fee
        uint256 fee = _calculateFee(truePayoutSize, TOTAL_FEE_BPS);

        // Calculate the payout after the fee
        uint256 payoutAfterFee = truePayoutSize - fee;

        // Handle the fees
        _disperseFees(fee, address(0));

        // Send the payout to the recipient
        (bool success,) = recipient.call{value: payoutAfterFee}("");
        if (!success) revert EthTransferFailed();

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

        return truePayoutSize;
    }

    /// @notice Burns tokens after the market has graduated to Uniswap V3
    /// @param tokensToBurn The number of tokens to burn
    function burn(uint256 tokensToBurn) external {
        if (marketType == MarketType.BONDING_CURVE) revert MarketNotGraduated();

        _burn(msg.sender, tokensToBurn);
    }

    /// @notice Returns current market type and address
    function state() external view returns (MarketState memory) {
        return MarketState({
            marketType: marketType,
            marketAddress: marketType == MarketType.BONDING_CURVE ? address(this) : poolAddress
        });
    }

    /// @notice The number of tokens that can be bought from a given amount of ETH.
    ///         This will revert if the market has graduated to the Uniswap V3 pool.
    function getEthBuyQuote(uint256 ethOrderSize) public view returns (uint256) {
        if (marketType == MarketType.UNISWAP_POOL) {
            revert MarketAlreadyGraduated();
        }

        return bondingCurve.getEthBuyQuote(totalSupply(), ethOrderSize);
    }

    /// @notice The number of tokens for selling a given amount of ETH.
    ///         This will revert if the market has graduated to the Uniswap V3 pool.
    function getEthSellQuote(uint256 ethOrderSize) public view returns (uint256) {
        if (marketType == MarketType.UNISWAP_POOL) {
            revert MarketAlreadyGraduated();
        }

        return bondingCurve.getEthSellQuote(totalSupply(), ethOrderSize);
    }

    /// @notice The amount of ETH needed to buy a given number of tokens.
    ///         This will revert if the market has graduated to the Uniswap V3 pool.
    function getTokenBuyQuote(uint256 tokenOrderSize) public view returns (uint256) {
        if (marketType == MarketType.UNISWAP_POOL) {
            revert MarketAlreadyGraduated();
        }

        return bondingCurve.getTokenBuyQuote(totalSupply(), tokenOrderSize);
    }

    /// @notice The amount of ETH that can be received for selling a given number of tokens.
    ///         This will revert if the market has graduated to the Uniswap V3 pool.
    function getTokenSellQuote(uint256 tokenOrderSize) public view returns (uint256) {
        if (marketType == MarketType.UNISWAP_POOL) {
            revert MarketAlreadyGraduated();
        }

        return bondingCurve.getTokenSellQuote(totalSupply(), tokenOrderSize);
    }

    /// @notice The current exchange rate of the token if the market has not graduated.
    ///         This will revert if the market has graduated to the Uniswap V3 pool.
    function currentExchangeRate() public view returns (uint256) {
        if (marketType == MarketType.UNISWAP_POOL) {
            revert MarketAlreadyGraduated();
        }

        uint256 remainingTokenLiquidity = balanceOf(address(this));
        uint256 ethBalance = address(this).balance;

        if (ethBalance < 0.01 ether) {
            ethBalance = 0.01 ether;
        }

        return (remainingTokenLiquidity * 1e18) / ethBalance;
    }

    /// @notice Receives ETH and executes a buy order.
    receive() external payable {
        if (msg.sender == WETH) {
            return;
        }

        buy(msg.sender, msg.sender, "", marketType, 0, 0);
    }

    /// @dev For receiving the Uniswap V3 LP NFT on market graduation.
    function onERC721Received(address, address, uint256, bytes calldata) external view returns (bytes4) {
        if (msg.sender != poolAddress) revert OnlyPool();

        return this.onERC721Received.selector;
    }

    /// @dev No-op to allow a swap on the pool to set the correct initial price, if needed
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {}

    /// @dev Overrides ERC20's _update function to
    ///      - Prevent transfers to the pool if the market has not graduated.
    ///      - Emit the superset `HigherrrrrrrrTokenTransfer` event with each ERC20 transfer.
    function _update(address from, address to, uint256 value) internal virtual override {
        if (marketType == MarketType.BONDING_CURVE && to == poolAddress) {
            revert MarketNotGraduated();
        }

        super._update(from, to, value);

        emit HigherrrrrrTokenTransfer(from, to, value, balanceOf(from), balanceOf(to), totalSupply());
    }

    /// @dev Validates a bonding curve buy order and if necessary, recalculates the order data if the size is greater than the remaining supply
    function _validateBondingCurveBuy(uint256 minOrderSize)
        internal
        returns (uint256 totalCost, uint256 trueOrderSize, uint256 fee, uint256 refund, bool startMarket)
    {
        // Set the total cost to the amount of ETH sent
        totalCost = msg.value;

        // Calculate the fee
        fee = _calculateFee(totalCost, TOTAL_FEE_BPS);

        // Calculate the amount of ETH remaining for the order
        uint256 remainingEth = totalCost - fee;

        // Get quote for the number of tokens that can be bought with the amount of ETH remaining
        trueOrderSize = bondingCurve.getEthBuyQuote(totalSupply(), remainingEth);

        // Ensure the order size is greater than the minimum order size
        if (trueOrderSize < minOrderSize) revert SlippageBoundsExceeded();

        // Calculate the maximum number of tokens that can be bought
        uint256 maxRemainingTokens = PRIMARY_MARKET_SUPPLY - totalSupply();

        // Start the market if the order size equals the number of remaining tokens
        if (trueOrderSize == maxRemainingTokens) {
            startMarket = true;
        }

        // If the order size is greater than the maximum number of remaining tokens:
        if (trueOrderSize > maxRemainingTokens) {
            // Reset the order size to the number of remaining tokens
            trueOrderSize = maxRemainingTokens;

            // Calculate the amount of ETH needed to buy the remaining tokens
            uint256 ethNeeded = bondingCurve.getTokenBuyQuote(totalSupply(), trueOrderSize);

            // Recalculate the fee with the updated order size
            fee = _calculateFee(ethNeeded, TOTAL_FEE_BPS);

            // Recalculate the total cost with the updated order size and fee
            totalCost = ethNeeded + fee;

            // Refund any excess ETH
            if (msg.value > totalCost) {
                refund = msg.value - totalCost;
            }

            startMarket = true;
        }
    }

    /// @dev Handles a bonding curve sell order
    function _handleBondingCurveSell(uint256 tokensToSell, uint256 minPayoutSize) private returns (uint256) {
        // Get quote for the number of ETH that can be received for the number of tokens to sell
        uint256 payout = bondingCurve.getTokenSellQuote(totalSupply(), tokensToSell);

        // Ensure the payout is greater than the minimum payout size
        if (payout < minPayoutSize) revert SlippageBoundsExceeded();

        // Ensure the payout is greater than the minimum order size
        if (payout < MIN_ORDER_SIZE) revert EthAmountTooSmall();

        // Burn the tokens from the seller
        _burn(msg.sender, tokensToSell);

        return payout;
    }

    /// @dev Handles a Uniswap V3 sell order
    function _handleUniswapSell(uint256 tokensToSell, uint256 minPayoutSize, uint160 sqrtPriceLimitX96)
        private
        returns (uint256)
    {
        // Transfer the tokens from the seller to this contract
        transfer(address(this), tokensToSell);

        // Approve the swap router to spend the tokens
        this.approve(swapRouter, tokensToSell);

        // Set up the swap parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(this),
            tokenOut: WETH,
            fee: LP_FEE,
            recipient: address(this),
            amountIn: tokensToSell,
            amountOutMinimum: minPayoutSize,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });

        // Execute the swap
        uint256 payout = ISwapRouter(swapRouter).exactInputSingle(params);

        // Withdraw the ETH from the contract
        IWETH(WETH).withdraw(payout);

        return payout;
    }

    /// @dev Graduates the market to a Uniswap V3 pool.
    function _graduateMarket() internal {
        // Update the market type
        marketType = MarketType.UNISWAP_POOL;

        // Convert the bonding curve's accumulated ETH to WETH
        uint256 ethLiquidity = address(this).balance;
        IWETH(WETH).deposit{value: ethLiquidity}();

        // Mint the secondary market supply to this contract
        _mint(address(this), SECONDARY_MARKET_SUPPLY);

        // Approve the nonfungible position manager to transfer the WETH and tokens
        SafeERC20.safeIncreaseAllowance(IERC20(WETH), address(nonfungiblePositionManager), ethLiquidity);
        SafeERC20.safeIncreaseAllowance(
            IERC20(address(this)), address(nonfungiblePositionManager), SECONDARY_MARKET_SUPPLY
        );

        // Determine the token order
        bool isWethToken0 = address(WETH) < address(this);
        address token0 = isWethToken0 ? WETH : address(this);
        address token1 = isWethToken0 ? address(this) : WETH;
        uint256 amount0 = isWethToken0 ? ethLiquidity : SECONDARY_MARKET_SUPPLY;
        uint256 amount1 = isWethToken0 ? SECONDARY_MARKET_SUPPLY : ethLiquidity;

        // Get the current and desired price of the pool

        (uint160 currentSqrtPriceX96,,,,,,) = IUniswapV3Pool(poolAddress).slot0();
        uint160 desiredSqrtPriceX96 = isWethToken0 ? POOL_SQRT_PRICE_X96_WETH_0 : POOL_SQRT_PRICE_X96_TOKEN_0;

        // If the current price is not the desired price, set the desired price
        if (currentSqrtPriceX96 != desiredSqrtPriceX96) {
            bool swap0To1 = currentSqrtPriceX96 > desiredSqrtPriceX96;
            IUniswapV3Pool(poolAddress).swap(address(this), swap0To1, 100, desiredSqrtPriceX96, "");
        }

        // Set up the liquidity position mint parameters
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
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
        });

        // Mint the liquidity position to this contract. It will be non-transferable and fees will be non-claimable.
        (uint256 positionId,,,) = INonfungiblePositionManager(nonfungiblePositionManager).mint(params);

        emit HigherrrrrrMarketGraduated(
            address(this), poolAddress, ethLiquidity, SECONDARY_MARKET_SUPPLY, positionId, marketType
        );
    }

    /// @dev Handles calculating and sending fees directly to the fee recipient
    function _disperseFees(uint256 _fee, address) internal {
        if (_fee > 0) {
            (bool success,) = feeRecipient.call{value: _fee}("");
            if (!success) revert EthTransferFailed();

            emit HigherrrrrrTokenFees(feeRecipient, _fee);
        }
    }

    /// @dev Calculates the fee for a given amount and basis points.
    function _calculateFee(uint256 amount, uint256 bps) internal pure returns (uint256) {
        return (amount * bps) / 10_000;
    }

    function name() public view virtual override(ERC20Upgradeable, IHigherrrrrrr) returns (string memory) {
        if (tokenType == TokenType.REGULAR) {
            return super.name();
        }

        (, PriceLevel memory currentLevel) = getCurrentPriceLevel();
        return currentLevel.name;
    }

    // Helper function to get current price from Uniswap pool
    function getCurrentPrice() public view returns (uint256) {
        if (marketType == MarketType.BONDING_CURVE) {
            // Calculate current price from bonding curve
            uint256 tokensForOneEth = bondingCurve.getEthBuyQuote(totalSupply(), 1 ether);
            return (1 ether * 1e18) / tokensForOneEth; // Price in wei per token
        }

        // Uniswap pool price calculation
        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(poolAddress).slot0();

        // Convert sqrtPriceX96 to actual price
        uint256 price;
        if (address(WETH) < address(this)) {
            // WETH is token0, price = 1/price
            price = ((2 ** 192) * 1e18) / (uint256(sqrtPriceX96) * uint256(sqrtPriceX96));
        } else {
            // WETH is token1, price = price
            price = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) * 1e18) >> 192;
        }

        return price;
    }

    /// @notice Returns all price levels and their corresponding names
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

        // If price is 0 (initial state), return first price level
        if (currentPrice == 0) {
            currentLevel = PriceLevel(0, super.name(), tokenURI);
            return (currentPrice, currentLevel);
        }

        // Find the highest price level that's below current price
        uint256 highestQualifyingPrice = 0;

        for (uint256 i = 0; i < numPriceLevels; i++) {
            if (currentPrice >= priceLevels[i].price && priceLevels[i].price > highestQualifyingPrice) {
                highestQualifyingPrice = priceLevels[i].price;
                currentLevel = priceLevels[i];
            }
        }

        return (currentPrice, currentLevel);
    }
}
