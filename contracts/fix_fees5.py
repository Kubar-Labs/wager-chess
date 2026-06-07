import os
import re

file_path = os.path.expanduser("~/hermes-workspace/wager-chess/contracts/src/WagerChessEngine.sol")
with open(file_path, "r") as f:
    content = f.read()

# Fix the docs issue by stripping the @param tags from the function above it that was pushed down
content = re.sub(r'\s+\*\s+\@param from Source square \(0-63\)\.\n\s+\*\s+\@param to   Destination square \(0-63\)\.\n\s+\*\s+\@param promotion For pawn promotion: 2=N, 3=B, 4=R, 5=Q\. 0=none\.', '', content)

with open(file_path, "w") as f:
    f.write(content)
