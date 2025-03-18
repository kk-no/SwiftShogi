import Foundation

/// 駒の動きの方向を表す列挙型
public enum Direction: String, Hashable {
    case up
    case down
    case left
    case right
    case leftUp = "left_up"
    case rightUp = "right_up"
    case leftDown = "left_down"
    case rightDown = "right_down"
    case leftUpKnight = "left_up_knight"
    case rightUpKnight = "right_up_knight"
    case leftDownKnight = "left_down_knight"
    case rightDownKnight = "right_down_knight"
}

/// 移動の種類を表す列挙型
public enum MoveType: String {
    /// 1マスのみ移動可能
    case short

    /// 長距離移動可能
    case long
}

/// 垂直方向の動きを表す列挙型
public enum VDirection {
    case up
    case none
    case down
}

/// 水平方向の動きを表す列挙型
public enum HDirection {
    case left
    case none
    case right
}

/// Direction関連のユーティリティ関数
public extension Direction {
    /// 反対方向を返します
    var reversed: Direction {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        case .leftUp: return .rightDown
        case .rightUp: return .leftDown
        case .leftDown: return .rightUp
        case .rightDown: return .leftUp
        case .leftUpKnight: return .rightDownKnight
        case .rightUpKnight: return .leftDownKnight
        case .leftDownKnight: return .rightUpKnight
        case .rightDownKnight: return .leftUpKnight
        }
    }

    /// 方向に対する相対座標を返します
    var delta: (x: Int, y: Int) {
        switch self {
        case .up: return (0, -1)
        case .down: return (0, 1)
        case .left: return (-1, 0)
        case .right: return (1, 0)
        case .leftUp: return (-1, -1)
        case .rightUp: return (1, -1)
        case .leftDown: return (-1, 1)
        case .rightDown: return (1, 1)
        case .leftUpKnight: return (-1, -2)
        case .rightUpKnight: return (1, -2)
        case .leftDownKnight: return (-1, 2)
        case .rightDownKnight: return (1, 2)
        }
    }

    /// 垂直方向の動きを取り出します
    var verticalDirection: VDirection {
        switch self {
        case .up, .leftUp, .rightUp, .leftUpKnight, .rightUpKnight:
            return .up
        case .down, .leftDown, .rightDown, .leftDownKnight, .rightDownKnight:
            return .down
        case .left, .right:
            return .none
        }
    }

    /// 水平方向の動きを取り出します
    var horizontalDirection: HDirection {
        switch self {
        case .left, .leftUp, .leftDown, .leftUpKnight, .leftDownKnight:
            return .left
        case .right, .rightUp, .rightDown, .rightUpKnight, .rightDownKnight:
            return .right
        case .up, .down:
            return .none
        }
    }

    /// 全ての方向を返します
    static var allDirections: [Direction] {
        return [
            .up, .down, .left, .right,
            .leftUp, .rightUp, .leftDown, .rightDown,
            .leftUpKnight, .rightUpKnight, .leftDownKnight, .rightDownKnight,
        ]
    }

    /// ベクトルを方向と距離に変換します
    /// - Parameters:
    ///   - x: x座標の差分
    ///   - y: y座標の差分
    /// - Returns: 方向、距離、変換が成功したかどうか
    static func fromVector(x: Int, y: Int) -> (direction: Direction?, distance: Int, valid: Bool) {
        // 桂馬の動き
        if x == 1, y == -2 {
            return (.rightUpKnight, 1, true)
        }
        if x == -1, y == -2 {
            return (.leftUpKnight, 1, true)
        }
        if x == 1, y == 2 {
            return (.rightDownKnight, 1, true)
        }
        if x == -1, y == 2 {
            return (.leftDownKnight, 1, true)
        }

        // 斜めの動きで、xとyの絶対値が異なる場合は無効
        if x != 0, y != 0, abs(x) != abs(y) {
            return (nil, 0, false)
        }

        var dx = x
        var dy = y
        var distance = 0

        if dx != 0 {
            distance = abs(dx)
            dx /= distance
        }

        if dy != 0 {
            distance = abs(dy)
            dy /= distance
        }

        let direction: Direction?

        switch (dx, dy) {
        case (-1, -1): direction = .leftUp
        case (0, -1): direction = .up
        case (1, -1): direction = .rightUp
        case (-1, 0): direction = .left
        case (1, 0): direction = .right
        case (-1, 1): direction = .leftDown
        case (0, 1): direction = .down
        case (1, 1): direction = .rightDown
        default: direction = nil
        }

        return (direction, distance, direction != nil)
    }
}
