import os

file_path = os.path.expanduser("~/hermes-workspace/wager-chess/frontend/app/components/ChessGame.tsx")
with open(file_path, "r") as f:
    content = f.read()

content = content.replace("position={game.fen()}", "options={{ position: game.fen() }}")

with open(file_path, "w") as f:
    f.write(content)
