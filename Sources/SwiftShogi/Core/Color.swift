import Foundation

/// 手番を表す列挙型
public enum Color: String, CaseIterable {
    /// 先手
    case black

    /// 後手
    case white
}

/// Color関連のユーティリティ関数
public extension Color {
    /// 反対の手番を返します
    func reversed() -> Color {
        return self == .black ? .white : .black
    }

    /// SFEN形式の手番を表す文字列を取得します
    var sfenNotation: String {
        return self == .black ? "b" : "w"
    }

    /// 指定した文字列が正しいSFENの手番かどうかを判定します
    /// - Parameter sfen: SFEN形式の手番文字列
    /// - Returns: 有効なSFEN手番文字列かどうか
    static func isValidSFENColor(_ sfen: String) -> Bool {
        return sfen == "b" || sfen == "w"
    }

    /// SFEN形式の手番を読み取ります
    /// - Parameter sfen: SFEN形式の手番文字列
    /// - Returns: 対応するColorオブジェクト
    static func fromSFEN(_ sfen: String) -> Color {
        return sfen == "b" ? .black : .white
    }
}
