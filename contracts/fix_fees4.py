import os

file_path = os.path.expanduser("~/hermes-workspace/wager-chess/contracts/src/WagerChessEngine.sol")
with open(file_path, "r") as f:
    content = f.read()

content = content.replace("/**\n    \n    function getMoveFee", "/*//////////////////////////////////////////////////////////////\n                              MOVE PLAY\n    //////////////////////////////////////////////////////////////*/\n\n    function getMoveFee")

with open(file_path, "w") as f:
    f.write(content)
