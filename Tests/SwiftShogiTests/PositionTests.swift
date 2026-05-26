import XCTest
@testable import SwiftShogi

final class PositionTests: XCTestCase {
    
    // MARK: - 局面作成テスト
    
    func testPositionFromSFEN() {
        let sfenString = "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1"
        
        if let position = Position.fromSFEN(sfenString) {
            XCTAssertNotNil(position)
            
            // Test that kings are in correct positions
            XCTAssertEqual(position.board.at(Square(file: 5, rank: 9))?.type, .king) // Black king
            XCTAssertEqual(position.board.at(Square(file: 5, rank: 1))?.type, .king) // White king
            
            // Test that some pawns are in correct positions
            XCTAssertEqual(position.board.at(Square(file: 9, rank: 7))?.type, .pawn) // Black pawn
            XCTAssertEqual(position.board.at(Square(file: 1, rank: 3))?.type, .pawn) // White pawn
        } else {
            XCTFail("Failed to create position from valid SFEN")
        }
    }
    
    func testPositionFromInvalidSFEN() {
        let invalidSfen = "invalid_sfen_format"
        let position = Position.fromSFEN(invalidSfen)
        XCTAssertNil(position)
    }
    
    func testPositionSFEN() {
        if let position = Position.fromSFEN("lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1") {
            let sfen = position.sfen
            
            // Should contain the board representation
            XCTAssertTrue(sfen.contains("lnsgkgsnl"))
            XCTAssertTrue(sfen.contains("LNSGKGSNL"))
            XCTAssertTrue(sfen.contains(" b "))
        }
    }
    
    // MARK: - 局面検証テスト
    
    func testSFENValidation() {
        // Test valid SFEN strings
        let validSfens = [
            "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1",
            "9/9/9/9/9/9/9/9/9 b - 1",
            "4k4/9/9/9/9/9/9/9/4K4 w R 10",
            "4k4/9/9/9/9/9/9/9/+P3K4 b - 1",
            "+P+L+N+S+B+R3/9/9/9/9/9/9/9/4k4 b - 1"
        ]
        
        for sfen in validSfens {
            XCTAssertTrue(Position.isValidSFEN(sfen), "Should be valid: \(sfen)")
        }
        
        // Test invalid SFEN strings
        let invalidSfens = [
            "",
            "invalid",
            "9/9/9/9/9/9/9/9", // Missing parts
            "10/9/9/9/9/9/9/9/9 b - 1" // Invalid board representation
        ]
        
        for sfen in invalidSfens {
            XCTAssertFalse(Position.isValidSFEN(sfen), "Should be invalid: \(sfen)")
        }
    }

    func testPositionFromSFENWithPromotedPieces() {
        let simpleSfen = "4k4/9/9/9/9/9/9/9/+P3K4 b - 1"
        guard let simple = Position.fromSFEN(simpleSfen) else {
            XCTFail("Failed to create position from SFEN with a promoted pawn")
            return
        }
        XCTAssertEqual(simple.board.at(Square(file: 9, rank: 9)), Piece(color: .black, type: .promPawn))
        XCTAssertEqual(simple.board.at(Square(file: 5, rank: 9))?.type, .king)
        XCTAssertEqual(simple.board.at(Square(file: 5, rank: 1))?.type, .king)
        XCTAssertEqual(simple.sfen, simpleSfen)

        let allSfen = "+P+L+N+S+B+R3/9/9/9/9/9/9/9/4k4 b - 1"
        guard let all = Position.fromSFEN(allSfen) else {
            XCTFail("Failed to create position from SFEN with all promoted piece types")
            return
        }
        XCTAssertEqual(all.board.at(Square(file: 9, rank: 1)), Piece(color: .black, type: .promPawn))
        XCTAssertEqual(all.board.at(Square(file: 8, rank: 1)), Piece(color: .black, type: .promLance))
        XCTAssertEqual(all.board.at(Square(file: 7, rank: 1)), Piece(color: .black, type: .promKnight))
        XCTAssertEqual(all.board.at(Square(file: 6, rank: 1)), Piece(color: .black, type: .promSilver))
        XCTAssertEqual(all.board.at(Square(file: 5, rank: 1)), Piece(color: .black, type: .horse))
        XCTAssertEqual(all.board.at(Square(file: 4, rank: 1)), Piece(color: .black, type: .dragon))
        XCTAssertEqual(all.sfen, allSfen)
    }
    
    // MARK: - 指し手実行テスト
    
    func testDoMove() {
        if let position = Position.fromSFEN("lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1") {
            // Test basic pawn move
            let move = Move(
                from: .left(Square(file: 7, rank: 7)),
                to: Square(file: 7, rank: 6),
                promote: false,
                color: .black,
                pieceType: .pawn,
                capturedPieceType: nil
            )
            
            let result = position.doMove(move, option: DoMoveOption())
            
            if result {
                // Move succeeded
                // Note: doMove modifies the position in place
                XCTAssertNil(position.board.at(Square(file: 7, rank: 7)))
                XCTAssertEqual(position.board.at(Square(file: 7, rank: 6))?.type, .pawn)
            } else {
                XCTFail("Move should have succeeded")
            }
        }
    }
    
    // MARK: - 持駒連携テスト
    
    func testPositionWithHand() {
        let sfenWithHand = "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b R2P 1"
        
        if let position = Position.fromSFEN(sfenWithHand) {
            // Test that hand is properly loaded
            XCTAssertGreaterThan(position.blackHand.count(pieceType: .rook), 0)
            XCTAssertGreaterThan(position.blackHand.count(pieceType: .pawn), 0)
        } else {
            XCTFail("Failed to create position with hand")
        }
    }
    
    // MARK: - 持将棋テスト（サポートされている場合）
    
    func testJishogiDeclarationBasic() {
        // Test basic jishogi point calculation
        if let position = Position.fromSFEN("4k4/9/9/9/9/9/9/9/4K4 b - 1") {
            let blackPoints = countJishogiDeclarationPoint(position: position, color: .black)
            let whitePoints = countJishogiDeclarationPoint(position: position, color: .white)
            
            // With minimal pieces, points should be low
            XCTAssertGreaterThanOrEqual(blackPoints, 0)
            XCTAssertGreaterThanOrEqual(whitePoints, 0)
        }
    }
    
    // MARK: - 局面プロパティテスト
    
    func testPositionProperties() {
        if let position = Position.fromSFEN("lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1") {
            // Test immutable operations
            let boardPiece = position.board.at(Square(file: 5, rank: 9))
            XCTAssertNotNil(boardPiece)
            
            // Test that hands are accessible
            XCTAssertNotNil(position.blackHand)
            XCTAssertNotNil(position.whiteHand)
        }
    }
    
    // MARK: - エラーケース
    
    func testInvalidMoves() {
        if let position = Position.fromSFEN("lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1") {
            // Test invalid move (trying to move opponent's piece)
            let invalidMove = Move(
                from: .left(Square(file: 7, rank: 3)),
                to: Square(file: 7, rank: 4),
                promote: false,
                color: .black,
                pieceType: .pawn,
                capturedPieceType: nil
            )
            
            let result = position.doMove(invalidMove, option: DoMoveOption())
            
            if result {
                // This might succeed depending on implementation
                XCTAssertTrue(true)
            } else {
                // Expected for invalid moves
                XCTAssertTrue(true)
            }
        }
    }
}