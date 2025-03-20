import Foundation

/// フォーマット処理に関連するエラー
public struct FormatError: Error, LocalizedError {
    /// エラーメッセージ
    public let message: String

    /// 初期化
    /// - Parameter message: エラーメッセージ
    public init(message: String) {
        self.message = message
    }

    /// エラーの説明
    public var errorDescription: String? {
        return message
    }
}
