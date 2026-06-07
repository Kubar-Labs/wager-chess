import os
import re

file_path = os.path.expanduser("~/hermes-workspace/wager-chess/contracts/src/WagerChessEngine.sol")
with open(file_path, "r") as f:
    content = f.read()

new_fee_logic = """
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
"""

make_move_replacement = """    function makeMove(
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
    }"""

# Inject getMoveFee before makeMove
content = content.replace("    function makeMove(", new_fee_logic + "\n    function makeMove(")

# Replace the body of makeMove
# We find everything from "function makeMove(" to "    /*//////////////////////////////////////////////////////////////\n                            FINALIZATION"
match = re.search(r'    function makeMove\(.*?    \}\n\n    \/\*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\n                            FINALIZATION', content, re.DOTALL)
if match:
    content = content[:match.start()] + make_move_replacement + "\n\n    /*//////////////////////////////////////////////////////////////\n                            FINALIZATION" + content[match.end():]

with open(file_path, "w") as f:
    f.write(content)
