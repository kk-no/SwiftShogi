import Foundation

/// 駒の種類を表す列挙型
public enum PieceType: String, Hashable, CaseIterable {
    case pawn // 歩
    case lance // 香
    case knight // 桂
    case silver // 銀
    case gold // 金
    case bishop // 角
    case rook // 飛
    case king // 玉
    case promPawn // と
    case promLance // 成香
    case promKnight // 成桂
    case promSilver // 成銀
    case horse // 馬
    case dragon // 竜
}

/// 持ち駒として使用できる駒の種類
public let handPieceTypes: [PieceType] = [
    .pawn, .lance, .knight, .silver, .gold, .bishop, .rook,
]

/// 全ての駒の種類
public let allPieceTypes: [PieceType] = PieceType.allCases.map { $0 }

/// 駒(手番を含む)
public struct Piece: Hashable, Equatable {
    /// 手番
    public let color: Color

    /// 駒の種類
    public let type: PieceType

    /// 初期化
    /// - Parameters:
    ///   - color: 手番
    ///   - type: 駒の種類
    public init(color: Color, type: PieceType) {
        self.color = color
        self.type = type
    }

    /// 先手番の駒に変換します
    public func black() -> Piece {
        return withColor(.black)
    }

    /// 後手番の駒に変換します
    public func white() -> Piece {
        return withColor(.white)
    }

    /// 手番を変更した駒を返します
    public func withColor(_ color: Color) -> Piece {
        return Piece(color: color, type: type)
    }

    /// 成った駒を返します
    public func promoted() -> Piece {
        let newType = promotedType(of: type)
        return Piece(color: color, type: newType)
    }

    /// 成る前の駒を返します
    public func unpromoted() -> Piece {
        let newType = unpromotedType(of: type)
        return Piece(color: color, type: newType)
    }

    /// 成ることが可能な駒かどうかを返します
    public var isPromotable: Bool {
        return isPromotableType(type)
    }

    /// 駒の向きと種類をローテートします
    public func rotate() -> Piece {
        let result = rotateResult(for: type)
        let newType = result.type
        let newColor = result.reverseColor ? color.reversed() : color
        return Piece(color: newColor, type: newType)
    }

    /// 手番と種類を一意に識別する ID を返します
    public var id: String {
        return "\(color.rawValue)_\(type.rawValue)"
    }

    /// SFEN形式の文字列を取得します
    public var sfen: String {
        if color == .black {
            return sfenStringBlack(for: type)
        } else {
            return sfenStringWhite(for: type)
        }
    }

    /// 指定した文字列が正しいSFEN形式の駒かどうかを判定します
    /// - Parameter sfen: SFEN文字列
    /// - Returns: 有効なSFEN形式ならtrue
    public static func isValidSFEN(_ sfen: String) -> Bool {
        return sfenCharToPieceType[sfen] != nil
    }

    /// SFEN形式の文字列から駒を生成します
    /// - Parameter sfen: SFEN文字列
    /// - Returns: 駒（無効な場合はnil）
    public static func fromSFEN(_ sfen: String) -> Piece? {
        guard let type = sfenCharToPieceType[sfen],
              let color = sfenCharToColor[sfen]
        else {
            return nil
        }
        return Piece(color: color, type: type)
    }
}

/// 成ることができる駒かどうかを判定します
/// - Parameter type: 駒の種類
/// - Returns: 成れる駒ならtrue
public func isPromotableType(_ type: PieceType) -> Bool {
    switch type {
    case .pawn, .lance, .knight, .silver, .bishop, .rook:
        return true
    default:
        return false
    }
}

/// 成った時の駒の種類を返します
/// - Parameter type: 駒の種類
/// - Returns: 成った駒の種類
public func promotedType(of type: PieceType) -> PieceType {
    switch type {
    case .pawn: return .promPawn
    case .lance: return .promLance
    case .knight: return .promKnight
    case .silver: return .promSilver
    case .bishop: return .horse
    case .rook: return .dragon
    default: return type
    }
}

/// 成る前の駒の種類を返します
/// - Parameter type: 駒の種類
/// - Returns: 成る前の駒の種類
public func unpromotedType(of type: PieceType) -> PieceType {
    switch type {
    case .promPawn: return .pawn
    case .promLance: return .lance
    case .promKnight: return .knight
    case .promSilver: return .silver
    case .horse: return .bishop
    case .dragon: return .rook
    default: return type
    }
}

/// SFEN形式の先手の駒文字を返します
/// - Parameter type: 駒の種類
/// - Returns: SFEN文字列
public func sfenStringBlack(for type: PieceType) -> String {
    switch type {
    case .pawn: return "P"
    case .lance: return "L"
    case .knight: return "N"
    case .silver: return "S"
    case .gold: return "G"
    case .bishop: return "B"
    case .rook: return "R"
    case .king: return "K"
    case .promPawn: return "+P"
    case .promLance: return "+L"
    case .promKnight: return "+N"
    case .promSilver: return "+S"
    case .horse: return "+B"
    case .dragon: return "+R"
    }
}

/// SFEN形式の後手の駒文字を返します
/// - Parameter type: 駒の種類
/// - Returns: SFEN文字列
public func sfenStringWhite(for type: PieceType) -> String {
    switch type {
    case .pawn: return "p"
    case .lance: return "l"
    case .knight: return "n"
    case .silver: return "s"
    case .gold: return "g"
    case .bishop: return "b"
    case .rook: return "r"
    case .king: return "k"
    case .promPawn: return "+p"
    case .promLance: return "+l"
    case .promKnight: return "+n"
    case .promSilver: return "+s"
    case .horse: return "+b"
    case .dragon: return "+r"
    }
}

/// 駒のローテーション結果
private struct RotateResult {
    let type: PieceType
    let reverseColor: Bool
}

/// 駒をローテートした結果を返します
/// - Parameter type: 駒の種類
/// - Returns: ローテーション結果
private func rotateResult(for type: PieceType) -> RotateResult {
    switch type {
    case .pawn: return RotateResult(type: .promPawn, reverseColor: false)
    case .lance: return RotateResult(type: .promLance, reverseColor: false)
    case .knight: return RotateResult(type: .promKnight, reverseColor: false)
    case .silver: return RotateResult(type: .promSilver, reverseColor: false)
    case .gold: return RotateResult(type: .gold, reverseColor: true)
    case .bishop: return RotateResult(type: .horse, reverseColor: false)
    case .rook: return RotateResult(type: .dragon, reverseColor: false)
    case .king: return RotateResult(type: .king, reverseColor: true)
    case .promPawn: return RotateResult(type: .pawn, reverseColor: true)
    case .promLance: return RotateResult(type: .lance, reverseColor: true)
    case .promKnight: return RotateResult(type: .knight, reverseColor: true)
    case .promSilver: return RotateResult(type: .silver, reverseColor: true)
    case .horse: return RotateResult(type: .bishop, reverseColor: true)
    case .dragon: return RotateResult(type: .rook, reverseColor: true)
    }
}

/// SFEN文字から駒の種類へのマッピング
private let sfenCharToPieceType: [String: PieceType] = [
    "P": .pawn, "L": .lance, "N": .knight, "S": .silver, "G": .gold, "B": .bishop, "R": .rook, "K": .king,
    "+P": .promPawn, "+L": .promLance, "+N": .promKnight, "+S": .promSilver, "+B": .horse, "+R": .dragon,
    "p": .pawn, "l": .lance, "n": .knight, "s": .silver, "g": .gold, "b": .bishop, "r": .rook, "k": .king,
    "+p": .promPawn, "+l": .promLance, "+n": .promKnight, "+s": .promSilver, "+b": .horse, "+r": .dragon,
]

/// SFEN文字から手番へのマッピング
private let sfenCharToColor: [String: Color] = [
    "P": .black, "L": .black, "N": .black, "S": .black, "G": .black, "B": .black, "R": .black, "K": .black,
    "+P": .black, "+L": .black, "+N": .black, "+S": .black, "+B": .black, "+R": .black,
    "p": .white, "l": .white, "n": .white, "s": .white, "g": .white, "b": .white, "r": .white, "k": .white,
    "+p": .white, "+l": .white, "+n": .white, "+s": .white, "+b": .white, "+r": .white,
]
