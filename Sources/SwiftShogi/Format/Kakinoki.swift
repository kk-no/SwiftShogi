import Foundation

/// KIF/KI2形式の種類
public enum KakinokiFormatType: String {
    case KIF
    case KI2
}

/// KIF/KI2形式の行の種類
private enum LineType {
    case programComment // プログラム用コメント
    case metadata // メタデータ
    case handicap // 手合割
    case blackHand // 先手の持ち駒
    case whiteHand // 後手の持ち駒
    case board // 盤面
    case blackTurn // 先手番
    case whiteTurn // 後手番
    case move // 指し手 (KIF)
    case move2 // 指し手 (KI2)
    case branch // 変化手順
    case comment // コメント
    case bookmark // しおり
    case endOfGame // 終局理由
    case unknown // 不明な行
}

/// 柿木形式のメタデータキー名とRecordMetadataKeyの対応マップ
private let metadataKeyMap: [String: RecordMetadataKey] = [
    "先手": .blackName,
    "後手": .whiteName,
    "下手": .shitateName,
    "上手": .uwateName,
    "開始日時": .startDatetime,
    "終了日時": .endDatetime,
    "対局日": .date,
    "棋戦": .tournament,
    "戦型": .strategy,
    "表題": .title,
    "持ち時間": .timeLimit,
    "秒読み": .byoyomi,
    "消費時間": .timeSpent,
    "場所": .place,
    "掲載": .postedOn,
    "備考": .note,
    "先手省略名": .blackShortName,
    "後手省略名": .whiteShortName,
    "記録係": .scorekeeper,
    "作品番号": .opusNo,
    "作品名": .opusName,
    "作者": .author,
    "発表誌": .publishedBy,
    "発表年月": .publishedAt,
    "出典": .source,
    "手数": .length,
    "完全性": .integrity,
    "分類": .category,
    "受賞": .award,

    // CSA 形式で規定されている項目
    "先手持ち時間": .blackTimeLimit,
    "後手持ち時間": .whiteTimeLimit,
    "最大手数": .maxMoves,
    "持将棋": .jishogi,
]

/// RecordMetadataKeyから柿木形式のメタデータキー名への対応マップ
private let metadataNameMap: [RecordMetadataKey: String] = [
    .blackName: "先手",
    .whiteName: "後手",
    .shitateName: "下手",
    .uwateName: "上手",
    .startDatetime: "開始日時",
    .endDatetime: "終了日時",
    .date: "対局日",
    .tournament: "棋戦",
    .strategy: "戦型",
    .title: "表題",
    .timeLimit: "持ち時間",
    .byoyomi: "秒読み",
    .timeSpent: "消費時間",
    .place: "場所",
    .postedOn: "掲載",
    .note: "備考",
    .blackShortName: "先手省略名",
    .whiteShortName: "後手省略名",
    .scorekeeper: "記録係",
    .opusNo: "作品番号",
    .opusName: "作品名",
    .author: "作者",
    .publishedBy: "発表誌",
    .publishedAt: "発表年月",
    .source: "出典",
    .length: "手数",
    .integrity: "完全性",
    .category: "分類",
    .award: "受賞",

    // CSA 形式で規定されている項目
    .blackTimeLimit: "先手持ち時間",
    .whiteTimeLimit: "後手持ち時間",
    .maxMoves: "最大手数",
    .jishogi: "持将棋",
]

/// 特殊な指し手の表示用文字列マップ
private let specialMoveToDisplayStringMap: [SpecialMoveType: String] = [
    .start: "開始局面",
    .resign: "投了",
    .interrupt: "中断",
    .maxMoves: "最大手数",
    .impass: "持将棋",
    .draw: "引き分け",
    .repetitionDraw: "千日手",
    .mate: "詰み",
    .noMate: "不詰",
    .timeout: "切れ負け",
    .foulWin: "反則勝ち",
    .foulLose: "反則負け",
    .enteringOfKing: "入玉",
    .winByDefault: "不戦勝",
    .loseByDefault: "不戦敗",
    .try: "トライ",
]

/// 特殊な指し手の文字列からSpecialMoveTypeへの変換マップ
private let stringToSpecialMoveType: [String: SpecialMoveType] = [
    "中断": .interrupt,
    "投了": .resign,
    "持将棋": .impass,
    "千日手": .repetitionDraw,
    "詰み": .mate,
    "詰": .mate,
    "不詰": .noMate,
    "切れ負け": .timeout,
    "反則勝ち": .foulWin,
    "反則負け": .foulLose,
    "入玉勝ち": .enteringOfKing,
    "不戦勝": .winByDefault,
    "不戦敗": .loseByDefault,
]

/// 解析された行情報
private struct Line {
    let type: LineType
    let data: String
    let isPosition: Bool
    let metadataKey: String
}

/// 柿木形式のメタデータキー名を RecordMetadataKey へ変換します
/// - Parameter key: メタデータキー名
/// - Returns: RecordMetadataKeyまたはnil
public func kakinokiToMetadataKey(_ key: String) -> RecordMetadataKey? {
    return metadataKeyMap[key]
}

/// RecordMetadataKey を柿木形式のメタデータのキー名へ変換します
/// - Parameter key: RecordMetadataKey
/// - Returns: メタデータキー名
public func metadataKeyToKakinoki(_ key: RecordMetadataKey) -> String {
    return metadataNameMap[key] ?? key.rawValue
}

/// KIF形式の出力オプション
public struct KIFExportOptions {
    /// 改行コード
    public let returnCode: String

    /// コメント
    public let comment: String?

    public init(returnCode: String = "\n", comment: String? = nil) {
        self.returnCode = returnCode
        self.comment = comment
    }
}

/// KI2形式の出力オプション
public struct KI2ExportOptions {
    /// 改行コード
    public let returnCode: String

    public init(returnCode: String = "\n") {
        self.returnCode = returnCode
    }
}

/// 柿木形式（KIF/KI2）のパーサーとフォーマッター
public class KakinokiFormatter {
    /// 行のパターン定義
    private static let linePatterns: [(prefix: String, type: LineType, removePrefix: Bool, isPosition: Bool)] = [
        (prefix: "^#", type: .programComment, removePrefix: false, isPosition: false),
        (prefix: "^手合割[：:]", type: .handicap, removePrefix: true, isPosition: true),
        (prefix: "^(先|下)手の持駒[：:]", type: .blackHand, removePrefix: true, isPosition: true),
        (prefix: "^(後|上)手の持駒[：:]", type: .whiteHand, removePrefix: true, isPosition: true),
        (prefix: "^\\|", type: .board, removePrefix: false, isPosition: true),
        (prefix: "^(先|下)手番", type: .blackTurn, removePrefix: false, isPosition: true),
        (prefix: "^(後|上)手番", type: .whiteTurn, removePrefix: false, isPosition: true),
        (prefix: "^ *[0-9]+ +", type: .move, removePrefix: false, isPosition: false),
        (prefix: "^[ \\u{3000}]*[▲△▼▽☗☖]", type: .move2, removePrefix: false, isPosition: false),
        (prefix: "^[ \\u{3000}]*変化[：:][ \\u{3000}]*", type: .branch, removePrefix: true, isPosition: false),
        (prefix: "^\\*", type: .comment, removePrefix: true, isPosition: false),
        (prefix: "^&", type: .bookmark, removePrefix: true, isPosition: false),
        (prefix: "^まで、?([0-9]+手で)?", type: .endOfGame, removePrefix: true, isPosition: false),
    ]

    /// 行を解析します
    /// - Parameter line: 解析する行
    /// - Returns: 解析結果
    private static func parseLine(_ line: String) -> Line {
        for pattern in linePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern.prefix, options: []),
               let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count))
            {
                let begin = pattern.removePrefix ? match.range.length : 0
                let data = begin < line.count ? String(line.dropFirst(begin)) : ""
                return Line(type: pattern.type, data: data, isPosition: pattern.isPosition, metadataKey: "")
            }
        }

        // メタデータ行のチェック
        if let regex = try? NSRegularExpression(pattern: "^[^ ：:]+[：:]", options: []),
           let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count))
        {
            guard let matchRange = Range(match.range, in: line) else {
                return Line(type: .unknown, data: line, isPosition: false, metadataKey: "")
            }

            let prefix = String(line[matchRange])
            let key = String(prefix.dropLast())
            let data = String(line.dropFirst(match.range.length))

            return Line(type: .metadata, data: data, isPosition: false, metadataKey: key)
        }

        return Line(type: .unknown, data: line, isPosition: false, metadataKey: "")
    }

    /// 手合割情報を読み取ります
    /// - Parameters:
    ///   - position: 局面
    ///   - data: 手合割情報
    private static func readHandicap(position: Position, data: String) {
        let trimmed = data.trimmingCharacters(in: .whitespacesAndNewlines)
        switch trimmed {
        case "平手":
            position.resetBySFEN(InitialPositionSFEN.standard)
        case "香落ち":
            position.resetBySFEN(InitialPositionSFEN.handicapLance)
        case "右香落ち":
            position.resetBySFEN(InitialPositionSFEN.handicapRightLance)
        case "角落ち":
            position.resetBySFEN(InitialPositionSFEN.handicapBishop)
        case "飛車落ち":
            position.resetBySFEN(InitialPositionSFEN.handicapRook)
        case "飛香落ち":
            position.resetBySFEN(InitialPositionSFEN.handicapRookLance)
        case "二枚落ち":
            position.resetBySFEN(InitialPositionSFEN.handicap2Pieces)
        case "四枚落ち":
            position.resetBySFEN(InitialPositionSFEN.handicap4Pieces)
        case "六枚落ち":
            position.resetBySFEN(InitialPositionSFEN.handicap6Pieces)
        case "八枚落ち":
            position.resetBySFEN(InitialPositionSFEN.handicap8Pieces)
        case "十枚落ち":
            position.resetBySFEN(InitialPositionSFEN.handicap10Pieces)
        case "その他":
            position.resetBySFEN(InitialPositionSFEN.empty)
        default:
            // マイナビ系のソフトウェアは「手合割：詰将棋」を使用する場合がある。
            // それを含め柿木将棋で規定していない値が使われるケースがしばしばあり、
            // それらに対して適切な処理を判断しようがなく、
            // エラーを返すわけにも行かないためここでは何もしない。
            break
        }
    }

    /// 盤面情報を読み取ります
    /// - Parameters:
    ///   - board: 盤面
    ///   - data: 盤面情報
    /// - Returns: エラーまたはnil
    private static func readBoard(board: Board, data: String) -> Error? {
        guard data.count >= 21 else {
            return FormatError(message: "Invalid board data format")
        }

        let rankIndex = data.index(data.startIndex, offsetBy: 20)
        let rankStr = String(data[rankIndex])

        guard let rank = TextUtil.stringToNumber(rankStr) else {
            return FormatError(message: "Invalid rank number")
        }

        for x in 0 ..< 9 {
            let file = 9 - x
            let square = Square(file: file, rank: rank)
            let index = x * 2 + 1

            guard index + 1 < data.count else {
                continue
            }

            let pieceIndex = data.index(data.startIndex, offsetBy: index + 1)
            let pieceStr = String(data[pieceIndex])

            guard let pieceType = TextUtil.stringToPieceType(pieceStr) else {
                board.remove(square: square)
                continue
            }

            let colorIndex = data.index(data.startIndex, offsetBy: index)
            let colorChar = data[colorIndex]
            let color: Color = colorChar != "v" ? .black : .white

            board.set(square: square, piece: Piece(color: color, type: pieceType))
        }

        return nil
    }

    /// 持ち駒情報を読み取ります
    /// - Parameters:
    ///   - hand: 持ち駒
    ///   - data: 持ち駒情報
    /// - Returns: エラーまたはnil
    private static func readHand(hand: Hand, data: String) -> Error? {
        // スペースで区切られていないものでも Kifu for Windows や ShogiGUI は読み込める。
        let sections = data.split(separator: " ").flatMap { $0.split(separator: "　") }

        for section in sections {
            let sectionStr = String(section)
            if sectionStr.isEmpty || sectionStr == "なし" {
                continue
            }

            guard let firstChar = sectionStr.first else {
                continue
            }

            let pieceStr = String(firstChar)
            let numberStr = String(sectionStr.dropFirst())

            guard let pieceType = TextUtil.stringToPieceType(pieceStr) else {
                return FormatError(message: "Invalid hand piece: \(sectionStr)")
            }

            let count = numberStr.isEmpty ? 1 : (TextUtil.stringToNumber(numberStr) ?? 1)
            hand.add(pieceType: pieceType, count: count)
        }

        return nil
    }

    /// 指し手の経過時間情報を読み取ります
    /// - Parameters:
    ///   - record: 棋譜
    ///   - data: 時間情報を含む文字列
    private static func readMoveTime(record: Record, data: String) {
        // 時間情報の正規表現: ( *([0-9]+):([0-9]+)/[0-9: ]*\)
        guard let regex = try? NSRegularExpression(pattern: "\\( *([0-9]+):([0-9]+)/[0-9: ]*\\)", options: []),
              let match = regex.firstMatch(in: data, options: [], range: NSRange(location: 0, length: data.utf16.count))
        else {
            return
        }

        guard match.numberOfRanges >= 3,
              let minutesRange = Range(match.range(at: 1), in: data),
              let secondsRange = Range(match.range(at: 2), in: data),
              let minutes = Int(data[minutesRange]),
              let seconds = Int(data[secondsRange])
        else {
            return
        }

        let elapsedMS = (minutes * 60 + seconds) * 1000

        // elapsedMsを設定するためには具体的なNodeクラスにキャストする必要がある
        if let currentNode = record.current as? Node {
            currentNode.setElapsedMs(elapsedMS)
        }
    }

    /// KIF形式の指し手を読み取ります
    /// - Parameters:
    ///   - record: 棋譜
    ///   - data: 指し手情報
    /// - Returns: エラーまたはnil
    private static func readMove(record: Record, data: String) -> Error? {
        // 通常の指し手を読み取り
        let result = readRegularMove(record: record, data: data)
        if let error = result as? Error {
            return error
        } else if result as? Bool == true {
            return nil
        }

        // 特殊な指し手を読み取り
        if readSpecialMove(record: record, data: data) {
            return nil
        }

        return FormatError(message: "Invalid move: \(data)")
    }

    /// KIF形式の通常の指し手を読み取ります
    /// - Parameters:
    ///   - record: 棋譜
    ///   - data: 指し手情報
    /// - Returns: 読み取り結果（Errorまたはbool）
    private static func readRegularMove(record: Record, data: String) -> Any {
        // 指し手の正規表現
        guard let regex = try? NSRegularExpression(pattern: #"^ *([0-9]+) +[▲△▼▽]?([１２３４５６７８９][一二三四五六七八九]|同\s*)(王|玉|飛|龍|竜|角|馬|金|銀|成銀|全|桂|成桂|圭|香|成香|杏|歩|と)\s*(成?)(打|\([1-9][1-9]\))\s*(.*|$)"#, options: []),
              let match = regex.firstMatch(in: data, options: [], range: NSRange(location: 0, length: data.utf16.count))
        else {
            return false
        }

        guard match.numberOfRanges >= 7,
              let numberRange = Range(match.range(at: 1), in: data),
              let toStrRange = Range(match.range(at: 2), in: data),
              let pieceTypeStrRange = Range(match.range(at: 3), in: data),
              let promStrRange = Range(match.range(at: 4), in: data),
              let fromStrRange = Range(match.range(at: 5), in: data),
              let timeStrRange = Range(match.range(at: 6), in: data)
        else {
            return false
        }

        let numberStr = String(data[numberRange])
        let toStr = String(data[toStrRange])
        let pieceTypeStr = String(data[pieceTypeStrRange])
        let promStr = String(data[promStrRange])
        let fromStr = String(data[fromStrRange])
        let timeStr = String(data[timeStrRange])

        guard let number = Int(numberStr), number > 0 else {
            return FormatError(message: "Invalid move number: \(numberStr)")
        }

        // 手数を設定
        record.goto(number - 1)

        // 移動先を解析
        let to: Square
        if toStr.hasPrefix("同") {
            guard let lastMove = record.current.move as? Move else {
                return FormatError(message: "Cannot find previous move to apply 'same position' notation")
            }
            to = lastMove.to
        } else {
            let fileIndex = toStr.startIndex
            let rankIndex = toStr.index(after: fileIndex)

            guard let file = TextUtil.stringToNumber(String(toStr[fileIndex])),
                  let rank = TextUtil.stringToNumber(String(toStr[rankIndex...]))
            else {
                return FormatError(message: "Invalid destination: \(toStr)")
            }

            to = Square(file: file, rank: rank)
        }

        // 駒の種類を解析
        guard let pieceType = TextUtil.stringToPieceType(pieceTypeStr) else {
            return FormatError(message: "Invalid piece type: \(pieceTypeStr)")
        }

        // 移動元を解析
        let from: Either<Square, PieceType>
        if fromStr == "打" {
            from = .right(pieceType)
        } else if fromStr.count >= 4 && fromStr.hasPrefix("(") && fromStr.hasSuffix(")") {
            // 座標指定形式 (例: "(76)")
            let fileIndex = fromStr.index(fromStr.startIndex, offsetBy: 1)
            let rankIndex = fromStr.index(fromStr.startIndex, offsetBy: 2)

            guard let file = Int(String(fromStr[fileIndex])),
                  let rank = Int(String(fromStr[rankIndex]))
            else {
                return FormatError(message: "Invalid source position: \(fromStr)")
            }

            from = .left(Square(file: file, rank: rank))
        } else {
            // 方向指定形式などから移動元を特定
            let attackers = record.position.listAttackersByPiece(to: to, piece: Piece(color: record.position.color, type: pieceType))

            // 条件に合う移動可能な駒を絞り込む
            let candidates = attackers.filter { _ in
                // 指定された方向条件に一致する駒のみ選択
                true
            }

            if candidates.count == 1 {
                from = .left(candidates[0])
            } else if candidates.isEmpty && record.position.hand(color: record.position.color).count(pieceType: pieceType) > 0 {
                from = .right(pieceType)
            } else {
                return FormatError(message: "Cannot determine the source of the move")
            }
        }

        // 指し手を生成
        guard var move = record.position.createMove(from: from, to: to) else {
            return FormatError(message: "Invalid move")
        }

        // 成りの設定
        if promStr == "成" {
            move = move.withPromote()
        }

        // 指し手を追加
        if !record.append(move, option: DoMoveOption(ignoreValidation: true)) {
            return FormatError(message: "Failed to apply move")
        }

        // 時間情報を読み取り
        readMoveTime(record: record, data: timeStr)

        return true
    }

    /// KIF形式の特殊な指し手を読み取ります
    /// - Parameters:
    ///   - record: 棋譜
    ///   - data: 指し手情報
    /// - Returns: 読み取り成功ならtrue
    private static func readSpecialMove(record: Record, data: String) -> Bool {
        // 特殊な指し手の正規表現
        guard let regex = try? NSRegularExpression(pattern: #"^ *([0-9]+) +(\S+) *\s*(.*|$)"#, options: []),
              let match = regex.firstMatch(in: data, options: [], range: NSRange(location: 0, length: data.utf16.count))
        else {
            return false
        }

        guard match.numberOfRanges >= 4,
              let numberRange = Range(match.range(at: 1), in: data),
              let moveRange = Range(match.range(at: 2), in: data),
              let timeRange = Range(match.range(at: 3), in: data)
        else {
            return false
        }

        let numberStr = String(data[numberRange])
        let moveStr = String(data[moveRange])
        let timeStr = String(data[timeRange])

        guard let number = Int(numberStr), number > 0 else {
            return false
        }

        // 手数を設定
        record.goto(number - 1)

        let moveType = stringToSpecialMoveType[moveStr]
        let specialMove: SpecialMove

        if let type = moveType {
            specialMove = .predefined(PredefinedSpecialMove(type: type))
        } else {
            specialMove = anySpecialMove(moveStr)
        }

        // 特殊な指し手を追加
        record.append(specialMove, option: DoMoveOption(ignoreValidation: true))

        // 時間情報を読み取り
        readMoveTime(record: record, data: timeStr)

        return true
    }

    /// KI2形式の指し手を読み取ります
    /// - Parameters:
    ///   - record: 棋譜
    ///   - data: 指し手情報
    /// - Returns: エラーまたはnil
    private static func readMove2(record: Record, data: String) -> Error? {
        let lastMove = record.current.move as? Move
        let movesResult = parseMoves(position: record.position as! Position, text: data, lastMove: lastMove)

        switch movesResult {
        case let .success(moves):
            for move in moves {
                record.append(move, option: DoMoveOption(ignoreValidation: true))
            }
            return nil
        case let .failure(error):
            return error
        }
    }

    /// 分岐情報を読み取ります
    /// - Parameters:
    ///   - record: 棋譜
    ///   - data: 分岐情報
    /// - Returns: エラーまたはnil
    private static func readBranch(record: Record, data: String) -> Error? {
        // 分岐の正規表現
        guard let regex = try? NSRegularExpression(pattern: "^ *([0-9]+)", options: []),
              let match = regex.firstMatch(in: data, options: [], range: NSRange(location: 0, length: data.utf16.count))
        else {
            return FormatError(message: "Invalid branch format")
        }

        guard let numberRange = Range(match.range(at: 1), in: data),
              let number = Int(data[numberRange])
        else {
            return FormatError(message: "Invalid move number in branch")
        }

        if number == 0 || number > record.current.ply + 1 {
            return FormatError(message: "Invalid move number: \(number)")
        }

        // 分岐の手数までジャンプ
        record.goto(number - 1)
        return nil
    }

    /// 終局情報を読み取ります
    /// - Parameters:
    ///   - record: 棋譜
    ///   - data: 終局情報
    private static func readEndOfGame(record: Record, data: String) {
        let clean = data.replacingOccurrences(of: "[\u{3000}\\s]", with: "", options: .regularExpression)

        // 特殊なケースを先に判定
        let specialMoveObj: SpecialMove

        if clean.hasPrefix("時間切れ") {
            specialMoveObj = .predefined(PredefinedSpecialMove(type: .timeout))
        } else if clean.hasSuffix("反則勝ち") {
            specialMoveObj = .predefined(PredefinedSpecialMove(type: .foulWin))
        } else if clean.hasSuffix("反則負け") {
            specialMoveObj = .predefined(PredefinedSpecialMove(type: .foulLose))
        } else if clean.hasSuffix("入玉勝ち") {
            specialMoveObj = .predefined(PredefinedSpecialMove(type: .enteringOfKing))
        } else if clean.hasSuffix("勝ち") {
            specialMoveObj = .predefined(PredefinedSpecialMove(type: .resign))
        } else {
            // 標準のSpecialMoveTypeの場合
            if let type = stringToSpecialMoveType[clean] {
                specialMoveObj = .predefined(PredefinedSpecialMove(type: type))
            } else {
                // それ以外の場合は任意の文字列として扱う
                specialMoveObj = .any(AnySpecialMove(name: clean))
            }
        }

        record.append(specialMoveObj)
    }

    /// KIF形式の棋譜文字列を解析します
    /// - Parameter data: KIF形式の棋譜文字列
    /// - Returns: 棋譜またはエラー
    public static func importKIF(_ data: String) -> Result<Record, Error> {
        return importKakinoki(data: data, formatType: .KIF)
    }

    /// KI2形式の棋譜文字列を解析します
    /// - Parameter data: KI2形式の棋譜文字列
    /// - Returns: 棋譜またはエラー
    public static func importKI2(_ data: String) -> Result<Record, Error> {
        return importKakinoki(data: data, formatType: .KI2)
    }

    /// 柿木形式（KIF/KI2）の棋譜文字列を解析します
    /// - Parameters:
    ///   - data: 棋譜文字列
    ///   - formatType: 形式の種類
    /// - Returns: 棋譜またはエラー
    private static func importKakinoki(data: String, formatType: KakinokiFormatType) -> Result<Record, Error> {
        let metadata = RecordMetadata()
        let record = Record()
        let position = Position()
        var preMoveComment = ""
        var preMoveBookmark = ""
        var isMoveSection = false

        let lines = data.split(separator: "\n").map { String($0) }

        // 各行を解析
        for line in lines {
            if line.isEmpty {
                continue
            }

            let parsed = parseLine(line)

            // 指し手セクションに入った後に局面設定行が来たらエラー
            if isMoveSection && parsed.isPosition {
                return .failure(FormatError(message: "Position data found after move section"))
            }

            switch parsed.type {
            case .metadata:
                // 標準メタデータまたはカスタムメタデータとして設定
                if let standardKey = metadataKeyMap[parsed.metadataKey] {
                    metadata.setStandardMetadata(standardKey, value: parsed.data)
                } else {
                    metadata.setCustomMetadata(parsed.metadataKey, value: parsed.data)
                }

            case .handicap:
                readHandicap(position: position, data: parsed.data)

            case .blackHand:
                if let error = readHand(hand: position.blackHand as! Hand, data: parsed.data) {
                    return .failure(error)
                }

            case .whiteHand:
                if let error = readHand(hand: position.whiteHand as! Hand, data: parsed.data) {
                    return .failure(error)
                }

            case .board:
                if let error = readBoard(board: position.board as! Board, data: parsed.data) {
                    return .failure(error)
                }

            case .blackTurn:
                position.setColor(.black)

            case .whiteTurn:
                position.setColor(.white)

            case .move:
                if formatType != .KIF {
                    return .failure(FormatError(message: "KIF move format found in KI2 file"))
                }

                startMoveSectionIfNot(record: record, position: position, preMoveComment: preMoveComment, preMoveBookmark: preMoveBookmark, isMoveSection: &isMoveSection)

                if let error = readMove(record: record, data: parsed.data) {
                    return .failure(error)
                }

            case .move2:
                if formatType != .KI2 {
                    return .failure(FormatError(message: "KI2 move format found in KIF file"))
                }

                startMoveSectionIfNot(record: record, position: position, preMoveComment: preMoveComment, preMoveBookmark: preMoveBookmark, isMoveSection: &isMoveSection)

                if let error = readMove2(record: record, data: parsed.data) {
                    return .failure(error)
                }

            case .branch:
                // KIF では指し手の先頭に手数が付与されるので必要ない。
                // KI2の場合のみ分岐を処理
                if isMoveSection && formatType == .KI2 {
                    if let error = readBranch(record: record, data: parsed.data) {
                        return .failure(error)
                    }
                }

            case .comment:
                if isMoveSection {
                    if let node = record.current as? Node {
                        node.comment = StringUtil.appendLine(node.comment, parsed.data)
                    }
                } else {
                    preMoveComment = StringUtil.appendLine(preMoveComment, parsed.data)
                }

            case .bookmark:
                if isMoveSection {
                    if let node = record.current as? Node {
                        node.bookmark = parsed.data
                    }
                } else {
                    preMoveBookmark = parsed.data
                }

            case .endOfGame:
                // KI2では "までn手で" で始まる行から終局理由を読み取る。
                // KIFでは指し手の一つとしても記載されるので必要ない。
                if formatType == .KI2 {
                    startMoveSectionIfNot(record: record, position: position, preMoveComment: preMoveComment, preMoveBookmark: preMoveBookmark, isMoveSection: &isMoveSection)
                    readEndOfGame(record: record, data: parsed.data)
                }

            case .programComment, .unknown:
                // 無視
                break
            }
        }

        // 指し手セクションを開始していない場合は開始する
        startMoveSectionIfNot(record: record, position: position, preMoveComment: preMoveComment, preMoveBookmark: preMoveBookmark, isMoveSection: &isMoveSection)

        record.goto(0)
        record.resetAllBranchSelection()
        record.metadata = metadata

        return .success(record)
    }

    /// 指し手セクションを開始していない場合に開始します
    /// - Parameters:
    ///   - record: 棋譜
    ///   - position: 局面
    ///   - preMoveComment: 指し手前のコメント
    ///   - preMoveBookmark: 指し手前のブックマーク
    ///   - isMoveSection: 指し手セクションかどうかのフラグ
    private static func startMoveSectionIfNot(record: Record, position: Position, preMoveComment: String, preMoveBookmark: String, isMoveSection: inout Bool) {
        if isMoveSection {
            return
        }

        record.clear(position: position)
        if let firstNode = record.first as? Node {
            firstNode.comment = preMoveComment
            firstNode.bookmark = preMoveBookmark
        }
        isMoveSection = true
    }

    /// KI2形式の指し手を解析します
    /// - Parameters:
    ///   - position: 局面
    ///   - text: 指し手文字列
    ///   - lastMove: 前の指し手
    /// - Returns: 指し手の配列または失敗
    public static func parseMoves(position: Position, text: String, lastMove: Move? = nil) -> Result<[Move], Error> {
        let moveRegExp = "[▲△▼▽☗☖]?([１２３４５６７８９一二三四五六七八九1-9]{2}|同)(王|玉|飛|龍|竜|角|馬|金|銀|成銀|全|桂|成桂|圭|香|成香|杏|歩|と)(左|直|右|)(引|寄|上|)(成|不成|打|)(\\([1-9][1-9]\\)|)"

        let clean = text.replacingOccurrences(of: "[\\s\\u{3000}]", with: "", options: .regularExpression)
        var moves: [Move] = []

        if clean.isEmpty {
            return .success([])
        }

        // 正規表現でマッチング
        guard let regex = try? NSRegularExpression(pattern: moveRegExp, options: []) else {
            return .failure(FormatError(message: "Failed to create regular expression"))
        }

        let range = NSRange(location: 0, length: clean.utf16.count)
        let matches = regex.matches(in: clean, options: [], range: range)

        if matches.isEmpty {
            return .failure(FormatError(message: "No valid moves found in: \(text)"))
        }

        let p = position.clone()

        for match in matches {
            guard match.numberOfRanges >= 7,
                  let toStrRange = Range(match.range(at: 1), in: clean),
                  let pieceTypeStrRange = Range(match.range(at: 2), in: clean),
                  let horStrRange = Range(match.range(at: 3), in: clean),
                  let verStrRange = Range(match.range(at: 4), in: clean),
                  let promOrDropStrRange = Range(match.range(at: 5), in: clean),
                  let fromStrRange = Range(match.range(at: 6), in: clean)
            else {
                return .failure(FormatError(message: "Invalid move format"))
            }

            let toStr = String(clean[toStrRange])
            let pieceTypeStr = String(clean[pieceTypeStrRange])
            let horStr = String(clean[horStrRange])
            let verStr = String(clean[verStrRange])
            let promOrDropStr = String(clean[promOrDropStrRange])
            let fromStr = String(clean[fromStrRange])

            // 移動先の解析
            let to: Square
            if toStr.hasPrefix("同") {
                if let lastMoveTo = (!moves.isEmpty ? moves.last?.to : lastMove?.to) {
                    to = lastMoveTo
                } else {
                    return .failure(FormatError(message: "Cannot determine 'same' position"))
                }
            } else {
                let fileStr = String(toStr.prefix(1))
                let rankStr = String(toStr.dropFirst())

                guard let file = TextUtil.stringToNumber(fileStr),
                      let rank = TextUtil.stringToNumber(rankStr)
                else {
                    return .failure(FormatError(message: "Invalid destination: \(toStr)"))
                }

                to = Square(file: file, rank: rank)
            }

            // 駒の種類を解析
            guard let pieceType = TextUtil.stringToPieceType(pieceTypeStr) else {
                return .failure(FormatError(message: "Invalid piece type: \(pieceTypeStr)"))
            }

            // 移動元の解析
            let from: Either<Square, PieceType>
            if promOrDropStr == "打" {
                from = .right(pieceType)
            } else if !fromStr.isEmpty {
                // 座標指定形式 (例: "(76)")
                let fileIndex = fromStr.index(fromStr.startIndex, offsetBy: 1)
                let rankIndex = fromStr.index(fromStr.startIndex, offsetBy: 2)

                guard let file = Int(String(fromStr[fileIndex])),
                      let rank = Int(String(fromStr[rankIndex]))
                else {
                    return .failure(FormatError(message: "Invalid source position: \(fromStr)"))
                }

                from = .left(Square(file: file, rank: rank))
            } else {
                // 方向指定を元に移動元を特定
                var candidates = p.listAttackersByPiece(to: to, piece: Piece(color: p.color, type: pieceType))

                // 方向修飾子による絞り込み
                if !horStr.isEmpty || !verStr.isEmpty {
                    candidates = candidates.filter { _ in
                        // TODO: 方向条件によるフィルタリングを実装
                        // 実際にはもっと複雑な条件がある
                        true
                    }
                }

                if candidates.count == 1 {
                    from = .left(candidates[0])
                } else if candidates.isEmpty && p.hand(color: p.color).count(pieceType: pieceType) > 0 {
                    from = .right(pieceType)
                } else {
                    return .failure(FormatError(message: "Cannot determine move source"))
                }
            }

            // 指し手を生成
            guard var move = p.createMove(from: from, to: to) else {
                return .failure(FormatError(message: "Invalid move"))
            }

            // 成りの設定
            if promOrDropStr == "成" {
                move = move.withPromote()
            }

            // 現在の局面に指し手を適用
            if !p.doMove(move, option: DoMoveOption(ignoreValidation: true)) {
                return .failure(FormatError(message: "Failed to apply move"))
            }

            moves.append(move)
        }

        return .success(moves)
    }

    /// KIF形式の指し手を出力します
    /// - Parameters:
    ///   - move: 指し手
    ///   - options: オプション（前の指し手、パディング）
    /// - Returns: 指し手の文字列
    public static func formatKIFMove(_ move: Move, options: [String: Any] = [:]) -> String {
        var ret = ""

        // 前の指し手と移動先が同じなら「同」を表示、そうでなければ座標を表示
        if let prev = options["prev"] as? Move, prev.to == move.to {
            ret += "同\u{3000}"
        } else {
            ret += TextUtil.fileToMultiByteChar(move.to.file)
            ret += TextUtil.rankToKanji(move.to.rank)
        }

        // 駒の種類
        ret += TextUtil.pieceTypeToStringForMove(move.pieceType)

        // 成り・不成り
        if move.promote {
            ret += "成"
        }

        // 駒打ちまたは座標表示
        if move.isFromBoard, let fromSquare = move.from.leftValue {
            ret += "(\(fromSquare.file)\(fromSquare.rank))"

            // パディングオプションが有効な場合、長さを揃える
            if (options["padding"] as? Bool) == true && ret.count == 7 {
                ret += "  "
            }
        } else {
            ret += "打"

            // パディングオプションが有効な場合、長さを揃える
            if (options["padding"] as? Bool) == true {
                ret += "    "
            }
        }

        return ret
    }

    /// メタデータを出力します
    /// - Parameters:
    ///   - metadata: メタデータ
    ///   - options: 出力オプション
    /// - Returns: メタデータの文字列
    private static func formatMetadata(_ metadata: ImmutableRecordMetadata, options: KIFExportOptions) -> String {
        var ret = ""
        let returnCode = options.returnCode

        // 標準メタデータを出力
        for key in metadata.standardMetadataKeys {
            if let value = metadata.getStandardMetadata(key) {
                ret += metadataNameMap[key]! + "：" + value + returnCode
            }
        }

        // カスタムメタデータを出力
        for key in metadata.customMetadataKeys {
            if let value = metadata.getCustomMetadata(key) {
                ret += key + "：" + value + returnCode
            }
        }

        return ret
    }

    /// 局面情報を出力します
    /// - Parameters:
    ///   - position: 局面
    ///   - options: 出力オプション
    /// - Returns: 局面情報の文字列
    private static func formatPosition(_ position: ImmutablePosition, options: KIFExportOptions) -> String {
        let returnCode = options.returnCode
        let sfen = position.sfen

        // 定型の初期局面の場合は手合割だけ出力
        switch sfen {
        case InitialPositionSFEN.standard:
            return "手合割：平手" + returnCode
        case InitialPositionSFEN.handicapLance:
            return "手合割：香落ち" + returnCode
        case InitialPositionSFEN.handicapRightLance:
            return "手合割：右香落ち" + returnCode
        case InitialPositionSFEN.handicapBishop:
            return "手合割：角落ち" + returnCode
        case InitialPositionSFEN.handicapRook:
            return "手合割：飛車落ち" + returnCode
        case InitialPositionSFEN.handicapRookLance:
            return "手合割：飛香落ち" + returnCode
        case InitialPositionSFEN.handicap2Pieces:
            return "手合割：二枚落ち" + returnCode
        case InitialPositionSFEN.handicap4Pieces:
            return "手合割：四枚落ち" + returnCode
        case InitialPositionSFEN.handicap6Pieces:
            return "手合割：六枚落ち" + returnCode
        case InitialPositionSFEN.handicap8Pieces:
            return "手合割：八枚落ち" + returnCode
        case InitialPositionSFEN.handicap10Pieces:
            return "手合割：十枚落ち" + returnCode
        default: break
        }

        // カスタム配置の場合は詳細な盤面情報を出力
        var ret = ""
        ret += "後手の持駒：" + formatHand(position.whiteHand) + returnCode
        ret += "  ９ ８ ７ ６ ５ ４ ３ ２ １" + returnCode
        ret += "+---------------------------+" + returnCode

        for y in 0 ..< 9 {
            ret += "|"
            for x in 0 ..< 9 {
                let square = Square.fromXY(x: x, y: y)
                let piece = position.board.at(square)

                if piece == nil {
                    ret += " ・"
                } else if piece!.color == .black {
                    ret += " " + TextUtil.pieceTypeToStringForBoard(piece!.type)
                } else {
                    ret += "v" + TextUtil.pieceTypeToStringForBoard(piece!.type)
                }
            }
            ret += "|" + TextUtil.rankToKanji(y + 1) + returnCode
        }

        ret += "+---------------------------+" + returnCode
        ret += "先手の持駒：" + formatHand(position.blackHand) + returnCode

        if position.color == .black {
            ret += "先手番" + returnCode
        } else {
            ret += "後手番" + returnCode
        }

        return ret
    }

    /// 持ち駒情報を出力します
    /// - Parameter hand: 持ち駒
    /// - Returns: 持ち駒情報の文字列
    private static func formatHand(_ hand: any ImmutableHand) -> String {
        var ret = ""

        if let handObj = hand as? Hand {
            for (type, count) in handObj {
                if count >= 1 {
                    ret += TextUtil.pieceTypeToStringForBoard(type)
                    if count >= 2 {
                        ret += TextUtil.numberToKanji(count)
                    }
                    ret += "　"
                }
            }
        }

        if ret.isEmpty {
            ret = "なし"
        }

        return ret
    }

    /// KIF形式の文字列を出力します
    /// - Parameters:
    ///   - record: 棋譜
    ///   - options: 出力オプション
    /// - Returns: KIF形式の文字列
    public static func exportKIF(_ record: ImmutableRecord, options: KIFExportOptions = KIFExportOptions()) -> String {
        var ret = ""
        let returnCode = options.returnCode

        // branchIndex を初期化して全ての分岐が処理できるようにする
        record.goto(0)
        record.resetAllBranchSelection()

        // ヘッダーコメントの出力
        if let comment = options.comment {
            for line in comment.split(separator: "\n") {
                ret += "#\(line)\(returnCode)"
            }
        }

        // 局面情報の出力
        ret += formatPosition(record.initialPosition, options: options)

        // ヘッダー行の出力
        ret += "手数----指手---------消費時間--" + returnCode

        // メイン手順のノードを正しい順序で取得
        var mainLineNodes: [ImmutableNode] = []
        var currentNode: ImmutableNode? = record.first

        while currentNode != nil {
            if currentNode!.ply > 0 {
                mainLineNodes.append(currentNode!)
            }

            // 次のアクティブノードを探す
            var nextNode = currentNode!.next
            while nextNode != nil && !nextNode!.activeBranch {
                nextNode = nextNode!.branch
            }

            currentNode = nextNode
        }

        // メイン手順を出力
        for node in mainLineNodes {
            outputNode(node, &ret, options)
        }

        // 処理済みの分岐を追跡するセット
        var processedBranches = Set<Int>()

        // 棋譜の分岐構造解析と出力のための再帰関数
        func processBranches(mainNodes: [ImmutableNode]) {
            // メイン手順から手数の大きい順に分岐を探す
            let sortedMainNodes = mainNodes.sorted { $0.ply > $1.ply }

            for mainNode in sortedMainNodes {
                if mainNode.hasBranch {
                    // このメインノードから派生する分岐を収集
                    var branchNode = mainNode.branch

                    while branchNode != nil {
                        // ノードのオブジェクトIDを使用して一意に識別
                        let branchNodeId = ObjectIdentifier(branchNode as AnyObject).hashValue

                        // 既に処理済みの分岐はスキップ
                        if !processedBranches.contains(branchNodeId) {
                            // 分岐を処理済みとしてマーク
                            processedBranches.insert(branchNodeId)

                            // 分岐の開始
                            ret += returnCode + "変化：\(mainNode.ply)手" + returnCode

                            // 分岐手順を収集
                            var branchPath: [ImmutableNode] = []
                            var currentBranchNode: ImmutableNode? = branchNode

                            while currentBranchNode != nil {
                                branchPath.append(currentBranchNode!)
                                currentBranchNode = currentBranchNode!.next
                            }

                            // 分岐手順を出力
                            for node in branchPath {
                                outputNode(node, &ret, options)
                            }

                            // この分岐内の分岐を再帰的に処理
                            processBranches(mainNodes: branchPath)
                        }

                        // 次の同手数分岐へ
                        branchNode = branchNode!.branch
                    }
                }
            }
        }

        // 分岐処理を開始
        processBranches(mainNodes: mainLineNodes)

        return ret
    }

    /// ノードを出力する
    private static func outputNode(_ node: ImmutableNode, _ output: inout String, _ options: KIFExportOptions) {
        let returnCode = options.returnCode

        // 手数の出力
        output += String(format: "%4d ", node.ply)

        // 指し手の出力
        if let move = node.move as? Move {
            let prev = (node.prev?.move as? Move)
            output += formatKIFMove(move, options: ["prev": prev as Any, "padding": true])
        } else if let specialMove = node.move as? SpecialMove {
            let name: String
            if let type = SpecialMoveType(rawValue: specialMove.name) {
                name = specialMoveToDisplayStringMap[type] ?? specialMove.name
            } else {
                name = specialMove.name
            }

            // パディングを適用
            let padding = max(12 - name.count * 2, 0)
            output += name + String(repeating: " ", count: padding)
        }

        // 時間情報の出力
        let elapsed = TimeUtil.millisecondsToMSS(node.elapsedMs)
        let totalElapsed = TimeUtil.millisecondsToHHMMSS(node.totalElapsedMs)
        output += " (\(elapsed)/\(totalElapsed))"

        // 分岐マークの出力
        // ノードに分岐がある場合のみ「+」を出力する
        if node.branch != nil {
            output += "+"
        }

        output += returnCode

        // コメントの出力
        if !node.comment.isEmpty {
            var comment = node.comment
            if comment.hasSuffix("\n") {
                comment = String(comment.dropLast())
            }

            for line in comment.split(separator: "\n") {
                output += "*\(line)\(returnCode)"
            }
        }

        // しおりの出力
        if !node.bookmark.isEmpty {
            output += "&\(node.bookmark)\(returnCode)"
        }
    }

    /// KI2形式の文字列を出力します
    /// - Parameters:
    ///   - record: 棋譜
    ///   - options: 出力オプション
    /// - Returns: KI2形式の文字列
    public static func exportKI2(_ record: ImmutableRecord, options: KI2ExportOptions = KI2ExportOptions()) -> String {
        var ret = ""
        var moveCountInLine = 0
        var lastMoveLength = 0

        let returnCode = options.returnCode

        // メタデータの出力（KIFExportOptionsをKI2用に変換）
        let kifOptions = KIFExportOptions(returnCode: returnCode)
        ret += formatMetadata(record.metadata, options: kifOptions)

        // 局面情報の出力
        ret += formatPosition(record.initialPosition, options: kifOptions)

        // swiftformat:disable:next preferForLoop
        record.forEach { node, pos in
            if node.ply != 0 {
                if !node.isFirstBranch {
                    if !ret.hasSuffix(returnCode) {
                        ret += returnCode
                    }
                    ret += returnCode
                    ret += "変化：\(node.ply)手" + returnCode
                    moveCountInLine = 0
                }

                if let move = node.move as? Move {
                    // 指し手の文字列を取得
                    let positionObj = pos as! Position // キャストが必要
                    let str = TextUtil.formatMove(position: positionObj, move: move, options: [
                        "lastMove": node.prev?.move as Any,
                        "compatible": true,
                    ])

                    // 新しい行または既存の行に追加
                    if ret.hasSuffix(returnCode) {
                        moveCountInLine = 0
                    } else if moveCountInLine > 0 {
                        ret += String(repeating: " ", count: max(12 - lastMoveLength * 2, 0))
                    }

                    ret += str
                    lastMoveLength = str.count
                    moveCountInLine += 1

                    // 1行に6手まで表示
                    if moveCountInLine >= 6 {
                        ret += returnCode
                    }
                } else {
                    // 特殊な指し手の場合は改行してから終局情報を出力
                    if !ret.hasSuffix(returnCode) {
                        ret += returnCode
                    }

                    ret += "まで\(node.ply - 1)手で"

                    if let specialMove = node.move as? SpecialMove {
                        if let moveType = SpecialMoveType(rawValue: specialMove.name) {
                            // 先後の情報を含める必要がある場合
                            let nextColor = node.nextColor
                            let prevColor = nextColor.reversed()

                            switch moveType {
                            case .resign:
                                ret += "\(prevColor == .black ? "先手" : "後手")の勝ち"
                            case .timeout:
                                ret += "時間切れにより\(prevColor == .black ? "先手" : "後手")の勝ち"
                            case .enteringOfKing:
                                ret += "\(nextColor == .black ? "先手" : "後手")の入玉勝ち"
                            case .foulWin:
                                ret += "\(nextColor == .black ? "先手" : "後手")の反則勝ち"
                            case .foulLose:
                                ret += "\(nextColor == .black ? "先手" : "後手")の反則負け"
                            default:
                                ret += specialMoveToDisplayStringMap[moveType] ?? specialMove.name
                            }
                        } else {
                            ret += specialMove.name
                        }
                    }

                    ret += returnCode
                }
            }

            // コメントの出力
            if !node.comment.isEmpty {
                if !ret.hasSuffix(returnCode) {
                    ret += returnCode
                }

                var comment = node.comment
                if comment.hasSuffix("\n") {
                    comment = String(comment.dropLast())
                }

                for line in comment.split(separator: "\n") {
                    ret += "*\(line)\(returnCode)"
                }
            }

            // しおりの出力
            if !node.bookmark.isEmpty {
                if !ret.hasSuffix(returnCode) {
                    ret += returnCode
                }
                ret += "&\(node.bookmark)\(returnCode)"
            }
        }

        return ret
    }
}
