# High-Level Diagram (HLD): Wager Chess

## 1. Architecture Overview
The system relies on a hybrid architecture to balance the strict rules of chess with decentralized financial settlement.

### 1.1 Components
1. **Frontend Client (Next.js + React-Chessboard)**
   - Manages UI, wallet connection, and local game state preview.
   - Implements Session Keys (e.g., via Biconomy or custom EIP-4337) to auto-sign move transactions without UI interruption.

2. **Game Server (Optional/Hybrid) vs. Fully On-Chain**
   - *Approach A (Fully On-Chain):* Monad is fast enough. Every move is an RPC call to the smart contract. The contract validates the move using an on-chain chess engine (e.g., Solidity-Chess).
   - *Approach B (State Channels):* Players sign moves off-chain. The smart contract acts only as the escrow and dispute resolution layer. 
   - *Decision:* Given Monad's 10,000 TPS, **Approach A (Fully On-Chain)** is selected to stress-test Monad and simplify the security model.

3. **Smart Contracts (Solidity - Foundry)**
   - `WagerChessEscrow.sol`: Manages player deposits, tracks the pot, and handles payouts.
   - `ChessLogic.sol`: Validates standard chess moves, tracks board state (FEN/bitboards), and detects check/checkmate.

## 2. Data Flow
[Player A] -> (Makes Move on UI) -> [Session Key Wallet] -> (Tx Broadcast to Monad RPC)
-> [Monad Testnet] -> (ChessLogic.sol validates) -> (WagerChessEscrow.sol deducts fee) 
-> (State Updated, Event Emitted) -> [Frontend Client B] -> (Updates UI)
