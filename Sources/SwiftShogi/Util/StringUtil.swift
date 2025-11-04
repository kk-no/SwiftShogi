import Foundation

/// 文字列処理に関するユーティリティ関数
public enum StringUtil {
    /// 文字列に新しい行を連結します。末尾に改行が無い場合だけ改行を追加します。
    /// - Parameters:
    ///   - base: 基本となる文字列
    ///   - newLine: 追加する新しい行
    /// - Returns: 連結された文字列
    public static func appendLine(_ base: String, _ newLine: String) -> String {
        return (base.isEmpty ? "" : appendReturnIfNotExists(base)) + appendReturnIfNotExists(newLine)
    }

    /// 文字列の末尾に改行がなければ追加します。
    /// - Parameter str: 対象の文字列
    /// - Returns: 改行が追加された文字列
    public static func appendReturnIfNotExists(_ str: String) -> String {
        return str.hasSuffix("\n") ? str : str + "\n"
    }

    /// 改行コードを標準化します。CR/CRLF を LF に統一します。
    /// - Parameter data: 標準化する文字列
    /// - Returns: 標準化された文字列（LF のみに統一）
    public static func normalizeLineEndings(_ data: String) -> String {
        return data.replacingOccurrences(of: "\r\n", with: "\n")
                   .replacingOccurrences(of: "\r", with: "\n")
    }
}
