import os

file_path = os.path.expanduser("~/hermes-workspace/wager-chess/contracts/src/WagerChessEngine.sol")
with open(file_path, "r") as f:
    content = f.read()

# Replace ChessLogic.inCheck with ChessLogic.isInCheck
content = content.replace("ChessLogic.inCheck(wg.chess, !whiteTurn)", "ChessLogic.isInCheck(wg.chess, !whiteTurn)")

# Fix the docs block above getMoveFee which causes the Doxygen error
import re
content = re.sub(
    r'\/\*\*.*?\@param to.*?\@param promotion.*?\*\/',
    '/**',
    content,
    flags=re.DOTALL
)

with open(file_path, "w") as f:
    f.write(content)
