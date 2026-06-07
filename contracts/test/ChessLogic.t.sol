// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ChessLogic.sol";

contract ChessLogicTest is Test {
    using ChessLogic for ChessLogic.Game;
    ChessLogic.Game g;

    function testExecuteMove() public {
        g = ChessLogic.newGame();
        
        ChessLogic.executeMove(g, 12, 28, 0);
        
        bool chk = ChessLogic.isInCheck(g, false);
        assertFalse(chk);
    }
}
