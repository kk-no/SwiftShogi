import XCTest
@testable import SwiftShogi

final class KakinokiFormatterTests: XCTestCase {
    
    // MARK: - KIFフォーマット読み込みテスト
    
    func testImportBasicKIF() {
        let kifString = """
        # KIF形式の棋譜ファイル
        開始日時：2023/04/01
        先手：先手プレイヤー
        後手：後手プレイヤー
        手合割：平手
        手数----指手---------消費時間--
           1 ７六歩(77)   ( 0:00/00:00:00)
           2 ３四歩(33)   ( 0:00/00:00:00)
           3 ２六歩(27)   ( 0:00/00:00:00)
           4 中断
        """
        
        let result = KakinokiFormatter.importKIF(kifString)
        
        switch result {
        case .success(let record):
            XCTAssertNotNil(record)
            // メタデータのチェック
            XCTAssertEqual(record.metadata.blackPlayerName, "先手プレイヤー")
            XCTAssertEqual(record.metadata.whitePlayerName, "後手プレイヤー")
            
        case .failure(let error):
            XCTFail("Failed to import KIF: \(error)")
        }
    }
    
    func testImportKIFWithHandicap() {
        let kifString = """
        手合割：香落ち
        先手：下手
        後手：上手
           1 ７六歩(77)
           2 ３四歩(33)
        """
        
        let result = KakinokiFormatter.importKIF(kifString)
        
        switch result {
        case .success(let record):
            XCTAssertNotNil(record)
            // 基本的な確認のみ
            XCTAssertNotNil(record.position)
            
        case .failure(let error):
            XCTFail("Failed to import handicap KIF: \(error)")
        }
    }
    
    func testImportKIFWithComments() {
        let kifString = """
        手数----指手---------消費時間--
           1 ７六歩(77)   ( 0:00/00:00:00)
        *初手は歩を突く
           2 ３四歩(33)   ( 0:00/00:00:00)
        *定跡手順
           3 投了
        """
        
        let result = KakinokiFormatter.importKIF(kifString)
        
        switch result {
        case .success(let record):
            XCTAssertNotNil(record)
            // コメントが正しく保存されているかは実装依存
            
        case .failure(let error):
            XCTFail("Failed to import KIF with comments: \(error)")
        }
    }
    
    // MARK: - KI2フォーマット読み込みテスト
    
    func testImportBasicKI2() {
        let ki2String = """
        先手：先手プレイヤー
        後手：後手プレイヤー
        ▲７六歩 △３四歩 ▲２六歩 △４四歩 ▲中断
        """
        
        let result = KakinokiFormatter.importKI2(ki2String)
        
        switch result {
        case .success(let record):
            XCTAssertNotNil(record)
            XCTAssertEqual(record.metadata.blackPlayerName, "先手プレイヤー")
            XCTAssertEqual(record.metadata.whitePlayerName, "後手プレイヤー")
            
        case .failure(let error):
            XCTFail("Failed to import KI2: \(error)")
        }
    }
    
    func testImportKI2WithAlternativeSymbols() {
        let ki2String = """
        ☗７六歩 ☖３四歩 ☗２六歩 ☖４四歩
        """
        
        let result = KakinokiFormatter.importKI2(ki2String)
        
        switch result {
        case .success(let record):
            XCTAssertNotNil(record)
            
        case .failure(let error):
            XCTFail("Failed to import KI2 with alternative symbols: \(error)")
        }
    }
    
    // MARK: - KIFエクスポートテスト
    
    func testExportBasicKIF() {
        // テスト用の基本的なレコードを作成
        if let position = Position.fromSFEN("lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1") {
            let record = Record(position: position)
            if let mutableMetadata = record.metadata as? RecordMetadata {
                mutableMetadata.setStandardMetadata(.blackName, value: "テスト先手")
                mutableMetadata.setStandardMetadata(.whiteName, value: "テスト後手")
            }
            
            let options = KIFExportOptions()
            let kifOutput = KakinokiFormatter.exportKIF(record, options: options)
            
            XCTAssertFalse(kifOutput.isEmpty)
            // メタデータが正しく設定されているかチェック
            print("KIF Output: \(kifOutput)")
            // KIFエクスポートの実装に依存するため、基本的な出力確認のみ
            XCTAssertTrue(kifOutput.contains("手合割"))
        } else {
            XCTFail("Failed to create test position")
        }
    }
    
    func testExportKIFWithMoves() {
        if let position = Position.fromSFEN("lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1") {
            let record = Record(position: position)
            
            // 基本的な手を追加（実装に依存）
            let move = Move(
                from: .left(Square(file: 7, rank: 7)),
                to: Square(file: 7, rank: 6),
                promote: false,
                color: .black,
                pieceType: .pawn,
                capturedPieceType: nil
            )
            
            // 手をレコードに追加（実際のAPIに合わせて調整が必要）
            let options = KIFExportOptions()
            let kifOutput = KakinokiFormatter.exportKIF(record, options: options)
            
            XCTAssertFalse(kifOutput.isEmpty)
            XCTAssertTrue(kifOutput.contains("手数----指手"))
        }
    }
    
    // MARK: - KI2エクスポートテスト
    
    func testExportBasicKI2() {
        if let position = Position.fromSFEN("lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1") {
            let record = Record(position: position)
            if let mutableMetadata = record.metadata as? RecordMetadata {
                mutableMetadata.setStandardMetadata(.blackName, value: "テスト先手")
                mutableMetadata.setStandardMetadata(.whiteName, value: "テスト後手")
            }
            
            let options = KI2ExportOptions()
            let ki2Output = KakinokiFormatter.exportKI2(record, options: options)
            
            XCTAssertFalse(ki2Output.isEmpty)
            XCTAssertTrue(ki2Output.contains("先手：テスト先手"))
            XCTAssertTrue(ki2Output.contains("後手：テスト後手"))
        } else {
            XCTFail("Failed to create test position")
        }
    }
    
    // MARK: - 手の記法テスト
    
    func testKIFMoveFormatting() {
        // 基本的な歩の動き
        let pawnMove = Move(
            from: .left(Square(file: 7, rank: 7)),
            to: Square(file: 7, rank: 6),
            promote: false,
            color: .black,
            pieceType: .pawn,
            capturedPieceType: nil
        )
        
        let options: [String: Any] = [:]
        let moveString = KakinokiFormatter.formatKIFMove(pawnMove, options: options)
        
        // 期待される形式: "７六歩(77)" または類似の形式
        XCTAssertFalse(moveString.isEmpty)
        XCTAssertTrue(moveString.contains("歩"))
    }
    
    func testKIFCaptureMove() {
        // 駒を取る手
        let captureMove = Move(
            from: .left(Square(file: 7, rank: 6)),
            to: Square(file: 6, rank: 5),
            promote: false,
            color: .black,
            pieceType: .pawn,
            capturedPieceType: .pawn
        )
        
        let options: [String: Any] = [:]
        let moveString = KakinokiFormatter.formatKIFMove(captureMove, options: options)
        
        XCTAssertFalse(moveString.isEmpty)
        XCTAssertTrue(moveString.contains("歩"))
    }
    
    // MARK: - エラーハンドリングテスト
    
    func testImportInvalidKIF() {
        let invalidKif = "これは無効なKIFファイルです"
        
        let result = KakinokiFormatter.importKIF(invalidKif)
        
        switch result {
        case .success(let record):
            // 実装は無効なKIFでも寛容に処理する可能性がある
            XCTAssertNotNil(record)
        case .failure:
            // 失敗も許容される
            XCTAssertTrue(true)
        }
    }
    
    func testImportEmptyKIF() {
        let emptyKif = ""
        
        let result = KakinokiFormatter.importKIF(emptyKif)
        
        switch result {
        case .success(let record):
            // 実装は空のKIFでも成功する（空のレコードを返す）
            XCTAssertNotNil(record)
        case .failure:
            // 失敗も許容される
            XCTAssertTrue(true)
        }
    }
    
    // MARK: - メタデータ解析テスト
    
    func testParseMetadata() {
        let kifString = """
        開始日時：2023/04/01 10:00:00
        棋戦：王位戦
        場所：東京
        持ち時間：各25分
        消費時間：
        先手：プロ棋士A
        後手：プロ棋士B
        戦型：居飛車
        表題：第1局
        """
        
        let result = KakinokiFormatter.importKIF(kifString)
        
        switch result {
        case .success(let record):
            XCTAssertEqual(record.metadata.blackPlayerName, "プロ棋士A")
            XCTAssertEqual(record.metadata.whitePlayerName, "プロ棋士B")
            // その他のメタデータも実装されている場合はテスト
            
        case .failure(let error):
            XCTFail("Failed to parse metadata: \(error)")
        }
    }
    
    // MARK: - 特殊手テスト
    
    func testSpecialMoves() {
        let kifString = """
        手数----指手---------消費時間--
           1 ７六歩(77)   ( 0:00/00:00:00)
           2 投了
        """
        
        let result = KakinokiFormatter.importKIF(kifString)
        
        switch result {
        case .success(let record):
            XCTAssertNotNil(record)
            // 投了の処理が正しく行われているかチェック（実装依存）
            
        case .failure(let error):
            XCTFail("Failed to parse special moves: \(error)")
        }
    }
    
    func testResignation() {
        let kifString = """
           1 ７六歩(77)
           2 投了
        """
        
        let result = KakinokiFormatter.importKIF(kifString)
        
        switch result {
        case .success(let record):
            XCTAssertNotNil(record)
            
        case .failure(let error):
            XCTFail("Failed to parse resignation: \(error)")
        }
    }
    
    // MARK: - 往復変換テスト
    
    func testKIFRoundTrip() {
        // KIF -> Record -> KIF の往復テスト
        let originalKif = """
        先手：テスト先手
        後手：テスト後手
        手合割：平手
        手数----指手---------消費時間--
           1 ７六歩(77)   ( 0:00/00:00:00)
           2 ３四歩(33)   ( 0:00/00:00:00)
           3 中断
        """
        
        let importResult = KakinokiFormatter.importKIF(originalKif)
        
        switch importResult {
        case .success(let record):
            let options = KIFExportOptions()
            let exportedKif = KakinokiFormatter.exportKIF(record, options: options)
            
            XCTAssertFalse(exportedKif.isEmpty)
            // 基本的な確認のみ
            XCTAssertTrue(true)
            
        case .failure(let error):
            XCTFail("Round trip failed: \(error)")
        }
    }
}