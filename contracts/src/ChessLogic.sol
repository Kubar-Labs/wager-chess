// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChessLogic
 * @notice Pure chess move validation, check detection, and checkmate detection.
 * @dev Board is uint8[64] (a1=0, h8=63). Piece encoding: 0=empty,
 *      1=WP, 2=WN, 3=WB, 4=WR, 5=WQ, 6=WK, 9=BP, 10=BN, 11=BB, 12=BR, 13=BQ, 14=BK.
 */
library ChessLogic {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error InvalidMove();
    error GameNotActive();
    error InvalidSquare();
    error NotYourTurn();

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct Game {
        uint8[64] board;
        bool whiteToMove;
        uint8 whiteKingPos;
        uint8 blackKingPos;
        bool whiteCanCastleKingside;
        bool whiteCanCastleQueenside;
        bool blackCanCastleKingside;
        bool blackCanCastleQueenside;
        uint8 enPassantTarget; // 64 = none
        uint8 halfmoveClock;
        uint16 fullmoveNumber;
        bool gameOver;
        address winner; // address(0) = draw / ongoing
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint8 constant EMPTY = 0;
    // White pieces
    uint8 constant WP = 1;
    uint8 constant WN = 2;
    uint8 constant WB = 3;
    uint8 constant WR = 4;
    uint8 constant WQ = 5;
    uint8 constant WK = 6;
    // Black pieces = white + 8
    uint8 constant BP = 9;
    uint8 constant BN = 10;
    uint8 constant BB = 11;
    uint8 constant BR = 12;
    uint8 constant BQ = 13;
    uint8 constant BK = 14;

    uint8 constant NO_EN_PASSANT = 64;
    uint8 constant NONE = 0;

    /*//////////////////////////////////////////////////////////////
                           INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    function newGame() internal pure returns (Game memory g) {
        g.board = _startingBoard();
        g.whiteToMove = true;
        g.whiteKingPos = 4;  // e1
        g.blackKingPos = 60; // e8
        g.whiteCanCastleKingside = true;
        g.whiteCanCastleQueenside = true;
        g.blackCanCastleKingside = true;
        g.blackCanCastleQueenside = true;
        g.enPassantTarget = NO_EN_PASSANT;
        g.halfmoveClock = 0;
        g.fullmoveNumber = 1;
    }

    function _startingBoard() private pure returns (uint8[64] memory b) {
        // Rank 8 (indices 56-63)
        b[56] = BR; b[57] = BN; b[58] = BB; b[59] = BQ; b[60] = BK; b[61] = BB; b[62] = BN; b[63] = BR;
        // Rank 7 (indices 48-55)
        for (uint8 i = 48; i < 56; i++) b[i] = BP;
        // Rank 2 (indices 8-15)
        for (uint8 i = 8; i < 16; i++) b[i] = WP;
        // Rank 1 (indices 0-7)
        b[0] = WR; b[1] = WN; b[2] = WB; b[3] = WQ; b[4] = WK; b[5] = WB; b[6] = WN; b[7] = WR;
    }

    /*//////////////////////////////////////////////////////////////
                           PIECE HELPERS
    //////////////////////////////////////////////////////////////*/

    function _pieceColor(uint8 p) internal pure returns (bool white) {
        return p != EMPTY && p < 8;
    }

    function _pieceType(uint8 p) internal pure returns (uint8) {
        return p > 8 ? p - 8 : p;
    }

    function _isWhite(uint8 p) internal pure returns (bool) {
        return p != EMPTY && p < 8;
    }

    function _file(uint8 sq) internal pure returns (uint8) {
        return sq % 8;
    }

    function _rank(uint8 sq) internal pure returns (uint8) {
        return sq / 8;
    }

    function _isValidSquare(uint8 sq) internal pure returns (bool) {
        return sq < 64;
    }

    /*//////////////////////////////////////////////////////////////
                          ATTACK / CHECK
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns true if `targetSq` is attacked by any piece of color `byWhite`.
     */
    function _isSquareAttacked(
        uint8[64] memory board,
        uint8 targetSq,
        bool byWhite
    ) internal pure returns (bool) {
        for (uint8 sq = 0; sq < 64; sq++) {
            uint8 p = board[sq];
            if (p == EMPTY) continue;
            if (_isWhite(p) != byWhite) continue;
            uint8 pt = _pieceType(p);
            if (pt == 1) {
                // Pawn
                int8 dir = byWhite ? int8(1) : int8(-1);
                uint8 r = _rank(sq);
                uint8 f = _file(sq);
                if (_rank(targetSq) == uint8(int8(r) + dir)) {
                    if (
                        _file(targetSq) == f + 1 ||
                        (f > 0 && _file(targetSq) == f - 1)
                    ) {
                        return true;
                    }
                }
            } else if (pt == 2) {
                // Knight
                if (_isKnightMove(sq, targetSq)) return true;
            } else if (pt == 3) {
                // Bishop
                if (_isBishopMove(board, sq, targetSq)) return true;
            } else if (pt == 4) {
                // Rook
                if (_isRookMove(board, sq, targetSq)) return true;
            } else if (pt == 5) {
                // Queen
                if (
                    _isBishopMove(board, sq, targetSq) ||
                    _isRookMove(board, sq, targetSq)
                ) return true;
            } else if (pt == 6) {
                // King attacks adjacent squares
                uint8 kdf = _absDiff(_file(sq), _file(targetSq));
                uint8 kdr = _absDiff(_rank(sq), _rank(targetSq));
                if (kdf <= 1 && kdr <= 1) return true;
            }
        }
        return false;
    }

    function isInCheck(Game memory g, bool whiteKing) internal pure returns (bool) {
        uint8 kingSq = whiteKing ? g.whiteKingPos : g.blackKingPos;
        return _isSquareAttacked(g.board, kingSq, !whiteKing);
    }

    /*//////////////////////////////////////////////////////////////
                        MOVE VALIDATION
    //////////////////////////////////////////////////////////////*/

    function isValidMove(
        Game memory g,
        uint8 from,
        uint8 to,
        uint8 promotion
    ) internal pure returns (bool) {
        if (!_isValidSquare(from) || !_isValidSquare(to)) return false;
        uint8 piece = g.board[from];
        if (piece == EMPTY) return false;
        bool movingWhite = _isWhite(piece);
        if (movingWhite != g.whiteToMove) return false;

        uint8 pt = _pieceType(piece);
        bool ok;

        if (pt == 1) ok = _isPawnMove(g, from, to, promotion);
        else if (pt == 2) ok = _isKnightMove(from, to);
        else if (pt == 3) ok = _isBishopMove(g.board, from, to);
        else if (pt == 4) ok = _isRookMove(g.board, from, to);
        else if (pt == 5) ok = _isBishopMove(g.board, from, to) || _isRookMove(g.board, from, to);
        else if (pt == 6) ok = _isKingMove(g, from, to);
        else return false;

        if (!ok) return false;

        // Make sure we are not leaving our king in check
        if (_wouldLeaveKingInCheck(g, from, to, pt == 1 ? promotion : NONE)) return false;

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                         MOVE TYPE CHECKS
    //////////////////////////////////////////////////////////////*/

    function _isPawnMove(
        Game memory g,
        uint8 from,
        uint8 to,
        uint8 promotion
    ) internal pure returns (bool) {
        bool white = _isWhite(g.board[from]);
        int8 dir = white ? int8(1) : int8(-1);
        uint8 fromR = _rank(from);
        uint8 toR = _rank(to);
        uint8 fromF = _file(from);
        uint8 toF = _file(to);
        uint8 targetPiece = g.board[to];

        // Single step forward
        if (toF == fromF) {
            if (targetPiece != EMPTY) return false;
            if (toR == uint8(int8(fromR) + dir)) {
                // Promotion check
                if (toR == (white ? 7 : 0)) {
                    return _isValidPromotion(promotion);
                }
                return promotion == NONE;
            }
            // Double step from starting rank
            uint8 startRank = white ? 1 : 6;
            if (fromR == startRank && toR == uint8(int8(fromR) + 2 * dir)) {
                uint8 mid = from + uint8(int8(8) * dir);
                if (g.board[mid] != EMPTY) return false;
                return promotion == NONE;
            }
            return false;
        }

        // Capture (diagonal)
        if (toR == uint8(int8(fromR) + dir) && (toF == fromF + 1 || (fromF > 0 && toF == fromF - 1))) {
            // Normal capture
            if (targetPiece != EMPTY && _isWhite(targetPiece) != white) {
                if (toR == (white ? 7 : 0)) {
                    return _isValidPromotion(promotion);
                }
                return promotion == NONE;
            }
            // En passant
            if (to == g.enPassantTarget && g.enPassantTarget != NO_EN_PASSANT) {
                return promotion == NONE;
            }
        }
        return false;
    }

    function _isValidPromotion(uint8 p) internal pure returns (bool) {
        return p == 2 || p == 3 || p == 4 || p == 5; // N, B, R, Q
    }

    function _isKnightMove(uint8 from, uint8 to) internal pure returns (bool) {
        uint8 df = _absDiff(_file(from), _file(to));
        uint8 dr = _absDiff(_rank(from), _rank(to));
        return (df == 2 && dr == 1) || (df == 1 && dr == 2);
    }

    function _isBishopMove(uint8[64] memory board, uint8 from, uint8 to) internal pure returns (bool) {
        uint8 df = _absDiff(_file(from), _file(to));
        uint8 dr = _absDiff(_rank(from), _rank(to));
        if (df == 0 || dr == 0 || df != dr) return false;
        return _pathClear(board, from, to);
    }

    function _isRookMove(uint8[64] memory board, uint8 from, uint8 to) internal pure returns (bool) {
        uint8 ff = _file(from);
        uint8 tf = _file(to);
        uint8 fr = _rank(from);
        uint8 tr = _rank(to);
        if (ff != tf && fr != tr) return false;
        return _pathClear(board, from, to);
    }

    function _isKingMove(Game memory g, uint8 from, uint8 to) internal pure returns (bool) {
        uint8 df = _absDiff(_file(from), _file(to));
        uint8 dr = _absDiff(_rank(from), _rank(to));
        // Normal king move
        if (df <= 1 && dr <= 1 && !(df == 0 && dr == 0)) {
            uint8 target = g.board[to];
            if (target != EMPTY && _isWhite(target) == g.whiteToMove) return false;
            return true;
        }
        // Castling
        if (dr == 0 && df == 2) {
            bool white = g.whiteToMove;
            uint8 rank = white ? 0 : 7;
            if (_rank(from) != rank || _rank(to) != rank) return false;
            if (_file(from) != 4) return false;

            bool kingside = _file(to) == 6;
            bool queenside = _file(to) == 2;
            if (!kingside && !queenside) return false;

            if (white) {
                if (kingside && !g.whiteCanCastleKingside) return false;
                if (queenside && !g.whiteCanCastleQueenside) return false;
            } else {
                if (kingside && !g.blackCanCastleKingside) return false;
                if (queenside && !g.blackCanCastleQueenside) return false;
            }

            uint8 rookFrom = kingside ? from + 3 : from - 4;
            uint8 rookTo = kingside ? from + 1 : from - 1;

            // Rook must be present
            uint8 expectedRook = white ? WR : BR;
            if (g.board[rookFrom] != expectedRook) return false;

            // Path between king and rook must be clear (except rook itself)
            uint8 step = kingside ? 1 : 255; // 255 = -1 as uint8
            uint8 cursor = from;
            while (true) {
                if (kingside) cursor++;
                else cursor--;
                if (cursor == rookFrom) break;
                if (g.board[cursor] != EMPTY) return false;
            }

            // King cannot be in check, and cannot pass through check
            if (_isSquareAttacked(g.board, from, !white)) return false;
            uint8 mid = kingside ? from + 1 : from - 1;
            if (_isSquareAttacked(g.board, mid, !white)) return false;
            if (_isSquareAttacked(g.board, to, !white)) return false;

            return true;
        }
        return false;
    }

    /*//////////////////////////////////////////////////////////////
                          PATH HELPERS
    //////////////////////////////////////////////////////////////*/

    function _pathClear(uint8[64] memory board, uint8 from, uint8 to) internal pure returns (bool) {
        int8 fStep = _step(_file(from), _file(to));
        int8 rStep = _step(_rank(from), _rank(to));
        uint8 f = _file(from);
        uint8 r = _rank(from);
        while (true) {
            if (fStep > 0) f++;
            else if (fStep < 0) f--;
            if (rStep > 0) r++;
            else if (rStep < 0) r--;
            uint8 sq = r * 8 + f;
            if (sq == to) break;
            if (board[sq] != EMPTY) return false;
        }
        return true;
    }

    function _step(uint8 a, uint8 b) internal pure returns (int8) {
        if (a < b) return 1;
        if (a > b) return -1;
        return 0;
    }

    function _absDiff(uint8 a, uint8 b) internal pure returns (uint8) {
        return a > b ? a - b : b - a;
    }

    /*//////////////////////////////////////////////////////////////
                      KING-SAFETY (would leave in check)
    //////////////////////////////////////////////////////////////*/

    function _wouldLeaveKingInCheck(
        Game memory g,
        uint8 from,
        uint8 to,
        uint8 promotion
    ) internal pure returns (bool) {
        // Simulate move on a copied board
        uint8[64] memory sim;
        for (uint8 i = 0; i < 64; i++) {
            sim[i] = g.board[i];
        }
        bool white = _isWhite(g.board[from]);
        uint8 pt = _pieceType(g.board[from]);

        // Execute on simulation
        sim[to] = promotion != NONE ? (white ? promotion : promotion + 8) : g.board[from];
        sim[from] = EMPTY;

        // Handle en passant capture
        if (pt == 1 && to == g.enPassantTarget && g.enPassantTarget != NO_EN_PASSANT) {
            uint8 capturedPawn = white ? to - 8 : to + 8;
            sim[capturedPawn] = EMPTY;
        }

        // Update king position
        uint8 kingSq = white ? g.whiteKingPos : g.blackKingPos;
        if (pt == 6) kingSq = to;

        return _isSquareAttacked(sim, kingSq, !white);
    }

    /*//////////////////////////////////////////////////////////////
                          MOVE EXECUTION
    //////////////////////////////////////////////////////////////*/

    function executeMove(
        Game storage g,
        uint8 from,
        uint8 to,
        uint8 promotion
    ) internal {
        if (g.gameOver) revert GameNotActive();
        if (!isValidMove(g, from, to, promotion)) revert InvalidMove();

        uint8 piece = g.board[from];
        bool white = _isWhite(piece);
        uint8 pt = _pieceType(piece);

        // Update castling rights if king or rook moves
        if (pt == 6) {
            if (white) {
                g.whiteCanCastleKingside = false;
                g.whiteCanCastleQueenside = false;
                g.whiteKingPos = to;
            } else {
                g.blackCanCastleKingside = false;
                g.blackCanCastleQueenside = false;
                g.blackKingPos = to;
            }
        } else if (pt == 4) {
            if (from == 0 && white) g.whiteCanCastleQueenside = false;
            else if (from == 7 && white) g.whiteCanCastleKingside = false;
            else if (from == 56 && !white) g.blackCanCastleQueenside = false;
            else if (from == 63 && !white) g.blackCanCastleKingside = false;
        }

        // If rook is captured, update castling rights
        if (to == 0 && g.board[to] == WR) g.whiteCanCastleQueenside = false;
        if (to == 7 && g.board[to] == WR) g.whiteCanCastleKingside = false;
        if (to == 56 && g.board[to] == BR) g.blackCanCastleQueenside = false;
        if (to == 63 && g.board[to] == BR) g.blackCanCastleKingside = false;

        // En passant handling
        uint8 prevEnPassant = g.enPassantTarget;
        g.enPassantTarget = NO_EN_PASSANT;

        if (pt == 1) {
            // Pawn double step sets en passant
            uint8 rankDiff = _absDiff(_rank(from), _rank(to));
            if (rankDiff == 2) {
                g.enPassantTarget = white ? from + 8 : from - 8;
            }
            // En passant capture
            if (to == prevEnPassant && prevEnPassant != NO_EN_PASSANT) {
                uint8 captured = white ? to - 8 : to + 8;
                g.board[captured] = EMPTY;
            }
        }

        // Castling: move rook
        if (pt == 6 && _absDiff(_file(from), _file(to)) == 2) {
            bool kingside = _file(to) == 6;
            uint8 rookFrom = kingside ? from + 3 : from - 4;
            uint8 rookTo = kingside ? from + 1 : from - 1;
            g.board[rookTo] = g.board[rookFrom];
            g.board[rookFrom] = EMPTY;
        }

        // Place piece (handle promotion)
        g.board[to] = promotion != NONE ? (white ? promotion : promotion + 8) : piece;
        g.board[from] = EMPTY;

        // Update clocks
        if (pt == 1 || g.board[to] != EMPTY) {
            g.halfmoveClock = 0;
        } else {
            g.halfmoveClock++;
        }

        // Switch side
        g.whiteToMove = !g.whiteToMove;
        if (!g.whiteToMove) {
            g.fullmoveNumber++;
        }

        // Check for checkmate or stalemate
        if (_hasNoLegalMoves(g)) {
            g.gameOver = true;
            if (isInCheck(g, !white)) {
                // Previous mover delivered checkmate
                g.winner = white ? address(1) : address(2); // placeholder; engine resolves
            } else {
                // Stalemate
                g.winner = address(0);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                     CHECKMATE / STALEMATE HELPERS
    //////////////////////////////////////////////////////////////*/

    function _hasNoLegalMoves(Game memory g) internal pure returns (bool) {
        bool side = g.whiteToMove;
        for (uint8 from = 0; from < 64; from++) {
            uint8 p = g.board[from];
            if (p == EMPTY) continue;
            if (_isWhite(p) != side) continue;
            uint8 pt = _pieceType(p);
            for (uint8 to = 0; to < 64; to++) {
                // Try every possible promotion for pawns that reach last rank
                if (pt == 1) {
                    uint8 toR = _rank(to);
                    bool lastRank = side ? toR == 7 : toR == 0;
                    if (lastRank) {
                        for (uint8 promo = 2; promo <= 5; promo++) {
                            if (isValidMove(g, from, to, promo)) return false;
                        }
                    } else {
                        if (isValidMove(g, from, to, NONE)) return false;
                    }
                } else {
                    if (isValidMove(g, from, to, NONE)) return false;
                }
            }
        }
        return true;
    }

    function isCheckmate(Game memory g) internal pure returns (bool) {
        if (!g.gameOver) return false;
        return
            g.winner != address(0) &&
            ((g.winner == address(1)) || (g.winner == address(2)));
    }

    function isStalemate(Game memory g) internal pure returns (bool) {
        if (!g.gameOver) return false;
        return g.winner == address(0);
    }
}
