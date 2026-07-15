import XCTest
@testable import SwiftShogi

final class FormatDetectorTests: XCTestCase {
    
    // MARK: - USIフォーマット検出テスト
    
    func testDetectUSIFormat() {
        let usiSamples = [
            "position sfen lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1 moves 7g7f 3c3d",
            "position startpos moves 7g7f 3c3d 2g2f",
            "sfen lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1",
            "moves 7g7f 3c3d 2g2f 4c4d"
        ]
        
        for sample in usiSamples {
            let detected = FormatDetector.detectRecordFormat(sample)
            XCTAssertEqual(detected, .USI, "Failed to detect USI format for: \(sample)")
        }
        
        // "startpos" alone doesn't have the required prefix, it would be detected as something else
        let startposOnly = "startpos"
        let detected = FormatDetector.detectRecordFormat(startposOnly)
        // This will likely be KIF due to frequency matching, which is correct behavior
        XCTAssertTrue([.KIF, .KI2, .CSA].contains(detected))
    }
    
    // MARK: - SFENフォーマット検出テスト
    
    func testDetectSFENFormat() {
        let sfenSamples = [
            "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1",
            "9/9/9/9/9/9/9/9/9 b - 1",
            "4k4/9/9/9/9/9/9/9/4K4 w R2P 10"
        ]
        
        for sample in sfenSamples {
            let detected = FormatDetector.detectRecordFormat(sample)
            XCTAssertEqual(detected, .SFEN, "Failed to detect SFEN format for: \(sample)")
        }
    }
    
    // MARK: - JKFフォーマット検出テスト
    
    func testDetectJKFFormat() {
        let jkfSamples = [
            "{}",
            "{ \"header\": {}, \"moves\": [] }",
            "   { \"game\": \"shogi\" }   ",
            "\n{\n  \"format\": \"jkf\"\n}\n"
        ]
        
        for sample in jkfSamples {
            let detected = FormatDetector.detectRecordFormat(sample)
            XCTAssertEqual(detected, .JKF, "Failed to detect JKF format for: \(sample)")
        }
    }
    
    // MARK: - USENフォーマット検出テスト
    
    func testDetectUSENFormat() {
        let usenSamples = [
            "game_123~1.abc.d~",
            "test-file_2~10.xyz.e",
            "example.name~0.123.a~end"
        ]
        
        for sample in usenSamples {
            let detected = FormatDetector.detectRecordFormat(sample)
            XCTAssertEqual(detected, .USEN, "Failed to detect USEN format for: \(sample)")
        }
    }
    
    // MARK: - KIFフォーマット検出テスト
    
    func testDetectKIFFormat() {
        // Use samples that clearly distinguish KIF from KI2
        let kifSamples = [
            "# 棋譜\n1 ７六歩(77)\n2 ３四歩(33)\n3 ２六歩(27)",
            "開始日時：2023/01/01\n先手：テスト\n1 ７六歩(77)\n2 ３四歩(33)",
            "棋戦：練習対局\n手合割：平手\n1 ７六歩(77)\n2 ３四歩(33)\n3 ２六歩(27)",
            "# KIF形式の棋譜ファイル\n先手：テスト\n後手：テスト2\n手数----指手---------消費時間--\n1 ７六歩(77)   ( 0:00/00:00:00)\n2 ３四歩(33)   ( 0:00/00:00:00)"
        ]
        
        for sample in kifSamples {
            let detected = FormatDetector.detectRecordFormat(sample)
            XCTAssertEqual(detected, .KIF, "Failed to detect KIF format for: \(sample)")
        }
    }
    
    // MARK: - KI2フォーマット検出テスト
    
    func testDetectKI2Format() {
        let ki2Samples = [
            "▲７六歩 △３四歩",
            "☗７六歩 ☖３四歩 ☗２六歩",
            "先手：テスト\n後手：テスト2\n▲７六歩 △３四歩 ▲２六歩\n▲２五歩 △３三角 ▲同角成",
        ]

        for sample in ki2Samples {
            let detected = FormatDetector.detectRecordFormat(sample)
            XCTAssertEqual(detected, .KI2, "Detected \(detected) for KI2 sample: \(sample)")
        }
    }
    
    // MARK: - CSAフォーマット検出テスト
    
    func testDetectCSAFormat() {
        let csaSamples = [
            "V2.2\n+\n+7776FU\n-3334FU",
            "N+テスト\nN-テスト2\n+\n+7776FU",
            "$OPENING:YAGURA\n+2726FU\n-8384FU",
            "PI\n+\n+7776FU\n-3334FU\n+2726FU",
            "'コメント\n+7776FU\n-3334FU"
        ]
        
        for sample in csaSamples {
            let detected = FormatDetector.detectRecordFormat(sample)
            XCTAssertEqual(detected, .CSA, "Failed to detect CSA format for: \(sample)")
        }
    }
    
    // MARK: - フォーマット優先度テスト
    
    func testFormatPriority() {
        // When multiple formats could match, test priority
        
        // USI should take priority over SFEN when USI prefixes are present
        let usiOverSfen = "position sfen lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1"
        XCTAssertEqual(FormatDetector.detectRecordFormat(usiOverSfen), .USI)
        
        // JKF should be detected when JSON structure is present
        let jkfSample = "{ \"moves\": [\"7g7f\", \"3c3d\"] }"
        XCTAssertEqual(FormatDetector.detectRecordFormat(jkfSample), .JKF)
        
        // Pure SFEN should be detected as SFEN
        let pureSfen = "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1"
        XCTAssertEqual(FormatDetector.detectRecordFormat(pureSfen), .SFEN)
    }
    
    // MARK: - 混在コンテンツテスト
    
    func testMixedContent() {
        // Test content that might have characteristics of multiple formats
        
        let mixedKifCsa = """
        # 棋譜ファイル
        開始日時：2023/01/01
        棋戦：練習対局
        手数----指手---------消費時間--
        1 ７六歩(77)   ( 0:00/00:00:00)
        2 ３四歩(33)   ( 0:00/00:00:00)
        """
        
        // Should detect as KIF based on frequency of KIF-specific patterns
        let detected = FormatDetector.detectRecordFormat(mixedKifCsa)
        XCTAssertEqual(detected, .KIF)
    }
    
    // MARK: - エッジケーステスト
    
    func testEmptyString() {
        let empty = ""
        let detected = FormatDetector.detectRecordFormat(empty)
        
        // With 0 matches for all: evalKIF=0, evalKI2=0, evalCSA=0
        // Logic: if evalKIF >= evalCSA && evalKIF >= evalKI2 -> return KIF
        // Since 0 >= 0 is true, KIF is returned
        XCTAssertEqual(detected, .KIF)
    }
    
    func testWhitespaceOnly() {
        let whitespace = "   \n\t  \r\n  "
        let detected = FormatDetector.detectRecordFormat(whitespace)
        
        // With 0 matches for all, KIF wins due to logic: evalKIF >= evalCSA && evalKIF >= evalKI2
        XCTAssertEqual(detected, .KIF)
    }
    
    func testSingleCharacters() {
        let singleChar = "a"
        let detected = FormatDetector.detectRecordFormat(singleChar)
        
        // Should return some format without crashing
        XCTAssertNotNil(detected)
    }
    
    func testUnicodeContent() {
        let unicodeContent = "将棋の棋譜です。７六歩"
        let detected = FormatDetector.detectRecordFormat(unicodeContent)
        
        // Should handle Unicode properly
        XCTAssertNotNil(detected)
    }
    
    // MARK: - 無効・不正形式コンテンツテスト
    
    func testInvalidJSON() {
        let invalidJson = "{ invalid json structure"
        let detected = FormatDetector.detectRecordFormat(invalidJson)
        
        // Should not detect as JKF since it's malformed
        XCTAssertNotEqual(detected, .JKF)
    }
    
    func testInvalidSFEN() {
        let invalidSfen = "invalid/sfen/format b - 1"
        let detected = FormatDetector.detectRecordFormat(invalidSfen)
        
        // Should not detect as SFEN
        XCTAssertNotEqual(detected, .SFEN)
    }
    
    // MARK: - 実世界の例テスト
    
    func testRealWorldKIF() {
        let realKif = """
        # ----  Kifu for Windows95 V3.53 棋譜ファイル  ----
        開始日時：2023/04/01 10:00:00
        棋戦：王位戦
        手合割：平手
        先手：先手プレイヤー
        後手：後手プレイヤー
        手数----指手---------消費時間--
           1 ７六歩(77)   ( 0:00/00:00:00)
           2 ３四歩(33)   ( 0:00/00:00:00)
           3 ２六歩(27)   ( 0:00/00:00:00)
        """
        
        XCTAssertEqual(FormatDetector.detectRecordFormat(realKif), .KIF)
    }
    
    func testRealWorldCSA() {
        let realCsa = """
        V2.2
        N+先手プレイヤー
        N-後手プレイヤー
        $EVENT:練習対局
        $SITE:自宅
        $START_TIME:2023/04/01 10:00:00
        $TIME_LIMIT:00:25+00
        PI
        +
        +7776FU
        -3334FU
        +2726FU
        -4132KI
        +2625FU
        """
        
        XCTAssertEqual(FormatDetector.detectRecordFormat(realCsa), .CSA)
    }
    
    func testRealWorldUSI() {
        let realUsi = "position startpos moves 7g7f 3c3d 2g2f 4c4d 2f2e 2b2c 6i7h 8b4b 5i6h"
        
        XCTAssertEqual(FormatDetector.detectRecordFormat(realUsi), .USI)
    }
    
    // MARK: - フォーマット列挙型テスト
    
    func testRecordFormatTypeRawValues() {
        XCTAssertEqual(RecordFormatType.USI.rawValue, "USI")
        XCTAssertEqual(RecordFormatType.SFEN.rawValue, "SFEN")
        XCTAssertEqual(RecordFormatType.KIF.rawValue, "KIF")
        XCTAssertEqual(RecordFormatType.KI2.rawValue, "KI2")
        XCTAssertEqual(RecordFormatType.CSA.rawValue, "CSA")
        XCTAssertEqual(RecordFormatType.JKF.rawValue, "JKF")
        XCTAssertEqual(RecordFormatType.USEN.rawValue, "USEN")
    }
    
    func testAllFormatTypes() {
        let allFormats: [RecordFormatType] = [.USI, .SFEN, .KIF, .KI2, .CSA, .JKF, .USEN]
        
        for format in allFormats {
            // Each format should have a non-empty raw value
            XCTAssertFalse(format.rawValue.isEmpty)
        }
    }
}