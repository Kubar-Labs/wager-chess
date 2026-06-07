// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ChessLogic.sol";

/**
 * @title WagerChessEngine
 * @notice Manages wager-based chess games: escrow, fixed fees per move, checkmate payouts.
 */
contract WagerChessEngine {
    using ChessLogic for ChessLogic.Game;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error InvalidWager();
    error NotAParticipant();
    error NotYourTurn();
    error GameNotActive();
    error GameAlreadyActive();
    error OpponentCannotBeSelf();
    error AlreadyJoined();
    error MoveFeeRequired();
    error GameNotOver();
    error NoPayoutAvailable();
    error TransferFailed();
    error InvalidPromotion();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event GameCreated(uint256 indexed gameId, address indexed white, address indexed black, uint256 wager);
    event MovePlayed(uint256 indexed gameId, address indexed player, uint8 from, uint8 to, uint8 promotion);
    event GameEnded(uint256 indexed gameId, address indexed winner, uint8 outcome); // 1=white win, 2=black win, 3=draw
    event FeeCollected(uint256 indexed gameId, uint256 amount);
    event PayoutClaimed(uint256 indexed gameId, address indexed recipient, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct WagerGame {
        ChessLogic.Game chess;
        address whitePlayer;
        address blackPlayer;
        uint256 wagerAmount;   // each player's wager
        uint256 totalPot;      // 2 * wagerAmount (escrowed)
        uint256 moveFee;       // fixed fee per move
        uint256 totalFeesCollected;
        bool active;
        bool payoutsSettled;
    }

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/
    uint256 public nextGameId;
    mapping(uint256 => WagerGame) public games;
    mapping(uint256 => mapping(address => uint256)) public pendingWithdrawals; // gameId => player => amount

    // Fixed fee schedule per move (in wei)
    uint256 public constant DEFAULT_MOVE_FEE = 0.0005 ether;

    /*//////////////////////////////////////////////////////////////
                           GAME LIFECYCLE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Create a new wager game. Creator is White.
     * @param opponent Address of the Black player.
     */
    function createGame(address opponent) external payable returns (uint256 gameId) {
        if (msg.value == 0) revert InvalidWager();
        if (opponent == msg.sender) revert OpponentCannotBeSelf();
        if (opponent == address(0)) revert OpponentCannotBeSelf();

        gameId = nextGameId++;
        WagerGame storage wg = games[gameId];
        wg.chess = ChessLogic.newGame();
        wg.whitePlayer = msg.sender;
        wg.blackPlayer = opponent;
        wg.wagerAmount = msg.value;
        wg.totalPot = msg.value;
        wg.moveFee = DEFAULT_MOVE_FEE;
        wg.active = true;

        emit GameCreated(gameId, msg.sender, opponent, msg.value);
    }

    /**
     * @notice Opponent (Black) joins the game by matching the wager.
     */
    function joinGame(uint256 gameId) external payable {
        WagerGame storage wg = games[gameId];
        if (!wg.active) revert GameNotActive();
        if (wg.blackPlayer != msg.sender) revert NotAParticipant();
        if (wg.totalPot != wg.wagerAmount) revert AlreadyJoined(); // Already matched
        if (msg.value != wg.wagerAmount) revert InvalidWager();

        wg.totalPot += msg.value;
    }

    /*//////////////////////////////////////////////////////////////
                              MOVE PLAY
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Play a move. Must pay the fixed moveFee.
     */

    function getMoveFee(uint256 gameId, uint8 from) public view returns (uint256) {
        WagerGame storage wg = games[gameId];
        uint8 p = wg.chess.board[from];
        uint8 pt = p > 8 ? p - 8 : p; // _pieceType equivalent
        
        // 1=Pawn, 2=Knight, 3=Bishop, 4=Rook, 5=Queen, 6=King
        if (pt == 5) return 0.0009 ether; // Queen ($9)
        if (pt == 4) return 0.0005 ether; // Rook
        if (pt == 3) return 0.0003 ether; // Bishop
        if (pt == 2) return 0.0003 ether; // Knight
        if (pt == 1) return 0.0001 ether; // Pawn ($1)
        if (pt == 6) return 0.0001 ether; // King ($1)
        
        return DEFAULT_MOVE_FEE;
    }

    function makeMove(
        uint256 gameId,
        uint8 from,
        uint8 to,
        uint8 promotion
    ) external payable {
        WagerGame storage wg = games[gameId];
        if (!wg.active) revert GameNotActive();

        uint256 requiredFee = getMoveFee(gameId, from);

        // Verify it's the sender's turn
        bool whiteTurn = wg.chess.whiteToMove;
        address expected = whiteTurn ? wg.whitePlayer : wg.blackPlayer;
        if (msg.sender != expected) revert NotYourTurn();

        // Check if the move gives a check
        // Note: ChessLogic doesn't easily expose this pre-move without executing,
        // so we'll execute the move, then check if the opponent is in check.
        ChessLogic.executeMove(wg.chess, from, to, promotion != 0 ? promotion : ChessLogic.NONE);
        
        // Is opponent now in check? Add $5 fee.
        if (ChessLogic.isInCheck(wg.chess, !whiteTurn)) {
            requiredFee += 0.0005 ether;
        }

        if (msg.value < requiredFee) revert MoveFeeRequired();

        // Collect fee
        wg.totalFeesCollected += requiredFee;
        uint256 refund = msg.value - requiredFee;
        if (refund > 0) {
            (bool ok, ) = msg.sender.call{value: refund}("");
            if (!ok) revert TransferFailed();
        }
        emit FeeCollected(gameId, requiredFee);
        emit MovePlayed(gameId, msg.sender, from, to, promotion);

        // Handle game end
        if (wg.chess.gameOver) {
            _finalizeGame(gameId, wg);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            FINALIZATION
    //////////////////////////////////////////////////////////////*/

    function _finalizeGame(uint256 gameId, WagerGame storage wg) internal {
        wg.active = false;
        uint8 outcome;
        if (ChessLogic.isCheckmate(wg.chess)) {
            // Determine winner from game state
            // Winner encoding in ChessLogic: address(1)=white, address(2)=black
            bool whiteWins = (wg.chess.winner == address(1));
            address winner = whiteWins ? wg.whitePlayer : wg.blackPlayer;
            uint256 payout = wg.totalPot - wg.totalFeesCollected;
            pendingWithdrawals[gameId][winner] = payout;
            outcome = whiteWins ? 1 : 2;
            emit GameEnded(gameId, winner, outcome);
        } else if (ChessLogic.isStalemate(wg.chess)) {
            // Draw: split pot minus fees equally
            uint256 remaining = wg.totalPot - wg.totalFeesCollected;
            uint256 each = remaining / 2;
            pendingWithdrawals[gameId][wg.whitePlayer] = each;
            pendingWithdrawals[gameId][wg.blackPlayer] = remaining - each; // safeguard odd wei
            outcome = 3;
            emit GameEnded(gameId, address(0), outcome);
        } else {
            // Should not reach here with gameOver=true unless checkmate/stalemate
            revert GameNotOver();
        }
        wg.payoutsSettled = true;
    }

    /*//////////////////////////////////////////////////////////////
                             WITHDRAWALS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Claim payout after game ends.
     */
    function claimPayout(uint256 gameId) external {
        uint256 amount = pendingWithdrawals[gameId][msg.sender];
        if (amount == 0) revert NoPayoutAvailable();
        pendingWithdrawals[gameId][msg.sender] = 0;

        (bool ok, ) = msg.sender.call{value: amount}("");
        if (!ok) revert TransferFailed();

        emit PayoutClaimed(gameId, msg.sender, amount);
    }

    /**
     * @notice If opponent never joins, White can withdraw their initial wager.
     */
    function withdrawUnmatchedWager(uint256 gameId) external {
        WagerGame storage wg = games[gameId];
        if (wg.whitePlayer != msg.sender) revert NotAParticipant();
        if (wg.totalPot != wg.wagerAmount) revert AlreadyJoined(); // opponent already joined
        if (!wg.active) revert GameNotActive();

        wg.active = false;
        uint256 amount = wg.wagerAmount;
        wg.totalPot = 0;
        wg.wagerAmount = 0;

        (bool ok, ) = msg.sender.call{value: amount}("");
        if (!ok) revert TransferFailed();

        emit GameEnded(gameId, address(0), 3);
    }

    /*//////////////////////////////////////////////////////////////
                               GETTERS
    //////////////////////////////////////////////////////////////*/

    function getBoard(uint256 gameId) external view returns (uint8[64] memory) {
        return games[gameId].chess.board;
    }

    function isWhiteToMove(uint256 gameId) external view returns (bool) {
        return games[gameId].chess.whiteToMove;
    }

    function isGameOver(uint256 gameId) external view returns (bool) {
        return games[gameId].chess.gameOver;
    }

    receive() external payable {}
    fallback() external payable {}
}
