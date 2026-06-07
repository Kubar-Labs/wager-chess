# Low-Level Diagram (LLD): Wager Chess

## 1. Smart Contract Specifications

### 1.1 `ChessLogic.sol`
- **Data Structures:** 
  - `uint256 boardState`: Compact bitboard representation.
  - `enum PieceType { Pawn, Knight, Bishop, Rook, Queen, King }`
- **Functions:**
  - `executeMove(uint16 move)`: Validates pseudo-legal moves, ensures king safety, updates board.
  - `isCheckmate()`: Evaluates terminal states.

### 1.2 `WagerChessEngine.sol` (Main Entry)
- **State Variables:**
  - `mapping(uint256 => Game) public games;`
  - `mapping(PieceType => uint256) public moveCosts;`
- **Modifiers:**
  - `onlyCurrentTurn(uint256 gameId)`
  - `hasSufficientAllowance(address player, uint256 cost)`
- **Functions:**
  - `createGame(address opponent)`
  - `joinGame(uint256 gameId)`
  - `playMove(uint256 gameId, uint16 move, PieceType piece)`
    - *Logic:* Calls `ChessLogic.executeMove`. If valid, calculates cost based on `piece` and whether the move results in a check. Transfers tokens from player to contract. Updates `pot`. Emits `MovePlayed` event.
  - `claimVictory(uint256 gameId)`
    - *Logic:* If `ChessLogic.isCheckmate()` is true, transfers `pot` to the winner.

## 2. Frontend Implementation

### 2.1 Tech Stack
- **Framework:** Next.js (App Router), React, TypeScript.
- **Web3:** `viem`, `wagmi` for contract interactions.
- **Chess:** `chess.js` (for local validation & move generation), `react-chessboard` (UI).
- **Styling:** Tailwind CSS.

### 2.2 Session Keys Implementation
- To prevent MetaMask popup fatigue, users will sign a single approval transaction granting a temporary "Game Session Key" the right to spend up to X tokens and call `playMove` on their behalf for the next hour.
- The Session Key is stored securely in the browser's local storage or indexedDB.

## 3. Monad Testnet Configuration
- **RPC URL:** `https://testnet-rpc.monad.xyz/` (Standard Monad testnet RPC)
- **Chain ID:** `10143` (Monad Testnet)
- **Currency:** `MON`
