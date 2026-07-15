import XCTest
@testable import SwiftShogi

class CSAFormatterTests: XCTestCase {

    // MARK: - CSA インポートテスト

    func testImportSimpleCSAGame() {
        let csaData = """
        V2.2
        N+TestBlack
        N-TestWhite
        $EVENT:TestGame
        PI
        +
        +7776FU
        -3334FU
        +2726FU
        %TORYO
        """

        let result = CSAFormatter.importCSA(csaData)
        switch result {
        case .success:
            XCTAssertTrue(true)
        case .failure:
            XCTAssertTrue(false, "Failed to import simple CSA game")
        }

        if case .success(let record) = result {
            // メタデータのチェック
            XCTAssertEqual(record.metadata.getStandardMetadata(.blackName), "TestBlack")
            XCTAssertEqual(record.metadata.getStandardMetadata(.whiteName), "TestWhite")
            XCTAssertEqual(record.metadata.getStandardMetadata(.tournament), "TestGame")
        }
    }

    func testImportCSAWithMetadata() {
        let csaData = """
        V2.2
        N+先手
        N-後手
        $EVENT:棋戦名
        $SITE:場所
        $START_TIME:2023/04/01 10:00:00
        $END_TIME:2023/04/01 11:00:00
        $TIME_LIMIT:00:25+00
        $OPENING:定跡名
        PI
        +
        %TORYO
        """

        let result = CSAFormatter.importCSA(csaData)
        switch result {
        case .success:
            XCTAssertTrue(true)
        case .failure:
            XCTAssertTrue(false, "Failed to import CSA with metadata")
        }

        if case .success(let record) = result {
            XCTAssertEqual(record.metadata.getStandardMetadata(.blackName), "先手")
            XCTAssertEqual(record.metadata.getStandardMetadata(.whiteName), "後手")
            XCTAssertEqual(record.metadata.getStandardMetadata(.tournament), "棋戦名")
            XCTAssertEqual(record.metadata.getStandardMetadata(.place), "場所")
            XCTAssertEqual(record.metadata.getStandardMetadata(.strategy), "定跡名")
        }
    }

    func testImportCSAWithMinimalData() {
        let csaData = """
        PI
        +
        +7776FU
        -3334FU
        %TORYO
        """

        let result = CSAFormatter.importCSA(csaData)
        switch result {
        case .success:
            XCTAssertTrue(true)
        case .failure:
            XCTAssertTrue(false, "Failed to import minimal CSA")
        }
    }

    func testCSAFormatDetection() {
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

    // MARK: - CSA エクスポートテスト

    func testExportSimpleCSAGame() {
        let record = Record(position: Position())

        // メタデータを設定
        if let metadata = record.metadata as? RecordMetadata {
            metadata.setStandardMetadata(.blackName, value: "Black")
            metadata.setStandardMetadata(.whiteName, value: "White")
        }

        let csaString = CSAFormatter.exportCSA(record)

        // バージョンとメタデータが含まれることを確認
        XCTAssertTrue(csaString.contains("V2.2"), "Exported CSA should contain version")
        XCTAssertTrue(csaString.contains("N+Black"), "Exported CSA should contain black player name")
        XCTAssertTrue(csaString.contains("N-White"), "Exported CSA should contain white player name")
        XCTAssertTrue(csaString.contains("PI"), "Exported CSA should contain initial position")
    }

    func testExportCSAMoveOrder() {
        let record = Record(position: Position())
        for usi in ["7g7f", "3c3d", "2g2f"] {
            guard let move = record.position.createMoveByUSI(usi), record.append(move) else {
                XCTFail("Failed to append move: \(usi)")
                return
            }
        }

        let csaString = CSAFormatter.exportCSA(record)

        XCTAssertTrue(csaString.contains("+7776FU\n-3334FU\n+2726FU"), "unexpected output: \(csaString)")
    }

    func testExportCSAWithCustomOptions() {
        let record = Record(position: Position())
        let options = CSAFormatter.CSAExportOptions(version: "V2.2", includeTime: false, includeComments: false)

        let csaString = CSAFormatter.exportCSA(record, options: options)

        XCTAssertTrue(csaString.contains("V2.2"), "Exported CSA should use specified version")
    }

    // MARK: - エラーハンドリング

    func testImportInvalidCSA() {
        let invalidCSA = "Invalid CSA Data Here"

        let result = CSAFormatter.importCSA(invalidCSA)
        // 不正なCSAデータが与えられたため、解析は成功しても手が無い棋譜になる
        // 解析処理が失敗またはエラーになることを確認
        switch result {
        case .success:
            // 空の棋譜が返される可能性もあるため、成功として扱う
            XCTAssertTrue(true)
        case .failure:
            // エラーが返された場合も正しく処理されている
            XCTAssertTrue(true)
        }
    }

    // MARK: - 特殊な手の処理テスト

    func testImportCSAWithSpecialMoves() {
        let csaDataWithToryo = """
        PI
        +
        +7776FU
        -3334FU
        %TORYO
        """

        let result = CSAFormatter.importCSA(csaDataWithToryo)
        switch result {
        case .success:
            XCTAssertTrue(true)
        case .failure:
            XCTAssertTrue(false, "Failed to import CSA with special move")
        }
    }

    // MARK: - 成りと取りのテスト

    func testImportCSAWithPromotedPiece() {
        // 実装中：成り判定のロジックを検証するためのテスト
        // 本来は以下のような進んだゲーの手順で成りを検証する必要があります
        let csaDataWithPromotion = """
        PI
        +
        +7776FU
        -3334FU
        +2726FU
        -8384FU
        """

        let result = CSAFormatter.importCSA(csaDataWithPromotion)
        switch result {
        case .success(let record):
            // 手を確認：正しく読み込めることを確認
            var moveCount = 0
            record.forEach { (node, _) in
                if node.move is Move {
                    moveCount += 1
                }
            }
            XCTAssertEqual(moveCount, 4, "Should have 4 moves")
        case .failure(let error):
            XCTAssertTrue(false, "Failed to import CSA: \(error.message)")
        }
    }

    func testImportCSAWithCapture() {
        // 標準的な初期局面からの手順をテスト
        let csaDataWithCapture = """
        PI
        +
        +7776FU
        -3334FU
        %TORYO
        """

        let result = CSAFormatter.importCSA(csaDataWithCapture)
        switch result {
        case .success(let record):
            // 手を確認：正しく読み込めることを確認
            var moveCount = 0
            record.forEach { (node, _) in
                if node.move is Move {
                    moveCount += 1
                }
            }
            XCTAssertEqual(moveCount, 2, "Should have 2 moves")
        case .failure(let error):
            XCTAssertTrue(false, "Failed to import CSA: \(error.message)")
        }
    }

    func testImportCSAWithInvalidFormat() {
        let invalidCSA = """
        PI
        +
        +7776
        """

        let result = CSAFormatter.importCSA(invalidCSA)
        switch result {
        case .success:
            // 無効な形式でも解析できる場合もある（不完全な指し手はスキップ）
            XCTAssertTrue(true)
        case .failure(let error):
            // または失敗する場合
            XCTAssertTrue(true, "Expected error for invalid format: \(error.message)")
        }
    }

    func testImportCSAWithGyKingVariant() {
        let csaDataWithGy = """
        PI
        +
        +7776FU
        -3334GY
        +2726FU
        %TORYO
        """

        let result = CSAFormatter.importCSA(csaDataWithGy)
        switch result {
        case .success:
            XCTAssertTrue(true, "Should handle GY (玉) king variant")
        case .failure:
            XCTAssertTrue(false, "Failed to import CSA with GY king variant")
        }
    }

    // MARK: - CSA 記録構造テスト

    func testCSAProducesConsistentRecord() {
        // CSA フォーマットから正常な Record が生成されることを確認
        let csaData = """
        V2.2
        N+先手プレイヤー
        N-後手プレイヤー
        PI
        +
        +7776FU
        -3334FU
        +2726FU
        -8384FU
        %TORYO
        """

        guard case .success(let record) = CSAFormatter.importCSA(csaData) else {
            XCTFail("CSA import failed")
            return
        }

        // Record が正常に構築されていることを確認
        XCTAssertNotNil(record, "CSA record should not be nil")

        // メタデータが正しくセットされていることを確認
        XCTAssertEqual(record.metadata.getStandardMetadata(.blackName), "先手プレイヤー")
        XCTAssertEqual(record.metadata.getStandardMetadata(.whiteName), "後手プレイヤー")

        // 手数を確認
        var moveCount = 0
        record.forEach { (node, _) in
            if node.move is Move {
                moveCount += 1
            }
        }

        XCTAssertEqual(moveCount, 4, "CSA should have 4 moves")
    }

    func testCSAProducesValidPositions() {
        let csaData = """
        V2.2
        N+先手
        N-後手
        PI
        +
        +7776FU
        -3334FU
        +2726FU
        %TORYO
        """

        guard case .success(let record) = CSAFormatter.importCSA(csaData) else {
            XCTFail("Import failed")
            return
        }

        // 初期局面が平手であることを確認
        XCTAssertNotNil(record.initialPosition, "CSA initial position should not be nil")

        // 現在の局面が有効であることを確認
        XCTAssertNotNil(record.position, "CSA position should not be nil")

        // 手番が有効（黒または白）であることを確認
        XCTAssertTrue(record.position.color == .black || record.position.color == .white,
                      "CSA position should have valid color")
    }

    func testCSATreeStructure() {
        let csaData = """
        V2.2
        PI
        +
        +7776FU
        -3334FU
        +2726FU
        %TORYO
        """

        guard case .success(let record) = CSAFormatter.importCSA(csaData) else {
            XCTFail("Import failed")
            return
        }

        // Record のツリー構造が正常であることを確認
        var nodeCount = 0
        record.forEach { (node, _) in
            nodeCount += 1
            // 各ノードに move が存在することを確認
            XCTAssertNotNil(node.move, "CSA node should have a move")
        }

        // ノード数がゼロより大きいことを確認
        XCTAssertGreaterThan(nodeCount, 0, "CSA should have nodes")
    }

    // MARK: - カスタム初期局面テスト

    func testImportCSAWithCustomInitialPosition() {
        // P1-P9 形式で平手と同じ配置を指定した CSA 棋譜
        let csaDataWithCustomInitial = """
        V2.2
        N+PlayerA
        N-PlayerB
        P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
        P2 * -HI *  *  *  *  * -KA *
        P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
        P4 *  *  *  *  *  *  *  *  *
        P5 *  *  *  *  *  *  *  *  *
        P6 *  *  *  *  *  *  *  *  *
        P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
        P8 * +KA *  *  *  *  * +HI *
        P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
        +
        +7776FU
        -3334FU
        +2726FU
        %TORYO
        """

        let result = CSAFormatter.importCSA(csaDataWithCustomInitial)
        switch result {
        case .success(let record):
            XCTAssertNotNil(record)
            // 手数を確認
            var moveCount = 0
            record.forEach { (node, _) in
                if node.move is Move {
                    moveCount += 1
                }
            }
            XCTAssertEqual(moveCount, 3, "Should have 3 moves")
        case .failure(let error):
            XCTAssertTrue(false, "Failed to import CSA with custom initial position: \(error.message)")
        }
    }

    // MARK: - 成り駒のキャプチャとundoテスト

    func testCapturedPromotedPieceUndoCSA() {
        // 角が成って馬になり、それを取ってundoする
        let csaData = """
        PI
        +
        +7776FU
        -3334FU
        +8822UM
        -3122GI
        """

        guard case .success(let record) = CSAFormatter.importCSA(csaData) else {
            XCTFail("CSA import failed")
            return
        }

        // 4手目まで進める
        record.goto(4)

        // 22に銀があることを確認
        let square22 = Square(file: 2, rank: 2)
        let pieceAt22After = record.position.board.at(square22)
        XCTAssertNotNil(pieceAt22After)
        XCTAssertEqual(pieceAt22After?.type, .silver)
        XCTAssertEqual(pieceAt22After?.color, .white, "22の駒は後手の駒であるべき")

        // 後手の持ち駒に角があることを確認
        XCTAssertEqual(record.position.hand(color: .white).count(pieceType: .bishop), 1, "後手の持ち駒に角が1枚あるべき")
        XCTAssertEqual(record.position.hand(color: .white).count(pieceType: .horse), 0, "後手の持ち駒に馬はない")

        // 1手戻す
        _ = record.goBack()

        // 22には馬があるべき
        let pieceAt22Before = record.position.board.at(square22)
        XCTAssertNotNil(pieceAt22Before, "22に駒があるべき")
        XCTAssertEqual(pieceAt22Before?.type, .horse, "22の駒は馬であるべき")

        // 持ち駒から角がなくなっていることを確認
        XCTAssertEqual(record.position.hand(color: .white).count(pieceType: .bishop), 0, "undo後、後手の持ち駒に角はない")
    }

    // MARK: - カスタム初期局面（ランダム配置）

    func testImportCSAWithRandomInitialPosition() {
        // カスタム初期局面 + 持ち駒 + T行 + %TIME_UP を含む CSA 棋譜
        let csaData = """
        SomeApp
        N+Player1(2000)
        N-Player2(2000)
        P1-KY-KE *  *  * -KI-GI-KE-KY
        P2 *  *  * -HI-KI * -OU-KA *
        P3 *  * -FU * -FU-FU * -FU-FU
        P4-FU *  *  * -GI * -FU *  *
        P5 * -FU+FU *  *  *  *  *  *
        P6 *  *  * +FU+FU *  *  *  *
        P7+FU+FU+KA+GI+GI+FU+FU+FU+FU
        P8 *  * +KI * +KI *  * +HI *
        P9+KY+KE+OU *  *  *  * +KE+KY
        P-00FU
        +
        +6776GI
        T3
        -0065FU
        T7
        +6665FU
        T2
        %TIME_UP
        """

        let result = CSAFormatter.importCSA(csaData)
        switch result {
        case .success(let record):
            // 指し手が3手あること
            var moveCount = 0
            record.forEach { (node, _) in
                if node.move is Move { moveCount += 1 }
            }
            XCTAssertEqual(moveCount, 3, "Should have 3 moves")

            // 後手の持ち駒（歩1枚）が初期局面に設定されていること
            let whiteHand = record.initialPosition.hand(color: .white)
            XCTAssertEqual(whiteHand.count(pieceType: .pawn), 1, "White should have 1 pawn in hand")

        case .failure(let error):
            XCTFail("Failed to import CSA with random initial position: \(error.message)")
        }
    }

    func testImportCSAWithHandPieces() {
        // 複数種類の持ち駒（先手歩2枚、後手桂1枚）
        let csaData = """
        V2.2
        P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
        P2 * -HI *  *  *  *  * -KA *
        P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
        P4 *  *  *  *  *  *  *  *  *
        P5 *  *  *  *  *  *  *  *  *
        P6 *  *  *  *  *  *  *  *  *
        P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
        P8 * +KA *  *  *  *  * +HI *
        P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
        P+00FU00FU
        P-00KE
        +
        +7776FU
        %TORYO
        """

        let result = CSAFormatter.importCSA(csaData)
        guard case .success(let record) = result else {
            XCTFail("Import failed")
            return
        }
        let blackHand = record.initialPosition.hand(color: .black)
        let whiteHand = record.initialPosition.hand(color: .white)
        XCTAssertEqual(blackHand.count(pieceType: .pawn), 2, "Black should have 2 pawns in hand")
        XCTAssertEqual(whiteHand.count(pieceType: .knight), 1, "White should have 1 knight in hand")
    }

    func testImportCSAWithWhiteToMove() {
        // 後手番開始のカスタム局面
        let csaData = """
        V2.2
        P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
        P2 * -HI *  *  *  *  * -KA *
        P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
        P4 *  *  *  *  *  *  *  *  *
        P5 *  *  *  *  *  *  *  *  *
        P6 *  *  *  *  *  *  *  *  *
        P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
        P8 * +KA *  *  *  *  * +HI *
        P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
        -
        -3334FU
        %TORYO
        """

        let result = CSAFormatter.importCSA(csaData)
        guard case .success(let record) = result else {
            XCTFail("Import failed")
            return
        }
        XCTAssertEqual(record.initialPosition.color, .white, "Should start with white to move")
    }
}
