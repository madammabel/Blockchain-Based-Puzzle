# CryptoQuest - Decentralized Puzzle Platform

A comprehensive blockchain-based puzzle ecosystem built on the Stacks blockchain where creators can publish encrypted challenges and solvers compete for STX rewards through cryptographic proof-of-solution mechanisms.

## Overview

CryptoQuest is a decentralized platform that gamifies problem-solving by allowing users to:
- Create cryptographic puzzles with STX rewards
- Solve challenges to earn cryptocurrency
- Build reputation through participation
- Compete in a fair, transparent environment

## Key Features

###  Challenge Creation
- **Encrypted Solutions**: Challenges use SHA-256 hashed solutions for security
- **Flexible Difficulty**: 5-tier difficulty rating system (1-5)
- **Time-Bound Challenges**: Configurable expiration periods
- **Rich Metadata**: Category tags, estimated solve times, and descriptions
- **Reward Escrow**: Automatic STX reward holding in smart contract

###  Competitive Solving
- **Cryptographic Verification**: Solutions verified through hash matching
- **Anti-Cheating**: Creators cannot solve their own challenges
- **Attempt Tracking**: Complete history of solution attempts
- **Instant Rewards**: Automatic STX distribution upon successful solve

###  Analytics & Reputation
- **Comprehensive Stats**: Track challenges created, solved, and rewards earned
- **Reputation System**: Build credibility through platform participation
- **Historical Data**: Complete attempt history and performance metrics
- **Leaderboard Ready**: Stats designed for competitive rankings

###  Economic Model
- **Fair Fee Structure**: 5% default platform commission (max 20%)
- **Minimum Rewards**: 1 STX minimum challenge reward
- **Bonus System**: Additional creator rewards and bonuses
- **Reclaim Protection**: Creators can reclaim rewards from expired challenges

## Technical Specifications

### Smart Contract Details
- **Language**: Clarity (Stacks Blockchain)
- **Network**: Stacks Mainnet/Testnet Compatible
- **Storage**: On-chain data structures for transparency
- **Security**: Comprehensive validation and error handling

### Data Structures

#### Challenge Structure
```clarity
{
  challenge-creator: principal,
  quest-title: (string-ascii 64),
  detailed-description: (string-ascii 256),
  encrypted-solution-hash: (buff 32),
  stx-reward-pool: uint,
  complexity-rating: uint,
  creation-block-height: uint,
  expiration-block-height: uint,
  completion-status: bool,
  successful-solver: (optional principal),
  completion-block-height: (optional uint)
}
```

#### User Analytics
```clarity
{
  total-challenges-created: uint,
  total-challenges-solved: uint,
  cumulative-rewards-earned: uint,
  cumulative-rewards-distributed: uint,
  reputation-score: uint
}
```

## Usage Guide

### Creating a Challenge

1. **Prepare Your Puzzle**: Design your challenge and create a solution
2. **Generate Hash**: Hash your solution using SHA-256
3. **Fund Challenge**: Ensure sufficient STX balance for rewards
4. **Call Contract**: Use `publish-cryptoquest` function

```clarity
(publish-cryptoquest 
  "My Crypto Puzzle"           ;; title
  "Solve this cryptographic riddle..." ;; description
  0x1234...                    ;; solution hash
  u3                           ;; difficulty (1-5)
  u1000                        ;; duration in blocks
  (list "crypto" "puzzle")     ;; category tags
  u60                          ;; estimated solve time (minutes)
)
```

### Solving a Challenge

1. **Browse Challenges**: Query available challenges
2. **Analyze Puzzle**: Study the challenge description
3. **Submit Solution**: Use `attempt-solution` function

```clarity
(attempt-solution 
  u1                           ;; challenge ID
  "your-solution-attempt"      ;; your solution
)
```

### Reclaiming Expired Rewards

If your challenge expires without being solved:

```clarity
(reclaim-expired-cryptoquest u1) ;; challenge ID
```

## API Reference

### Read-Only Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `get-challenge-details` | Retrieve challenge information | `challenge-id: uint` |
| `get-current-challenge-count` | Get total number of challenges | None |
| `get-participant-profile` | Get user statistics | `user-address: principal` |
| `get-solver-statistics` | Get solve attempts for challenge | `challenge-id: uint, solver: principal` |
| `check-if-challenge-expired` | Check if challenge has expired | `challenge-id: uint` |
| `calculate-platform-fee-amount` | Calculate platform commission | `reward-total: uint` |

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `publish-cryptoquest` | Create new challenge | See creation example above |
| `attempt-solution` | Submit solution attempt | `challenge-id: uint, solution: string` |
| `reclaim-expired-cryptoquest` | Reclaim expired challenge rewards | `challenge-id: uint` |
| `provide-creator-bonus` | Send bonus to challenge creator | `challenge-id: uint, amount: uint` |

### Administrative Functions

| Function | Description | Access |
|----------|-------------|---------|
| `adjust-minimum-reward-threshold` | Set minimum reward amount | Admin only |
| `modify-platform-commission-rate` | Adjust platform fee | Admin only |
| `emergency-contract-withdrawal` | Emergency fund withdrawal | Admin only |

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | `ERR-UNAUTHORIZED-ACCESS` | Insufficient permissions |
| u101 | `ERR-CHALLENGE-NOT-FOUND` | Invalid challenge ID |
| u102 | `ERR-ALREADY-COMPLETED` | Challenge already solved |
| u103 | `ERR-INVALID-SOLUTION-PROVIDED` | Incorrect solution |
| u104 | `ERR-INSUFFICIENT-REWARD-AMOUNT` | Reward below minimum |
| u105 | `ERR-CHALLENGE-TIME-EXPIRED` | Challenge deadline passed |
| u106 | `ERR-INVALID-DIFFICULTY-LEVEL` | Difficulty not in range 1-5 |
| u107 | `ERR-CREATOR-CANNOT-SOLVE-OWN` | Self-solving prevented |

## Security Features

### Input Validation
- **Length Limits**: Title (64 chars), Description (256 chars), Solution (256 chars)
- **Hash Verification**: 32-byte SHA-256 hash validation
- **Amount Validation**: STX amount bounds checking
- **Time Validation**: Block height and duration limits

### Access Control
- **Creator Rights**: Only creators can reclaim expired challenges
- **Admin Functions**: Restricted administrative capabilities
- **Self-Solving Prevention**: Creators cannot solve their own puzzles

### Economic Security
- **Escrow System**: Rewards held in contract until completion
- **Fee Caps**: Maximum 20% platform commission
- **Minimum Stakes**: 1 STX minimum reward requirement

## Platform Economics

### Fee Structure
- **Default Commission**: 5% of challenge rewards
- **Maximum Commission**: 20% (admin adjustable)
- **Minimum Reward**: 1 STX (1,000,000 µSTX)
- **Maximum Bonus**: 100 STX per transaction

### Reward Distribution
1. **Solver**: Receives 95% of reward pool (default)
2. **Platform**: Receives 5% commission (default)
3. **Creator**: Can provide additional bonuses

## Development & Integration

### Prerequisites
- Stacks blockchain knowledge
- Clarity smart contract understanding
- STX wallet integration capability

### Contract Deployment
1. Deploy contract to Stacks testnet/mainnet
2. Initialize with admin address
3. Configure minimum rewards and commission rates
4. Begin accepting challenges

### Frontend Integration
The contract is designed for easy frontend integration with:
- Batch query functions for efficient data retrieval
- Comprehensive analytics for user dashboards
- Event-driven architecture for real-time updates

## Roadmap

### Phase 1 (Current)
-  Core puzzle creation and solving
-  Basic reputation system
-  STX reward distribution

### Phase 2 (Planned)
-  Advanced hint systems
-  Team-based challenges
-  Tournament mechanics

### Phase 3 (Future)
-  Cross-chain integration
-  NFT reward systems
-  Governance token

## Community & Support

### Getting Started
1. Acquire STX tokens
2. Connect Stacks-compatible wallet
3. Browse existing challenges
4. Create your first puzzle

### Best Practices
- **Clear Descriptions**: Write detailed, unambiguous challenge descriptions
- **Fair Difficulty**: Match difficulty rating to actual complexity
- **Reasonable Timeframes**: Set appropriate expiration periods
- **Test Solutions**: Verify your solution hash before publishing