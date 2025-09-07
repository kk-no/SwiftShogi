import XCTest
@testable import SwiftShogi

final class BasicFunctionalityTests: XCTestCase {
    
    // MARK: - Basic Piece Tests
    
    func testPieceCreation() {
        let blackPawn = Piece(color: .black, type: .pawn)
        XCTAssertEqual(blackPawn.color, .black)
        XCTAssertEqual(blackPawn.type, .pawn)
        
        let whitePawn = Piece(color: .white, type: .pawn)
        XCTAssertEqual(whitePawn.color, .white)
        XCTAssertEqual(whitePawn.type, .pawn)
        
        XCTAssertNotEqual(blackPawn, whitePawn)
    }
    
    func testPiecePromotion() {
        let pawn = Piece(color: .black, type: .pawn)
        let promotedPawn = pawn.promoted()
        
        XCTAssertEqual(promotedPawn.type, .promPawn)
        XCTAssertEqual(promotedPawn.color, .black)
        XCTAssertTrue(pawn.isPromotable)
    }
    
    // MARK: - Basic Square Tests
    
    func testSquareCreation() {
        let square = Square(file: 5, rank: 5)
        XCTAssertEqual(square.file, 5)
        XCTAssertEqual(square.rank, 5)
        XCTAssertTrue(square.isValid)
    }
    
    func testSquareUSI() {
        let square = Square(file: 7, rank: 6)
        XCTAssertEqual(square.usi, "7f")
    }
    
    // MARK: - Basic Color Tests
    
    func testColorReversal() {
        XCTAssertEqual(Color.black.reversed(), .white)
        XCTAssertEqual(Color.white.reversed(), .black)
    }
    
    // MARK: - Basic Direction Tests
    
    func testDirectionDeltas() {
        XCTAssertEqual(Direction.up.delta.x, 0)
        XCTAssertEqual(Direction.up.delta.y, -1)
        
        XCTAssertEqual(Direction.down.delta.x, 0)
        XCTAssertEqual(Direction.down.delta.y, 1)
    }
    
    // MARK: - Basic Board Tests
    
    func testBoardOperations() {
        let board = Board()
        let square = Square(file: 5, rank: 5)
        let piece = Piece(color: .black, type: .king)
        
        // Test setting and getting
        board.set(square: square, piece: piece)
        XCTAssertEqual(board.at(square), piece)
        
        // Test removal
        let removedPiece = board.remove(square: square)
        XCTAssertEqual(removedPiece, piece)
        XCTAssertNil(board.at(square))
        
        // Test clearing
        board.set(square: square, piece: piece)
        board.clear()
        XCTAssertNil(board.at(square))
    }
    
    // MARK: - Basic Hand Tests
    
    func testHandOperations() {
        let hand = Hand()
        
        // Test setting and getting counts
        hand.set(pieceType: .pawn, count: 5)
        XCTAssertEqual(hand.count(pieceType: .pawn), 5)
        
        // Test adding
        hand.add(pieceType: .pawn, count: 2)
        XCTAssertEqual(hand.count(pieceType: .pawn), 7)
        
        // Test reducing
        hand.reduce(pieceType: .pawn, count: 3)
        XCTAssertEqual(hand.count(pieceType: .pawn), 4)
    }
    
    // MARK: - Format Detection Tests
    
    func testFormatDetection() {
        // Test SFEN detection
        let sfenString = "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1"
        XCTAssertEqual(FormatDetector.detectRecordFormat(sfenString), .SFEN)
        
        // Test USI detection
        let usiString = "position startpos moves 7g7f 3c3d"
        XCTAssertEqual(FormatDetector.detectRecordFormat(usiString), .USI)
    }
}