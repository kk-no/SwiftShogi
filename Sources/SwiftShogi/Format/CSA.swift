import Foundation

/// CSA形式のフォーマッター
public class CSAFormatter {
    /// CSAフォーマッターのエクスポートオプション
    public struct CSAExportOptions {
        /// CSAバージョン
        public let version: String
        /// 時間データを含めるか
        public let includeTime: Bool
        /// コメントを含めるか
        public let includeComments: Bool

        /// 初期化
        /// - Parameters:
        ///   - version: CSAバージョン（デフォルト: "V2.2"）
        ///   - includeTime: 時間データを含めるか（デフォルト: true）
        ///   - includeComments: コメントを含めるか（デフォルト: false）
        public init(version: String = "V2.2", includeTime: Bool = true, includeComments: Bool = false) {
            self.version = version
            self.includeTime = includeTime
            self.includeComments = includeComments
        }
    }

    // MARK: - CSA形式の駒コード
    static let csaPieceCodeMap: [PieceType: String] = [
        .pawn: "FU",
        .lance: "KY",
        .knight: "KE",
        .silver: "GI",
        .gold: "KI",
        .bishop: "KA",
        .rook: "HI",
        .king: "OU",
        .promPawn: "TO",
        .promLance: "NY",
        .promKnight: "NK",
        .promSilver: "NG",
        .horse: "UM",
        .dragon: "RY",
    ]

    static let csaPieceCodeReverseMap: [String: PieceType] = [
        "FU": .pawn,
        "KY": .lance,
        "KE": .knight,
        "GI": .silver,
        "KI": .gold,
        "KA": .bishop,
        "HI": .rook,
        "OU": .king,
        "GY": .king,
        "TO": .promPawn,
        "NY": .promLance,
        "NK": .promKnight,
        "NG": .promSilver,
        "UM": .horse,
        "RY": .dragon,
    ]

    // MARK: - インポート

    /// CSA形式の棋譜を読み込みます
    /// - Parameter data: CSA形式の文字列
    /// - Returns: 棋譜またはエラー
    public static func importCSA(_ data: String) -> Result<Record, FormatError> {
        let lines = StringUtil.normalizeLineEndings(data).split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let parser = CSAParser(lines: lines)

        do {
            let record = try parser.parse()
            return .success(record)
        } catch let error as FormatError {
            return .failure(error)
        } catch {
            return .failure(FormatError(message: "Unknown error: \(error)"))
        }
    }

    // MARK: - エクスポート

    /// 棋譜をCSA形式の文字列にエクスポートします
    /// - Parameters:
    ///   - record: 棋譜
    ///   - options: エクスポートオプション
    /// - Returns: CSA形式の文字列
    public static func exportCSA(_ record: ImmutableRecord, options: CSAExportOptions = CSAExportOptions()) -> String {
        var result = ""

        // バージョン
        result += options.version + "\n"

        // メタデータ
        let metadata = record.metadata
        if let blackName = metadata.getStandardMetadata(.blackName) {
            result += "N+\(blackName)\n"
        }
        if let whiteName = metadata.getStandardMetadata(.whiteName) {
            result += "N-\(whiteName)\n"
        }

        // 標準メタデータ
        if let event = metadata.getStandardMetadata(.tournament) {
            result += "$EVENT:\(event)\n"
        }
        if let site = metadata.getStandardMetadata(.place) {
            result += "$SITE:\(site)\n"
        }
        if let startTime = metadata.getStandardMetadata(.startDatetime) {
            result += "$START_TIME:\(startTime)\n"
        }
        if let endTime = metadata.getStandardMetadata(.endDatetime) {
            result += "$END_TIME:\(endTime)\n"
        }
        if let timeLimit = metadata.getStandardMetadata(.timeLimit) {
            result += "$TIME_LIMIT:\(timeLimit)\n"
        }
        if let opening = metadata.getStandardMetadata(.strategy) {
            result += "$OPENING:\(opening)\n"
        }

        // 初期局面
        result += exportPosition(record.initialPosition)

        // 手番
        let color = record.initialPosition.color
        result += color == .black ? "+\n" : "-\n"

        // 指し手（Recordはシーケンスプロトコルをサポート）
        record.forEach { (node, _) in
            let move = node.move
            if let regularMove = move as? Move {
                result += exportMove(regularMove)
                result += "\n"
            } else if let specialMove = move as? SpecialMove {
                result += exportSpecialMove(specialMove)
                result += "\n"
            }
        }

        return result
    }

    // MARK: - ヘルパーメソッド

    /// 手をCSA形式にエクスポート
    private static func exportMove(_ move: Move) -> String {
        let sideStr = move.color == .black ? "+" : "-"

        let fromStr: String
        switch move.from {
        case let .left(square):
            fromStr = String(format: "%d%d", square.file, square.rank)
        case .right:
            fromStr = "00"
        }

        let toStr = String(format: "%d%d", move.to.file, move.to.rank)

        let pieceCode = csaPieceCodeMap[move.pieceType] ?? "??"

        return sideStr + fromStr + toStr + pieceCode
    }

    /// 特殊な手をCSA形式にエクスポート
    private static func exportSpecialMove(_ move: SpecialMove) -> String {
        switch move {
        case let .predefined(specialMove):
            switch specialMove.type {
            case .resign:
                return "%TORYO"
            case .repetitionDraw:
                return "%SENNICHITE"
            case .mate:
                return "%TSUMI"
            case .interrupt:
                return "%CHUDAN"
            case .timeout:
                return "%TIME_UP"
            case .enteringOfKing:
                return "%JISHOGI"
            case .draw:
                return "%HIKIWAKE"
            default:
                return "%\(specialMove.type.rawValue.uppercased())"
            }
        case let .any(specialMove):
            return "%\(specialMove.name)"
        }
    }

    /// 初期局面をCSA形式にエクスポート
    private static func exportPosition(_ position: ImmutablePosition) -> String {
        // 簡略版：PI（標準初期位置）か、完全なP1-P9を出力
        // 現在は標準初期位置として出力（実装は簡略版）
        return "PI\n"
    }
}

// MARK: - CSAパーサー

private class CSAParser {
    private let lines: [String]
    private var currentLineIndex = 0
    private var metadata: [String: String] = [:]
    private var position: Position = Position()
    private var version: String = "1.0"
    private var blackName: String?
    private var whiteName: String?

    init(lines: [String]) {
        self.lines = lines
    }

    func parse() throws -> Record {
        // パース段階1: バージョンとメタデータを読む
        try parseMetadata()

        // パース段階2: 初期局面を読む
        try parsePosition()

        // パース段階3: 棋譜を作成
        let record = Record(position: position)

        // メタデータを設定（型キャストが必要）
        if let metadata = record.metadata as? RecordMetadata {
            if let blackName = blackName {
                metadata.setStandardMetadata(.blackName, value: blackName)
            }
            if let whiteName = whiteName {
                metadata.setStandardMetadata(.whiteName, value: whiteName)
            }

            // CSA形式のメタデータをRecordMetadataKeyにマッピング
            for (keyStr, value) in self.metadata {
                mapCSAMetadataToRecord(metadata: metadata, csaKey: keyStr, value: value)
            }
        }

        // パース段階4: 指し手を適用
        try parseMoves(record: record)

        record.goto(0)
        record.resetAllBranchSelection()

        return record
    }

    private func parseMetadata() throws {
        while currentLineIndex < lines.count {
            let line = lines[currentLineIndex].trimmingCharacters(in: .whitespaces)

            // 空行はスキップ
            if line.isEmpty {
                currentLineIndex += 1
                continue
            }

            // コメント行はスキップ
            if line.hasPrefix("'") {
                currentLineIndex += 1
                continue
            }

            // バージョン行
            if line.hasPrefix("V") {
                version = line
                currentLineIndex += 1
                continue
            }

            // プレイヤー名
            if line.hasPrefix("N+") {
                blackName = String(line.dropFirst(2))
                currentLineIndex += 1
                continue
            }
            if line.hasPrefix("N-") {
                whiteName = String(line.dropFirst(2))
                currentLineIndex += 1
                continue
            }

            // メタデータ（$で始まる行）
            if line.hasPrefix("$") {
                let metadataLine = String(line.dropFirst(1))
                if let colonIndex = metadataLine.firstIndex(of: ":") {
                    let key = String(metadataLine[..<colonIndex])
                    let value = String(metadataLine[metadataLine.index(after: colonIndex)...])
                    metadata[key] = value
                }
                currentLineIndex += 1
                continue
            }

            // 局面の開始（P、+、-で始まる行）
            if line.hasPrefix("P") || line.hasPrefix("+") || line.hasPrefix("-") {
                break
            }

            currentLineIndex += 1
        }
    }

    private func parsePosition() throws {
        position = Position()

        var boardLines: [Int: String] = [:]
        let blackHand = Hand()
        let whiteHand = Hand()
        var sideToMove: Color = .black
        var hasCustomPosition = false

        while currentLineIndex < lines.count {
            let line = lines[currentLineIndex].trimmingCharacters(in: .whitespaces)

            if line.isEmpty || line.hasPrefix("'") {
                currentLineIndex += 1
                continue
            }

            // PI: 標準初期位置（Position() のデフォルトが平手なので何もしない）
            if line == "PI" {
                currentLineIndex += 1
                continue
            }

            if line.hasPrefix("P") && line.count > 1 {
                let secondCharIndex = line.index(line.startIndex, offsetBy: 1)
                let secondChar = line[secondCharIndex]

                if let rank = Int(String(secondChar)), 1 <= rank && rank <= 9 {
                    hasCustomPosition = true
                    // trimmingCharacters で末尾スペースが落ちる場合があるため 27 文字にパディング
                    let content = String(line.dropFirst(2)).padding(toLength: 27, withPad: " ", startingAt: 0)
                    boardLines[rank] = content
                    currentLineIndex += 1
                    continue
                }

                if secondChar == "+" || secondChar == "-" {
                    hasCustomPosition = true
                    let hand = secondChar == "+" ? blackHand : whiteHand
                    let handStr = String(line.dropFirst(2))
                    var i = handStr.startIndex
                    while handStr.distance(from: i, to: handStr.endIndex) >= 4 {
                        let end = handStr.index(i, offsetBy: 4)
                        let chunk = handStr[i..<end]
                        if chunk.hasPrefix("00") {
                            let pieceCode = String(chunk.suffix(2))
                            if let pieceType = CSAFormatter.csaPieceCodeReverseMap[pieceCode] {
                                hand.add(pieceType: pieceType, count: 1)
                            }
                        }
                        i = end
                    }
                    currentLineIndex += 1
                    continue
                }
            }

            if line == "+" || line == "-" {
                sideToMove = (line == "+") ? .black : .white
                currentLineIndex += 1
                break
            }

            if line.hasPrefix("+") || line.hasPrefix("-") {
                break
            }

            currentLineIndex += 1
        }

        if hasCustomPosition {
            let sfen = buildSFENFromCSAPosition(
                boardLines: boardLines,
                blackHand: blackHand,
                whiteHand: whiteHand,
                color: sideToMove
            )
            guard position.resetBySFEN(sfen) else {
                throw FormatError(message: "CSA P1-P9 形式の局面を SFEN に変換できませんでした: \(sfen)")
            }
        }
    }

    private func buildSFENFromCSAPosition(
        boardLines: [Int: String],
        blackHand: Hand,
        whiteHand: Hand,
        color: Color
    ) -> String {
        var boardSFEN = ""
        for rank in 1...9 {
            if rank > 1 { boardSFEN += "/" }

            guard let line = boardLines[rank] else {
                boardSFEN += "9"
                continue
            }

            var empty = 0
            var i = line.startIndex
            while line.distance(from: i, to: line.endIndex) >= 3 {
                let end = line.index(i, offsetBy: 3)
                let cell = line[i..<end]
                i = end

                if cell == " * " {
                    empty += 1
                } else {
                    if empty > 0 {
                        boardSFEN += String(empty)
                        empty = 0
                    }
                    let pieceCode = String(cell.suffix(2))
                    if let pieceType = CSAFormatter.csaPieceCodeReverseMap[pieceCode] {
                        let pieceColor: Color = cell.hasPrefix("+") ? .black : .white
                        boardSFEN += Piece(color: pieceColor, type: pieceType).sfen
                    }
                }
            }
            if empty > 0 {
                boardSFEN += String(empty)
            }
        }

        let colorSFEN = color.sfenNotation
        let handSFEN = Hand.formatSFEN(black: blackHand, white: whiteHand)

        return "\(boardSFEN) \(colorSFEN) \(handSFEN) 1"
    }


    private func parseMoves(record: Record) throws {
        while currentLineIndex < lines.count {
            let line = lines[currentLineIndex].trimmingCharacters(in: .whitespaces)

            if line.isEmpty || line.hasPrefix("'") {
                currentLineIndex += 1
                continue
            }

            // 時間行
            if line.hasPrefix("T") {
                currentLineIndex += 1
                continue
            }

            // 特殊な手（終局マーカー）
            if line.hasPrefix("%") {
                let marker = String(line.dropFirst(1))
                _ = try addSpecialMove(to: record, marker: marker)
                currentLineIndex += 1
                break
            }

            // 通常の手
            if (line.hasPrefix("+") || line.hasPrefix("-")) && line.count >= 7 {
                do {
                    try addMove(to: record, line: line)
                } catch {
                    throw FormatError(message: "Invalid move format at line \(currentLineIndex + 1): \(line)")
                }
                currentLineIndex += 1
                continue
            }

            currentLineIndex += 1
        }
    }

    private func addMove(to record: Record, line: String) throws {
        let sideStr = String(line.prefix(1))
        let moveData = String(line.dropFirst(1))

        guard moveData.count >= 6 else {
            throw FormatError(message: "Invalid move format")
        }

        let fromStr = String(moveData.prefix(2))
        let toStr = String(moveData[moveData.index(moveData.startIndex, offsetBy: 2)..<moveData.index(moveData.startIndex, offsetBy: 4)])
        let pieceCodeStr = String(moveData.suffix(2))

        let color: Color = sideStr == "+" ? .black : .white

        guard let fromFile = Int(String(fromStr.prefix(1))),
              let fromRank = Int(String(fromStr.suffix(1))),
              let toFile = Int(String(toStr.prefix(1))),
              let toRank = Int(String(toStr.suffix(1))),
              let destinationPieceType = CSAFormatter.csaPieceCodeReverseMap[pieceCodeStr]
        else {
            throw FormatError(message: "Invalid move format")
        }

        let toSquare = Square(file: toFile, rank: toRank)

        // 移動元を決定
        let from: Either<Square, PieceType>
        if fromFile == 0 && fromRank == 0 {
            from = .right(destinationPieceType)
        } else {
            from = .left(Square(file: fromFile, rank: fromRank))
        }

        // 指し手を生成
        guard var move = record.position.createMove(from: from, to: toSquare) else {
            throw FormatError(message: "Invalid move")
        }

        // 手番の整合性チェック
        if record.position.color != color {
            throw FormatError(message: "Invalid move")
        }

        // 成りの設定
        if case let .left(fromSquare) = from {
            guard let sourcePiece = record.position.board.at(fromSquare) else {
                throw FormatError(message: "Cannot determine the source of the move")
            }

            let sourcePieceType = sourcePiece.type
            let sourceIsPromoted = unpromotedType(of: sourcePieceType) != sourcePieceType

            // 移動先コードが成駒（UM, RY等）かつ移動元が成っていない場合
            if isPromotedPiece(destinationPieceType) && !sourceIsPromoted {
                move = move.withPromote()
            }
        }

        // 指し手を追加
        let success = record.append(move)
        if !success {
            throw FormatError(message: "Failed to apply move")
        }
    }

    private func addSpecialMove(to record: Record, marker: String) throws -> Bool {
        let specialMoveVal: SpecialMove

        switch marker {
        case "TORYO":
            specialMoveVal = specialMove(.resign)
        case "SENNICHITE":
            specialMoveVal = specialMove(.repetitionDraw)
        case "TSUMI":
            specialMoveVal = specialMove(.mate)
        case "CHUDAN":
            specialMoveVal = specialMove(.interrupt)
        case "TIME_UP":
            specialMoveVal = specialMove(.timeout)
        case "JISHOGI":
            specialMoveVal = specialMove(.enteringOfKing)
        case "HIKIWAKE":
            specialMoveVal = specialMove(.draw)
        default:
            specialMoveVal = anySpecialMove(marker)
        }

        return record.append(specialMoveVal)
    }

    // MARK: - ユーティリティ

    private func mapCSAMetadataToRecord(metadata: RecordMetadata, csaKey: String, value: String) {
        // CSA形式のメタデータキーをRecordMetadataKeyにマッピング
        let keyMapping: [String: RecordMetadataKey] = [
            "EVENT": .tournament,
            "SITE": .place,
            "START_TIME": .startDatetime,
            "END_TIME": .endDatetime,
            "TIME_LIMIT": .timeLimit,
            "OPENING": .strategy,
            "BLACK_TIME": .blackTimeLimit,
            "WHITE_TIME": .whiteTimeLimit,
            "MAX_MOVES": .maxMoves,
        ]

        if let recordKey = keyMapping[csaKey] {
            metadata.setStandardMetadata(recordKey, value: value)
        } else {
            // マッピングされないキーはカスタムメタデータとして保存
            metadata.setCustomMetadata(csaKey, value: value)
        }
    }

    private func isPromotedPiece(_ pieceType: PieceType) -> Bool {
        return [.promPawn, .promLance, .promKnight, .promSilver, .horse, .dragon].contains(pieceType)
    }

    private func getPieceTypeBeforePromotion(_ pieceType: PieceType) -> PieceType {
        switch pieceType {
        case .promPawn: return .pawn
        case .promLance: return .lance
        case .promKnight: return .knight
        case .promSilver: return .silver
        case .horse: return .bishop
        case .dragon: return .rook
        default: return pieceType
        }
    }
}
