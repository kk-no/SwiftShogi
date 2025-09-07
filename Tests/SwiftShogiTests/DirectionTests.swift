import XCTest
@testable import SwiftShogi

final class DirectionTests: XCTestCase {
    
    // MARK: - 基本方向テスト
    
    func testDirectionRawValues() {
        XCTAssertEqual(Direction.up.rawValue, "up")
        XCTAssertEqual(Direction.down.rawValue, "down")
        XCTAssertEqual(Direction.left.rawValue, "left")
        XCTAssertEqual(Direction.right.rawValue, "right")
        XCTAssertEqual(Direction.leftUp.rawValue, "left_up")
        XCTAssertEqual(Direction.rightUp.rawValue, "right_up")
        XCTAssertEqual(Direction.leftDown.rawValue, "left_down")
        XCTAssertEqual(Direction.rightDown.rawValue, "right_down")
        XCTAssertEqual(Direction.leftUpKnight.rawValue, "left_up_knight")
        XCTAssertEqual(Direction.rightUpKnight.rawValue, "right_up_knight")
        XCTAssertEqual(Direction.leftDownKnight.rawValue, "left_down_knight")
        XCTAssertEqual(Direction.rightDownKnight.rawValue, "right_down_knight")
    }
    
    // MARK: - 方向反転テスト
    
    func testBasicDirectionReversal() {
        XCTAssertEqual(Direction.up.reversed, .down)
        XCTAssertEqual(Direction.down.reversed, .up)
        XCTAssertEqual(Direction.left.reversed, .right)
        XCTAssertEqual(Direction.right.reversed, .left)
    }
    
    func testDiagonalDirectionReversal() {
        XCTAssertEqual(Direction.leftUp.reversed, .rightDown)
        XCTAssertEqual(Direction.rightUp.reversed, .leftDown)
        XCTAssertEqual(Direction.leftDown.reversed, .rightUp)
        XCTAssertEqual(Direction.rightDown.reversed, .leftUp)
    }
    
    func testKnightDirectionReversal() {
        XCTAssertEqual(Direction.leftUpKnight.reversed, .rightDownKnight)
        XCTAssertEqual(Direction.rightUpKnight.reversed, .leftDownKnight)
        XCTAssertEqual(Direction.leftDownKnight.reversed, .rightUpKnight)
        XCTAssertEqual(Direction.rightDownKnight.reversed, .leftUpKnight)
    }
    
    func testDoubleReversal() {
        let allDirections = Direction.allDirections
        for direction in allDirections {
            XCTAssertEqual(direction.reversed.reversed, direction)
        }
    }
    
    // MARK: - デルタテスト
    
    func testBasicDirectionDeltas() {
        XCTAssertEqual(Direction.up.delta.x, 0)
        XCTAssertEqual(Direction.up.delta.y, -1)
        
        XCTAssertEqual(Direction.down.delta.x, 0)
        XCTAssertEqual(Direction.down.delta.y, 1)
        
        XCTAssertEqual(Direction.left.delta.x, -1)
        XCTAssertEqual(Direction.left.delta.y, 0)
        
        XCTAssertEqual(Direction.right.delta.x, 1)
        XCTAssertEqual(Direction.right.delta.y, 0)
    }
    
    func testDiagonalDirectionDeltas() {
        XCTAssertEqual(Direction.leftUp.delta.x, -1)
        XCTAssertEqual(Direction.leftUp.delta.y, -1)
        
        XCTAssertEqual(Direction.rightUp.delta.x, 1)
        XCTAssertEqual(Direction.rightUp.delta.y, -1)
        
        XCTAssertEqual(Direction.leftDown.delta.x, -1)
        XCTAssertEqual(Direction.leftDown.delta.y, 1)
        
        XCTAssertEqual(Direction.rightDown.delta.x, 1)
        XCTAssertEqual(Direction.rightDown.delta.y, 1)
    }
    
    func testKnightDirectionDeltas() {
        XCTAssertEqual(Direction.leftUpKnight.delta.x, -1)
        XCTAssertEqual(Direction.leftUpKnight.delta.y, -2)
        
        XCTAssertEqual(Direction.rightUpKnight.delta.x, 1)
        XCTAssertEqual(Direction.rightUpKnight.delta.y, -2)
        
        XCTAssertEqual(Direction.leftDownKnight.delta.x, -1)
        XCTAssertEqual(Direction.leftDownKnight.delta.y, 2)
        
        XCTAssertEqual(Direction.rightDownKnight.delta.x, 1)
        XCTAssertEqual(Direction.rightDownKnight.delta.y, 2)
    }
    
    // MARK: - 垂直方向テスト
    
    func testVerticalDirection() {
        XCTAssertEqual(Direction.up.verticalDirection, .up)
        XCTAssertEqual(Direction.leftUp.verticalDirection, .up)
        XCTAssertEqual(Direction.rightUp.verticalDirection, .up)
        XCTAssertEqual(Direction.leftUpKnight.verticalDirection, .up)
        XCTAssertEqual(Direction.rightUpKnight.verticalDirection, .up)
        
        XCTAssertEqual(Direction.down.verticalDirection, .down)
        XCTAssertEqual(Direction.leftDown.verticalDirection, .down)
        XCTAssertEqual(Direction.rightDown.verticalDirection, .down)
        XCTAssertEqual(Direction.leftDownKnight.verticalDirection, .down)
        XCTAssertEqual(Direction.rightDownKnight.verticalDirection, .down)
        
        XCTAssertEqual(Direction.left.verticalDirection, .none)
        XCTAssertEqual(Direction.right.verticalDirection, .none)
    }
    
    // MARK: - 水平方向テスト
    
    func testHorizontalDirection() {
        XCTAssertEqual(Direction.left.horizontalDirection, .left)
        XCTAssertEqual(Direction.leftUp.horizontalDirection, .left)
        XCTAssertEqual(Direction.leftDown.horizontalDirection, .left)
        XCTAssertEqual(Direction.leftUpKnight.horizontalDirection, .left)
        XCTAssertEqual(Direction.leftDownKnight.horizontalDirection, .left)
        
        XCTAssertEqual(Direction.right.horizontalDirection, .right)
        XCTAssertEqual(Direction.rightUp.horizontalDirection, .right)
        XCTAssertEqual(Direction.rightDown.horizontalDirection, .right)
        XCTAssertEqual(Direction.rightUpKnight.horizontalDirection, .right)
        XCTAssertEqual(Direction.rightDownKnight.horizontalDirection, .right)
        
        XCTAssertEqual(Direction.up.horizontalDirection, .none)
        XCTAssertEqual(Direction.down.horizontalDirection, .none)
    }
    
    // MARK: - 全方向テスト
    
    func testAllDirections() {
        let allDirections = Direction.allDirections
        XCTAssertEqual(allDirections.count, 12)
        
        // Check that all expected directions are present
        XCTAssertTrue(allDirections.contains(.up))
        XCTAssertTrue(allDirections.contains(.down))
        XCTAssertTrue(allDirections.contains(.left))
        XCTAssertTrue(allDirections.contains(.right))
        XCTAssertTrue(allDirections.contains(.leftUp))
        XCTAssertTrue(allDirections.contains(.rightUp))
        XCTAssertTrue(allDirections.contains(.leftDown))
        XCTAssertTrue(allDirections.contains(.rightDown))
        XCTAssertTrue(allDirections.contains(.leftUpKnight))
        XCTAssertTrue(allDirections.contains(.rightUpKnight))
        XCTAssertTrue(allDirections.contains(.leftDownKnight))
        XCTAssertTrue(allDirections.contains(.rightDownKnight))
    }
    
    // MARK: - ベクトル変換テスト
    
    func testFromVectorBasicDirections() {
        let upResult = Direction.fromVector(x: 0, y: -1)
        XCTAssertTrue(upResult.valid)
        XCTAssertEqual(upResult.direction, .up)
        XCTAssertEqual(upResult.distance, 1)
        
        let downResult = Direction.fromVector(x: 0, y: 1)
        XCTAssertTrue(downResult.valid)
        XCTAssertEqual(downResult.direction, .down)
        XCTAssertEqual(downResult.distance, 1)
        
        let leftResult = Direction.fromVector(x: -1, y: 0)
        XCTAssertTrue(leftResult.valid)
        XCTAssertEqual(leftResult.direction, .left)
        XCTAssertEqual(leftResult.distance, 1)
        
        let rightResult = Direction.fromVector(x: 1, y: 0)
        XCTAssertTrue(rightResult.valid)
        XCTAssertEqual(rightResult.direction, .right)
        XCTAssertEqual(rightResult.distance, 1)
    }
    
    func testFromVectorDiagonalDirections() {
        let leftUpResult = Direction.fromVector(x: -1, y: -1)
        XCTAssertTrue(leftUpResult.valid)
        XCTAssertEqual(leftUpResult.direction, .leftUp)
        XCTAssertEqual(leftUpResult.distance, 1)
        
        let rightDownResult = Direction.fromVector(x: 2, y: 2)
        XCTAssertTrue(rightDownResult.valid)
        XCTAssertEqual(rightDownResult.direction, .rightDown)
        XCTAssertEqual(rightDownResult.distance, 2)
    }
    
    func testFromVectorKnightMoves() {
        let leftUpKnightResult = Direction.fromVector(x: -1, y: -2)
        XCTAssertTrue(leftUpKnightResult.valid)
        XCTAssertEqual(leftUpKnightResult.direction, .leftUpKnight)
        XCTAssertEqual(leftUpKnightResult.distance, 1)
        
        let rightUpKnightResult = Direction.fromVector(x: 1, y: -2)
        XCTAssertTrue(rightUpKnightResult.valid)
        XCTAssertEqual(rightUpKnightResult.direction, .rightUpKnight)
        XCTAssertEqual(rightUpKnightResult.distance, 1)
        
        let leftDownKnightResult = Direction.fromVector(x: -1, y: 2)
        XCTAssertTrue(leftDownKnightResult.valid)
        XCTAssertEqual(leftDownKnightResult.direction, .leftDownKnight)
        XCTAssertEqual(leftDownKnightResult.distance, 1)
        
        let rightDownKnightResult = Direction.fromVector(x: 1, y: 2)
        XCTAssertTrue(rightDownKnightResult.valid)
        XCTAssertEqual(rightDownKnightResult.direction, .rightDownKnight)
        XCTAssertEqual(rightDownKnightResult.distance, 1)
    }
    
    func testFromVectorInvalidMoves() {
        // Invalid diagonal (different absolute values for x and y, not knight move)
        let invalidDiagonal = Direction.fromVector(x: 2, y: 3)
        XCTAssertFalse(invalidDiagonal.valid)
        XCTAssertNil(invalidDiagonal.direction)
        
        // Invalid knight-like move (different from standard knight pattern)
        let invalidKnight = Direction.fromVector(x: 3, y: 4)
        XCTAssertFalse(invalidKnight.valid)
        XCTAssertNil(invalidKnight.direction)
        
        // Zero vector
        let zeroVector = Direction.fromVector(x: 0, y: 0)
        XCTAssertFalse(zeroVector.valid)
        XCTAssertNil(zeroVector.direction)
    }
    
    func testFromVectorLongDistance() {
        // Test longer distances in valid directions
        let longUp = Direction.fromVector(x: 0, y: -5)
        XCTAssertTrue(longUp.valid)
        XCTAssertEqual(longUp.direction, .up)
        XCTAssertEqual(longUp.distance, 5)
        
        let longDiagonal = Direction.fromVector(x: -3, y: -3)
        XCTAssertTrue(longDiagonal.valid)
        XCTAssertEqual(longDiagonal.direction, .leftUp)
        XCTAssertEqual(longDiagonal.distance, 3)
    }
    
    // MARK: - 往復変換テスト
    
    func testDeltaToVectorRoundTrip() {
        let allDirections = Direction.allDirections
        
        for direction in allDirections {
            let delta = direction.delta
            let vectorResult = Direction.fromVector(x: delta.x, y: delta.y)
            
            XCTAssertTrue(vectorResult.valid, "Failed for direction: \(direction)")
            XCTAssertEqual(vectorResult.direction, direction, "Failed for direction: \(direction)")
            XCTAssertEqual(vectorResult.distance, 1, "Failed for direction: \(direction)")
        }
    }
}