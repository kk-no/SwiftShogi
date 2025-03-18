import Foundation

/// マス目を表す構造体
public struct Square: Hashable, Equatable {
    /// 筋（列）: 1〜9
    public let file: Int

    /// 段（行）: 1〜9
    public let rank: Int

    /// 新しいマス目を作成します
    /// - Parameters:
    ///   - file: 筋（1〜9）
    ///   - rank: 段（1〜9）
    public init(file: Int, rank: Int) {
        self.file = file
        self.rank = rank
    }

    /// 9筋を0としたx座標
    public var x: Int {
        return 9 - file
    }

    /// 1段目を0としたy座標
    public var y: Int {
        return rank - 1
    }

    /// 0～80のインデックス
    /// 0=「9一」, 1=「8一」, ..., 80=「1九」
    public var index: Int {
        return y * 9 + x
    }

    /// 先後を反転したマスを取得します
    public var opposite: Square {
        return Square(file: 10 - file, rank: 10 - rank)
    }

    /// 相対座標を指定して近隣のマスを取得します
    /// - Parameters:
    ///   - dx: x方向の移動量
    ///   - dy: y方向の移動量
    /// - Returns: 移動後のマス
    public func neighbor(dx: Int, dy: Int) -> Square {
        return Square(file: file - dx, rank: rank + dy)
    }

    /// 方向を指定して隣接(桂馬とびを含む)のマスを取得します
    /// - Parameter direction: 移動方向
    /// - Returns: 隣接するマス
    public func neighbor(direction: Direction) -> Square {
        let delta = direction.delta
        return neighbor(dx: delta.x, dy: delta.y)
    }

    /// 指定したマスへの方向を返します
    /// - Parameter square: 目標のマス
    /// - Returns: 方向
    public func directionTo(_ square: Square) -> Direction? {
        let result = Direction.fromVector(x: square.x - x, y: square.y - y)
        return result.valid ? result.direction : nil
    }

    /// 有効なマス目であるか判定します
    public var isValid: Bool {
        return file >= 1 && file <= 9 && rank >= 1 && rank <= 9
    }

    /// USI形式の文字列を取得します
    public var usi: String {
        let rankChars = ["a", "b", "c", "d", "e", "f", "g", "h", "i"]
        return "\(file)\(rankChars[rank - 1])"
    }

    /// SFEN形式の文字列を取得します（USIと同じ）
    public var sfen: String {
        return usi
    }

    /// 座標を指定してマスを取得します
    /// - Parameters:
    ///   - x: x座標 (0〜8)
    ///   - y: y座標 (0〜8)
    /// - Returns: マス
    public static func fromXY(x: Int, y: Int) -> Square {
        return Square(file: 9 - x, rank: y + 1)
    }

    /// インデクスを指定してマスを取得します
    /// - Parameter index: インデックス (0〜80)
    /// - Returns: マス
    public static func fromIndex(_ index: Int) -> Square {
        return Square(file: 9 - (index % 9), rank: (index / 9) + 1)
    }

    /// USI形式のマス目をパースします
    /// - Parameter usi: USI形式の文字列
    /// - Returns: マス（無効な場合はnil）
    public static func fromUSI(_ usi: String) -> Square? {
        guard usi.count == 2 else { return nil }

        let fileStr = String(usi.prefix(1))
        let rankStr = String(usi.suffix(1))

        guard let file = Int(fileStr), (1 ... 9).contains(file) else { return nil }

        let rankChars = ["a", "b", "c", "d", "e", "f", "g", "h", "i"]
        guard let rank = rankChars.firstIndex(of: rankStr)?.advanced(by: 1) else { return nil }

        return Square(file: file, rank: rank)
    }

    /// SFEN形式のマス目をパースします（USIと同じ）
    /// - Parameter sfen: SFEN形式の文字列
    /// - Returns: マス（無効な場合はnil）
    public static func fromSFEN(_ sfen: String) -> Square? {
        return fromUSI(sfen)
    }

    /// 全てのマス目の一覧を取得します
    public static var allSquares: [Square] {
        return (0 ... 80).map { fromIndex($0) }
    }
}

/// Square型の拡張比較演算子
public extension Square {
    /// 同じマス目か判定します
    /// - Parameters:
    ///   - lhs: 左辺値
    ///   - rhs: 右辺値
    /// - Returns: 同じマスならtrue
    static func == (lhs: Square, rhs: Square) -> Bool {
        return lhs.file == rhs.file && lhs.rank == rhs.rank
    }
}
