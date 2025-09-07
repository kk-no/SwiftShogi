import XCTest
@testable import SwiftShogi

final class UtilityTests: XCTestCase {
    
    // MARK: - ユーティリティ関数テスト
    // Note: Placeholder tests removed as they provided no value
    // When actual utility functions are implemented, specific tests should be added
    
    // MARK: - フォーマットエラーテスト
    
    func testFormatErrorCreation() {
        let error = FormatError(message: "Test error message")
        XCTAssertEqual(error.localizedDescription, "Test error message")
    }
    
    func testFormatErrorEquality() {
        let error1 = FormatError(message: "Same message")
        let error2 = FormatError(message: "Same message")
        let error3 = FormatError(message: "Different message")
        
        XCTAssertEqual(error1.localizedDescription, error2.localizedDescription)
        XCTAssertNotEqual(error1.localizedDescription, error3.localizedDescription)
    }
}