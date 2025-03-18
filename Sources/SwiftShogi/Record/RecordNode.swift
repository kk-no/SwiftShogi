import Foundation

/// 棋譜を構成するノード(読み取り専用)
public protocol ImmutableNode: AnyObject {
    /// 現在の手数（ply）
    var ply: Int { get }

    /// 前のノード
    var prev: ImmutableNode? { get }

    /// 次のノード
    var next: ImmutableNode? { get }

    /// 分岐ノード
    var branch: ImmutableNode? { get }

    /// 分岐のインデックス
    var branchIndex: Int { get }

    /// アクティブな分岐かどうか
    var activeBranch: Bool { get }

    /// 次の手番
    var nextColor: Color { get }

    /// 指し手または特殊な指し手
    var move: Any { get }

    /// 王手がかかっているか
    var isCheck: Bool { get }

    /// コメント
    var comment: String { get }

    /// カスタムデータ
    var customData: Any? { get }

    /// 表示用のテキスト
    var displayText: String { get }

    /// 時間表示用のテキスト
    var timeText: String { get }

    /// 分岐があるかどうか
    var hasBranch: Bool { get }

    /// 最初の分岐かどうか
    var isFirstBranch: Bool { get }

    /// 最後の手かどうか
    var isLastMove: Bool { get }

    /// 経過時間（ミリ秒）
    var elapsedMs: Int { get }

    /// 累計経過時間（ミリ秒）
    var totalElapsedMs: Int { get }

    /// しおり
    var bookmark: String { get }
}

/// 棋譜を構成するノード
public protocol Node: ImmutableNode {
    /// コメント（書き込み可）
    var comment: String { get set }

    /// カスタムデータ（書き込み可）
    var customData: Any? { get set }

    /// 経過時間を設定する
    func setElapsedMs(_ elapsedMs: Int)

    /// しおり（書き込み可）
    var bookmark: String { get set }
}

/// ノードの実装
public class NodeImpl: Node {
    // ノード間の参照
    private var _prev: NodeImpl?
    private var _next: NodeImpl?
    private var _branch: NodeImpl?

    // 変更可能なプロパティ
    public var comment: String = ""
    public var customData: Any?
    public var elapsedMs: Int = 0
    public var totalElapsedMs: Int = 0
    public var bookmark: String = ""
    public var activeBranch: Bool

    // 不変のプロパティ
    public let ply: Int
    public let branchIndex: Int
    public let nextColor: Color
    public let move: Any
    public let isCheck: Bool
    public let displayText: String

    /// 初期化
    /// - Parameters:
    ///   - ply: 手数
    ///   - prev: 前のノード
    ///   - branchIndex: 分岐のインデックス
    ///   - activeBranch: アクティブな分岐かどうか
    ///   - nextColor: 次の手番
    ///   - move: 指し手または特殊な指し手
    ///   - isCheck: 王手がかかっているか
    ///   - displayText: 表示用のテキスト
    public init(
        ply: Int,
        prev: NodeImpl?,
        branchIndex: Int,
        activeBranch: Bool,
        nextColor: Color,
        move: Any,
        isCheck: Bool,
        displayText: String
    ) {
        self.ply = ply
        _prev = prev
        self.branchIndex = branchIndex
        self.activeBranch = activeBranch
        self.nextColor = nextColor
        self.move = move
        self.isCheck = isCheck
        self.displayText = displayText
    }

    // ImmutableNode プロトコルの要件を満たすプロパティ
    public var prev: ImmutableNode? {
        return _prev
    }

    public var next: ImmutableNode? {
        return _next
    }

    public var branch: ImmutableNode? {
        return _branch
    }

    // アクセサメソッド
    public var nextNode: NodeImpl? {
        get { return _next }
        set { _next = newValue }
    }

    public var branchNode: NodeImpl? {
        get { return _branch }
        set { _branch = newValue }
    }

    public var prevNode: NodeImpl? {
        get { return _prev }
        set { _prev = newValue }
    }

    /// 時間表示用のテキスト
    public var timeText: String {
        let elapsed = TimeUtil.millisecondsToMSS(elapsedMs)
        let totalElapsed = TimeUtil.millisecondsToHHMMSS(totalElapsedMs)
        return "\(elapsed) / \(totalElapsed)"
    }

    /// 分岐があるかどうか
    public var hasBranch: Bool {
        return _prev != nil && _prev?._next != nil && _prev?._next?._branch != nil
    }

    /// 最初の分岐かどうか
    public var isFirstBranch: Bool {
        return _prev == nil || _prev?._next === self
    }

    /// 最後の手かどうか
    public var isLastMove: Bool {
        if _next == nil {
            return true
        }

        var p: NodeImpl? = _next
        while p != nil {
            if p?.move is Move {
                return false
            }
            p = p?._branch
        }

        return true
    }

    /// 経過時間を設定する
    /// - Parameter elapsedMs: 経過時間（ミリ秒）
    public func setElapsedMs(_ elapsedMs: Int) {
        self.elapsedMs = elapsedMs
        updateTotalElapsedMs()

        // 後続のノードの累計時間も更新
        var p = _next
        var stack: [NodeImpl] = []

        while p != nil {
            p?.updateTotalElapsedMs()

            if let branch = p?._branch {
                stack.append(branch)
            }

            if let next = p?._next {
                p = next
            } else if let popped = stack.popLast() {
                p = popped
            } else {
                p = nil
            }
        }
    }

    /// 累計経過時間を更新する
    private func updateTotalElapsedMs() {
        totalElapsedMs = elapsedMs
        if let prevPrev = _prev?._prev {
            totalElapsedMs += prevPrev.totalElapsedMs
        }
    }

    /// 開始局面用のノードを作成する
    /// - Parameter color: 手番
    /// - Returns: 開始局面のノード
    public static func newRootEntry(color: Color) -> NodeImpl {
        return NodeImpl(
            ply: 0,
            prev: nil,
            branchIndex: 0,
            activeBranch: true,
            nextColor: color,
            move: specialMove(.start),
            isCheck: false,
            displayText: "開始局面"
        )
    }
}
