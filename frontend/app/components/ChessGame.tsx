"use client";

import { useState, useCallback } from "react";
import { Chess } from "chess.js";
import { Chessboard } from "react-chessboard";

export function ChessGame() {
  const [game, setGame] = useState(new Chess());
  const [moveHistory, setMoveHistory] = useState<string[]>([]);

  const makeMove = useCallback(
    (sourceSquare: string, targetSquare: string) => {
      const gameCopy = new Chess(game.fen());
      const move = gameCopy.move({
        from: sourceSquare,
        to: targetSquare,
        promotion: "q", // Always promote to queen for simplicity
      });

      if (move === null) return false;

      setGame(gameCopy);
      setMoveHistory((prev) => [...prev, move.san]);
      return true;
    },
    [game]
  );

  const resetGame = () => {
    setGame(new Chess());
    setMoveHistory([]);
  };

  const undoMove = () => {
    const gameCopy = new Chess(game.fen());
    gameCopy.undo();
    setGame(gameCopy);
    setMoveHistory((prev) => prev.slice(0, -1));
  };

  const turn = game.turn() === "w" ? "White" : "Black";
  const isCheck = game.isCheck();
  const isCheckmate = game.isCheckmate();
  const isDraw = game.isDraw();

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between rounded-lg bg-surface p-4 border border-border">
        <div className="flex flex-col">
          <span className="text-sm font-medium text-zinc-400">Turn</span>
          <span className="text-lg font-semibold text-foreground">{turn}</span>
        </div>
        <div className="flex flex-col items-end">
          {isCheckmate && (
            <span className="text-sm font-bold text-red-400">Checkmate!</span>
          )}
          {isCheck && !isCheckmate && (
            <span className="text-sm font-bold text-yellow-400">Check!</span>
          )}
          {isDraw && (
            <span className="text-sm font-bold text-zinc-400">Draw</span>
          )}
        </div>
      </div>

      <div className="rounded-xl overflow-hidden border border-border shadow-lg">
        <Chessboard
          options={{
            position: game.fen(),
            onPieceDrop: ({ sourceSquare, targetSquare }) => {
              if (!targetSquare) return false;
              return makeMove(sourceSquare, targetSquare);
            },
            boardStyle: {
              borderRadius: "0px",
            },
            darkSquareStyle: { backgroundColor: "#475569" },
            lightSquareStyle: { backgroundColor: "#94a3b8" },
          }}
        />
      </div>

      <div className="flex items-center gap-2">
        <button
          onClick={undoMove}
          disabled={moveHistory.length === 0}
          className="flex-1 rounded-lg bg-surface-raised px-4 py-2.5 text-sm font-medium text-foreground transition-colors hover:bg-border disabled:opacity-30 border border-border"
        >
          Undo
        </button>
        <button
          onClick={resetGame}
          className="flex-1 rounded-lg bg-accent px-4 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-accent-hover"
        >
          New Game
        </button>
      </div>

      <div className="rounded-lg bg-surface p-4 border border-border">
        <h3 className="text-sm font-semibold text-zinc-400 mb-2">Move History</h3>
        <div className="flex flex-wrap gap-2 max-h-32 overflow-y-auto">
          {moveHistory.length === 0 ? (
            <span className="text-sm text-zinc-500">No moves yet</span>
          ) : (
            moveHistory.map((move, i) => (
              <span
                key={i}
                className="inline-flex items-center rounded bg-surface-raised px-2 py-0.5 text-xs font-mono text-zinc-300"
              >
                {Math.floor(i / 2) + 1}.{i % 2 === 0 ? "" : ".."} {move}
              </span>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
