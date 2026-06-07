# Product Requirements Document (PRD): Wager Chess

## 1. Product Overview
Wager Chess is a Web3 game where every chess move requires an on-chain transaction with an associated token cost. The game runs on the Monad testnet, ensuring low latency and high throughput. 

## 2. Core Features
### 2.1 Game Logic & State Management
- Standard chess rules enforced strictly.
- State can be managed off-chain (via state channels or specialized backend) with on-chain settlement, OR fully on-chain if Monad's throughput permits (preferred for pure Web3 ethos).

### 2.2 Financial Mechanics (The Wager)
- ERC20 token integration (using Monad testnet native token or a custom ERC20).
- Fixed fee schedule for moves:
  - Pawn: 1 unit
  - Knight/Bishop: 3 units
  - Rook: 5 units
  - Queen: 9 units
  - King: 1 unit
  - Delivering a Check: +5 units (bonus fee)
- Escrow Contract: Holds the accumulated pot.
- Payout Mechanism: Automatic transfer of the pot to the winner's wallet upon verified checkmate or resignation.

### 2.3 User Interface
- Web3 wallet integration (MetaMask/Rabby via WalletConnect).
- Interactive Chess Board UI.
- Live Financial Dashboard:
  - Current Pot Size.
  - Personal Spend vs. Opponent Spend.
  - Transaction status indicator.

## 3. User Flow
1. **Lobby:** Player connects wallet, deposits an initial allowance into the game escrow contract, and matches with an opponent.
2. **Gameplay:** Player makes a move -> Wallet prompts for signature/approval (or utilizes a session key for auto-signing) -> Move cost is deducted -> Pot increases.
3. **Resolution:** Game concludes -> Escrow contract releases funds to the winner -> Players return to lobby.

## 4. Technical Constraints
- Must deploy on Monad Testnet.
- Move latency must not exceed 2-3 seconds to maintain game flow (necessitates Session Keys or Account Abstraction to avoid MetaMask popups per move).
