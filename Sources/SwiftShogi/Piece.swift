public struct Piece {
    public enum Kind {
        case pawn(State)
        case lance(State)
        case knight(State)
        case silver(State)
        case gold
        case bishop(State)
        case rook(State)
        case king
    }

    public enum State {
        case normal
        case promoted
    }

    public private(set) var kind: Kind
    public private(set) var color: Color

    public init(kind: Kind, color: Color) {
        self.kind = kind
        self.color = color
    }
}

public extension Piece {
    var sfenString: String {
        switch kind {
        case .pawn(.normal): return color.isBlack ? "P" : "p"
        case .pawn(.promoted): return color.isBlack ? "+P" : "+p"
        case .lance(.normal): return color.isBlack ? "L" : "l"
        case .lance(.promoted): return color.isBlack ? "+L" : "+l"
        case .knight(.normal): return color.isBlack ? "N" : "n"
        case .knight(.promoted): return color.isBlack ? "+N" : "+n"
        case .silver(.normal): return color.isBlack ? "S" : "s"
        case .silver(.promoted): return color.isBlack ? "+S" : "+s"
        case .gold: return color.isBlack ? "G" : "g"
        case .bishop(.normal): return color.isBlack ? "B" : "b"
        case .bishop(.promoted): return color.isBlack ? "+B" : "+b"
        case .rook(.normal): return color.isBlack ? "R" : "r"
        case .rook(.promoted): return color.isBlack ? "+R" : "+r"
        case .king: return color.isBlack ? "K" : "k"
        }
    }

    var kifString: String {
        switch kind {
        case .pawn(.normal): return "歩"
        case .pawn(.promoted): return "と"
        case .lance(.normal): return "香"
        case .lance(.promoted): return "成香"
        case .knight(.normal): return "桂"
        case .knight(.promoted): return "成桂"
        case .silver(.normal): return "銀"
        case .silver(.promoted): return "成銀"
        case .gold: return "金"
        case .bishop(.normal): return "角"
        case .bishop(.promoted): return "馬"
        case .rook(.normal): return "飛"
        case .rook(.promoted): return "龍"
        case .king: return "玉"
        }
    }

    var isPromoted: Bool {
        switch kind {
        case .pawn(.promoted),
             .lance(.promoted),
             .knight(.promoted),
             .silver(.promoted),
             .bishop(.promoted),
             .rook(.promoted):
            return true
        default:
            return false
        }
    }

    var canPromote: Bool {
        switch kind {
        case .pawn(.normal),
             .lance(.normal),
             .knight(.normal),
             .silver(.normal),
             .bishop(.normal),
             .rook(.normal):
            return true
        default:
            return false
        }
    }

    mutating func promote() {
        switch kind {
        case .pawn(.normal): kind = .pawn(.promoted)
        case .lance(.normal): kind = .lance(.promoted)
        case .knight(.normal): kind = .knight(.promoted)
        case .silver(.normal): kind = .silver(.promoted)
        case .bishop(.normal): kind = .bishop(.promoted)
        case .rook(.normal): kind = .rook(.promoted)
        default: break
        }
    }

    mutating func unpromote() {
        switch kind {
        case .pawn(.promoted): kind = .pawn(.normal)
        case .lance(.promoted): kind = .lance(.normal)
        case .knight(.promoted): kind = .knight(.normal)
        case .silver(.promoted): kind = .silver(.normal)
        case .bishop(.promoted): kind = .bishop(.normal)
        case .rook(.promoted): kind = .rook(.normal)
        default: break
        }
    }

    mutating func capture(by color: Color) {
        unpromote()
        self.color = color
    }
}

extension Piece {
    struct Attack: Hashable {
        let direction: Direction
        let isFarReaching: Bool
    }

    var attacks: Set<Attack> { Self.pieceAttacks[self]! }

    init?(character: Character, isPromoted: Bool) {
        let state: State = isPromoted ? .promoted : .normal
        switch character.lowercased() {
        case "p": kind = .pawn(state)
        case "l": kind = .lance(state)
        case "n": kind = .knight(state)
        case "s": kind = .silver(state)
        case "g": kind = .gold
        case "b": kind = .bishop(state)
        case "r": kind = .rook(state)
        case "k": kind = .king
        default: return nil
        }
        color = character.isUppercase ? .black : .white
    }
}

private extension Piece {
    static let pieceAttacks: [Self: Set<Attack>] = Dictionary(uniqueKeysWithValues: piecesAndAttacks)

    static var piecesAndAttacks: [(Self, Set<Attack>)] {
        allCases.map { piece in
            let directions = piece.farReachingDirections
            let attacks = piece.attackableDirections.map {
                Attack(direction: $0, isFarReaching: directions.contains($0))
            }
            return (piece, Set(attacks))
        }
    }

    var attackableDirections: [Direction] {
        let directions: [Direction] = {
            switch kind {
            case .pawn(.normal),
                 .lance(.normal):
                return [.north]
            case .knight(.normal):
                return [.northNorthEast, .northNorthWest]
            case .silver(.normal):
                return [.north, .northEast, .northWest, .southEast, .southWest]
            case .pawn(.promoted),
                 .lance(.promoted),
                 .knight(.promoted),
                 .silver(.promoted),
                 .gold:
                return [.north, .south, .east, .west, .northEast, .northWest]
            case .bishop(.normal):
                return [.northEast, .northWest, .southEast, .southWest]
            case .rook(.normal):
                return [.north, .south, .east, .west]
            case .bishop(.promoted),
                 .rook(.promoted),
                 .king:
                return [.north, .south, .east, .west, .northEast, .northWest, .southEast, .southWest]
            }
        }()
        return color.isBlack ? directions : directions.map { $0.flippedVertically }
    }

    var farReachingDirections: [Direction] {
        let directions: [Direction] = {
            switch kind {
            case .lance(.normal):
                return [.north]
            case .bishop:
                return [.northEast, .northWest, .southEast, .southWest]
            case .rook:
                return [.north, .south, .east, .west]
            default:
                return []
            }
        }()
        return color.isBlack ? directions : directions.map { $0.flippedVertically }
    }
}

extension Piece.Kind: CaseIterable {
    public static let allCases: [Self] = [
        .pawn(.normal), .pawn(.promoted),
        .lance(.normal), .lance(.promoted),
        .knight(.normal), .knight(.promoted),
        .silver(.normal), .silver(.promoted),
        .gold,
        .bishop(.normal), .bishop(.promoted),
        .rook(.normal), .rook(.promoted),
        .king,
    ]
}

extension Piece: CaseIterable {
    public static let allCases: [Self] = kindsAndColors.map(Self.init)

    private static var kindsAndColors: [(Kind, Color)] {
        Kind.allCases.flatMap { kind in
            Color.allCases.map { color in (kind, color) }
        }
    }
}

extension Piece.Kind: Comparable {
    public static func < (lhs: Piece.Kind, rhs: Piece.Kind) -> Bool {
        return allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}

extension Piece.Kind: Hashable {}
extension Piece: Hashable {}
