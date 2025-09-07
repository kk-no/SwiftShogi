import XCTest
@testable import SwiftShogi

final class PieceTests: XCTestCase {
    
    // MARK: - 基本駒作成テスト
    
    func testPieceInitialization() {
        let piece = Piece(color: .black, type: .pawn)
        XCTAssertEqual(piece.color, .black)
        XCTAssertEqual(piece.type, .pawn)
    }
    
    func testPieceEquality() {
        let piece1 = Piece(color: .black, type: .pawn)
        let piece2 = Piece(color: .black, type: .pawn)
        let piece3 = Piece(color: .white, type: .pawn)
        
        XCTAssertEqual(piece1, piece2)
        XCTAssertNotEqual(piece1, piece3)
    }
    
    func testPieceHashable() {
        let piece1 = Piece(color: .black, type: .pawn)
        let piece2 = Piece(color: .black, type: .pawn)
        let piece3 = Piece(color: .white, type: .pawn)
        
        var set = Set<Piece>()
        set.insert(piece1)
        set.insert(piece2)
        set.insert(piece3)
        
        XCTAssertEqual(set.count, 2) // piece1 and piece2 are the same
    }
    
    // MARK: - 色変換テスト
    
    func testBlackConversion() {
        let whitePawn = Piece(color: .white, type: .pawn)
        let blackPawn = whitePawn.black()
        
        XCTAssertEqual(blackPawn.color, .black)
        XCTAssertEqual(blackPawn.type, .pawn)
    }
    
    func testWhiteConversion() {
        let blackPawn = Piece(color: .black, type: .pawn)
        let whitePawn = blackPawn.white()
        
        XCTAssertEqual(whitePawn.color, .white)
        XCTAssertEqual(whitePawn.type, .pawn)
    }
    
    func testWithColor() {
        let piece = Piece(color: .black, type: .rook)
        let whiteRook = piece.withColor(.white)
        
        XCTAssertEqual(whiteRook.color, .white)
        XCTAssertEqual(whiteRook.type, .rook)
    }
    
    // MARK: - 成りテスト
    
    func testPromotedPiece() {
        let pawn = Piece(color: .black, type: .pawn)
        let promotedPawn = pawn.promoted()
        
        XCTAssertEqual(promotedPawn.type, .promPawn)
        XCTAssertEqual(promotedPawn.color, .black)
    }
    
    func testUnpromotedPiece() {
        let promotedPawn = Piece(color: .black, type: .promPawn)
        let pawn = promotedPawn.unpromoted()
        
        XCTAssertEqual(pawn.type, .pawn)
        XCTAssertEqual(pawn.color, .black)
    }
    
    func testIsPromotable() {
        let pawn = Piece(color: .black, type: .pawn)
        let king = Piece(color: .black, type: .king)
        let gold = Piece(color: .black, type: .gold)
        
        XCTAssertTrue(pawn.isPromotable)
        XCTAssertFalse(king.isPromotable)
        XCTAssertFalse(gold.isPromotable)
    }
    
    // MARK: - 回転テスト
    
    func testRotatePiece() {
        let blackPawn = Piece(color: .black, type: .pawn)
        let rotated = blackPawn.rotate()
        
        // Rotation changes pawn to promPawn but doesn't reverse color
        XCTAssertEqual(rotated.color, .black)
        XCTAssertEqual(rotated.type, .promPawn)
    }
    
    // MARK: - IDテスト
    
    func testPieceID() {
        let blackPawn = Piece(color: .black, type: .pawn)
        let whitePawn = Piece(color: .white, type: .pawn)
        
        XCTAssertEqual(blackPawn.id, "black_pawn")
        XCTAssertEqual(whitePawn.id, "white_pawn")
        XCTAssertNotEqual(blackPawn.id, whitePawn.id)
    }
    
    // MARK: - SFENテスト
    
    func testSFENConversion() {
        let blackPawn = Piece(color: .black, type: .pawn)
        let whitePawn = Piece(color: .white, type: .pawn)
        
        // SFEN notation uses uppercase for black, lowercase for white
        XCTAssertEqual(blackPawn.sfen, "P")
        XCTAssertEqual(whitePawn.sfen, "p")
    }
    
    func testSFENValidation() {
        XCTAssertTrue(Piece.isValidSFEN("P"))  // Black pawn
        XCTAssertTrue(Piece.isValidSFEN("p"))  // White pawn
        XCTAssertTrue(Piece.isValidSFEN("K"))  // Black king
        XCTAssertTrue(Piece.isValidSFEN("k"))  // White king
        
        XCTAssertFalse(Piece.isValidSFEN("X")) // Invalid character
        XCTAssertFalse(Piece.isValidSFEN(""))  // Empty string
    }
    
    func testFromSFEN() {
        // Test valid SFEN conversions
        let blackPawn = Piece.fromSFEN("P")
        XCTAssertNotNil(blackPawn)
        XCTAssertEqual(blackPawn?.color, .black)
        XCTAssertEqual(blackPawn?.type, .pawn)
        
        let whitePawn = Piece.fromSFEN("p")
        XCTAssertNotNil(whitePawn)
        XCTAssertEqual(whitePawn?.color, .white)
        XCTAssertEqual(whitePawn?.type, .pawn)
        
        // Test invalid SFEN
        let invalidPiece = Piece.fromSFEN("X")
        XCTAssertNil(invalidPiece)
    }
    
    // MARK: - 駒種類テスト
    
    func testPieceTypeRawValues() {
        XCTAssertEqual(PieceType.pawn.rawValue, "pawn")
        XCTAssertEqual(PieceType.king.rawValue, "king")
        XCTAssertEqual(PieceType.rook.rawValue, "rook")
        XCTAssertEqual(PieceType.bishop.rawValue, "bishop")
    }
    
    func testPieceTypeCaseIterable() {
        let allTypes = PieceType.allCases
        XCTAssertTrue(allTypes.contains(.pawn))
        XCTAssertTrue(allTypes.contains(.king))
        XCTAssertTrue(allTypes.contains(.promPawn))
        XCTAssertEqual(allTypes.count, 14) // All piece types
    }
    
    // MARK: - ヘルパー関数テスト
    
    func testPromotionHelperFunctions() {
        // Test promotable types
        XCTAssertTrue(isPromotableType(.pawn))
        XCTAssertTrue(isPromotableType(.lance))
        XCTAssertTrue(isPromotableType(.knight))
        XCTAssertTrue(isPromotableType(.silver))
        XCTAssertTrue(isPromotableType(.bishop))
        XCTAssertTrue(isPromotableType(.rook))
        
        // Test non-promotable types
        XCTAssertFalse(isPromotableType(.king))
        XCTAssertFalse(isPromotableType(.gold))
        XCTAssertFalse(isPromotableType(.promPawn))
        
        // Test promotion mappings
        XCTAssertEqual(promotedType(of: .pawn), .promPawn)
        XCTAssertEqual(promotedType(of: .bishop), .horse)
        XCTAssertEqual(promotedType(of: .rook), .dragon)
        
        // Test unpromoted mappings
        XCTAssertEqual(unpromotedType(of: .promPawn), .pawn)
        XCTAssertEqual(unpromotedType(of: .horse), .bishop)
        XCTAssertEqual(unpromotedType(of: .dragon), .rook)
    }
}