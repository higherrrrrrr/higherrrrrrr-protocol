// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IHigherrrrrrr {
    /// @notice Unauthorized
    error Unauthorized();

    /// @notice Thrown when an operation is attempted with a zero address
    error AddressZero(string variable);

    /// @notice Thrown when an invalid market type
    error InvalidMarketType();

    /// @notice Thrown when there are insufficient funds for an operation
    error InsufficientFunds();

    /// @notice Thrown when the slippage bounds are exceeded during a transaction
    error SlippageBoundsExceeded();

    /// @notice Thrown when price levels are invalid
    error InvalidPriceLevels();

    /// @notice Represents the type of token
    enum TokenType {
        REGULAR,
        TEXT_EVOLUTION,
        IMAGE_EVOLUTION
    }

    /// @notice Represents the type of market
    enum MarketType {
        BONDING_CURVE,
        UNISWAP_POOL
    }

    /// @notice Represents the state of the market
    struct MarketState {
        MarketType marketType;
        address marketAddress;
    }

    /// @notice Represents a price level
    struct PriceLevel {
        uint256 price;
        string name;
        string imageURI;
    }

    /// @notice Emitted when a token is bought
    /// @param buyer The address of the buyer
    /// @param recipient The address of the recipient
    /// @param totalEth The total ETH involved in the transaction
    /// @param ethFee The ETH fee for the transaction
    /// @param ethSold The amount of ETH sold
    /// @param tokensBought The number of tokens bought
    /// @param buyerTokenBalance The token balance of the buyer after the transaction
    /// @param comment A comment associated with the transaction
    /// @param totalSupply The total supply of tokens after the buy
    /// @param marketType The type of market
    event HigherrrrrrTokenBuy(
        address indexed buyer,
        address indexed recipient,
        uint256 totalEth,
        uint256 ethFee,
        uint256 ethSold,
        uint256 tokensBought,
        uint256 buyerTokenBalance,
        string comment,
        uint256 totalSupply,
        MarketType marketType
    );

    /// @notice Emitted when a token is sold
    /// @param seller The address of the seller
    /// @param recipient The address of the recipient
    /// @param totalEth The total ETH involved in the transaction
    /// @param ethFee The ETH fee for the transaction
    /// @param ethBought The amount of ETH bought
    /// @param tokensSold The number of tokens sold
    /// @param sellerTokenBalance The token balance of the seller after the transaction
    /// @param comment A comment associated with the transaction
    /// @param totalSupply The total supply of tokens after the sell
    /// @param marketType The type of market
    event HigherrrrrrTokenSell(
        address indexed seller,
        address indexed recipient,
        uint256 totalEth,
        uint256 ethFee,
        uint256 ethBought,
        uint256 tokensSold,
        uint256 sellerTokenBalance,
        string comment,
        uint256 totalSupply,
        MarketType marketType
    );

    /// @notice Emitted when tokens are transferred
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param amount The amount of tokens transferred
    /// @param fromTokenBalance The token balance of the sender after the transfer
    /// @param toTokenBalance The token balance of the recipient after the transfer
    /// @param totalSupply The total supply of tokens after the transfer
    event HigherrrrrrTokenTransfer(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 fromTokenBalance,
        uint256 toTokenBalance,
        uint256 totalSupply
    );

    /// @notice Emitted when fees are distributed
    /// @param feeRecipient The address of the fee recipient
    /// @param fee The fee amount
    event HigherrrrrrTokenFees(address indexed feeRecipient, address token, uint256 fee);

    /// @notice Emitted when a market graduates
    /// @param tokenAddress The address of the token
    /// @param poolAddress The address of the pool
    /// @param totalEthLiquidity The total ETH liquidity in the pool
    /// @param totalTokenLiquidity The total token liquidity in the pool
    /// @param lpPositionId The ID of the liquidity position
    /// @param marketType The type of market
    event HigherrrrrrMarketGraduated(
        address indexed tokenAddress,
        address indexed poolAddress,
        uint256 totalEthLiquidity,
        uint256 totalTokenLiquidity,
        uint256 lpPositionId,
        MarketType marketType
    );

    /// @notice Buys tokens from the bonding curve or Uniswap V3 pool depending on the market state.
    /// @param recipient The address to receive the purchased tokens
    /// @param refundRecipient The address to receive any excess ETH
    /// @param comment A comment associated with the buy order
    /// @param expectedMarketType The expected market type (0 = BONDING_CURVE, 1 = UNISWAP_POOL)
    /// @param minOrderSize The minimum size of the order to prevent slippage
    /// @param sqrtPriceLimitX96 The price limit for Uniswap V3 pool swaps
    function buy(
        address recipient,
        address refundRecipient,
        string memory comment,
        MarketType expectedMarketType,
        uint256 minOrderSize,
        uint160 sqrtPriceLimitX96
    ) external payable returns (uint256);

    /// @notice Sells tokens to the bonding curve or Uniswap V3 pool depending on the market state
    /// @param tokensToSell The number of tokens to sell
    /// @param recipient The address to receive the ETH payout
    /// @param comment A comment associated with the sell order
    /// @param expectedMarketType The expected market type (0 = BONDING_CURVE, 1 = UNISWAP_POOL)
    /// @param minPayoutSize The minimum payout size to prevent slippage
    /// @param sqrtPriceLimitX96 The price limit for Uniswap V3 pool swaps
    function sell(
        uint256 tokensToSell,
        address recipient,
        string memory comment,
        MarketType expectedMarketType,
        uint256 minPayoutSize,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256);

    /// @notice Allows a holder to burn their tokens after the market has graduated
    /// @param tokensToBurn The number of tokens to burn
    function burn(uint256 tokensToBurn) external;

    /// @notice Provides a quote for buying tokens with a given amount of ETH
    /// @param amount The amount of ETH
    /// @return The number of tokens that can be bought
    function getEthBuyQuote(uint256 amount) external view returns (uint256);

    /// @notice Provides a quote for selling a given amount of ETH
    /// @param amount The amount of ETH
    /// @return The number of tokens that can be received
    function getEthSellQuote(uint256 amount) external view returns (uint256);

    /// @notice Provides a quote for buying a given number of tokens
    /// @param amount The number of tokens
    /// @return The amount of ETH needed
    function getTokenBuyQuote(uint256 amount) external view returns (uint256);

    /// @notice Provides a quote for selling a given number of tokens
    /// @param amount The number of tokens
    /// @return The amount of ETH that can be received
    function getTokenSellQuote(uint256 amount) external view returns (uint256);

    /// @notice Returns the current state of the market
    /// @return The market state
    function state() external view returns (MarketState memory);

    /// @notice Returns the address of the Conviction NFT contract
    /// @return The Conviction NFT contract address
    function convictionNFT() external view returns (address);

    /// @notice Returns the type of token
    /// @return The token type
    function tokenType() external view returns (TokenType);

    /// @notice Returns the current price from Uniswap pool or 0 if in bonding curve
    /// @return The current price in ETH
    function getCurrentPrice() external view returns (uint256);

    /// @notice Uniswap V3 LP Position ID
    /// @return The LP NFT ID
    function positionId() external view returns (uint256);

    /// @notice Returns the current price level
    /// @return currentPrice The current price in ETH
    /// @return currentLevel The current price level
    function getCurrentPriceLevel() external view returns (uint256 currentPrice, PriceLevel memory currentLevel);

    /// @notice Initializes a new Higherrrrrrr token
    /// @param _weth The WETH token address
    /// @param _convictionNFT The address of the conviction NFT contract
    /// @param _nonfungiblePositionManager The Uniswap V3 position manager address
    /// @param _swapRouter The Uniswap V3 router address
    /// @param _protocolFeeRecipient The address to receive fees
    /// @param _name The token name
    /// @param _symbol The token symbol
    /// @param _tokenType The type of token (REGULAR or TEXT_EVOLUTION)
    /// @param _tokenURI The basic token URI for the Conviction NFT
    /// @param _priceLevels The price levels and names
    function initialize(
        /// @dev Constants from Factory
        address _weth,
        address _convictionNFT,
        address _nonfungiblePositionManager,
        address _swapRouter,
        address _protocolFeeRecipient,
        /// @dev ERC20
        string memory _name,
        string memory _symbol,
        /// @dev Evolution
        TokenType _tokenType,
        string memory _tokenURI,
        PriceLevel[] calldata _priceLevels
    ) external;

    /// @notice Collects and reinvests LP fees back into the pool
    /// @return wethAmount The amount of WETH reinvested into the pool
    /// @return tokenAmount The amount of tokens reinvested into the pool
    function harderrrrrrr() external returns (uint256 wethAmount, uint256 tokenAmount);

    /// @notice Calculates the trading fee for a given amount
    /// @param amount The amount to calculate the fee for
    /// @return protocolFee The calculated fee
    function calculateTradingFee(uint256 amount) external pure returns (uint256 protocolFee);

    /// @notice Calculates the trading markup for a desired amount
    /// @param desiredAmount The desired amount to calculate the markup for
    /// @return protocolFee The calculated markup fee
    function calculateTradingMarkup(uint256 desiredAmount) external pure returns (uint256 protocolFee);
}
