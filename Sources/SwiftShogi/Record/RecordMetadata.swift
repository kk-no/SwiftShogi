import Foundation

/// 棋譜メタデータのキー
public enum RecordMetadataKey: String {
    case title // 表題
    case blackName // 先手
    case whiteName // 後手
    case shitateName // 下手
    case uwateName // 上手
    case blackShortName // 先手省略名
    case whiteShortName // 後手省略名
    case startDatetime // 開始日時
    case endDatetime // 終了日時
    case date // 対局日
    case tournament // 棋戦
    case strategy // 戦型
    case timeLimit // 持ち時間
    case blackTimeLimit // 先手の持ち時間 (CSA V3)
    case whiteTimeLimit // 後手の持ち時間 (CSA V3)
    case byoyomi // 秒読み
    case timeSpent // 消費時間
    case maxMoves // 最大手数 (CSA V3)
    case jishogi // 持将棋規定 (CSA V3)
    case place // 場所
    case postedOn // 掲載
    case note // 備考
    case scorekeeper // 記録係

    // 詰将棋に関する項目
    case opusNo // 作品番号
    case opusName // 作品名
    case author // 作者
    case publishedBy // 発表誌
    case publishedAt // 発表年月
    case source // 出典
    case length // 手数
    case integrity // 完全性
    case category // 分類
    case award // 受賞
}

/// 棋譜メタデータ(読み取り専用)プロトコル
public protocol ImmutableRecordMetadata {
    /// 定義済みのメタデータのキーの一覧を取得します。
    var standardMetadataKeys: [RecordMetadataKey] { get }

    /// 定義済みのメタデータを取得します。
    /// - Parameter key: キー
    /// - Returns: メタデータ値
    func getStandardMetadata(_ key: RecordMetadataKey) -> String?

    /// カスタムメタデータのキーの一覧を取得します。
    var customMetadataKeys: [String] { get }

    /// カスタムメタデータを取得します。
    /// - Parameter key: キー
    /// - Returns: メタデータ値
    func getCustomMetadata(_ key: String) -> String?
}

/// 棋譜メタデータ関連のユーティリティ関数
public extension ImmutableRecordMetadata {
    /// 先手の対局者名をフルネーム優先で取得します
    var blackPlayerName: String? {
        return getStandardMetadata(.blackName) ??
            getStandardMetadata(.blackShortName) ??
            getStandardMetadata(.shitateName)
    }

    /// 後手の対局者名をフルネーム優先で取得します
    var whitePlayerName: String? {
        return getStandardMetadata(.whiteName) ??
            getStandardMetadata(.whiteShortName) ??
            getStandardMetadata(.uwateName)
    }

    /// 先手の対局者名を省略名優先で取得します
    var blackPlayerNamePreferShort: String? {
        return getStandardMetadata(.blackShortName) ??
            getStandardMetadata(.blackName) ??
            getStandardMetadata(.shitateName)
    }

    /// 後手の対局者名を省略名優先で取得します
    var whitePlayerNamePreferShort: String? {
        return getStandardMetadata(.whiteShortName) ??
            getStandardMetadata(.whiteName) ??
            getStandardMetadata(.uwateName)
    }
}

/// 棋譜メタデータ
/// キーの一覧は設定した順序を保持します(エクスポート時にヘッダ行の順序が保たれるようにするため)。
public class RecordMetadata: ImmutableRecordMetadata {
    private var standard: [RecordMetadataKey: String] = [:]
    private var standardKeyOrder: [RecordMetadataKey] = []
    private var custom: [String: String] = [:]
    private var customKeyOrder: [String] = []

    /// 初期化
    public init() {}

    /// 定義済みのメタデータのキーの一覧を取得します
    public var standardMetadataKeys: [RecordMetadataKey] {
        return standardKeyOrder
    }

    /// 定義済みのメタデータを取得します
    /// - Parameter key: キー
    /// - Returns: メタデータ値
    public func getStandardMetadata(_ key: RecordMetadataKey) -> String? {
        return standard[key]
    }

    /// 定義済みのメタデータを設定します
    /// - Parameters:
    ///   - key: キー
    ///   - value: メタデータ値
    public func setStandardMetadata(_ key: RecordMetadataKey, value: String?) {
        if let value = value, !value.isEmpty {
            if standard[key] == nil {
                standardKeyOrder.append(key)
            }
            standard[key] = value
        } else if standard.removeValue(forKey: key) != nil {
            standardKeyOrder.removeAll { $0 == key }
        }
    }

    /// カスタムメタデータのキーの一覧を取得します
    public var customMetadataKeys: [String] {
        return customKeyOrder
    }

    /// カスタムメタデータを取得します
    /// - Parameter key: キー
    /// - Returns: メタデータ値
    public func getCustomMetadata(_ key: String) -> String? {
        return custom[key]
    }

    /// カスタムメタデータを設定します
    /// - Parameters:
    ///   - key: キー
    ///   - value: メタデータ値
    public func setCustomMetadata(_ key: String, value: String?) {
        if let value = value, !value.isEmpty {
            if custom[key] == nil {
                customKeyOrder.append(key)
            }
            custom[key] = value
        } else if custom.removeValue(forKey: key) != nil {
            customKeyOrder.removeAll { $0 == key }
        }
    }
}
