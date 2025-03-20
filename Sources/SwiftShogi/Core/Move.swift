import Foundation

/// 指し手
public struct Move: Equatable, Hashable {
    /// 移動元（Square: 盤上の駒を動かす場合、PieceType: 持ち駒を打つ場合）
    public let from: Either<Square, PieceType>

    /// 移動先
    public let to: Square

    /// 成るかどうか
    public let promote: Bool

    /// 手番
    public let color: Color

    /// 駒の種類
    public let pieceType: PieceType

    /// 取った駒の種類（駒を取らない場合はnil）
    public let capturedPieceType: PieceType?

    /// 移動元が盤上の駒かどうか
    public var isFromBoard: Bool {
        return from.isLeft
    }

    /// 移動元が持ち駒かどうか
    public var isFromHand: Bool {
        return from.isRight
    }

    /// 初期化
    /// - Parameters:
    ///   - from: 移動元（Square: 盤上の駒を動かす場合、PieceType: 持ち駒を打つ場合）
    ///   - to: 移動先
    ///   - promote: 成るかどうか
    ///   - color: 手番
    ///   - pieceType: 駒の種類
    ///   - capturedPieceType: 取った駒の種類（駒を取らない場合はnil）
    public init(from: Either<Square, PieceType>, to: Square, promote: Bool, color: Color, pieceType: PieceType, capturedPieceType: PieceType? = nil) {
        self.from = from
        self.to = to
        self.promote = promote
        self.color = color
        self.pieceType = pieceType
        self.capturedPieceType = capturedPieceType
    }

    /// Square型の移動元を持つ指し手を作成
    public init(from: Square, to: Square, promote: Bool, color: Color, pieceType: PieceType, capturedPieceType: PieceType? = nil) {
        self.init(from: .left(from), to: to, promote: promote, color: color, pieceType: pieceType, capturedPieceType: capturedPieceType)
    }

    /// PieceType型の移動元を持つ指し手を作成
    public init(from pieceType: PieceType, to: Square, color: Color, capturedPieceType: PieceType? = nil) {
        self.init(from: .right(pieceType), to: to, promote: false, color: color, pieceType: pieceType, capturedPieceType: capturedPieceType)
    }

    /// 指し手が等しいかどうかを判定します
    public static func == (lhs: Move, rhs: Move) -> Bool {
        return lhs.from == rhs.from &&
            lhs.to == rhs.to &&
            lhs.promote == rhs.promote &&
            lhs.color == rhs.color &&
            lhs.pieceType == rhs.pieceType &&
            lhs.capturedPieceType == rhs.capturedPieceType
    }

    /// 成る手を返します
    public func withPromote() -> Move {
        return Move(from: from, to: to, promote: true, color: color, pieceType: pieceType, capturedPieceType: capturedPieceType)
    }

    /// USI形式の文字列を取得します
    public var usi: String {
        switch from {
        case let .left(square):
            let fromStr = square.usi
            let toStr = to.usi
            let promoteStr = promote ? "+" : ""
            return fromStr + toStr + promoteStr
        case let .right(pieceType):
            let pieceStr = sfenStringBlack(for: pieceType)
            let toStr = to.usi
            return pieceStr + "*" + toStr
        }
    }
}

/// 特殊な指し手の種類
public enum SpecialMoveType: String {
    case start
    case interrupt
    case resign
    case maxMoves
    case impass
    case draw
    case repetitionDraw
    case mate
    case noMate
    case timeout
    case foulWin // 手番側の勝ち(直前の指し手が反則手)
    case foulLose // 手番側の負け
    case enteringOfKing
    case winByDefault
    case loseByDefault
    case `try` // トライ成立
}

/// 定義済みの特殊な指し手
public struct PredefinedSpecialMove: Equatable {
    public let type: SpecialMoveType

    public init(type: SpecialMoveType) {
        self.type = type
    }
}

/// 未定義の特殊な指し手
public struct AnySpecialMove: Equatable {
    public let name: String

    public init(name: String) {
        self.name = name
    }
}

/// 特殊な指し手
public enum SpecialMove: Equatable {
    case predefined(PredefinedSpecialMove)
    case any(AnySpecialMove)

    public var type: String {
        switch self {
        case let .predefined(move):
            return move.type.rawValue
        case .any:
            return "any"
        }
    }

    public var name: String {
        switch self {
        case let .predefined(move):
            return move.type.rawValue
        case let .any(move):
            return move.name
        }
    }
}

/// 定義済みの特殊な指し手を作成します
/// - Parameter type: 種類
/// - Returns: 特殊な指し手
public func specialMove(_ type: SpecialMoveType) -> SpecialMove {
    return .predefined(PredefinedSpecialMove(type: type))
}

/// 未定義の特殊な指し手を作成します
/// - Parameter name: 名前
/// - Returns: 特殊な指し手
public func anySpecialMove(_ name: String) -> SpecialMove {
    return .any(AnySpecialMove(name: name))
}

/// 定義済みの特殊な指し手かどうかを判定します
/// - Parameter move: 指し手
/// - Returns: 定義済みならtrue
public func isKnownSpecialMove(_ move: SpecialMove) -> Bool {
    switch move {
    case .predefined:
        return true
    case .any:
        return false
    }
}

/// 二つの特殊な指し手が同じかどうかを判定します
/// - Parameters:
///   - a: 特殊な指し手
///   - b: 特殊な指し手
/// - Returns: 同じ特殊な指し手ならtrue
public func areSameSpecialMoves(_ a: SpecialMove, _ b: SpecialMove) -> Bool {
    switch (a, b) {
    case let (.predefined(moveA), .predefined(moveB)):
        return moveA.type == moveB.type
    case let (.any(moveA), .any(moveB)):
        return moveA.name == moveB.name
    default:
        return false
    }
}

/// 二つの指し手が同じかどうかを判定します
/// - Parameters:
///   - a: 指し手または特殊な指し手
///   - b: 指し手または特殊な指し手
/// - Returns: 同じ指し手ならtrue
public func areSameMoves(_ a: Any, _ b: Any) -> Bool {
    switch (a, b) {
    case let (moveA as Move, moveB as Move):
        return moveA == moveB
    case let (moveA as SpecialMove, moveB as SpecialMove):
        return areSameSpecialMoves(moveA, moveB)
    default:
        return false
    }
}

/// USI形式の文字列を解析します
/// - Parameter usiMove: USI形式の指し手文字列
/// - Returns: 移動元、移動先、成るかどうか（無効な形式の場合はnil）
public func parseUSIMove(_ usiMove: String) -> (from: Either<Square, PieceType>, to: Square, promote: Bool)? {
    // 持ち駒を打つ場合
    if usiMove.contains("*") {
        let components = usiMove.split(separator: "*")
        guard components.count == 2,
              let piece = Piece.fromSFEN(String(components[0])),
              let to = Square.fromUSI(String(components[1]))
        else {
            return nil
        }
        return (from: .right(piece.type), to: to, promote: false)
    }

    // 盤上の駒を動かす場合
    let promote = usiMove.hasSuffix("+")
    let cleanMove = promote ? String(usiMove.dropLast()) : usiMove

    guard cleanMove.count == 4,
          let from = Square.fromUSI(String(cleanMove.prefix(2))),
          let to = Square.fromUSI(String(cleanMove.suffix(2)))
    else {
        return nil
    }

    return (from: .left(from), to: to, promote: promote)
}

/// Either型 - 2つの型のうちどちらか一方を保持する
public enum Either<L, R>: Equatable, Hashable where L: Equatable, R: Equatable, L: Hashable, R: Hashable {
    case left(L)
    case right(R)

    public var isLeft: Bool {
        switch self {
        case .left: return true
        case .right: return false
        }
    }

    public var isRight: Bool {
        switch self {
        case .left: return false
        case .right: return true
        }
    }

    public var leftValue: L? {
        switch self {
        case let .left(value): return value
        case .right: return nil
        }
    }

    public var rightValue: R? {
        switch self {
        case .left: return nil
        case let .right(value): return value
        }
    }

    public static func == (lhs: Either<L, R>, rhs: Either<L, R>) -> Bool {
        switch (lhs, rhs) {
        case let (.left(lhsValue), .left(rhsValue)):
            return lhsValue == rhsValue
        case let (.right(lhsValue), .right(rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .left(value):
            hasher.combine(0) // leftを示す識別子
            hasher.combine(value)
        case let .right(value):
            hasher.combine(1) // rightを示す識別子
            hasher.combine(value)
        }
    }
}
