import XCTest
@testable import SwiftShogi

final class MoveTests: XCTestCase {
    
    // MARK: - 基本指し手テスト
    
    func testBoardMove() {
        // Test basic board-to-board move
        let from = Square(file: 7, rank: 7)
        let to = Square(file: 7, rank: 6)
        
        // Using the correct Either type for from parameter
        let move = Move(
            from: .left(from),
            to: to,
            promote: false,
            color: .black,
            pieceType: .pawn,
            capturedPieceType: nil
        )
        
        XCTAssertEqual(move.to, to)
        XCTAssertFalse(move.promote)
        XCTAssertTrue(move.isFromBoard)
        XCTAssertFalse(move.isFromHand)
    }
    
    func testHandMove() {
        // Test drop move from hand
        let to = Square(file: 5, rank: 5)
        
        let move = Move(
            from: .right(.pawn),
            to: to,
            promote: false,
            color: .black,
            pieceType: .pawn,
            capturedPieceType: nil
        )
        
        XCTAssertEqual(move.to, to)
        XCTAssertEqual(move.pieceType, .pawn)
        XCTAssertFalse(move.isFromBoard)
        XCTAssertTrue(move.isFromHand)
    }
    
    func testPromotionMove() {
        let from = Square(file: 7, rank: 3)
        let to = Square(file: 7, rank: 2)
        
        let move = Move(
            from: .left(from),
            to: to,
            promote: true,
            color: .black,
            pieceType: .pawn,
            capturedPieceType: nil
        )
        
        XCTAssertTrue(move.promote)
        XCTAssertEqual(move.pieceType, .pawn)
    }
    
    func testMoveEquality() {
        let from = Square(file: 5, rank: 5)
        let to = Square(file: 5, rank: 4)
        
        let move1 = Move(
            from: .left(from),
            to: to,
            promote: false,
            color: .black,
            pieceType: .pawn,
            capturedPieceType: nil
        )
        
        let move2 = Move(
            from: .left(from),
            to: to,
            promote: false,
            color: .black,
            pieceType: .pawn,
            capturedPieceType: nil
        )
        
        XCTAssertEqual(move1, move2)
    }
    
    func testWithPromote() {
        let from = Square(file: 7, rank: 3)
        let to = Square(file: 7, rank: 2)
        
        let originalMove = Move(
            from: .left(from),
            to: to,
            promote: false,
            color: .black,
            pieceType: .pawn,
            capturedPieceType: nil
        )
        
        let promotedMove = originalMove.withPromote()
        
        XCTAssertFalse(originalMove.promote)
        XCTAssertTrue(promotedMove.promote)
        XCTAssertEqual(originalMove.to, promotedMove.to)
    }
    
    func testUSIFormat() {
        // Test USI format for board move
        let from = Square(file: 7, rank: 7)
        let to = Square(file: 7, rank: 6)
        
        let move = Move(
            from: .left(from),
            to: to,
            promote: false,
            color: .black,
            pieceType: .pawn,
            capturedPieceType: nil
        )
        
        XCTAssertEqual(move.usi, "7g7f")
    }
    
    func testUSIFormatWithPromotion() {
        let from = Square(file: 7, rank: 3)
        let to = Square(file: 7, rank: 2)
        
        let move = Move(
            from: .left(from),
            to: to,
            promote: true,
            color: .black,
            pieceType: .pawn,
            capturedPieceType: nil
        )
        
        XCTAssertEqual(move.usi, "7c7b+")
    }
    
    func testUSIFormatForHandMove() {
        let to = Square(file: 5, rank: 5)
        
        let move = Move(
            from: .right(.pawn),
            to: to,
            promote: false,
            color: .black,
            pieceType: .pawn,
            capturedPieceType: nil
        )
        
        XCTAssertEqual(move.usi, "P*5e")
    }
}