import XCTest
@testable import SwiftShogi

final class BasicFunctionalityTests: XCTestCase {
    
    // MARK: - 基本駒テスト
    
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
    
    // MARK: - 基本マス目テスト
    
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
    
    // MARK: - 基本色テスト
    
    func testColorReversal() {
        XCTAssertEqual(Color.black.reversed(), .white)
        XCTAssertEqual(Color.white.reversed(), .black)
    }
    
    // MARK: - 基本方向テスト
    
    func testDirectionDeltas() {
        XCTAssertEqual(Direction.up.delta.x, 0)
        XCTAssertEqual(Direction.up.delta.y, -1)
        
        XCTAssertEqual(Direction.down.delta.x, 0)
        XCTAssertEqual(Direction.down.delta.y, 1)
    }
    
    // MARK: - 基本盤面テスト
    
    func testBoardOperations() {
        let board = Board()
        let square = Square(file: 5, rank: 5)
        let piece = Piece(color: .black, type: .king)
        
        // 駒の設定と取得テスト
        board.set(square: square, piece: piece)
        XCTAssertEqual(board.at(square), piece)
        
        // 駒の除去テスト
        let removedPiece = board.remove(square: square)
        XCTAssertEqual(removedPiece, piece)
        XCTAssertNil(board.at(square))
        
        // 盤面クリアテスト
        board.set(square: square, piece: piece)
        board.clear()
        XCTAssertNil(board.at(square))
    }
    
    // MARK: - 基本持ち駒テスト
    
    func testHandOperations() {
        let hand = Hand()
        
        // 枚数の設定と取得テスト
        hand.set(pieceType: .pawn, count: 5)
        XCTAssertEqual(hand.count(pieceType: .pawn), 5)
        
        // 駒の追加テスト
        hand.add(pieceType: .pawn, count: 2)
        XCTAssertEqual(hand.count(pieceType: .pawn), 7)
        
        // 駒の減算テスト
        hand.reduce(pieceType: .pawn, count: 3)
        XCTAssertEqual(hand.count(pieceType: .pawn), 4)
    }
    
    // MARK: - フォーマット検出テスト
    
    func testFormatDetection() {
        // SFEN検出テスト
        let sfenString = "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1"
        XCTAssertEqual(FormatDetector.detectRecordFormat(sfenString), .SFEN)
        
        // USI検出テスト
        let usiString = "position startpos moves 7g7f 3c3d"
        XCTAssertEqual(FormatDetector.detectRecordFormat(usiString), .USI)
    }
}