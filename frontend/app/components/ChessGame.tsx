"use client";

import { useState, useCallback } from "react";
import { Chess } from "chess.js";
import { Chessboard } from "react-chessboard";
import { useAccount, useWriteContract, useReadContract, usePublicClient } from "wagmi";
import { parseEther } from "viem";
import WagerChessEngineABI from "../../abi/WagerChessEngine.json";

export const WAGER_CHESS_ENGINE_ADDRESS = "0xF2c1e9a198A11eAD70bF7C9d054cFc3AD460AEF2";

// Convert algebraic e2 to index 0-63
function squareToIndex(sq: string): number {
  const file = sq.charCodeAt(0) - 'a'.charCodeAt(0);
  const rank = parseInt(sq[1]) - 1;
  return rank * 8 + file;
}

export function ChessGame() {
  const { address, isConnected } = useAccount();
  const [game, setGame] = useState(new Chess());
  const [moveHistory, setMoveHistory] = useState<string[]>([]);
  const [gameId, setGameId] = useState<bigint | null>(null);
  const [inputGameId, setInputGameId] = useState("");

  const { writeContractAsync } = useWriteContract();
  const publicClient = usePublicClient();

  const { data: contractGameState } = useReadContract({
    address: WAGER_CHESS_ENGINE_ADDRESS,
    abi: WagerChessEngineABI,
    functionName: "games",
    args: gameId !== null ? [gameId] : undefined,
    query: {
      enabled: gameId !== null,
      refetchInterval: 2000,
    }
  });

  const makeMove = useCallback(
    async (sourceSquare: string, targetSquare: string) => {
      if (!gameId && gameId !== BigInt(0)) {
        alert("Please set an Active Game ID first!");
        return false;
      }

      const gameCopy = new Chess(game.fen());
      try {
        const move = gameCopy.move({
          from: sourceSquare,
          to: targetSquare,
          promotion: "q",
        });

        if (move === null) return false;

        const fromIdx = squareToIndex(sourceSquare);
        const toIdx = squareToIndex(targetSquare);
        const promotion = move.promotion ? 5 : 0; // 5=Queen

        
        console.log("Fetching dynamic fee...");
        const fee = await publicClient?.readContract({
          address: WAGER_CHESS_ENGINE_ADDRESS,
          abi: WagerChessEngineABI,
          functionName: "getMoveFee",
          args: [gameId, fromIdx],
        }) as bigint;

        // If it's going to be a check, we need to manually add 0.0005 to the fee requirement on the frontend 
        // to pass the msg.value check, because getMoveFee only calculates the piece base cost, not the post-move check penalty.
        let finalValue = fee;
        const testCheck = new Chess(game.fen());
        testCheck.move({ from: sourceSquare, to: targetSquare, promotion: "q" });
        if (testCheck.isCheck()) {
            finalValue = finalValue + parseEther("0.0005");
        }

        console.log("Submitting TX with value:", finalValue.toString());
        const tx = await writeContractAsync({
          address: WAGER_CHESS_ENGINE_ADDRESS,
          abi: WagerChessEngineABI,
          functionName: "makeMove",
          args: [gameId, fromIdx, toIdx, promotion],
          value: finalValue, 
        });


        console.log("Move TX submitted:", tx);
        
        setGame(gameCopy);
        setMoveHistory((prev) => [...prev, move.san]);
        return true;
      } catch (err) {
        console.error("Move failed:", err);
        return false;
      }
    },
    [game, gameId, writeContractAsync]
  );

  const handleCreateGame = async () => {
    if (!isConnected) return alert("Connect wallet first");
    const opponent = prompt("Enter opponent address (or leave blank to play against a burner):", "0x0000000000000000000000000000000000000001");
    if (!opponent) return;

    try {
      const tx = await writeContractAsync({
        address: WAGER_CHESS_ENGINE_ADDRESS,
        abi: WagerChessEngineABI,
        functionName: "createGame",
        args: [opponent],
        value: parseEther("0.01"), 
      });
      console.log("Create Game TX:", tx);
      alert("Game created! TX: " + tx);
    } catch (e) {
      console.error(e);
    }
  };

  const handleJoinGame = async () => {
    if (!isConnected) return alert("Connect wallet first");
    if (!inputGameId) return alert("Enter a game ID");
    
    try {
      const tx = await writeContractAsync({
        address: WAGER_CHESS_ENGINE_ADDRESS,
        abi: WagerChessEngineABI,
        functionName: "joinGame",
        args: [BigInt(inputGameId)],
        value: parseEther("0.01"),
      });
      console.log("Join Game TX:", tx);
      setGameId(BigInt(inputGameId));
      alert("Joined game " + inputGameId);
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-col gap-4 p-4 bg-surface rounded-lg border border-border">
        <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold">Wager Chess Controls</h2>
            <span className="text-xs text-zinc-400">Wallet: {isConnected ? address : "Not connected"}</span>
        </div>
        <div className="flex flex-col gap-2">
            <button onClick={handleCreateGame} className="px-4 py-2 bg-accent text-white rounded transition-colors hover:bg-accent-hover">
                Create New Game (Wager 0.01 MON)
            </button>
        </div>
        <div className="flex gap-2 items-center">
          <input 
            type="number" 
            placeholder="Game ID" 
            value={inputGameId} 
            onChange={(e) => setInputGameId(e.target.value)}
            className="flex-1 px-3 py-2 bg-black border border-border rounded text-white text-sm"
          />
          <button onClick={handleJoinGame} className="px-4 py-2 bg-surface-raised text-white rounded border border-border hover:bg-border transition-colors text-sm">
            Join Game
          </button>
          <button onClick={() => {if(inputGameId) setGameId(BigInt(inputGameId))}} className="px-4 py-2 bg-blue-600 text-white rounded text-sm hover:bg-blue-700 transition-colors">
            Set Active ID
          </button>
        </div>
        {gameId !== null && <p className="text-green-400 text-sm font-medium">✅ Active Game ID: {gameId.toString()}</p>}
      </div>

      <div className="rounded-xl overflow-hidden border border-border shadow-lg">
        <Chessboard
          // @ts-ignore
          position={game.fen()}
          onPieceDrop={(sourceSquare: string, targetSquare: string) => {
            makeMove(sourceSquare, targetSquare);
            return true;
          }}
          customBoardStyle={{ borderRadius: "0px" }}
          customDarkSquareStyle={{ backgroundColor: "#475569" }}
          customLightSquareStyle={{ backgroundColor: "#94a3b8" }}
        />
      </div>

      <div className="rounded-lg bg-surface p-4 border border-border">
        <h3 className="text-sm font-semibold text-zinc-400 mb-2">Move History</h3>
        <div className="flex flex-wrap gap-2 max-h-32 overflow-y-auto">
          {moveHistory.length === 0 ? (
            <span className="text-sm text-zinc-500">No moves yet</span>
          ) : (
            moveHistory.map((move, i) => (
              <span key={i} className="inline-flex items-center rounded bg-surface-raised px-2 py-0.5 text-xs font-mono text-zinc-300">
                {Math.floor(i / 2) + 1}.{i % 2 === 0 ? "" : ".."} {move}
              </span>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
