import XCTest
@testable import SwiftShogi

/// KI2形式の読み込み・書き出しのテスト
final class KI2FormatterTests: XCTestCase {

    // MARK: - 読み込みテスト

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
            XCTAssertEqual(record.length, 4)

            record.goto(1)
            if let move = record.current.move as? Move {
                XCTAssertEqual(move.to, Square(file: 7, rank: 6))
            } else {
                XCTFail("First node should be a move")
            }

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
            XCTAssertEqual(record.length, 4)

        case .failure(let error):
            XCTFail("Failed to import KI2 with alternative symbols: \(error)")
        }
    }

    func testImportKI2WithFullWidthSpaceLines() {
        // 行頭の全角スペース+手番記号、「同」の後の全角スペースを読み込める
        let ki2String = "▲７六歩 △３四歩 ▲２二角成 △同　銀\n　▲４五角"

        let result = KakinokiFormatter.importKI2(ki2String)

        switch result {
        case .success(let record):
            XCTAssertEqual(record.length, 5)

            record.goto(5)
            if let move = record.current.move as? Move {
                XCTAssertEqual(move.to, Square(file: 4, rank: 5))
            } else {
                XCTFail("Node at ply 5 should be a move")
            }

        case .failure(let error):
            XCTFail("Failed to import KI2: \(error)")
        }
    }

    func testImportKI2StopsAtSpecialMoveToken() {
        // Shogi DB2などは「投了」等を指し手と同列に出力する。
        // これらが現れた時点で以降の指し手は読み込まない。
        let ki2String = """
        ▲７六歩 △３四歩
        ▲投了
        """

        switch KakinokiFormatter.importKI2(ki2String) {
        case .success(let record):
            XCTAssertEqual(record.length, 2)
        case .failure(let error):
            XCTFail("Failed to import KI2: \(error)")
        }
    }

    func testImportKI2StopsAtSpecialMoveTokenMidLine() {
        let ki2String = "▲７六歩 △３四歩 ▲投了 △これは読まれない"

        switch KakinokiFormatter.importKI2(ki2String) {
        case .success(let record):
            XCTAssertEqual(record.length, 2)
        case .failure(let error):
            XCTFail("Failed to import KI2: \(error)")
        }
    }

    func testImportKI2StopsAtInlineTimeout() {
        // 「時間切れ」もインラインの終局表記として受理する
        let ki2String = "▲７六歩 △時間切れ"

        switch KakinokiFormatter.importKI2(ki2String) {
        case .success(let record):
            XCTAssertEqual(record.length, 1)
        case .failure(let error):
            XCTFail("Failed to import KI2: \(error)")
        }
    }

    func testImportKI2FailsOnBareTurnSymbol() {
        // 手番記号だけの行は破損とみなしてエラーにする
        let ki2String = "▲７六歩\n▲"

        if case .success = KakinokiFormatter.importKI2(ki2String) {
            XCTFail("Expected failure for a bare turn symbol line")
        }
    }

    func testImportKI2FailsOnInvalidToken() {
        // 手番記号に続くトークンが指し手として解釈できない場合はエラー
        let ki2String = "▲７六歩 ▲ほげほげ"

        if case .success = KakinokiFormatter.importKI2(ki2String) {
            XCTFail("Expected failure for invalid move token")
        }
    }

    func testImportKI2WithOldCoordinateNotation() {
        // 移動元座標付きの古い表記も受理する
        let ki2String = "▲７六歩(77) △３四歩(33)"

        switch KakinokiFormatter.importKI2(ki2String) {
        case .success(let record):
            XCTAssertEqual(record.length, 2)
        case .failure(let error):
            XCTFail("Failed to import KI2: \(error)")
        }
    }

    func testImportKI2WithBranch() {
        let ki2String = """
        ▲７六歩 △３四歩 ▲２六歩
        変化：3手
        ▲６六歩
        """

        let result = KakinokiFormatter.importKI2(ki2String)

        switch result {
        case .success(let record):
            // 本譜3手 + 3手目の分岐に▲６六歩
            XCTAssertEqual(record.length, 3)

            record.goto(3)
            XCTAssertTrue(record.current.hasBranch)
            if let branchMove = record.current.branch?.move as? Move {
                XCTAssertEqual(branchMove.to, Square(file: 6, rank: 6))
            } else {
                XCTFail("Branch node should hold ▲６六歩")
            }

        case .failure(let error):
            XCTFail("Failed to import KI2 with branch: \(error)")
        }
    }

    // MARK: - 終局行テスト

    /// 「まで」行を含むKI2を読み込み、終局の特殊な指し手を検証します
    private func assertKI2EndOfGame(_ endLine: String, _ expected: SpecialMove, file: StaticString = #filePath, line: UInt = #line) {
        let ki2String = "▲７六歩 △３四歩\n" + endLine

        switch KakinokiFormatter.importKI2(ki2String) {
        case .success(let record):
            record.goto(3)
            XCTAssertEqual(record.current.move as? SpecialMove, expected, "for \(endLine)", file: file, line: line)
        case .failure(let error):
            XCTFail("Failed to import KI2 with \(endLine): \(error)", file: file, line: line)
        }
    }

    func testImportKI2EndOfGameVariants() {
        assertKI2EndOfGame("まで2手で先手の勝ち", specialMove(.resign))
        assertKI2EndOfGame("まで2手で中断", specialMove(.interrupt))
        assertKI2EndOfGame("まで2手で千日手", specialMove(.repetitionDraw))
        assertKI2EndOfGame("まで2手で持将棋", specialMove(.impass))
        assertKI2EndOfGame("まで2手で時間切れにより先手の勝ち", specialMove(.timeout))
        assertKI2EndOfGame("まで2手で後手の反則勝ち", specialMove(.foulWin))
    }

    func testImportKI2TsumeShogiEndOfGame() {
        // 詰将棋の棋譜は「まで◯手詰」（「で」なし）で終わる
        assertKI2EndOfGame("まで49手詰", specialMove(.mate))
    }

    // MARK: - 方向修飾子による移動元特定テスト

    /// SFEN局面上で指し手テキストを解析し、最後の指し手を返します
    private func parseLastMove(sfen: String, text: String, lastMove: Move? = nil, file: StaticString = #filePath, line: UInt = #line) -> Move? {
        guard let position = Position.fromSFEN(sfen) else {
            XCTFail("Invalid SFEN: \(sfen)", file: file, line: line)
            return nil
        }

        switch KakinokiFormatter.parseMoves(position: position, text: text, lastMove: lastMove) {
        case .success(let moves):
            guard let move = moves.last else {
                XCTFail("No moves parsed from: \(text)", file: file, line: line)
                return nil
            }
            return move
        case .failure(let error):
            XCTFail("Failed to parse \(text): \(error)", file: file, line: line)
            return nil
        }
    }

    /// SFEN局面上で指し手テキストの解析が失敗することを検証します
    private func assertParseFails(sfen: String, text: String, file: StaticString = #filePath, line: UInt = #line) {
        guard let position = Position.fromSFEN(sfen) else {
            XCTFail("Invalid SFEN: \(sfen)", file: file, line: line)
            return
        }

        if case .success(let moves) = KakinokiFormatter.parseMoves(position: position, text: text) {
            XCTFail("Expected failure for \(text) but got \(moves.count) moves", file: file, line: line)
        }
    }

    func testGoldRightStraightLeft() {
        // 金が５九・４九・３九に並び、いずれも４八へ移動できる局面
        let sfen = "4k4/9/9/9/9/9/9/9/4GGG1K b - 1"

        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲４八金右")?.from, .left(Square(file: 3, rank: 9)))
        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲４八金直")?.from, .left(Square(file: 4, rank: 9)))
        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲４八金左")?.from, .left(Square(file: 5, rank: 9)))
    }

    func testAmbiguousMoveWithoutModifierFails() {
        // 3枚の金が同じマスへ移動できるのに修飾子がない場合はエラー
        let sfen = "4k4/9/9/9/9/9/9/9/4GGG1K b - 1"

        assertParseFails(sfen: sfen, text: "▲４八金")
    }

    func testGoldPullSideUp() {
        // 金が４七（引）・５八（寄）・４九（上）から４八へ移動できる局面
        let sfen = "4k4/9/9/9/9/9/5G3/4G4/5G2K b - 1"

        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲４八金引")?.from, .left(Square(file: 4, rank: 7)))
        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲４八金寄")?.from, .left(Square(file: 5, rank: 8)))
        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲４八金上")?.from, .left(Square(file: 4, rank: 9)))
    }

    func testGoUpAlternativeNotation() {
        // 「行」は「上」の異表記として受理する
        let sfen = "4k4/9/9/9/9/9/5G3/4G4/5G2K b - 1"

        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲４八金行")?.from, .left(Square(file: 4, rank: 9)))
    }

    func testSilverCompoundModifiers() {
        // 銀が５六・３六・５八・３八の十字に配置され、いずれも４七へ移動できる局面
        let sfen = "4k4/9/9/9/9/4S1S2/9/4S1S2/8K b - 1"

        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲４七銀右上")?.from, .left(Square(file: 3, rank: 8)))
        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲４七銀右引")?.from, .left(Square(file: 3, rank: 6)))
        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲４七銀左上")?.from, .left(Square(file: 5, rank: 8)))
        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲４七銀左引")?.from, .left(Square(file: 5, rank: 6)))
    }

    func testSilverPartialModifierStillAmbiguousFails() {
        // 「右」だけでは３八と３六の2候補が残るためエラー
        let sfen = "4k4/9/9/9/9/4S1S2/9/4S1S2/8K b - 1"

        assertParseFails(sfen: sfen, text: "▲４七銀右")
    }

    func testHorseSpecialCase() {
        // 馬が８七・７七に並び、いずれも７六へ移動できる局面。
        // 竜・馬は直進する場合も「直」ではなく「右」「左」で表記される。
        let sfen = "4k4/9/9/9/9/9/1+B+B6/9/4K4 b - 1"

        // ７七の馬は直進（右側の駒）、８七の馬は斜め（左側の駒）
        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲７六馬右")?.from, .left(Square(file: 7, rank: 7)))
        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲７六馬左")?.from, .left(Square(file: 8, rank: 7)))
    }

    func testHorseAmbiguousWithoutModifierFails() {
        // 馬2枚が同じマスへ移動できるのに修飾子がない場合は特定できずエラー
        let sfen = "4k4/9/9/9/9/9/1+B+B6/9/4K4 b - 1"

        assertParseFails(sfen: sfen, text: "▲７六馬")
    }

    func testDragonSameRank() {
        // 竜が８二・４二に並び、いずれも６二へ移動できる局面
        let sfen = "4k4/1+R3+R3/9/9/9/9/9/9/4K4 b - 1"

        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲６二竜左")?.from, .left(Square(file: 8, rank: 2)))
        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲６二竜右")?.from, .left(Square(file: 4, rank: 2)))
    }

    func testKnightLeftRight() {
        // 桂が４九・２九に配置され、いずれも３七へ跳べる局面
        let sfen = "4k4/9/9/9/9/9/9/9/5N1NK b - 1"

        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲３七桂左")?.from, .left(Square(file: 4, rank: 9)))
        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲３七桂右")?.from, .left(Square(file: 2, rank: 9)))
    }

    func testWhiteHorizontalReversal() {
        // 後手の金が７一・５一に並び、いずれも６一へ移動できる局面。
        // 右・左は指す側から見た向きなので後手では盤面表示と逆になる。
        let sfen = "2g1gk3/9/9/9/9/9/9/9/4K4 w - 1"

        XCTAssertEqual(parseLastMove(sfen: sfen, text: "△６一金左")?.from, .left(Square(file: 5, rank: 1)))
        XCTAssertEqual(parseLastMove(sfen: sfen, text: "△６一金右")?.from, .left(Square(file: 7, rank: 1)))
    }

    func testWhiteVerticalReversal() {
        // 後手の金が５三・５五に並び、いずれも５四へ移動できる局面。
        // 後手にとっての「上」は段番号が増える方向。
        let sfen = "4k4/9/4g4/9/4g4/9/9/9/4K4 w - 1"

        XCTAssertEqual(parseLastMove(sfen: sfen, text: "△５四金上")?.from, .left(Square(file: 5, rank: 3)))
        XCTAssertEqual(parseLastMove(sfen: sfen, text: "△５四金引")?.from, .left(Square(file: 5, rank: 5)))
    }

    // MARK: - 駒打ちテスト

    func testExplicitDrop() {
        // 盤上の金（５六）も５五へ移動できるため、持ち駒を打つ場合は「打」が必須
        let sfen = "4k4/9/9/9/9/4G4/9/9/4K4 b G 1"

        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲５五金打")?.from, .right(.gold))
        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲５五金")?.from, .left(Square(file: 5, rank: 6)))
    }

    func testImplicitDrop() {
        // 盤上に移動できる桂がない場合は「打」がなくても持ち駒から打つ
        let sfen = "4k4/9/9/9/9/9/9/9/4K4 b N 1"

        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲４五桂")?.from, .right(.knight))
    }

    // MARK: - 成・不成テスト

    func testPromotionFlags() {
        guard let position = Position.fromSFEN(InitialPositionSFEN.standard) else {
            XCTFail("Invalid SFEN")
            return
        }

        switch KakinokiFormatter.parseMoves(position: position, text: "▲７六歩 △３四歩 ▲２二角成") {
        case .success(let moves):
            XCTAssertEqual(moves.count, 3)
            XCTAssertTrue(moves[2].promote)
        case .failure(let error):
            XCTFail("Failed to parse: \(error)")
        }
    }

    func testNoPromotionFlag() {
        guard let position = Position.fromSFEN(InitialPositionSFEN.standard) else {
            XCTFail("Invalid SFEN")
            return
        }

        switch KakinokiFormatter.parseMoves(position: position, text: "▲７六歩 △３四歩 ▲２二角不成") {
        case .success(let moves):
            XCTAssertEqual(moves.count, 3)
            XCTAssertFalse(moves[2].promote)
        case .failure(let error):
            XCTFail("Failed to parse: \(error)")
        }
    }

    func testForcedPromotion() {
        // 強制成りでも KI2 では「成」が明記される
        let sfen = "4k4/8P/9/9/9/9/9/9/4K4 b - 1"

        let move = parseLastMove(sfen: sfen, text: "▲１一歩成")
        XCTAssertEqual(move?.from, .left(Square(file: 1, rank: 2)))
        XCTAssertEqual(move?.promote, true)
    }

    // MARK: - 駒名の異体テスト

    func testPromotedPieceNames() {
        // 成銀の移動は「成銀」「全」のどちらでも受理する
        let sfen = "4k4/9/9/9/9/9/9/4+S4/4K4 b - 1"

        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲５七成銀")?.from, .left(Square(file: 5, rank: 8)))
        XCTAssertEqual(parseLastMove(sfen: sfen, text: "▲５七全")?.from, .left(Square(file: 5, rank: 8)))
    }

    func testKingAndDragonAliases() {
        // 「王」「玉」、「龍」「竜」の異体をどちらも受理する
        let kingSFEN = "4k4/9/9/9/9/9/9/9/4K4 b - 1"
        XCTAssertEqual(parseLastMove(sfen: kingSFEN, text: "▲５八玉")?.from, .left(Square(file: 5, rank: 9)))
        XCTAssertEqual(parseLastMove(sfen: kingSFEN, text: "▲５八王")?.from, .left(Square(file: 5, rank: 9)))

        let dragonSFEN = "4k4/9/9/9/9/9/9/2+R6/4K4 b - 1"
        XCTAssertEqual(parseLastMove(sfen: dragonSFEN, text: "▲７七龍")?.from, .left(Square(file: 7, rank: 8)))
        XCTAssertEqual(parseLastMove(sfen: dragonSFEN, text: "▲７七竜")?.from, .left(Square(file: 7, rank: 8)))
    }

    // MARK: - 「同」テスト

    func testSameDestinationInline() {
        guard let position = Position.fromSFEN(InitialPositionSFEN.standard) else {
            XCTFail("Invalid SFEN")
            return
        }

        switch KakinokiFormatter.parseMoves(position: position, text: "▲７六歩 △３四歩 ▲２二角成 △同　銀") {
        case .success(let moves):
            XCTAssertEqual(moves.count, 4)
            XCTAssertEqual(moves.last?.to, Square(file: 2, rank: 2))
            XCTAssertEqual(moves.last?.from, .left(Square(file: 3, rank: 1)))
        case .failure(let error):
            XCTFail("Failed to parse: \(error)")
        }
    }

    func testSameDestinationViaLastMove() {
        // テキストの1手目が「同」の場合は lastMove 引数から移動先を決定する
        guard let position = Position.fromSFEN(InitialPositionSFEN.standard),
              let pawn76 = position.createMoveByUSI("7g7f"), position.doMove(pawn76),
              let pawn34 = position.createMoveByUSI("3c3d"), position.doMove(pawn34),
              let bishop22 = position.createMoveByUSI("8h2b+"), position.doMove(bishop22)
        else {
            XCTFail("Failed to set up position")
            return
        }

        switch KakinokiFormatter.parseMoves(position: position, text: "△同　銀", lastMove: bishop22) {
        case .success(let moves):
            XCTAssertEqual(moves.count, 1)
            XCTAssertEqual(moves[0].to, Square(file: 2, rank: 2))
            XCTAssertEqual(moves[0].from, .left(Square(file: 3, rank: 1)))
        case .failure(let error):
            XCTFail("Failed to parse: \(error)")
        }
    }

    func testSameDestinationWithoutContextFails() {
        assertParseFails(sfen: InitialPositionSFEN.standard, text: "▲同歩")
    }

    // MARK: - 初期局面（BOD形式）テスト

    func testImportWithBODAmbiguousGolds() {
        // 金3枚が４八へ移動できる局面で「直」を解決する
        let ki2String = """
        後手の持駒：なし
          ９ ８ ７ ６ ５ ４ ３ ２ １
        +---------------------------+
        | ・ ・ ・ ・v玉 ・ ・ ・ ・|一
        | ・ ・ ・ ・ ・ ・ ・ ・ ・|二
        | ・ ・ ・ ・ ・ ・ ・ ・ ・|三
        | ・ ・ ・ ・ ・ ・ ・ ・ ・|四
        | ・ ・ ・ ・ ・ ・ ・ ・ ・|五
        | ・ ・ ・ ・ ・ ・ ・ ・ ・|六
        | ・ ・ ・ ・ ・ ・ ・ ・ ・|七
        | ・ ・ ・ ・ ・ ・ ・ ・ ・|八
        | ・ ・ ・ ・ 金 金 金 ・ 玉|九
        +---------------------------+
        先手の持駒：なし
        先手番
        ▲４八金直
        """

        switch KakinokiFormatter.importKI2(ki2String) {
        case .success(let record):
            XCTAssertEqual(record.length, 1)

            record.goto(1)
            XCTAssertEqual(record.position.board.at(Square(file: 4, rank: 8)), Piece(color: .black, type: .gold))
            XCTAssertNil(record.position.board.at(Square(file: 4, rank: 9)))
            XCTAssertEqual(record.position.board.at(Square(file: 5, rank: 9)), Piece(color: .black, type: .gold))
            XCTAssertEqual(record.position.board.at(Square(file: 3, rank: 9)), Piece(color: .black, type: .gold))

        case .failure(let error):
            XCTFail("Failed to import KI2: \(error)")
        }
    }

    func testImportWithBODExplicitDrop() {
        // 盤上の金（５四）も５五へ移動できるため「打」で持ち駒からの打ちを明示する
        let ki2String = """
        後手の持駒：なし
          ９ ８ ７ ６ ５ ４ ３ ２ １
        +---------------------------+
        | ・ ・ ・ ・v玉 ・ ・ ・ ・|一
        | ・ ・ ・ ・ ・ ・ ・ ・ ・|二
        | ・ ・ ・ ・ ・ ・ ・ ・ ・|三
        | ・ ・ ・ ・ 金 ・ ・ ・ ・|四
        | ・ ・ ・ ・ ・ ・ ・ ・ ・|五
        | ・ ・ ・ ・ ・ ・ ・ ・ ・|六
        | ・ ・ ・ ・ ・ ・ ・ ・ ・|七
        | ・ ・ ・ ・ ・ ・ ・ ・ ・|八
        | ・ ・ ・ ・ ・ ・ ・ ・ 玉|九
        +---------------------------+
        先手の持駒：金
        先手番
        ▲５五金打
        """

        switch KakinokiFormatter.importKI2(ki2String) {
        case .success(let record):
            record.goto(1)
            XCTAssertEqual(record.position.board.at(Square(file: 5, rank: 5)), Piece(color: .black, type: .gold))
            XCTAssertEqual(record.position.board.at(Square(file: 5, rank: 4)), Piece(color: .black, type: .gold))
            XCTAssertEqual(record.position.hand(color: .black).count(pieceType: .gold), 0)

        case .failure(let error):
            XCTFail("Failed to import KI2: \(error)")
        }
    }

    // MARK: - 実戦形棋譜テスト

    /// USI形式の指し手列を適用した局面を返します
    private func positionByUSIMoves(_ usiMoves: [String], file: StaticString = #filePath, line: UInt = #line) -> Position? {
        guard let position = Position.fromSFEN(InitialPositionSFEN.standard) else {
            XCTFail("Invalid SFEN", file: file, line: line)
            return nil
        }

        for usiMove in usiMoves {
            guard let move = position.createMoveByUSI(usiMove), position.doMove(move) else {
                XCTFail("Failed to apply USI move: \(usiMove)", file: file, line: line)
                return nil
            }
        }

        return position
    }

    func testImportRealGame() {
        // 四間飛車の序盤に修飾子（金右・金左）・「同」の応酬・駒打ちを含む実戦形の棋譜。
        // 同一の手順をUSIで適用した局面と最終局面が一致することを検証する。
        let ki2String = """
        先手：先手プレイヤー
        後手：後手プレイヤー
        手合割：平手
        ▲７六歩 △３四歩 ▲２六歩 △４四歩 ▲４八銀 △４二飛
        ▲５六歩 △７二銀 ▲６八玉 △３二銀 ▲７八玉 △４三銀
        ▲５八金右 △５二金左 ▲５七銀 △９四歩 ▲９六歩 △９五歩
        ▲同　歩 △同　香 ▲同　香 △９二歩
        まで22手で中断
        """

        let usiMoves = [
            "7g7f", "3c3d", "2g2f", "4c4d", "3i4h", "8b4b",
            "5g5f", "7a7b", "5i6h", "3a3b", "6h7h", "3b4c",
            "4i5h", "4a5b", "4h5g", "9c9d", "9g9f", "9d9e",
            "9f9e", "9a9e", "9i9e", "P*9b",
        ]

        guard let expected = positionByUSIMoves(usiMoves) else {
            return
        }

        switch KakinokiFormatter.importKI2(ki2String) {
        case .success(let record):
            XCTAssertEqual(record.length, 23) // 22手 + 終局（中断）

            record.goto(22)
            XCTAssertEqual(record.position.sfen, expected.sfen)

            record.goto(23)
            XCTAssertEqual(record.current.move as? SpecialMove, specialMove(.interrupt))

        case .failure(let error):
            XCTFail("Failed to import KI2: \(error)")
        }
    }

    // MARK: - エクスポートテスト

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

    func testExportKI2MoveOrder() {
        guard let position = Position.fromSFEN(InitialPositionSFEN.standard) else {
            XCTFail("Failed to create position")
            return
        }

        let record = Record(position: position)
        for usi in ["7g7f", "3c3d", "2g2f"] {
            guard let move = record.position.createMoveByUSI(usi), record.append(move) else {
                XCTFail("Failed to append move: \(usi)")
                return
            }
        }

        let ki2Output = KakinokiFormatter.exportKI2(record)

        // 指し手が棋譜どおりの順序で1行に出力される
        let normalized = ki2Output.replacingOccurrences(of: " +", with: " ", options: .regularExpression)
        XCTAssertTrue(normalized.contains("▲７六歩 △３四歩 ▲２六歩"), "unexpected output: \(ki2Output)")
    }

    func testExportPreservesHeaderOrder() {
        // ヘッダ行はファイルに現れた順序のままエクスポートされる
        let ki2String = """
        後手：後手プレイヤー
        棋戦：テスト棋戦
        先手：先手プレイヤー
        ▲７六歩
        """

        guard case .success(let record) = KakinokiFormatter.importKI2(ki2String) else {
            XCTFail("Failed to import KI2")
            return
        }

        let exported = KakinokiFormatter.exportKI2(record)
        XCTAssertTrue(exported.hasPrefix("後手：後手プレイヤー\n棋戦：テスト棋戦\n先手：先手プレイヤー\n"), "unexpected output: \(exported)")
    }

    // MARK: - 往復変換テスト

    func testRoundTrip() {
        // 修飾子・同・成・駒打ち・終局を含む棋譜の import → export → import → export で
        // 1回目と2回目のエクスポート文字列が一致することを検証する
        let ki2String = """
        先手：先手プレイヤー
        後手：後手プレイヤー
        ▲７六歩 △３四歩 ▲２二角成 △同　銀 ▲４五角 △５二金右
        ▲３四角 △３三銀 ▲５六角 △９四歩 ▲５八金右
        まで11手で中断
        """

        guard case .success(let record1) = KakinokiFormatter.importKI2(ki2String) else {
            XCTFail("Failed to import original KI2")
            return
        }

        let export1 = KakinokiFormatter.exportKI2(record1)

        guard case .success(let record2) = KakinokiFormatter.importKI2(export1) else {
            XCTFail("Failed to import exported KI2: \(export1)")
            return
        }

        let export2 = KakinokiFormatter.exportKI2(record2)
        XCTAssertEqual(export1, export2)
    }

    func testRoundTripWithBranch() {
        let ki2String = """
        ▲７六歩 △３四歩 ▲２六歩
        変化：3手
        ▲６六歩 △８四歩
        """

        guard case .success(let record1) = KakinokiFormatter.importKI2(ki2String) else {
            XCTFail("Failed to import original KI2")
            return
        }

        let export1 = KakinokiFormatter.exportKI2(record1)

        guard case .success(let record2) = KakinokiFormatter.importKI2(export1) else {
            XCTFail("Failed to import exported KI2: \(export1)")
            return
        }

        let export2 = KakinokiFormatter.exportKI2(record2)
        XCTAssertEqual(export1, export2)
        XCTAssertTrue(export1.contains("変化：3手"))
    }
}
