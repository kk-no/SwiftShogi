import SwiftShogi
import XCTest

final class GamePerformanceTests: XCTestCase {
    func testValidMoves() {
        let game = Game(sfen: .default)
        measure {
            _ = game.validMoves()
        }
    }
}
