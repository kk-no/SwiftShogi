import XCTest
@testable import SwiftShogi

final class RecordTests: XCTestCase {
    
    // MARK: - 棋譜作成テスト
    
    func testRecordCreation() {
        let record = Record()
        XCTAssertNotNil(record)
    }
    
    func testRecordWithPosition() {
        if let position = Position.fromSFEN("lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1") {
            let record = Record(position: position)
            XCTAssertNotNil(record)
        } else {
            XCTFail("Failed to create position for record")
        }
    }
    
    // MARK: - 棋譜ノードテスト
    
    // Note: RecordNode tests removed as they were placeholder tests
    // When RecordNode implementation is complete, specific tests should be added
    
    // MARK: - 棋譜メタデータテスト
    
    func testRecordMetadata() {
        let metadata = RecordMetadata()
        XCTAssertNotNil(metadata)
    }
    
    // MARK: - SFENインポート／エクスポート連携
    
    func testSFENImportExport() {
        let sfenString = "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1"
        
        let importResult = SFENFormatter.importSFEN(sfenString)
        
        switch importResult {
        case .success(let record):
            XCTAssertNotNil(record)
            
            // Test export
            let options = SFENFormatter.USIFormatOptions()
            let exportedUSI = SFENFormatter.exportUSI(record, options: options)
            XCTAssertFalse(exportedUSI.isEmpty)
            
        case .failure(let error):
            XCTFail("Failed to import SFEN: \(error)")
        }
    }
    
    func testUSIImportExport() {
        let usiString = "position startpos moves 7g7f 3c3d"
        
        let importResult = SFENFormatter.importUSI(usiString)
        
        switch importResult {
        case .success(let record):
            XCTAssertNotNil(record)
            
            // Test export
            let options = SFENFormatter.USIFormatOptions()
            let exportedUSI = SFENFormatter.exportUSI(record, options: options)
            XCTAssertFalse(exportedUSI.isEmpty)
            
        case .failure(let error):
            XCTFail("Failed to import USI: \(error)")
        }
    }
    
    // MARK: - 複数手テスト
    
    func testMultipleMoves() {
        let usiString = "position startpos moves 7g7f 3c3d 2g2f 4c4d"
        
        let importResult = SFENFormatter.importUSI(usiString)
        
        switch importResult {
        case .success(let record):
            XCTAssertNotNil(record)
            
            // Export should contain all moves
            let options = SFENFormatter.USIFormatOptions()
            let exportedUSI = SFENFormatter.exportUSI(record, options: options)
            
            XCTAssertTrue(exportedUSI.contains("7g7f"))
            XCTAssertTrue(exportedUSI.contains("3c3d"))
            XCTAssertTrue(exportedUSI.contains("2g2f"))
            XCTAssertTrue(exportedUSI.contains("4c4d"))
            
        case .failure(let error):
            XCTFail("Failed to import USI with multiple moves: \(error)")
        }
    }
    
    // MARK: - エラーハンドリングテスト
    
    func testInvalidSFENImport() {
        let invalidSfen = "invalid_sfen_format"
        
        let result = SFENFormatter.importSFEN(invalidSfen)
        
        switch result {
        case .success:
            XCTFail("Should have failed for invalid SFEN")
        case .failure:
            // Expected
            XCTAssertTrue(true)
        }
    }
    
    func testInvalidUSIImport() {
        let invalidUSI = "invalid_usi_format"
        
        let result = SFENFormatter.importUSI(invalidUSI)
        
        switch result {
        case .success:
            XCTFail("Should have failed for invalid USI")
        case .failure:
            // Expected
            XCTAssertTrue(true)
        }
    }
    
    // MARK: - エクスポートオプションテスト
    
    func testUSIExportOptions() {
        if let position = Position.fromSFEN("lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1") {
            let record = Record(position: position)
            
            // Test export options - simplified version
            let options = SFENFormatter.USIFormatOptions()
            let export = SFENFormatter.exportUSI(record, options: options)
            
            XCTAssertFalse(export.isEmpty)
        }
    }
    
    // MARK: - USENフォーマットテスト
    
    func testUSENExport() {
        if let position = Position.fromSFEN("lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1") {
            let record = Record(position: position)
            let options = SFENFormatter.USENExportOptions()
            
            let usenResult = SFENFormatter.exportUSEN(record, options: options)
            XCTAssertNotNil(usenResult)
            XCTAssertFalse(usenResult.usen.isEmpty)
        }
    }
}