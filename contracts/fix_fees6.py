import os
import re

file_path = os.path.expanduser("~/hermes-workspace/wager-chess/contracts/src/WagerChessEngine.sol")
with open(file_path, "r") as f:
    content = f.read()

# Fix the underflow by moving the require check above the subtraction
fixed_logic = """
        if (msg.value < requiredFee) revert MoveFeeRequired();

        // Collect fee
        wg.totalFeesCollected += requiredFee;
        uint256 refund = msg.value - requiredFee;
"""

content = content.replace("""        if (msg.value < requiredFee) revert MoveFeeRequired();

        // Collect fee
        wg.totalFeesCollected += requiredFee;
        uint256 refund = msg.value - requiredFee;""", fixed_logic)

# In case my simple replace failed:
content = re.sub(
    r'wg\.totalFeesCollected \+= requiredFee;\s*uint256 refund = msg\.value - requiredFee;',
    'if (msg.value < requiredFee) revert MoveFeeRequired();\n\n        wg.totalFeesCollected += requiredFee;\n        uint256 refund = msg.value - requiredFee;',
    content
)

# And remove the duplicate `if (msg.value < requiredFee) revert MoveFeeRequired();` that was above it
content = re.sub(r'if \(msg\.value < requiredFee\) revert MoveFeeRequired\(\);\s*if \(msg\.value < requiredFee\) revert MoveFeeRequired\(\);', 'if (msg.value < requiredFee) revert MoveFeeRequired();', content)

with open(file_path, "w") as f:
    f.write(content)
