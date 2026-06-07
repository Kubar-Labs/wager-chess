// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/WagerChessEngine.sol";

contract WagerChessEngineTest is Test {
    WagerChessEngine engine;
    address alice = address(0xA);
    address bob = address(0xB);

    function setUp() public {
        engine = new WagerChessEngine();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function testCreateAndJoinGame() public {
        vm.startPrank(alice);
        uint256 gameId = engine.createGame{value: 0.01 ether}(bob);
        vm.stopPrank();

        ( , address w, address b, uint256 wager, uint256 pot, , , bool active, ) = engine.games(gameId);
        assertEq(w, alice);
        assertEq(b, bob);
        assertEq(wager, 0.01 ether);
        assertEq(pot, 0.01 ether);
        assertTrue(active);

        vm.startPrank(bob);
        engine.joinGame{value: 0.01 ether}(gameId);
        vm.stopPrank();

        ( , , , , pot, , , , ) = engine.games(gameId);
        assertEq(pot, 0.02 ether);
    }

    function testPawnMoveFee() public {
        vm.startPrank(alice);
        uint256 gameId = engine.createGame{value: 0.01 ether}(bob);
        vm.stopPrank();

        vm.startPrank(bob);
        engine.joinGame{value: 0.01 ether}(gameId);
        vm.stopPrank();

        // e2 to e4 -> from = 12, to = 28
        // Wait, index calculation: e2 is file 'e' (4), rank '2' (1). index = 1 * 8 + 4 = 12.
        uint8 e2 = 12;
        uint8 e4 = 28;

        vm.startPrank(alice);
        // Pawn fee is 0.0001 ether
        engine.makeMove{value: 0.0001 ether}(gameId, e2, e4, 0);
        vm.stopPrank();

        // Check if whiteToMove is now false
        assertFalse(engine.isWhiteToMove(gameId));
    }
}
