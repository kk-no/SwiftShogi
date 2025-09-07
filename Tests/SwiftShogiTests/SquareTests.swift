import XCTest
@testable import SwiftShogi

final class SquareTests: XCTestCase {
    
    // MARK: - Basic Square Creation Tests
    
    func testSquareInitialization() {
        let square = Square(file: 5, rank: 5)
        XCTAssertEqual(square.file, 5)
        XCTAssertEqual(square.rank, 5)
    }
    
    func testSquareEquality() {
        let square1 = Square(file: 1, rank: 1)
        let square2 = Square(file: 1, rank: 1)
        let square3 = Square(file: 2, rank: 1)
        
        XCTAssertEqual(square1, square2)
        XCTAssertNotEqual(square1, square3)
    }
    
    func testSquareHashable() {
        let square1 = Square(file: 5, rank: 5)
        let square2 = Square(file: 5, rank: 5)
        let square3 = Square(file: 6, rank: 5)
        
        var set = Set<Square>()
        set.insert(square1)
        set.insert(square2)
        set.insert(square3)
        
        XCTAssertEqual(set.count, 2) // square1 and square2 are the same
    }
    
    // MARK: - Coordinate System Tests
    
    func testXYCoordinates() {
        let square = Square(file: 5, rank: 5) // Center of board
        XCTAssertEqual(square.x, 4) // 9 - 5 = 4
        XCTAssertEqual(square.y, 4) // 5 - 1 = 4
        
        let corner = Square(file: 9, rank: 1) // Top-left corner
        XCTAssertEqual(corner.x, 0) // 9 - 9 = 0
        XCTAssertEqual(corner.y, 0) // 1 - 1 = 0
        
        let opposite = Square(file: 1, rank: 9) // Bottom-right corner
        XCTAssertEqual(opposite.x, 8) // 9 - 1 = 8
        XCTAssertEqual(opposite.y, 8) // 9 - 1 = 8
    }
    
    func testIndex() {
        let topLeft = Square(file: 9, rank: 1)
        XCTAssertEqual(topLeft.index, 0) // y * 9 + x = 0 * 9 + 0 = 0
        
        let topRight = Square(file: 1, rank: 1)
        XCTAssertEqual(topRight.index, 8) // y * 9 + x = 0 * 9 + 8 = 8
        
        let bottomLeft = Square(file: 9, rank: 9)
        XCTAssertEqual(bottomLeft.index, 72) // y * 9 + x = 8 * 9 + 0 = 72
        
        let bottomRight = Square(file: 1, rank: 9)
        XCTAssertEqual(bottomRight.index, 80) // y * 9 + x = 8 * 9 + 8 = 80
    }
    
    func testOpposite() {
        let center = Square(file: 5, rank: 5)
        let opposite = center.opposite
        XCTAssertEqual(opposite.file, 5) // 10 - 5 = 5
        XCTAssertEqual(opposite.rank, 5) // 10 - 5 = 5
        
        let corner = Square(file: 1, rank: 1)
        let oppositeCorner = corner.opposite
        XCTAssertEqual(oppositeCorner.file, 9) // 10 - 1 = 9
        XCTAssertEqual(oppositeCorner.rank, 9) // 10 - 1 = 9
    }
    
    // MARK: - Neighbor Tests
    
    func testNeighborWithDelta() {
        let center = Square(file: 5, rank: 5)
        
        let up = center.neighbor(dx: 0, dy: -1)
        XCTAssertEqual(up, Square(file: 5, rank: 4))
        
        let down = center.neighbor(dx: 0, dy: 1)
        XCTAssertEqual(down, Square(file: 5, rank: 6))
        
        let left = center.neighbor(dx: -1, dy: 0)
        XCTAssertEqual(left, Square(file: 6, rank: 5))
        
        let right = center.neighbor(dx: 1, dy: 0)
        XCTAssertEqual(right, Square(file: 4, rank: 5))
    }
    
    func testNeighborWithDirection() {
        let center = Square(file: 5, rank: 5)
        
        let up = center.neighbor(direction: .up)
        XCTAssertEqual(up, Square(file: 5, rank: 4))
        
        let down = center.neighbor(direction: .down)
        XCTAssertEqual(down, Square(file: 5, rank: 6))
        
        let left = center.neighbor(direction: .left)
        XCTAssertEqual(left, Square(file: 6, rank: 5))
        
        let right = center.neighbor(direction: .right)
        XCTAssertEqual(right, Square(file: 4, rank: 5))
    }
    
    // MARK: - Direction Tests
    
    func testDirectionTo() {
        let origin = Square(file: 5, rank: 5)
        
        let up = Square(file: 5, rank: 4)
        XCTAssertEqual(origin.directionTo(up), .up)
        
        let down = Square(file: 5, rank: 6)
        XCTAssertEqual(origin.directionTo(down), .down)
        
        let left = Square(file: 6, rank: 5)
        XCTAssertEqual(origin.directionTo(left), .left)
        
        let right = Square(file: 4, rank: 5)
        XCTAssertEqual(origin.directionTo(right), .right)
        
        // Test invalid direction (not in a straight line)
        let diagonal = Square(file: 4, rank: 4)
        let direction = origin.directionTo(diagonal)
        // This should return a diagonal direction or nil depending on implementation
        XCTAssertNotNil(direction)
    }
    
    // MARK: - Validation Tests
    
    func testIsValid() {
        // Valid squares
        XCTAssertTrue(Square(file: 1, rank: 1).isValid)
        XCTAssertTrue(Square(file: 9, rank: 9).isValid)
        XCTAssertTrue(Square(file: 5, rank: 5).isValid)
        
        // Invalid squares
        XCTAssertFalse(Square(file: 0, rank: 5).isValid)
        XCTAssertFalse(Square(file: 10, rank: 5).isValid)
        XCTAssertFalse(Square(file: 5, rank: 0).isValid)
        XCTAssertFalse(Square(file: 5, rank: 10).isValid)
        XCTAssertFalse(Square(file: -1, rank: 5).isValid)
    }
    
    // MARK: - USI/SFEN Format Tests
    
    func testUSIFormat() {
        XCTAssertEqual(Square(file: 1, rank: 1).usi, "1a")
        XCTAssertEqual(Square(file: 9, rank: 9).usi, "9i")
        XCTAssertEqual(Square(file: 5, rank: 5).usi, "5e")
    }
    
    func testSFENFormat() {
        XCTAssertEqual(Square(file: 1, rank: 1).sfen, "1a")
        XCTAssertEqual(Square(file: 9, rank: 9).sfen, "9i")
        XCTAssertEqual(Square(file: 5, rank: 5).sfen, "5e")
        
        // SFEN should be the same as USI
        let square = Square(file: 7, rank: 3)
        XCTAssertEqual(square.sfen, square.usi)
    }
    
    // MARK: - Static Factory Methods Tests
    
    func testFromXY() {
        let square = Square.fromXY(x: 4, y: 4)
        XCTAssertEqual(square.file, 5) // 9 - 4 = 5
        XCTAssertEqual(square.rank, 5) // 4 + 1 = 5
        
        let topLeft = Square.fromXY(x: 0, y: 0)
        XCTAssertEqual(topLeft.file, 9) // 9 - 0 = 9
        XCTAssertEqual(topLeft.rank, 1) // 0 + 1 = 1
        
        let bottomRight = Square.fromXY(x: 8, y: 8)
        XCTAssertEqual(bottomRight.file, 1) // 9 - 8 = 1
        XCTAssertEqual(bottomRight.rank, 9) // 8 + 1 = 9
    }
    
    func testFromIndex() {
        let square0 = Square.fromIndex(0)
        XCTAssertEqual(square0.file, 9) // 9 - (0 % 9) = 9 - 0 = 9
        XCTAssertEqual(square0.rank, 1) // (0 / 9) + 1 = 0 + 1 = 1
        
        let square80 = Square.fromIndex(80)
        XCTAssertEqual(square80.file, 1) // 9 - (80 % 9) = 9 - 8 = 1
        XCTAssertEqual(square80.rank, 9) // (80 / 9) + 1 = 8 + 1 = 9
        
        let squareMiddle = Square.fromIndex(40)
        XCTAssertEqual(squareMiddle.file, 5) // 9 - (40 % 9) = 9 - 4 = 5
        XCTAssertEqual(squareMiddle.rank, 5) // (40 / 9) + 1 = 4 + 1 = 5
    }
    
    func testFromUSI() {
        let square = Square.fromUSI("5e")
        XCTAssertNotNil(square)
        XCTAssertEqual(square?.file, 5)
        XCTAssertEqual(square?.rank, 5)
        
        let corner = Square.fromUSI("1a")
        XCTAssertNotNil(corner)
        XCTAssertEqual(corner?.file, 1)
        XCTAssertEqual(corner?.rank, 1)
        
        let invalid = Square.fromUSI("invalid")
        XCTAssertNil(invalid)
        
        let empty = Square.fromUSI("")
        XCTAssertNil(empty)
        
        let outOfRange = Square.fromUSI("0a")
        XCTAssertNil(outOfRange)
        
        let invalidRank = Square.fromUSI("5z")
        XCTAssertNil(invalidRank)
    }
    
    func testFromSFEN() {
        // SFEN should work the same as USI
        let square = Square.fromSFEN("5e")
        XCTAssertNotNil(square)
        XCTAssertEqual(square?.file, 5)
        XCTAssertEqual(square?.rank, 5)
        
        let invalid = Square.fromSFEN("invalid")
        XCTAssertNil(invalid)
    }
    
    // MARK: - Round Trip Tests
    
    func testUSIRoundTrip() {
        let originalSquare = Square(file: 7, rank: 3)
        let usiString = originalSquare.usi
        let parsedSquare = Square.fromUSI(usiString)
        
        XCTAssertNotNil(parsedSquare)
        XCTAssertEqual(parsedSquare, originalSquare)
    }
    
    func testIndexRoundTrip() {
        for index in 0...80 {
            let square = Square.fromIndex(index)
            XCTAssertEqual(square.index, index)
        }
    }
    
    func testXYRoundTrip() {
        for x in 0...8 {
            for y in 0...8 {
                let square = Square.fromXY(x: x, y: y)
                XCTAssertEqual(square.x, x)
                XCTAssertEqual(square.y, y)
            }
        }
    }
    
    // MARK: - All Squares Test
    
    func testAllSquares() {
        let allSquares = Square.allSquares
        XCTAssertEqual(allSquares.count, 81) // 9x9 board
        
        // Check that all squares are valid
        for square in allSquares {
            XCTAssertTrue(square.isValid)
        }
        
        // Check that we have all unique squares
        let uniqueSquares = Set(allSquares)
        XCTAssertEqual(uniqueSquares.count, 81)
        
        // Check corner squares are present
        XCTAssertTrue(allSquares.contains(Square(file: 1, rank: 1)))
        XCTAssertTrue(allSquares.contains(Square(file: 9, rank: 9)))
        XCTAssertTrue(allSquares.contains(Square(file: 1, rank: 9)))
        XCTAssertTrue(allSquares.contains(Square(file: 9, rank: 1)))
    }
}