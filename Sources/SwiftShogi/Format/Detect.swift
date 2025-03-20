import Foundation

/// 棋譜形式の種類
public enum RecordFormatType: String {
    case USI
    case SFEN
    case KIF
    case KI2
    case CSA
    case JKF
    case USEN
}

/// 棋譜形式を検出するクラス
public enum FormatDetector {
    /// 文字列から棋譜形式を推定します。
    /// 一部の文字の並びや出現頻度による簡易的な判定であり、判定結果のフォーマットに準拠していることを保証するものではありません。
    /// - Parameter data: 判定する文字列
    /// - Returns: 推定される棋譜形式
    public static func detectRecordFormat(_ data: String) -> RecordFormatType {
        // USI
        if data.hasPrefix("position sfen ") ||
            data.hasPrefix("position startpos ") ||
            data.hasPrefix("sfen ") ||
            data.hasPrefix("startpos ") ||
            data.hasPrefix("moves ")
        {
            return .USI
        }

        // SFEN
        if Position.isValidSFEN(data) {
            return .SFEN
        }

        // JKF
        let jkfPattern = "^[\\s\\r\\n]*\\{.*\\}[\\s\\r\\n]*$"
        if regularExpressionMatch(pattern: jkfPattern, data: data, options: [.dotMatchesLineSeparators]) {
            return .JKF
        }

        // USEN
        let usenPattern = "^[-_.A-Za-z0-9]*~[0-9]*\\.[0-9A-Za-z]*\\.[a-z]?(~|$)"
        if regularExpressionMatch(pattern: usenPattern, data: data) {
            return .USEN
        }

        // KIF vs KI2 vs CSA: 行頭の文字の出現頻度を比較する。
        let pattKIF = "(^|\\n)[ \\u{3000}]*[#0-9開終棋手戦表持秒記消場掲備先後作発出完分受]"
        let pattKI2 = "(^|\\n)[ \\u{3000}]*[#▲△▼▽☗☖開終棋手戦表持秒記消場掲備先後作発出完分受]"
        let pattCSA = "(^|,|\\n)[-+$%'VNPT]"

        let matchedKIF = regularExpressionMatches(pattern: pattKIF, data: data)
        let matchedKI2 = regularExpressionMatches(pattern: pattKI2, data: data)
        let matchedCSA = regularExpressionMatches(pattern: pattCSA, data: data)

        let evalKIF = matchedKIF.count
        let evalKI2 = matchedKI2.count
        let evalCSA = matchedCSA.count

        if evalKIF >= evalCSA && evalKIF >= evalKI2 {
            return .KIF
        } else if evalKI2 >= evalCSA {
            return .KI2
        } else {
            return .CSA
        }
    }

    /// 正規表現でマッチするかチェック
    /// - Parameters:
    ///   - pattern: 正規表現パターン
    ///   - data: 検査する文字列
    ///   - options: 正規表現オプション
    /// - Returns: マッチすればtrue
    private static func regularExpressionMatch(pattern: String, data: String, options: NSRegularExpression.Options = []) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return false
        }

        let range = NSRange(location: 0, length: data.utf16.count)
        return regex.firstMatch(in: data, options: [], range: range) != nil
    }

    /// 正規表現でマッチする全ての箇所を取得
    /// - Parameters:
    ///   - pattern: 正規表現パターン
    ///   - data: 検査する文字列
    /// - Returns: マッチした文字列の配列
    private static func regularExpressionMatches(pattern: String, data: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let range = NSRange(location: 0, length: data.utf16.count)
        let matches = regex.matches(in: data, options: [], range: range)

        var results: [String] = []
        for match in matches {
            guard let matchRange = Range(match.range, in: data) else { continue }
            results.append(String(data[matchRange]))
        }

        return results
    }
}
