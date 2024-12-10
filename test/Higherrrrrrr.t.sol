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

contract HigherrrrrrrTest is Test {
    Higherrrrrrr public token;
    HigherrrrrrrConviction public conviction;
    HigherrrrrrrFactory public factory;
    BondingCurve public bondingCurve;
    MockWETH public weth;
    MockPositionManager public positionManager;

    address public constant UNISWAP_V3_FACTORY = address(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    address public constant SWAP_ROUTER = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    address public feeRecipient;
    address public user1;
    address public user2;

    IHigherrrrrrr.PriceLevel[] priceLevels;
    IHigherrrrrrr.ImageLevel[] imageLevels;

    // Add Uniswap pool price constants
    uint160 public constant POOL_SQRT_PRICE_X96_WETH_0 = 400950665883918763141200546267337;
    uint160 public constant POOL_SQRT_PRICE_X96_TOKEN_0 = 15655546353934715619853339;

    // Add constants from Higherrrrrrr.sol
    uint256 public constant MAX_TOTAL_SUPPLY = 1_000_000_000e18; // 1B tokens with 18 decimals
    uint256 public constant CONVICTION_THRESHOLD = 1000; // 0.1% = 1/1000

    function setUp() public {
        // Create test addresses
        feeRecipient = makeAddr("feeRecipient");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy mock contracts
        weth = new MockWETH();
        positionManager = new MockPositionManager();

        // Deploy bonding curve
        bondingCurve = new BondingCurve();

        // Setup price levels with lower thresholds
        priceLevels.push(
            IHigherrrrrrr.PriceLevel({
                price: 1_000_000_000, // 1 gwei
                name: "highr"
            })
        );
        priceLevels.push(
            IHigherrrrrrr.PriceLevel({
                price: 5_000_000_000, // 5 gwei
                name: "highrrr"
            })
        );
        priceLevels.push(
            IHigherrrrrrr.PriceLevel({
                price: 10_000_000_000, // 10 gwei
                name: "highrrrrrr"
            })
        );
        priceLevels.push(
            IHigherrrrrrr.PriceLevel({
                price: 50_000_000_000, // 50 gwei
                name: "highrrrrrrr"
            })
        );
        priceLevels.push(
            IHigherrrrrrr.PriceLevel({
                price: 100_000_000_000, // 100 gwei
                name: "highrrrrrrrr"
            })
        );

        imageLevels.push(
            IHigherrrrrrr.ImageLevel({
                price: 1_000_000_000, // 1 gwei
                imageUri: "ipfs://QmHash1"
            })
        );
        imageLevels.push(
            IHigherrrrrrr.ImageLevel({
                price: 5_000_000_000, // 5 gwei
                imageUri: "ipfs://QmHash2"
            })
        );
        imageLevels.push(
            IHigherrrrrrr.ImageLevel({
                price: 10_000_000_000, // 10 gwei
                imageUri: "ipfs://QmHash3"
            })
        );
        imageLevels.push(
            IHigherrrrrrr.ImageLevel({
                price: 50_000_000_000, // 50 gwei
                imageUri: "ipfs://QmHash4"
            })
        );
        imageLevels.push(
            IHigherrrrrrr.ImageLevel({
                price: 100_000_000_000, // 100 gwei
                imageUri: "ipfs://QmHash5"
            })
        );

        // Deploy factory
        factory = new HigherrrrrrrFactory(
            feeRecipient, address(weth), address(positionManager), SWAP_ROUTER, address(bondingCurve)
        );

        // Create new token instance with 0.01 ETH initial liquidity
        vm.deal(address(this), 1 ether);
        (address tokenAddress, address convictionAddress) = factory.createHigherrrrrrr{value: 0.01 ether}(
            "highr", // Initial name
            "HIGHR", // Symbol
            "ipfs://QmHash", // Token URI
            priceLevels,
            new IHigherrrrrrr.ImageLevel[](0),
            IHigherrrrrrr.TokenType.TEXT_EVOLUTION
        );

        token = Higherrrrrrr(payable(tokenAddress));
        conviction = HigherrrrrrrConviction(convictionAddress);

        // Label addresses for better trace output
        vm.label(address(weth), "WETH");
        vm.label(address(positionManager), "PositionManager");
        vm.label(address(token), "Higherrrrrrr");
        vm.label(address(conviction), "Conviction");
    }

    function test_InitialState() public {
        assertEq(token.name(), "highr");
        assertEq(token.symbol(), "HIGHR");
        assertEq(address(token.bondingCurve()), address(bondingCurve));
        assertEq(uint256(token.marketType()), uint256(IHigherrrrrrr.MarketType.BONDING_CURVE));
        assertEq(token.numPriceLevels(), 5);
    }

    function test_PriceLevelProgression() public {
        // Initial state
        assertEq(token.name(), "highr");

        // Buy enough to reach second level (5 gwei threshold)
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);

        // First buy should be large enough to move price above 5 gwei
        token.buy{value: 0.5 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        assertEq(token.name(), "highrrr");

        // Buy more to reach third level (10 gwei threshold)
        token.buy{value: 2 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        assertEq(token.name(), "highrrrrrr");
        vm.stopPrank();
    }

    function test_ConvictionNFTMinting() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);

        // Buy enough tokens to trigger NFT mint (>0.1% of total supply)
        token.buy{value: 5 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // Check NFT details
        assertEq(conviction.balanceOf(user1), 1);
        (string memory evolution,,) = conviction.getHigherrrrrrrState();
        assertEq(evolution, "highrrrrrr");
        vm.stopPrank();
    }

    function test_MarketGraduation() public {
        vm.startPrank(user1);
        vm.deal(user1, 1000 ether);

        // Buy enough tokens to trigger market graduation (800M tokens)
        token.buy{value: 8.1 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // Verify graduation
        assertEq(uint256(token.marketType()), uint256(IHigherrrrrrr.MarketType.UNISWAP_POOL));
        assertEq(token.totalSupply(), 1_000_000_000e18); // Should be at max supply
        vm.stopPrank();
    }

    function testFail_BuyWithInsufficientETH() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);

        // Try to buy with less than minimum order size
        token.buy{value: 0.00000001 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);
        vm.stopPrank();
    }

    function test_FeeCollection() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);

        uint256 initialFeeRecipientBalance = feeRecipient.balance;

        // Buy tokens with 0.1 ETH
        token.buy{value: 0.1 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // Check if 1% fee was collected
        assertEq(feeRecipient.balance - initialFeeRecipientBalance, 0.001 ether);
        vm.stopPrank();
    }

    function test_NoGraduationOnSmallBuy() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);

        // Buy tokens but not enough to trigger graduation (< 8 ETH)
        token.buy{value: 5 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // Verify still in bonding curve phase
        assertEq(uint256(token.marketType()), uint256(IHigherrrrrrr.MarketType.BONDING_CURVE));

        // Verify supply is less than graduation amount
        assert(token.totalSupply() < 800_000_000e18); // Should be less than PRIMARY_MARKET_SUPPLY

        // Buy more but still not enough to graduate
        token.buy{value: 2 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // Still should not have graduated
        assertEq(uint256(token.marketType()), uint256(IHigherrrrrrr.MarketType.BONDING_CURVE));
        assert(token.totalSupply() < 800_000_000e18);
        vm.stopPrank();
    }

    // Security Tests
    function testFail_ReinitializeToken() public {
        // Try to initialize again
        token.initialize(
            address(bondingCurve),
            "ipfs://QmHash2",
            "highr2",
            "HIGHR2",
            priceLevels,
            new IHigherrrrrrr.ImageLevel[](0),
            address(conviction),
            IHigherrrrrrr.TokenType.TEXT_EVOLUTION
        );
    }

    function testFail_UnauthorizedConvictionMint() public {
        vm.startPrank(user1);
        conviction.mintConviction(user1, "highr", 1000e18, 0.1 ether);
        vm.stopPrank();
    }

    function test_SlippageProtection() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);

        // Get quote first
        uint256 expectedTokens = token.getEthBuyQuote(0.1 ether);

        // Try to buy with minimum tokens higher than possible
        vm.expectRevert(IHigherrrrrrr.SlippageBoundsExceeded.selector);
        token.buy{value: 0.1 ether}(
            user1,
            user1,
            "",
            IHigherrrrrrr.MarketType.BONDING_CURVE,
            expectedTokens * 2, // Require double the possible tokens
            0
        );
        vm.stopPrank();
    }

    function test_RefundOnLargeOrder() public {
        vm.startPrank(user1);
        vm.deal(user1, 1000 ether);

        // Send more ETH than needed for graduation
        uint256 initialBalance = user1.balance;
        token.buy{value: 20 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // Should have received refund
        assertGt(user1.balance, initialBalance - 20 ether);
        vm.stopPrank();
    }

    function testFail_TransferToPoolBeforeGraduation() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);

        // Buy some tokens
        token.buy{value: 1 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // Try to transfer to pool before graduation
        token.transfer(token.poolAddress(), 1000e18);
        vm.stopPrank();
    }

    function test_BurnAfterGraduation() public {
        // Graduate the market first
        vm.startPrank(user1);
        vm.deal(user1, 1000 ether);
        token.buy{value: 8.1 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // Should be able to burn after graduation
        uint256 balance = token.balanceOf(user1);
        uint256 burnAmount = balance / 2;
        uint256 expectedBalance = balance - burnAmount;

        token.burn(burnAmount);
        // Allow for 1 wei rounding difference
        assertApproxEqAbs(token.balanceOf(user1), expectedBalance, 1);
        vm.stopPrank();
    }

    function testFail_BurnBeforeGraduation() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);

        // Buy some tokens
        token.buy{value: 1 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // Try to burn before graduation
        token.burn(1000e18);
        vm.stopPrank();
    }

    function testFail_QuotesAfterGraduation() public {
        // Graduate the market
        vm.startPrank(user1);
        vm.deal(user1, 1000 ether);
        token.buy{value: 8.1 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // Try to get quotes after graduation
        token.getEthBuyQuote(1 ether);
        vm.stopPrank();
    }

    function test_DirectETHTransfer() public {
        vm.deal(user1, 10 ether);

        // Send ETH directly to token contract
        vm.prank(user1);
        (bool success,) = address(token).call{value: 1 ether}("");

        require(success, "ETH transfer failed");
        assertGt(token.balanceOf(user1), 0);
    }

    function test_MarketStateTransitions() public {
        // Check initial state
        (IHigherrrrrrr.MarketState memory state) = token.state();
        assertEq(uint256(state.marketType), uint256(IHigherrrrrrr.MarketType.BONDING_CURVE));
        assertEq(state.marketAddress, address(token));

        // Graduate market
        vm.startPrank(user1);
        vm.deal(user1, 1000 ether);
        token.buy{value: 8.1 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // Check graduated state
        (state) = token.state();
        assertEq(uint256(state.marketType), uint256(IHigherrrrrrr.MarketType.UNISWAP_POOL));
        assertEq(state.marketAddress, token.poolAddress());
        vm.stopPrank();
    }

    function test_ConvictionNFTMetadata() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);

        // Buy enough to mint NFT
        token.buy{value: 5 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // Check NFT URI
        uint256 tokenId = 0;
        string memory uri = conviction.tokenURI(tokenId);
        assertTrue(bytes(uri).length > 0);

        // Verify conviction details
        (string memory evolution, uint256 amount, uint256 price, uint256 timestamp) =
            conviction.convictionDetails(tokenId);
        assertEq(evolution, token.name());
        assertGt(amount, 0);
        assertGt(price, 0);
        assertEq(timestamp, block.timestamp);
        vm.stopPrank();
    }

    function test_FullLifecycle() public {
        // Initial state check
        assertEq(token.name(), "highr");
        assertEq(uint256(token.marketType()), uint256(IHigherrrrrrr.MarketType.BONDING_CURVE));

        vm.startPrank(user1);
        vm.deal(user1, 100 ether);

        // 1. Small buy - first evolution
        uint256 tokens = token.buy{value: 0.001 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // 2. Medium buy - second evolution + NFT mint
        tokens = token.buy{value: 0.6 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // 3. Large buy - graduate to Uniswap
        tokens = token.buy{value: 8 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // Verify graduation
        assertEq(
            uint256(token.marketType()), uint256(IHigherrrrrrr.MarketType.UNISWAP_POOL), "Should graduate to Uniswap"
        );
        address poolAddress = token.poolAddress();
        assertTrue(poolAddress != address(0), "Pool should be created");

        // 4. Test Uniswap pool interaction and evolution
        // Mock the Uniswap pool price to trigger next evolution
        MockUniswapV3Pool(poolAddress).initialize(POOL_SQRT_PRICE_X96_TOKEN_0 * 2); // Double the price
        assertEq(token.name(), "highrrrrrrrr"); // Should evolve to next level

        vm.stopPrank();
    }

    function test_RegularToken() public {
        (address tokenAddress,) = factory.createHigherrrrrrr{value: 0.01 ether}(
            "Regular",
            "REG",
            "ipfs://QmHash",
            priceLevels,
            new IHigherrrrrrr.ImageLevel[](0),
            IHigherrrrrrr.TokenType.REGULAR
        );

        Higherrrrrrr regularToken = Higherrrrrrr(payable(tokenAddress));

        // Name should stay constant regardless of price
        assertEq(regularToken.name(), "Regular");

        vm.startPrank(user1);
        vm.deal(user1, 10 ether);
        regularToken.buy{value: 5 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // Name should still be the same after price increase
        assertEq(regularToken.name(), "Regular");
        vm.stopPrank();
    }

    function test_TextEvolutionToken() public {
        // Already tested in test_PriceLevelProgression()
        // Just verify the token type
        assertEq(uint256(token.tokenType()), uint256(IHigherrrrrrr.TokenType.TEXT_EVOLUTION));
    }

    function testFail_InvalidImageUri() public {
        // Create invalid image levels with malicious URI
        IHigherrrrrrr.ImageLevel[] memory invalidImageLevels = new IHigherrrrrrr.ImageLevel[](1);
        invalidImageLevels[0] = IHigherrrrrrr.ImageLevel({price: 1_000_000_000, imageUri: "javascript:alert('xss')"});

        // Should revert due to invalid URI
        factory.createHigherrrrrrr{value: 0.01 ether}(
            "InvalidImage",
            "INVALID",
            "ipfs://QmHash",
            priceLevels,
            invalidImageLevels,
            IHigherrrrrrr.TokenType.IMAGE_EVOLUTION
        );
    }

    function testFail_EmptyImageLevels() public {
        // Try to create IMAGE_EVOLUTION token without image levels
        IHigherrrrrrr.ImageLevel[] memory emptyImageLevels;

        factory.createHigherrrrrrr{value: 0.01 ether}(
            "NoImages", "NIMG", "ipfs://QmHash", priceLevels, emptyImageLevels, IHigherrrrrrr.TokenType.IMAGE_EVOLUTION
        );
    }

    function test_RegularTokenWithImageLevels() public {
        // Should allow creation of regular token with empty image levels
        IHigherrrrrrr.ImageLevel[] memory emptyImageLevels;

        (address tokenAddress,) = factory.createHigherrrrrrr{value: 0.01 ether}(
            "Regular", "REG", "ipfs://QmHash", priceLevels, emptyImageLevels, IHigherrrrrrr.TokenType.REGULAR
        );

        Higherrrrrrr regularToken = Higherrrrrrr(payable(tokenAddress));

        // Name should remain constant
        assertEq(regularToken.name(), "Regular");
        assertEq(regularToken.getCurrentImageUri(), "");

        // Buy some tokens
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);
        regularToken.buy{value: 5 ether}(user1, user1, "", IHigherrrrrrr.MarketType.BONDING_CURVE, 0, 0);

        // Name and URI should still be the same
        assertEq(regularToken.name(), "Regular");
        assertEq(regularToken.getCurrentImageUri(), "");
        vm.stopPrank();
    }

}
