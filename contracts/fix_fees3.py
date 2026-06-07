import os
import re

file_path = os.path.expanduser("~/hermes-workspace/wager-chess/contracts/src/WagerChessEngine.sol")
with open(file_path, "r") as f:
    content = f.read()

# Fix the Regex truncation that deleted half the contract
# Oh wait, the previous regex replaced `function makeMove...` all the way to `/*//// FINALIZATION`, truncating everything in between?
# Wait, I see lines 60-66. makeMove ends, then `/*//// FINALIZATION`. Wait, no, where did the rest of the contract go?
