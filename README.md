# Higherrrrrrr Protocol

Higherrrrrrr is the first Evolutionary Meme Coin protocol, combining bonding curves with Uniswap V3 price oracles to create tokens that evolve onchain based on their market performance.

We're going 

higher
higherr
higherrr
higherrrr
higherrrrr
higherrrrrr
higherrrrrrr

Note: thank you to the wow.xyz protocol team for letting us use their bonding curve and uniswap graduation logic!

## Overview

The protocol introduces a novel concept of token evolution, where the token's identity changes dynamically based on price milestones. As the token's price increases, it "evolves" through different forms, creating a natural narrative arc tied directly to market performance.

### Evolution Mechanics

1. **Bonding Curve Phase**: 
   - Initial distribution phase where price increases predictably
   - Token evolution begins tracking price milestones
   - Community forms around early evolutionary stages

2. **Uniswap V3 Phase**: 
   - Market-driven price discovery
   - Uniswap V3 TWAP oracles determine evolution state
   - Dynamic evolution based on real-time market performance

### Key Features

- **Dynamic Evolution**: Token name and identity evolve based on price milestones, creating a living narrative
- **Price Oracle Integration**: Uses Uniswap V3's precise price feeds to determine evolutionary stages
- **Conviction NFTs**: Commemorative and tradable NFTs that capture evolutionary moments (>0.1% of supply purchases)
- **Automated Market Graduation**: Seamless transition from predictable bonding curve to market-driven pricing
- **Fair Launch**: Pure bonding curve distribution with no pre-mine
- **Memetic Evolution**: Each price level represents a new evolution in the token's journey

## Technical Details

### Smart Contracts

- `Higherrrrrrr.sol`: Core evolutionary logic and market mechanics
- `HigherrrrrrrConviction.sol`: NFT contract capturing evolutionary moments
- `HigherrrrrrrFactory.sol`: Factory for deploying new evolutionary tokens
- `BondingCurve.sol`: Exponential bonding curve mathematics
- `StringSanitizer.sol`: Secure string handling for evolution names

### Token Economics (per memecoin)

- Total Supply: 1,000,000,000 tokens
- Primary Market (Bonding Curve): 800,000,000 tokens
- Secondary Market (Uniswap V3): 200,000,000 tokens
- Fee: 1% on all transactions
- Minimum Order Size: 0.0000001 ETH

### Evolution Mechanics

The protocol uses two price oracle systems:
1. Bonding Curve Phase: Price calculated from exponential curve
2. Uniswap Phase: Real-time price feeds from Uniswap V3 pools

Each evolution level is triggered by crossing predefined price thresholds, creating a dynamic narrative that follows the token's market success.

## Development

### Prerequisites

- Foundry
- Node.js >= 16

### Installation

```shell
git clone https://github.com/Thrive-Point-Group/higherrrrrrr-protocol
cd higherrrrrrr-protocol
forge install
```

### Testing

```shell
forge test
```

### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Deploy

```shell
forge script script/Deploy.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## Security

### Price Oracle Security
- Dual oracle system with bonding curve and Uniswap V3
- Protection against price manipulation through TWAP oracles
- Automatic market graduation prevents oracle exploitation
- Slippage protection on all trades

### Smart Contract Security
- Non-upgradeable design ensures immutability
- Reentrancy protection on all state-changing functions
- Strict input validation and bounds checking
- Safe math operations using OpenZeppelin libraries
- Protected ownership transfers
- Deterministic deployment addresses via CREATE2

### NFT Security
- Full UTF-8 and emoji support with comprehensive sanitization
- SVG and JSON injection protection
- Base64 encoding for on-chain metadata
- Secure minting controls
- Protected evolution state management

### Market Mechanics
- Automated market transitions
- Protected liquidity pool creation
- Secure fee collection and distribution
- Minimum order size requirements
- Maximum supply enforcement
- Gradual token distribution through bonding curve

### Access Controls
- Role-based permission system
- Only Higherrrrrrr contract can mint Conviction NFTs
- Protected initialization functions
- Market state transition controls
- Transfer restrictions during bonding curve phase

### Evolution Security
- On-chain price level verification
- Protected name evolution logic
- Immutable price thresholds
- Secure string handling for evolution names
- Protected state transitions

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Evolution Examples

All evolution logic is handled entirely on-chain through price oracles and smart contracts. Here are some example evolution paths:

### Example 1: Higherrrrrrr
```
$0.0001: "highr"
$0.001:  "highrrr"
$0.01:   "highrrrrrr"
$0.1:    "highrrrrrrrrr"
$1:      "highrrrrrrrrrrrr"
```

### Example 2: Rocket to Moon
```
$0.0001: "🚀"
$0.001:  "🚀🌙"
$0.01:   "🚀🌙✨"
$0.1:    "🚀🌙✨💫"
$1:      "🚀🌙✨💫⭐"
```

### Example 3: Bull Run
```
$0.0001: "🐂"
$0.001:  "🐂💪"
$0.01:   "🐂💪📈"
$0.1:    "🐂💪📈🔥"
$1:      "🐂💪📈🔥👑"
```

### Example 4: Up Only
```
$0.0001: "⬆️"
$0.001:  "⬆️⬆️"
$0.01:   "⬆️⬆️⬆️"
$0.1:    "⬆️⬆️⬆️⬆️"
$1:      "⬆️⬆️⬆️⬆️⬆️"
```

### On-Chain Evolution Mechanics

- All evolution names and price thresholds are stored on-chain
- Price oracle data comes directly from:
  - Bonding curve calculations during initial phase
  - Uniswap V3 TWAP oracles after graduation
- Evolution state changes are determined by pure on-chain logic
- Each evolution is permanently recorded in Conviction NFTs
- No off-chain oracle or manual intervention needed
- Full UTF-8 support for emoji evolution paths
- String sanitization ensures safe rendering in NFTs

This creates a fully autonomous, market-driven evolution system where token identity emerges organically from trading activity, with each price milestone adding more characters or emojis to reflect the token's growth.

## Name Evolution Mechanics

The protocol's defining feature is its dynamic name evolution system, which creates an on-chain narrative tied directly to price performance. As the token's price increases, its name evolves to reflect its growth.

### How Evolution Works

1. **Price Thresholds**: Each evolution level is defined by a price threshold
2. **On-Chain Oracle**: Price is determined by:
   - Bonding curve calculations during initial phase
   - Uniswap V3 TWAP oracles after market graduation
3. **Automatic Updates**: Name changes happen automatically when price thresholds are crossed
4. **Permanent Record**: Each evolution state is captured in Conviction NFTs

### Evolution Patterns

The protocol supports various evolution patterns, with names getting more emphatic as price increases:

#### Letter Repetition
```
$0.0001: "highr"        // Initial form
$0.001:  "highrrr"      // Growing confidence
$0.01:   "highrrrrrr"   // Building momentum
$0.1:    "highrrrrrrr"  // Strong conviction
$1:      "highrrrrrrrr" // Peak evolution
```

#### Emoji Progression
```
$0.0001: "🚀"           // Launch
$0.001:  "🚀🌙"         // Moon bound
$0.01:   "🚀🌙✨"       // Reaching stars
$0.1:    "🚀🌙✨💫"     // Cosmic expansion
$1:      "🚀🌙✨💫⭐"   // Universal dominance
```

### Technical Implementation

- Evolution states are stored entirely on-chain
- UTF-8 encoding supports both text and emoji evolution paths
- String sanitization ensures safe rendering in all contexts
- Gas-efficient name resolution through optimized storage
- Immutable price thresholds prevent manipulation

### Evolution Benefits

1. **Narrative Building**: Creates natural community excitement around price milestones
2. **Visual Feedback**: Token name visually represents market performance
3. **Meme Potential**: Each evolution stage can become its own meme
4. **Historical Record**: Conviction NFTs capture the token's evolutionary journey
5. **Community Engagement**: Holders unite around achieving next evolution

## Conviction NFTs: Proof of Early Evolution

Conviction NFTs are a core mechanic that rewards early believers and significant token purchases. These on-chain NFTs serve as historical proof of participation in a token's evolutionary journey.

### Conviction NFT Mechanics

1. **Automatic Minting**
   - Minted automatically for purchases > 0.1% of total supply
   - Captures exact evolution state at time of purchase
   - Records price, amount, and timestamp permanently
   - Fully on-chain SVG art that evolves with the token

2. **Historical Value**
   - Early evolution states become increasingly rare
   - Each NFT proves participation at specific price points
   - Captures the "conviction" of early believers
   - Creates collectible moments in token's history

### Example Conviction NFT Journey
```
Purchase 1: 0.2% supply at $0.0001 -> "highr" NFT (rare, earliest form)
Purchase 2: 0.15% supply at $0.001 -> "highrrr" NFT (evolution captured)
Purchase 3: 0.1% supply at $0.01 -> "highrrrrrr" NFT (milestone moment)
```

### NFT Metadata
Each Conviction NFT includes:
- Evolution name at time of purchase
- Exact purchase amount
- Price point achieved
- Timestamp of conviction
- Dynamic SVG art reflecting evolution
- Proof of early participation

### Incentive Structure

1. **Early Purchase Rewards**
   - Earlier purchases capture rarer evolution states
   - First believers get most primitive forms
   - Historical significance increases with price growth
   - Creates natural FOMO for early participation

2. **Size-Based Incentives**
   - Larger purchases (>0.1% supply) earn NFTs
   - Encourages meaningful participation
   - Rewards conviction with permanent proof
   - More skin in the game = more historical recognition

3. **Collection Value**
   - Complete evolution sets become possible
   - Early forms become increasingly scarce
   - Each price milestone creates new collectibles
   - Natural market for evolution completionists

4. **Community Status**
   - NFTs prove early believer status
   - Visible on-chain proof of conviction
   - Community recognition of early support
   - Historical record of price achievement

This NFT mechanism creates a powerful incentive loop:
1. Early buyers get rarest evolution forms
2. Large buyers get permanent proof of conviction
3. Each evolution becomes increasingly scarce
4. Historical value compounds with token success
5. Community forms around evolution collecting

The result is a natural pressure to participate early and meaningfully, with permanent on-chain recognition for those who showed the most conviction in the token's early stages.
