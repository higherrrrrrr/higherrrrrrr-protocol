// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IBondingCurve {
    /// @notice Returns number of tokens that can be bought with a given amount of ETH
    /// @param currentSupply Current total supply of tokens
    /// @param ethOrderSize Amount of ETH to spend
    /// @return Amount of tokens that can be bought
    function getEthBuyQuote(uint256 currentSupply, uint256 ethOrderSize) external pure returns (uint256);

    /// @notice Returns amount of ETH needed to buy a given amount of tokens
    /// @param currentSupply Current total supply of tokens
    /// @param tokenOrderSize Amount of tokens to buy
    /// @return Amount of ETH needed
    function getTokenBuyQuote(uint256 currentSupply, uint256 tokenOrderSize) external pure returns (uint256);

    /// @notice Returns number of tokens that should be sold for a given amount of ETH
    /// @param currentSupply Current total supply of tokens
    /// @param ethOrderSize Desired ETH output
    /// @return Amount of tokens to sell
    function getEthSellQuote(uint256 currentSupply, uint256 ethOrderSize) external pure returns (uint256);

    /// @notice Returns amount of ETH received for selling a given amount of tokens
    /// @param currentSupply Current total supply of tokens
    /// @param tokensToSell Amount of tokens to sell
    /// @return Amount of ETH to receive
    function getTokenSellQuote(uint256 currentSupply, uint256 tokensToSell) external pure returns (uint256);

    /// @notice The base coefficient in the exponential bonding curve formula y = A*e^(Bx)
    function A() external pure returns (uint256);

    /// @notice The exponent coefficient in the exponential bonding curve formula y = A*e^(Bx)
    function B() external pure returns (uint256);

    /// @notice Thrown when trying to sell more tokens than available
    error InsufficientLiquidity();

    /// @notice Returns the current price of the token
    /// @param totalSupply Current total supply of tokens
    /// @return Current price of the token
    function getCurrentPrice(uint256 totalSupply) external view returns (uint256);
}
