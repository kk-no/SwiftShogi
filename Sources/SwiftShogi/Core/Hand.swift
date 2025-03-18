import Foundation

/// 持ち駒(読み取り専用)プロトコル
public protocol ImmutableHand {
    /// 持ち駒の枚数を取得します
    /// - Parameter pieceType: 駒の種類
    /// - Returns: 枚数
    func count(pieceType: PieceType) -> Int

    /// 駒の種類ごとにハンドラーを呼び出します
    /// - Parameter handler: 各駒の種類と枚数を受け取るハンドラー
    func forEach(_ handler: (PieceType, Int) -> Void)

    /// 持ち駒の種類と枚数の一覧を取得します
    var counts: [(type: PieceType, count: Int)] { get }

    /// 先手の持ち駒に対してSFEN形式の文字列を取得します
    var sfenBlack: String { get }

    /// 後手の持ち駒に対してSFEN形式の文字列を取得します
    var sfenWhite: String { get }

    /// SFEN形式の文字列を取得します
    /// - Parameter color: 手番
    /// - Returns: SFEN形式の文字列
    func formatSFEN(color: Color) -> String
}

/// 持ち駒
public class Hand: ImmutableHand {
    private var pieces: [PieceType: Int]

    /// 初期化
    public init() {
        pieces = [:]
        // 持ち駒として使用できる駒の種類を初期化
        for pieceType in handPieceTypes {
            pieces[pieceType] = 0
        }
    }

    /// 持ち駒の種類と枚数の一覧を取得します
    public var counts: [(type: PieceType, count: Int)] {
        return [
            (type: .rook, count: count(pieceType: .rook)),
            (type: .bishop, count: count(pieceType: .bishop)),
            (type: .gold, count: count(pieceType: .gold)),
            (type: .silver, count: count(pieceType: .silver)),
            (type: .knight, count: count(pieceType: .knight)),
            (type: .lance, count: count(pieceType: .lance)),
            (type: .pawn, count: count(pieceType: .pawn)),
        ]
    }

    /// 持ち駒の枚数を取得します
    /// - Parameter pieceType: 駒の種類
    /// - Returns: 枚数
    public func count(pieceType: PieceType) -> Int {
        return pieces[pieceType] ?? 0
    }

    /// 持ち駒の枚数を設定します
    /// - Parameters:
    ///   - pieceType: 駒の種類
    ///   - count: 枚数
    public func set(pieceType: PieceType, count: Int) {
        pieces[pieceType] = count
    }

    /// 持ち駒を追加します
    /// - Parameters:
    ///   - pieceType: 駒の種類
    ///   - n: 追加する枚数
    /// - Returns: 追加後の枚数
    @discardableResult
    public func add(pieceType: PieceType, count n: Int) -> Int {
        let current = count(pieceType: pieceType)
        let newCount = current + n
        set(pieceType: pieceType, count: newCount)
        return newCount
    }

    /// 持ち駒を減らします
    /// - Parameters:
    ///   - pieceType: 駒の種類
    ///   - n: 減らす枚数
    /// - Returns: 減らした後の枚数
    @discardableResult
    public func reduce(pieceType: PieceType, count n: Int) -> Int {
        let current = count(pieceType: pieceType)
        let newCount = current - n
        set(pieceType: pieceType, count: newCount)
        return newCount
    }

    /// 駒の種類ごとにハンドラーを呼び出します
    /// - Parameter handler: 各駒の種類と枚数を受け取るハンドラー
    public func forEach(_ handler: (PieceType, Int) -> Void) {
        for pieceType in handPieceTypes {
            handler(pieceType, count(pieceType: pieceType))
        }
    }

    /// 先手の持ち駒に対してSFEN形式の文字列を取得します
    public var sfenBlack: String {
        return formatSFEN(color: .black)
    }

    /// 後手の持ち駒に対してSFEN形式の文字列を取得します
    public var sfenWhite: String {
        return formatSFEN(color: .white)
    }

    /// SFEN形式の文字列を取得します
    /// - Parameter color: 手番
    /// - Returns: SFEN形式の文字列
    public func formatSFEN(color: Color) -> String {
        var ret = ""
        let pieceCounts = counts.filter { $0.count > 0 }

        // 持ち駒が多い順に出力
        for (type, count) in pieceCounts.sorted(by: { $0.type.rawValue > $1.type.rawValue }) {
            let piece = Piece(color: color, type: type)
            ret += buildSFEN(count: count, piece: piece)
        }

        if ret.isEmpty {
            return "-"
        }
        return ret
    }

    /// 別のオブジェクトからコピーします
    /// - Parameter hand: コピー元の持ち駒
    public func copyFrom(_ hand: Hand) {
        for pieceType in handPieceTypes {
            set(pieceType: pieceType, count: hand.count(pieceType: pieceType))
        }
    }

    /// SFEN形式の文字列を取得します
    /// - Parameters:
    ///   - black: 先手の持ち駒
    ///   - white: 後手の持ち駒
    /// - Returns: SFEN形式の文字列
    public static func formatSFEN(black: Hand, white: Hand) -> String {
        let b = black.sfenBlack
        let w = white.sfenWhite

        if b == "-" && w == "-" {
            return "-"
        }
        if w == "-" {
            return b
        }
        if b == "-" {
            return w
        }
        return b + w
    }

    /// 指定した文字列が正しい持ち駒のSFENであるかどうかを判定します
    /// - Parameter sfen: SFEN文字列
    /// - Returns: 有効なSFENならtrue
    public static func isValidSFEN(_ sfen: String) -> Bool {
        if sfen == "-" {
            return true
        }
        // 正規表現：2桁以下の数字＋[PLNSGBRplnsgbr]の繰り返し
        let pattern = "^(?:[0-9]{0,2}[PLNSGBRplnsgbr])+$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: sfen.utf16.count)
        return regex?.firstMatch(in: sfen, range: range) != nil
    }

    /// 持ち駒のSFENを解析します
    /// - Parameter sfen: SFEN文字列
    /// - Returns: 先手と後手の持ち駒（無効な形式の場合はnil）
    public static func parseSFEN(_ sfen: String) -> (black: Hand, white: Hand)? {
        if sfen == "-" {
            return (black: Hand(), white: Hand())
        }

        // 正規表現：([0-9]{0,2}[PLNSGBRplnsgbr]) の繰り返しを捕捉
        let pattern = "([0-9]{0,2}[PLNSGBRplnsgbr])"
        let regex = try? NSRegularExpression(pattern: pattern)
        guard let regex = regex else { return nil }

        let range = NSRange(location: 0, length: sfen.utf16.count)
        let matches = regex.matches(in: sfen, range: range)

        guard !matches.isEmpty else { return nil }

        let black = Hand()
        let white = Hand()

        for match in matches {
            let range = match.range(at: 1)
            guard let swiftRange = Range(range, in: sfen) else { continue }

            let section = String(sfen[swiftRange])
            let lastCharIndex = section.index(before: section.endIndex)
            let pieceChar = String(section[lastCharIndex])

            let countStr = section.count > 1 ? String(section[..<lastCharIndex]) : ""
            let count = countStr.isEmpty ? 1 : Int(countStr) ?? 1

            guard let piece = Piece.fromSFEN(pieceChar) else { continue }

            if piece.color == .black {
                black.add(pieceType: piece.type, count: count)
            } else {
                white.add(pieceType: piece.type, count: count)
            }
        }

        return (black: black, white: white)
    }
}

/// SFEN形式の文字列を構築します
/// - Parameters:
///   - count: 駒の枚数
///   - piece: 駒
/// - Returns: SFEN形式の文字列
private func buildSFEN(count: Int, piece: Piece) -> String {
    if count == 0 {
        return ""
    }
    let countStr = count > 1 ? "\(count)" : ""
    return countStr + piece.sfen
}
