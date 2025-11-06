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
        // 現在の位置を初期化
        position = Position()

        // PI（標準初期位置）または P1-P9（カスタム位置 - すべて初期局面として扱う）
        while currentLineIndex < lines.count {
            let line = lines[currentLineIndex].trimmingCharacters(in: .whitespaces)

            if line.isEmpty || line.hasPrefix("'") {
                currentLineIndex += 1
                continue
            }

            // PI: 標準初期位置
            if line == "PI" {
                position = Position()
                currentLineIndex += 1
                continue
            }

            // P1-P9: ボードラインの指定（無視して初期局面のままにする）
            if line.hasPrefix("P") && line.count > 1 {
                let secondCharIndex = line.index(line.startIndex, offsetBy: 1)
                let secondChar = line[secondCharIndex]

                if let rank = Int(String(secondChar)), rank >= 1 && rank <= 9 {
                    // P1-P9 は無視する
                    currentLineIndex += 1
                    continue
                } else if secondChar == "+" || secondChar == "-" {
                    // 持ち駒行は無視する
                    currentLineIndex += 1
                    continue
                }
            }

            // 手番の宣言（+ または -）
            if line == "+" || line == "-" {
                // 手番は position.color で管理される
                currentLineIndex += 1
                break
            }

            // 指し手の開始
            if line.hasPrefix("+") || line.hasPrefix("-") {
                break
            }

            currentLineIndex += 1
        }
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
            throw FormatError(message: "CSA形式が不正です（期待: +/-FFTTPP）: \(line)")
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
            throw FormatError(message: "指し手データが不正です（ファイル、段、駒コード）: \(line)")
        }

        let toSquare = Square(file: toFile, rank: toRank)

        let move: Move
        if fromFile == 0 && fromRank == 0 {
            // 手駒から打つ手
            let capturedPiece = record.position.board.at(toSquare)
            let capturedPieceType = capturedPiece?.unpromoted().type
            move = Move(from: destinationPieceType, to: toSquare, color: color, capturedPieceType: capturedPieceType)
        } else {
            // 盤上の駒を動かす手
            let fromSquare = Square(file: fromFile, rank: fromRank)

            // 移動元の駒を確認する
            guard let sourcePiece = record.position.board.at(fromSquare) else {
                throw FormatError(message: "移動元に駒がありません（\(fromStr)): \(line)")
            }

            let sourcePieceType = sourcePiece.type
            // 駒が成駒かどうかを判定：成る前のタイプと現在のタイプが異なる
            let sourceIsPromoted = unpromotedType(of: sourcePieceType) != sourcePieceType

            // 成ったかどうかの判定：
            // - 移動先コードが成駒（UM, RY等）
            // - かつ移動元の駒が成ったていない（角→馬、飛→竜の成り）
            let promote = isPromotedPiece(destinationPieceType) && !sourceIsPromoted

            // 移動先の駒を取得
            let capturedPiece = record.position.board.at(toSquare)
            let capturedPieceType = capturedPiece?.unpromoted().type

            move = Move(from: fromSquare, to: toSquare, promote: promote, color: color, pieceType: sourcePieceType, capturedPieceType: capturedPieceType)
        }

        // 手を適用
        let success = record.append(move)
        if !success {
            throw FormatError(message: "不正な指し手（ルール違反またはその他の検証エラー）: \(line)")
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
