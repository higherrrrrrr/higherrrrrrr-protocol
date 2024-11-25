// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MockUniswapV3Pool} from "./MockUniswapV3Pool.sol";

contract MockUniswapV3Factory {
    mapping(address => mapping(address => mapping(uint24 => address))) public getPool;

    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool) {
        require(tokenA != tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        pool = address(new MockUniswapV3Pool());
        getPool[token0][token1][fee] = pool;
        getPool[token1][token0][fee] = pool;

        return pool;
    }
}
