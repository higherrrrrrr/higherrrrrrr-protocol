// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MockUniswapV3Pool {
    uint160 public sqrtPriceX96;
    int24 public tick;
    uint16 public observationIndex;
    uint16 public observationCardinality;
    uint16 public observationCardinalityNext;
    uint8 public feeProtocol;
    bool public unlocked = true;

    function initialize(uint160 _sqrtPriceX96) external {
        sqrtPriceX96 = _sqrtPriceX96;
    }

    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96_,
            int24 tick_,
            uint16 observationIndex_,
            uint16 observationCardinality_,
            uint16 observationCardinalityNext_,
            uint8 feeProtocol_,
            bool unlocked_
        )
    {
        return (
            sqrtPriceX96,
            tick,
            observationIndex,
            observationCardinality,
            observationCardinalityNext,
            feeProtocol,
            unlocked
        );
    }

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1) {
        // Mock implementation that just updates the price
        sqrtPriceX96 = sqrtPriceLimitX96;
        return (0, 0);
    }
}
