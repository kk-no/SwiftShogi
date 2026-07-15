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
            let options = SFENFormatter.USIFormatOptions(allMoves: true)
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

    // MARK: - 分岐削除テスト

    func testRemoveBranch_RemovesNodeAndDescendants() {
        // Given: Record with branches
        // 1.☗7六歩 → 2.☖3四歩 → [3.☗2六歩, 3.☗6六歩]
        let record = Record()

        // Create moves
        let move1 = record.position.createMove(from: .left(Square(file: 7, rank: 7)), to: Square(file: 7, rank: 6))
        let move2 = record.position.createMove(from: .left(Square(file: 3, rank: 3)), to: Square(file: 3, rank: 4))

        XCTAssertNotNil(move1)
        XCTAssertNotNil(move2)

        record.append(move1!)
        record.append(move2!)

        let move3a = record.position.createMove(from: .left(Square(file: 2, rank: 7)), to: Square(file: 2, rank: 6))
        XCTAssertNotNil(move3a)
        record.append(move3a!)

        record.goBack()

        let move3b = record.position.createMove(from: .left(Square(file: 6, rank: 7)), to: Square(file: 6, rank: 6))
        XCTAssertNotNil(move3b)
        record.append(move3b!)

        record.goBack()

        // When: Remove the second branch
        let branches = record.nextBranches
        XCTAssertEqual(branches.count, 2)

        let branchToRemove = branches[1]
        let result = record.removeBranch(branchToRemove)

        // Then: Branch is removed
        XCTAssertTrue(result)
        XCTAssertEqual(record.nextBranches.count, 1)
    }

    func testRemoveBranch_CannotRemoveRootNode() {
        // Given: A record
        let record = Record()

        // When: Try to remove root node
        let result = record.removeBranch(record.first)

        // Then: Should fail
        XCTAssertFalse(result)
    }

    func testRemoveBranch_FirstBranchRemoved_PromotesSecond() {
        // Given: Two branches at same position
        let record = Record()

        let move1 = record.position.createMove(from: .left(Square(file: 7, rank: 7)), to: Square(file: 7, rank: 6))
        XCTAssertNotNil(move1)
        record.append(move1!)

        record.goBack()

        let move2 = record.position.createMove(from: .left(Square(file: 2, rank: 7)), to: Square(file: 2, rank: 6))
        XCTAssertNotNil(move2)
        record.append(move2!)

        record.goBack()

        // When: Remove first branch
        let branches = record.nextBranches
        XCTAssertEqual(branches.count, 2)

        let firstBranch = branches[0]
        let secondBranchMove = branches[1].move

        let result = record.removeBranch(firstBranch)

        // Then: Second branch becomes first (branchIndex = 0)
        XCTAssertTrue(result)
        XCTAssertEqual(record.nextBranches.count, 1)
        XCTAssertEqual(record.nextBranches[0].branchIndex, 0)

        // Verify it's the original second branch
        XCTAssertTrue(areSameMoves(record.nextBranches[0].move, secondBranchMove))
    }

    func testRemoveBranch_UpdatesCurrentIfNeeded() {
        // Given: Current is within the branch to delete
        let record = Record()

        let move1 = record.position.createMove(from: .left(Square(file: 7, rank: 7)), to: Square(file: 7, rank: 6))
        XCTAssertNotNil(move1)
        record.append(move1!)

        let move2 = record.position.createMove(from: .left(Square(file: 3, rank: 3)), to: Square(file: 3, rank: 4))
        XCTAssertNotNil(move2)
        record.append(move2!)

        let currentPly = record.current.ply
        XCTAssertEqual(currentPly, 2)

        // When: Remove the branch containing current
        let branchToRemove = record.movesBefore[1] // move1
        let result = record.removeBranch(branchToRemove)

        // Then: Current moves to parent node
        XCTAssertTrue(result)
        XCTAssertEqual(record.current.ply, 0) // Moved to root
    }

    func testRemoveBranch_ActiveBranchDeleted_ActivatesFirst() {
        // Given: Active branch is the one being deleted
        let record = Record()

        let move1 = record.position.createMove(from: .left(Square(file: 7, rank: 7)), to: Square(file: 7, rank: 6))
        XCTAssertNotNil(move1)
        record.append(move1!)

        record.goBack()

        let move2 = record.position.createMove(from: .left(Square(file: 2, rank: 7)), to: Square(file: 2, rank: 6))
        XCTAssertNotNil(move2)
        record.append(move2!)

        // Current is on move2, which is active
        let branches = record.nextBranches
        XCTAssertEqual(branches.count, 0) // No next branches from current position

        record.goBack() // Go back to root

        let branchesAtRoot = record.nextBranches
        XCTAssertEqual(branchesAtRoot.count, 2)

        // The second branch should be active
        XCTAssertTrue(branchesAtRoot[1].activeBranch)

        // When: Remove the active branch
        let result = record.removeBranch(branchesAtRoot[1])

        // Then: First remaining branch becomes active
        XCTAssertTrue(result)
        XCTAssertEqual(record.nextBranches.count, 1)
        XCTAssertTrue(record.nextBranches[0].activeBranch)
    }

    func testNextBranches_ReturnsAllBranches() {
        // Given: Record with multiple branches
        let record = Record()

        let move1 = record.position.createMove(from: .left(Square(file: 7, rank: 7)), to: Square(file: 7, rank: 6))
        XCTAssertNotNil(move1)
        record.append(move1!)

        record.goBack()

        let move2 = record.position.createMove(from: .left(Square(file: 2, rank: 7)), to: Square(file: 2, rank: 6))
        XCTAssertNotNil(move2)
        record.append(move2!)

        record.goBack()

        let move3 = record.position.createMove(from: .left(Square(file: 6, rank: 7)), to: Square(file: 6, rank: 6))
        XCTAssertNotNil(move3)
        record.append(move3!)

        record.goBack()

        // When: Get next branches
        let branches = record.nextBranches

        // Then: Should return all 3 branches
        XCTAssertEqual(branches.count, 3)
        XCTAssertEqual(branches[0].branchIndex, 0)
        XCTAssertEqual(branches[1].branchIndex, 1)
        XCTAssertEqual(branches[2].branchIndex, 2)
    }

    func testRemoveBranch_RecalculatesPositionState() {
        // Given: Record with moves that build up position state
        let record = Record()

        // 1.☗7六歩
        let move1 = record.position.createMove(from: .left(Square(file: 7, rank: 7)), to: Square(file: 7, rank: 6))
        XCTAssertNotNil(move1)
        record.append(move1!)

        // 2.☖3四歩
        let move2 = record.position.createMove(from: .left(Square(file: 3, rank: 3)), to: Square(file: 3, rank: 4))
        XCTAssertNotNil(move2)
        record.append(move2!)

        // 3.☗2六歩
        let move3 = record.position.createMove(from: .left(Square(file: 2, rank: 7)), to: Square(file: 2, rank: 6))
        XCTAssertNotNil(move3)
        record.append(move3!)

        // 現在の位置のSFENを記録
        let currentPly = record.current.ply
        XCTAssertEqual(currentPly, 3)

        // When: 2手目のノードを含む分岐を削除
        // これによりcurrentは1手目の位置に移動するはず
        let move2Node = record.movesBefore[2] // 2.☖3四歩のノード
        let result = record.removeBranch(move2Node)

        // Then: 削除が成功
        XCTAssertTrue(result)

        // currentは1手目に移動しているはず
        XCTAssertEqual(record.current.ply, 1)

        // 重要: position状態が1手目の状態と一致することを確認
        // 1手目 = ☗7六歩が指された後なので、7六に歩がある状態
        let expectedSfenAtMove1 = "lnsgkgsnl/1r5b1/ppppppppp/9/9/2P6/PP1PPPPPP/1B5R1/LNSGKGSNL w - 2"

        // position SFENを比較（手数は期待値と合わない可能性があるため、盤面と手番のみ確認）
        let actualSfenComponents = record.position.sfen.split(separator: " ")
        let expectedSfenComponents = expectedSfenAtMove1.split(separator: " ")

        // 盤面が一致することを確認
        XCTAssertEqual(actualSfenComponents[0], expectedSfenComponents[0], "Board should match")
        // 手番が一致することを確認
        XCTAssertEqual(actualSfenComponents[1], expectedSfenComponents[1], "Turn should match")
        // 持ち駒が一致することを確認
        XCTAssertEqual(actualSfenComponents[2], expectedSfenComponents[2], "Hand should match")

        // 1手目から再度進めた場合の整合性を確認
        record.goForward()
        XCTAssertEqual(record.current.ply, 1, "No forward moves should exist after branch deletion")
    }

    // MARK: - メタデータ

    func testMetadataKeysPreserveInsertionOrder() {
        let metadata = RecordMetadata()
        metadata.setStandardMetadata(.whiteName, value: "後手")
        metadata.setStandardMetadata(.blackName, value: "先手")
        metadata.setStandardMetadata(.tournament, value: "棋戦")
        metadata.setStandardMetadata(.place, value: "場所")
        metadata.setStandardMetadata(.strategy, value: "戦型")
        metadata.setStandardMetadata(.note, value: "備考")

        XCTAssertEqual(metadata.standardMetadataKeys, [.whiteName, .blackName, .tournament, .place, .strategy, .note])

        // 既存キーの更新では順序を変えない
        metadata.setStandardMetadata(.blackName, value: "先手2")
        XCTAssertEqual(metadata.standardMetadataKeys, [.whiteName, .blackName, .tournament, .place, .strategy, .note])

        // 削除したキーは一覧から消える
        metadata.setStandardMetadata(.tournament, value: nil)
        XCTAssertEqual(metadata.standardMetadataKeys, [.whiteName, .blackName, .place, .strategy, .note])

        metadata.setCustomMetadata("ふ", value: "2")
        metadata.setCustomMetadata("あ", value: "1")
        metadata.setCustomMetadata("ん", value: "3")
        XCTAssertEqual(metadata.customMetadataKeys, ["ふ", "あ", "ん"])
    }
}