import os

file_path = os.path.expanduser("~/hermes-workspace/wager-chess/frontend/app/components/ChessGame.tsx")
with open(file_path, "r") as f:
    content = f.read()

# Replace the incorrect <Chessboard> usage with standard props
correct_chessboard = """<Chessboard
          position={game.fen()}
          onPieceDrop={(sourceSquare, targetSquare) => {
            makeMove(sourceSquare, targetSquare);
            return true;
          }}
          customBoardStyle={{ borderRadius: "0px" }}
          customDarkSquareStyle={{ backgroundColor: "#475569" }}
          customLightSquareStyle={{ backgroundColor: "#94a3b8" }}
        />"""

lines = content.split('\n')
start_idx = -1
end_idx = -1
for i, line in enumerate(lines):
    if '<Chessboard' in line:
        start_idx = i
    if '/>' in line and start_idx != -1:
        end_idx = i
        break

if start_idx != -1 and end_idx != -1:
    new_content = "\n".join(lines[:start_idx]) + "\n        " + correct_chessboard + "\n" + "\n".join(lines[end_idx+1:])
    with open(file_path, "w") as f:
        f.write(new_content)
