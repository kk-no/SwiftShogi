import XCTest
@testable import SwiftShogi

final class SimpleBoardTests: XCTestCase {
    
    var board: Board!
    
    override func setUp() {
        super.setUp()
        board = Board()
    }
    
    func testBoardInitialization() {
        XCTAssertNotNil(board)
        
        // Test setting and getting a piece
        let square = Square(file: 5, rank: 5)
        let piece = Piece(color: .black, type: .pawn)
        
        board.set(square: square, piece: piece)
        let retrievedPiece = board.at(square)
        
        XCTAssertEqual(retrievedPiece, piece)
    }
    
    func testBoardClear() {
        let square = Square(file: 5, rank: 5)
        let piece = Piece(color: .black, type: .king)
        
        board.set(square: square, piece: piece)
        XCTAssertNotNil(board.at(square))
        
        board.clear()
        XCTAssertNil(board.at(square))
    }
    
    func testFindKing() {
        let kingSquare = Square(file: 5, rank: 9)
        let king = Piece(color: .black, type: .king)
        
        board.set(square: kingSquare, piece: king)
        
        let foundKing = board.findKing(color: .black)
        XCTAssertEqual(foundKing, kingSquare)
        
        let notFoundKing = board.findKing(color: .white)
        XCTAssertNil(notFoundKing)
    }
    
    func testBoardSFEN() {
        let sfen = board.sfen
        XCTAssertEqual(sfen, "9/9/9/9/9/9/9/9/9")
    }
}