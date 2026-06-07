import os

file_path = os.path.expanduser("~/hermes-workspace/wager-chess/contracts/src/ChessLogic.sol")
with open(file_path, "r") as f:
    content = f.read()

content = content.replace("uint8 mid = from + uint8(int8(8) * dir);", "uint8 mid = white ? from + 8 : from - 8;")
content = content.replace("toR == uint8(int8(fromR) + 2 * dir)", "toR == (white ? fromR + 2 : fromR - 2)")
content = content.replace("toR == uint8(int8(fromR) + dir)", "toR == (white ? fromR + 1 : fromR - 1)")
content = content.replace("_rank(targetSq) == uint8(int8(r) + dir)", "_rank(targetSq) == (byWhite ? r + 1 : r - 1)")

with open(file_path, "w") as f:
    f.write(content)
