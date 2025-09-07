import XCTest
@testable import SwiftShogi

final class ColorTests: XCTestCase {
    
    // MARK: - Basic Color Tests
    
    func testColorRawValues() {
        XCTAssertEqual(Color.black.rawValue, "black")
        XCTAssertEqual(Color.white.rawValue, "white")
    }
    
    func testColorCaseIterable() {
        let allColors = Color.allCases
        XCTAssertEqual(allColors.count, 2)
        XCTAssertTrue(allColors.contains(.black))
        XCTAssertTrue(allColors.contains(.white))
    }
    
    // MARK: - Color Reversal Tests
    
    func testColorReversal() {
        XCTAssertEqual(Color.black.reversed(), .white)
        XCTAssertEqual(Color.white.reversed(), .black)
    }
    
    func testDoubleReversal() {
        XCTAssertEqual(Color.black.reversed().reversed(), .black)
        XCTAssertEqual(Color.white.reversed().reversed(), .white)
    }
    
    // MARK: - SFEN Notation Tests
    
    func testSFENNotation() {
        XCTAssertEqual(Color.black.sfenNotation, "b")
        XCTAssertEqual(Color.white.sfenNotation, "w")
    }
    
    func testSFENValidation() {
        XCTAssertTrue(Color.isValidSFENColor("b"))
        XCTAssertTrue(Color.isValidSFENColor("w"))
        
        XCTAssertFalse(Color.isValidSFENColor("B"))
        XCTAssertFalse(Color.isValidSFENColor("W"))
        XCTAssertFalse(Color.isValidSFENColor("x"))
        XCTAssertFalse(Color.isValidSFENColor(""))
        XCTAssertFalse(Color.isValidSFENColor("black"))
        XCTAssertFalse(Color.isValidSFENColor("white"))
    }
    
    func testFromSFEN() {
        XCTAssertEqual(Color.fromSFEN("b"), .black)
        XCTAssertEqual(Color.fromSFEN("w"), .white)
        
        // Test behavior with invalid input (should default to white based on implementation)
        XCTAssertEqual(Color.fromSFEN("invalid"), .white)
        XCTAssertEqual(Color.fromSFEN(""), .white)
    }
    
    // MARK: - Round Trip Tests
    
    func testSFENRoundTrip() {
        // Test that converting to SFEN and back gives the original color
        let blackSfen = Color.black.sfenNotation
        let whiteFromSfen = Color.fromSFEN(blackSfen)
        XCTAssertEqual(whiteFromSfen, .black)
        
        let whiteSfen = Color.white.sfenNotation
        let blackFromSfen = Color.fromSFEN(whiteSfen)
        XCTAssertEqual(blackFromSfen, .white)
    }
}