import os
import re

file_path = os.path.expanduser("~/hermes-workspace/wager-chess/frontend/app/components/ChessGame.tsx")
with open(file_path, "r") as f:
    content = f.read()

# Make the frontend fetch the dynamic fee before submitting the transaction
# We'll replace the static `parseEther("0.0005")` with a dynamic read.

read_contract_import = "import { useAccount, useWriteContract, useReadContract, usePublicClient } from \"wagmi\";"
content = content.replace('import { useAccount, useWriteContract, useReadContract } from "wagmi";', read_contract_import)

dynamic_fee_logic = """
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
"""

# Replace the specific block of makeMove
content = re.sub(
    r'console\.log\("Submitting TX\.\.\."\);\s*const tx = await writeContractAsync\(\{\s*address: WAGER_CHESS_ENGINE_ADDRESS,\s*abi: WagerChessEngineABI,\s*functionName: "makeMove",\s*args: \[gameId, fromIdx, toIdx, promotion\],\s*value: parseEther\("0\.0005"\), \/\/ DEFAULT_MOVE_FEE\s*\}\);',
    dynamic_fee_logic,
    content,
    flags=re.DOTALL
)

# inject publicClient hook
content = content.replace("const { writeContractAsync } = useWriteContract();", "const { writeContractAsync } = useWriteContract();\n  const publicClient = usePublicClient();")

with open(file_path, "w") as f:
    f.write(content)
