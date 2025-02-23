public struct Move {
    public enum Source {
        case board(Square)
        case capturedPiece
    }

    public enum Destination {
        case board(Square)
    }

    public let source: Source
    public let destination: Destination
    public let piece: Piece
    public let shouldPromote: Bool
    public var capturedPiece: Piece?

    public init(source: Move.Source, destination: Move.Destination, piece: Piece, shouldPromote: Bool = false, capturedPiece: Piece? = nil) {
        self.source = source
        self.destination = destination
        self.piece = piece
        self.shouldPromote = shouldPromote
        self.capturedPiece = capturedPiece
    }
}

public extension Move {
    var destinationSquare: Square? {
        if case let .board(square) = destination {
            return square
        }
        return nil
    }

    var canPromote: Bool {
        guard !piece.isPromoted, piece.canPromote else { return false }
        switch (source, destination) {
        case let (.board(sourceSquare), .board(destinationSquare)):
            let promotableSquares = Square.promotableCases(for: piece.color)
            return promotableSquares.contains(where: { $0 == sourceSquare || $0 == destinationSquare })
        default:
            return false
        }
    }

    var mustPromote: Bool {
        if source == .capturedPiece {
            return false
        }
        if case let .board(square) = destination {
            let rank = square.rank

            if case .pawn(.normal) = piece.kind {
                return (piece.color == .black && rank == .a) || (piece.color == .white && rank == .i)
            }
            if case .lance(.normal) = piece.kind {
                return (piece.color == .black && rank == .a) || (piece.color == .white && rank == .i)
            }
            if case .knight(.normal) = piece.kind {
                return (piece.color == .black && (rank == .a || rank == .b)) || (piece.color == .white && (rank == .h || rank == .i))
            }
        }
        return false
    }

    var toUSIMove: String {
        let sourceString: String
        let destinationString: String

        switch source {
        case let .board(square):
            sourceString = square.usiString
        case .capturedPiece:
            sourceString = "\(piece.sfenString.uppercased())*"
        }

        switch destination {
        case let .board(square):
            destinationString = square.usiString
        }

        return sourceString + destinationString + (shouldPromote ? "+" : "")
    }

    var toKIFMove: String {
        let destinationString: String
        let sourceString: String
        let actionString: String

        switch destination {
        case let .board(square):
            destinationString = "\(square.file.kifStringWide)\(square.rank.kifString)"
        }

        switch source {
        case .capturedPiece:
            sourceString = ""
            actionString = "打"
        case let .board(square):
            sourceString = "(\(square.file.kifString)\(square.rank.numString))"
            actionString = shouldPromote ? "成" : ""
        }

        return "\(destinationString)\(piece.kifString)\(actionString)\(sourceString)"
    }
}

public extension Array where Element == Move {
    func toUSIMoves() -> [String] {
        map { $0.toUSIMove }
    }
}

extension Move.Source: Equatable {}
extension Move.Destination: Equatable {}
extension Move: Equatable {}
