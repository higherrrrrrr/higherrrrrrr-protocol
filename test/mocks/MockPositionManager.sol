// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MockUniswapV3Factory} from "./MockUniswapV3Factory.sol";
import {MockUniswapV3Pool} from "./MockUniswapV3Pool.sol";

contract MockPositionManager {
    MockUniswapV3Factory public factory;

    constructor() {
        factory = new MockUniswapV3Factory();
    }

    function createAndInitializePoolIfNecessary(address token0, address token1, uint24 fee, uint160 sqrtPriceX96)
        external
        returns (address pool)
    {
        pool = factory.getPool(token0, token1, fee);
        if (pool == address(0)) {
            pool = factory.createPool(token0, token1, fee);
            MockUniswapV3Pool(pool).initialize(sqrtPriceX96);
        }
        return pool;
    }

    function mint(MintParams calldata)
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        return (1, 0, 0, 0);
    }

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }
}
