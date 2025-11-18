import Foundation

/// USI/SFEN形式のフォーマッター
public class SFENFormatter {
    /// USI形式の棋譜を読み込みます
    /// - Parameter data: USI形式の文字列
    /// - Returns: 棋譜またはエラー
    public static func importUSI(_ data: String) -> Result<Record, Error> {
        // USI形式の各種パターン
        let prefixPositionStartpos = "position startpos "
        let prefixPositionSFEN = "position sfen "
        let prefixStartpos = "startpos "
        let prefixSFEN = "sfen "
        let prefixMoves = "moves "

        if data.hasPrefix(prefixPositionStartpos) {
            return newByUSIFromMoves(position: Position(), data: String(data.dropFirst(prefixPositionStartpos.count)))
        } else if data.hasPrefix(prefixPositionSFEN) {
            return newByUSIFromSFEN(data: String(data.dropFirst(prefixPositionSFEN.count)))
        } else if data.hasPrefix(prefixStartpos) {
            return newByUSIFromMoves(position: Position(), data: String(data.dropFirst(prefixStartpos.count)))
        } else if data.hasPrefix(prefixSFEN) {
            return newByUSIFromSFEN(data: String(data.dropFirst(prefixSFEN.count)))
        } else if data.hasPrefix(prefixMoves) {
            return newByUSIFromMoves(position: Position(), data: data)
        } else {
            return .failure(FormatError(message: "Invalid USI format: \(data)"))
        }
    }

    /// SFEN部分からのUSI読み込み
    /// - Parameter data: SFEN部分の文字列
    /// - Returns: 棋譜またはエラー
    private static func newByUSIFromSFEN(data: String) -> Result<Record, Error> {
        let sections = data.split(separator: " ")

        if sections.count < 3 {
            return .failure(FormatError(message: "Invalid SFEN format: insufficient sections"))
        }

        // movesセクションの開始インデックスを特定
        let movesIndex = sections.count == 3 || sections[3] == "moves" ? 3 : 4

        // SFEN部分を連結
        let sfenPart = sections[0 ..< movesIndex].joined(separator: " ")

        guard let position = Position.fromSFEN(sfenPart) else {
            return .failure(FormatError(message: "Invalid SFEN: \(sfenPart)"))
        }

        // movesセクションがあれば解析
        if movesIndex < sections.count {
            let movesPart = sections[movesIndex...].joined(separator: " ")
            return newByUSIFromMoves(position: position, data: movesPart)
        }

        // movesセクションがなければ局面のみの棋譜を作成
        return .success(Record(position: position))
    }

    /// 指し手部分からのUSI読み込み
    /// - Parameters:
    ///   - position: 初期局面
    ///   - data: 指し手部分の文字列
    /// - Returns: 棋譜またはエラー
    private static func newByUSIFromMoves(position: Position, data: String) -> Result<Record, Error> {
        let record = Record(position: position)

        if data.isEmpty {
            return .success(record)
        }

        let sections = data.split(separator: " ")

        // 先頭が "moves" でなければエラー
        if sections[0] != "moves" {
            return .failure(FormatError(message: "Move section must start with 'moves' keyword"))
        }

        // 指し手を順に適用
        for i in 1 ..< sections.count {
            let section = String(sections[i])

            // 投了
            if section == "resign" {
                record.append(specialMove(.resign))
                break
            }

            // 通常の指し手
            if let move = record.position.createMoveByUSI(section) {
                if !record.append(move, option: DoMoveOption(ignoreValidation: true)) {
                    return .failure(FormatError(message: "Failed to apply move: \(section)"))
                }
            } else {
                return .failure(FormatError(message: "Invalid move format: \(section)"))
            }
        }

        record.goto(0)
        record.resetAllBranchSelection()

        return .success(record)
    }

    /// SFEN形式の棋譜を読み込みます（単純なSFEN文字列のみ対応）
    /// - Parameter data: SFEN形式の文字列
    /// - Returns: 棋譜またはエラー
    public static func importSFEN(_ data: String) -> Result<Record, Error> {
        if let position = Position.fromSFEN(data) {
            return .success(Record(position: position))
        } else {
            return .failure(FormatError(message: "Invalid SFEN format: \(data)"))
        }
    }

    /// USI形式の文字列から次の手番を取得します
    /// - Parameter usi: USI形式の文字列
    /// - Returns: 次の手番
    public static func getNextColorFromUSI(_ usi: String) -> Color {
        let sections = usi.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")

        // 基本となる手番を決定
        let baseColor: Color
        if sections.count > 1, sections[1] == "startpos" || (sections.count > 3 && sections[3] == "b") {
            baseColor = .black
        } else {
            baseColor = .white
        }

        // 最初の指し手の位置を特定
        let firstMoveIndex: Int
        if sections.count > 1, sections[1] == "startpos" {
            firstMoveIndex = sections.count > 2 && sections[2] == "moves" ? 3 : 2
        } else {
            firstMoveIndex = sections.count > 6 && sections[6] == "moves" ? 7 : 6
        }

        // 指し手の数で手番を反転
        return (sections.count - firstMoveIndex) % 2 == 0 ? baseColor : baseColor.reversed()
    }

    /// USI出力オプション
    public struct USIFormatOptions {
        /// 平手の場合に "startpos" を使用するかを指定します。デフォルトは true です。
        public let startpos: Bool

        /// 投了 "resign" を出力に含めるかどうか。デフォルトは false です。
        public let resign: Bool

        /// 全ての指し手を含めるかどうか。デフォルトは false です。
        public let allMoves: Bool

        /// 初期化
        public init(startpos: Bool = true, resign: Bool = false, allMoves: Bool = false) {
            self.startpos = startpos
            self.resign = resign
            self.allMoves = allMoves
        }
    }

    /// USI形式の文字列を出力します
    /// - Parameters:
    ///   - record: 棋譜
    ///   - options: 出力オプション
    /// - Returns: USI形式の文字列
    public static func exportUSI(_ record: ImmutableRecord, options: USIFormatOptions? = nil) -> String {
        let sfen = record.initialPosition.sfen
        let opts = options ?? USIFormatOptions()

        // startposオプションが有効で平手の場合は startpos を使用
        let useStartpos = opts.startpos && sfen == InitialPositionSFEN.standard
        let position = "position " + (useStartpos ? "startpos" : "sfen \(sfen)")

        var moves: [String] = []
        var p: ImmutableNode? = record.first

        // 指し手を収集
        while p != nil {
            // アクティブな分岐をたどる
            while p != nil && !p!.activeBranch {
                p = p!.branch
            }

            guard let node = p else {
                break
            }

            if let move = node.move as? Move {
                moves.append(move.usi)
            } else if opts.resign,
                      let specialMove = node.move as? SpecialMove,
                      specialMove.name == SpecialMoveType.resign.rawValue
            {
                moves.append("resign")
            }

            // 終了条件：最後の手または現在の手（allMovesオプションが無効の場合）
            if node.next == nil || (!opts.allMoves && node === record.current) {
                break
            }

            p = node.next
        }

        // 指し手がなければposition部分のみ返す
        if moves.isEmpty {
            return position
        }

        // "position"と"moves"キーワードに指し手を連結
        return ([position, "moves"] + moves).joined(separator: " ")
    }

    /// USEN出力オプション
    public struct USENExportOptions {
        /// 分岐インデックス
        public let branchIndex: Int?

        /// 手数
        public let ply: Int?

        /// 初期化
        public init(branchIndex: Int? = nil, ply: Int? = nil) {
            self.branchIndex = branchIndex
            self.ply = ply
        }
    }

    /// USEN形式の文字列を出力します
    /// - Parameters:
    ///   - record: 棋譜
    ///   - options: 出力オプション
    /// - Returns: USEN形式の文字列とアクティブな分岐インデックス
    public static func exportUSEN(_ record: ImmutableRecord, options _: USENExportOptions? = nil) -> (usen: String, branchIndex: Int) {
        // record.usen は Record クラスで既に実装されているため、そちらにリダイレクト
        let (usen, branchIndex) = record.usen
        return (usen, branchIndex)
    }
}
