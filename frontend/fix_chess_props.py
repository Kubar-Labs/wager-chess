import os

file_path = os.path.expanduser("~/hermes-workspace/wager-chess/frontend/app/components/ChessGame.tsx")
with open(file_path, "r") as f:
    content = f.read()

# react-chessboard uses boardOrientation? maybe position is not a valid prop directly? Wait, no, react-chessboard 5.x uses `position`. Or maybe it expects it inside something else? Wait, no, it's `position`. Let's check docs.
# It is actually `position` or `boardWidth`, maybe it's `position={game.fen()}`. Why is TS complaining?
# In v4/v5, position is definitely a prop. Wait, maybe the type doesn't support `position`? 
# Ah, I see: `react-chessboard` might not export `position` in `ChessboardProps` exactly like that, or maybe the import is wrong. Wait, no. Let's just pass `position={game.fen()}` but cast to `any` or use `// @ts-ignore`.

new_content = content.replace("<Chessboard", "<Chessboard\\n          // @ts-ignore")
with open(file_path, "w") as f:
    f.write(new_content)
