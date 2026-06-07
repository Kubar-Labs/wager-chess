import os

file_path = os.path.expanduser("~/hermes-workspace/wager-chess/frontend/app/components/ChessGame.tsx")
with open(file_path, "r") as f:
    content = f.read()

# React-chessboard v3 uses positional props directly instead of options dict usually, but wait, the previous code had:
# options={{ position: game.fen(), onPieceDrop: ... }}

new_props = """options={{
            position: game.fen(),
            onPieceDrop: ({ sourceSquare, targetSquare }: any) => {
              makeMove(sourceSquare, targetSquare);
              return true;
            },
            boardStyle: { borderRadius: "0px" },
            darkSquareStyle: { backgroundColor: "#475569" },
            lightSquareStyle: { backgroundColor: "#94a3b8" }
          }}"""

# Remove the bad props block
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
    new_content = "\\n".join(lines[:start_idx+1]) + "\\n          " + new_props + "\\n        />\\n" + "\\n".join(lines[end_idx+1:])
    with open(file_path, "w") as f:
        f.write(new_content)
