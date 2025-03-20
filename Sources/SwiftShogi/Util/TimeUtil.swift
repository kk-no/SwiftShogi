import Foundation

/// 時間表記に関するユーティリティ関数
public enum TimeUtil {
    /// ミリ秒をHH:MM:SS形式に変換します。秒未満は切り捨てられます。
    /// - Parameter ms: ミリ秒
    /// - Returns: HH:MM:SS形式の文字列
    public static func millisecondsToHHMMSS(_ ms: Int) -> String {
        return secondsToHHMMSS(ms / 1000)
    }

    /// ミリ秒をM:SS形式に変換します。分の十の位はスペースでパディングされます。秒未満は切り捨てられます。
    /// - Parameter ms: ミリ秒
    /// - Returns: M:SS形式の文字列
    public static func millisecondsToMSS(_ ms: Int) -> String {
        return secondsToMSS(ms / 1000)
    }

    /// 秒をHH:MM:SS形式に変換します。
    /// - Parameter seconds: 秒
    /// - Returns: HH:MM:SS形式の文字列
    public static func secondsToHHMMSS(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds - h * 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    /// 秒をM:SS形式に変換します。分の十の位はスペースでパディングされます。
    /// - Parameter seconds: 秒
    /// - Returns: M:SS形式の文字列
    public static func secondsToMSS(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%2d:%02d", m, s)
    }
}
