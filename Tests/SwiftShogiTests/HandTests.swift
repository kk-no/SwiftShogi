import XCTest
@testable import SwiftShogi

final class HandTests: XCTestCase {
    
    var hand: Hand!
    
    override func setUp() {
        super.setUp()
        hand = Hand()
    }
    
    // MARK: - 基本持駒操作
    
    func testHandInitialization() {
        XCTAssertNotNil(hand)
        
        // All piece counts should be 0 initially
        for pieceType in handPieceTypes {
            XCTAssertEqual(hand.count(pieceType: pieceType), 0)
        }
    }
    
    func testSetPieceCount() {
        hand.set(pieceType: .pawn, count: 5)
        XCTAssertEqual(hand.count(pieceType: .pawn), 5)
        
        hand.set(pieceType: .pawn, count: 0)
        XCTAssertEqual(hand.count(pieceType: .pawn), 0)
    }
    
    func testAddPieceCount() {
        hand.add(pieceType: .rook, count: 2)
        XCTAssertEqual(hand.count(pieceType: .rook), 2)
        
        hand.add(pieceType: .rook, count: 1)
        XCTAssertEqual(hand.count(pieceType: .rook), 3)
    }
    
    func testReducePieceCount() {
        hand.set(pieceType: .bishop, count: 3)
        
        hand.reduce(pieceType: .bishop, count: 1)
        XCTAssertEqual(hand.count(pieceType: .bishop), 2)
        
        hand.reduce(pieceType: .bishop, count: 5) // Try to reduce more than available
        XCTAssertEqual(hand.count(pieceType: .bishop), -3) // Implementation allows negative values
    }
    
    // MARK: - SFENフォーマットテスト
    
    func testSFENFormat() {
        hand.set(pieceType: .pawn, count: 2)
        hand.set(pieceType: .rook, count: 1)
        
        let blackSfen = hand.formatSFEN(color: .black)
        let whiteSfen = hand.formatSFEN(color: .white)
        
        XCTAssertTrue(blackSfen.contains("R") || blackSfen.contains("P"))
        XCTAssertTrue(whiteSfen.contains("r") || whiteSfen.contains("p"))
        XCTAssertNotEqual(blackSfen, whiteSfen)
    }
    
    func testEmptyHandSFEN() {
        let blackSfen = hand.formatSFEN(color: .black)
        let whiteSfen = hand.formatSFEN(color: .white)
        
        XCTAssertEqual(blackSfen, "-")
        XCTAssertEqual(whiteSfen, "-")
    }
    
    // MARK: - ForEachテスト
    
    func testForEach() {
        hand.set(pieceType: .pawn, count: 3)
        hand.set(pieceType: .rook, count: 1)
        
        var totalCount = 0
        hand.forEach { _, count in
            totalCount += count
        }
        
        XCTAssertEqual(totalCount, 4) // 3 pawns + 1 rook
    }
    
    func testForEachEmptyHand() {
        var callCount = 0
        hand.forEach { _, _ in
            callCount += 1
        }
        XCTAssertEqual(callCount, 7) // forEach iterates over all handPieceTypes, even with 0 count
    }
    
    // MARK: - コピー操作
    
    func testCopyFrom() {
        let sourceHand = Hand()
        sourceHand.set(pieceType: .pawn, count: 5)
        sourceHand.set(pieceType: .rook, count: 2)
        
        hand.copyFrom(sourceHand)
        
        XCTAssertEqual(hand.count(pieceType: .pawn), 5)
        XCTAssertEqual(hand.count(pieceType: .rook), 2)
        
        // Verify independence
        sourceHand.set(pieceType: .pawn, count: 10)
        XCTAssertEqual(hand.count(pieceType: .pawn), 5) // Should remain unchanged
    }
    
    // MARK: - 静的メソッドテスト
    
    func testStaticSFENFormatting() {
        let blackHand = Hand()
        blackHand.set(pieceType: .pawn, count: 2)
        
        let whiteHand = Hand()
        whiteHand.set(pieceType: .bishop, count: 1)
        
        let combinedSfen = Hand.formatSFEN(black: blackHand, white: whiteHand)
        
        XCTAssertTrue(combinedSfen.contains("P") || combinedSfen.contains("b"))
        XCTAssertFalse(combinedSfen.isEmpty)
    }
    
    func testStaticSFENFormattingEmptyHands() {
        let blackHand = Hand()
        let whiteHand = Hand()
        
        let combinedSfen = Hand.formatSFEN(black: blackHand, white: whiteHand)
        XCTAssertEqual(combinedSfen, "-")
    }
    
    // MARK: - SFEN解析テスト
    
    func testParseSFENBasic() {
        if let (blackHand, whiteHand) = Hand.parseSFEN("R2Pb3p") {
            // Black should have R and 2P
            XCTAssertEqual(blackHand.count(pieceType: .rook), 1)
            XCTAssertEqual(blackHand.count(pieceType: .pawn), 2)
            
            // White should have b and 3p
            XCTAssertEqual(whiteHand.count(pieceType: .bishop), 1)
            XCTAssertEqual(whiteHand.count(pieceType: .pawn), 3)
        } else {
            XCTFail("Failed to parse valid SFEN")
        }
    }
    
    func testParseSFENEmptyHands() {
        if let (blackHand, whiteHand) = Hand.parseSFEN("-") {
            for pieceType in handPieceTypes {
                XCTAssertEqual(blackHand.count(pieceType: pieceType), 0)
                XCTAssertEqual(whiteHand.count(pieceType: pieceType), 0)
            }
        } else {
            XCTFail("Failed to parse empty hands SFEN")
        }
    }
    
    func testParseSFENInvalid() {
        let result = Hand.parseSFEN("xyz123")  // No valid piece characters
        // Implementation returns nil for completely unmatched input
        XCTAssertNil(result)
    }
    
    // MARK: - 反復テスト
    
    func testHandIteration() {
        hand.set(pieceType: .pawn, count: 2)
        hand.set(pieceType: .rook, count: 1)
        
        var iteratedPieces: [PieceType: Int] = [:]
        
        for (pieceType, count) in hand {
            iteratedPieces[pieceType] = count
        }
        
        XCTAssertEqual(iteratedPieces[.pawn], 2)
        XCTAssertEqual(iteratedPieces[.rook], 1)
        XCTAssertEqual(iteratedPieces.count, 2)
    }
}