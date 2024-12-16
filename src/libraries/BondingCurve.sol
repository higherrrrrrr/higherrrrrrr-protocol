// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";
import {SafeCastLib} from "solady/src/utils/SafeCastLib.sol";

library BondingCurve {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;
    using SafeCastLib for uint256;
    using SafeCastLib for int256;

    error InsufficientLiquidity();

    // y = A*e^(Bx)
    uint256 public constant A = 1060848709;
    uint256 public constant B = 4379701787;

    function getEthSellQuote(uint256 currentSupply, uint256 ethOrderSize) external pure returns (uint256) {
        uint256 deltaY = ethOrderSize;
        uint256 x0 = currentSupply;
        uint256 exp_b_x0 = B.mulWad(x0).toInt256().expWad().toUint256();

        uint256 exp_b_x1 = exp_b_x0 - deltaY.fullMulDiv(B, A);
        uint256 x1 = exp_b_x1.toInt256().lnWad().toUint256().divWad(B);
        uint256 tokensToSell = x0 - x1;

        return tokensToSell;
    }

    function getTokenSellQuote(uint256 currentSupply, uint256 tokensToSell) external pure returns (uint256) {
        if (currentSupply < tokensToSell) revert InsufficientLiquidity();
        uint256 x0 = currentSupply;
        uint256 x1 = x0 - tokensToSell;

        uint256 exp_b_x0 = B.mulWad(x0).toInt256().expWad().toUint256();
        uint256 exp_b_x1 = B.mulWad(x1).toInt256().expWad().toUint256();

        // calculate deltaY = (a/b)*(exp(b*x0) - exp(b*x1))
        uint256 deltaY = (exp_b_x0 - exp_b_x1).fullMulDiv(A, B);

        return deltaY;
    }

    function getEthBuyQuote(uint256 currentSupply, uint256 ethOrderSize) external pure returns (uint256) {
        uint256 x0 = currentSupply;
        uint256 deltaY = ethOrderSize;

        // calculate exp(b*x0)
        uint256 exp_b_x0 = B.mulWad(x0).toInt256().expWad().toUint256();

        // calculate exp(b*x0) + (dy*b/a)
        uint256 exp_b_x1 = exp_b_x0 + deltaY.fullMulDiv(B, A);

        uint256 deltaX = exp_b_x1.toInt256().lnWad().toUint256().divWad(B) - x0;

        return deltaX;
    }

    function getTokenBuyQuote(uint256 currentSupply, uint256 tokenOrderSize) external pure returns (uint256) {
        uint256 x0 = currentSupply;
        uint256 x1 = tokenOrderSize + currentSupply;

        uint256 exp_b_x0 = B.mulWad(x0).toInt256().expWad().toUint256();
        uint256 exp_b_x1 = B.mulWad(x1).toInt256().expWad().toUint256();

        uint256 deltaY = (exp_b_x1 - exp_b_x0).fullMulDiv(A, B);

        return deltaY;
    }
}
