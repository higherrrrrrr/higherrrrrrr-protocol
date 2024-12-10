// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {Higherrrrrrr} from "../src/Higherrrrrrr.sol";
import {HigherrrrrrrConviction} from "../src/HigherrrrrrrConviction.sol";
import {HigherrrrrrrFactory} from "../src/HigherrrrrrrFactory.sol";
import {BondingCurve} from "../src/BondingCurve.sol";
import {IHigherrrrrrr} from "../src/interfaces/IHigherrrrrrr.sol";
import {MockWETH} from "./mocks/MockWETH.sol";
import {MockPositionManager} from "./mocks/MockPositionManager.sol";
import {MockUniswapV3Pool} from "./mocks/MockUniswapV3Pool.sol";

contract HigherrrrrrrFactoryTest is Test {
    HigherrrrrrrFactory public factory;
    BondingCurve public bondingCurve;
    MockWETH public weth;
    MockPositionManager public positionManager;

    address public feeRecipient;
    address public user1;
    IHigherrrrrrr.PriceLevel[] priceLevels;
    IHigherrrrrrr.ImageLevel[] imageLevels;

    function setUp() public {
        feeRecipient = makeAddr("feeRecipient");
        user1 = makeAddr("user1");

        weth = new MockWETH();
        positionManager = new MockPositionManager();
        bondingCurve = new BondingCurve();

        // Setup basic price levels
        priceLevels.push(IHigherrrrrrr.PriceLevel({price: 1_000_000_000, name: "Level1"}));
        priceLevels.push(IHigherrrrrrr.PriceLevel({price: 5_000_000_000, name: "Level2"}));

        factory = new HigherrrrrrrFactory(
            feeRecipient, address(weth), address(positionManager), makeAddr("swapRouter"), address(bondingCurve)
        );
    }

    function test_CreateToken() public {
        vm.deal(address(this), 1 ether);
        (address token, address conviction) = factory.createHigherrrrrrr{value: 0.01 ether}(
            "Test",
            "TEST",
            "ipfs://test",
            priceLevels,
            new IHigherrrrrrr.ImageLevel[](0),
            IHigherrrrrrr.TokenType.REGULAR
        );

        assertTrue(token != address(0), "Token address should not be zero");
        assertTrue(conviction != address(0), "Conviction address should not be zero");

        Higherrrrrrr createdToken = Higherrrrrrr(payable(token));
        assertEq(createdToken.name(), "Test");
        assertEq(createdToken.symbol(), "TEST");
        assertEq(uint256(createdToken.tokenType()), uint256(IHigherrrrrrr.TokenType.REGULAR));
    }

    function testFail_CreateTokenWithEmptyPriceLevels() public {
        vm.deal(address(this), 1 ether);
        factory.createHigherrrrrrr{value: 0.01 ether}(
            "Test",
            "TEST",
            "ipfs://test",
            new IHigherrrrrrr.PriceLevel[](0),
            new IHigherrrrrrr.ImageLevel[](0),
            IHigherrrrrrr.TokenType.REGULAR
        );
    }

    function testFail_ImageEvolutionWithoutImageLevels() public {
        vm.deal(address(this), 1 ether);
        factory.createHigherrrrrrr{value: 0.01 ether}(
            "Image",
            "IMG",
            "ipfs://test",
            priceLevels,
            new IHigherrrrrrr.ImageLevel[](0),
            IHigherrrrrrr.TokenType.IMAGE_EVOLUTION
        );
    }
}
