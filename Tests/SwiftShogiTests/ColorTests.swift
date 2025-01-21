@testable import SwiftShogi
import XCTest

final class ColorTests: XCTestCase {
    func testToggle() {
        var color = Color.black

        color.toggle()
        XCTAssertEqual(color, .white)

        color.toggle()
        XCTAssertEqual(color, .black)
    }

    func testInitializerWithCharacter() {
        let characters: [(character: Character, expected: Color?)] = [
            (Character("b"), .black),
            (Character("w"), .white),
            (Character("z"), nil),
        ]
        for item in characters {
            XCTAssertEqual(Color(character: item.character), item.expected)
        }
    }
}
