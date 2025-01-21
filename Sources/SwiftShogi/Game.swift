import Foundation

public struct Game {
    public private(set) var board: Board
    public private(set) var color: Color
    public private(set) var capturedPieces: [Piece]
    public private(set) var history: History = .init()

    public init(board: Board = Board(), color: Color = .black, capturedPieces: [Piece] = []) {
        self.board = board
        self.color = color
        self.capturedPieces = capturedPieces
    }

    public init(sfen: SFEN) {
        self.init(
            board: sfen.board,
            color: sfen.color,
            capturedPieces: sfen.capturedPieces
        )
    }
}

public extension Game {
    mutating func perform(_ move: Move) throws {
        try validate(move)

        var capturedPiece: Piece?
        if case let .board(destinationSquare) = move.destination {
            capturedPiece = board[destinationSquare]
        }

        let updatedMove = Move(
            source: move.source,
            destination: move.destination,
            piece: move.piece,
            shouldPromote: move.shouldPromote,
            capturedPiece: capturedPiece
        )

        capturePieceIfNeeded(from: updatedMove.destination)
        remove(updatedMove.piece, from: updatedMove.source)
        insert(updatedMove.piece, to: updatedMove.destination, shouldPromote: updatedMove.shouldPromote)
        color.toggle()

        history.addMove(updatedMove)
    }

    mutating func performMoveWithoutValidation(_ move: Move) {
        var capturedPiece: Piece?
        if case let .board(destinationSquare) = move.destination {
            capturedPiece = board[destinationSquare]
        }

        let updatedMove = Move(
            source: move.source,
            destination: move.destination,
            piece: move.piece,
            shouldPromote: move.shouldPromote,
            capturedPiece: capturedPiece
        )

        capturePieceIfNeeded(from: updatedMove.destination)
        remove(updatedMove.piece, from: updatedMove.source)
        insert(updatedMove.piece, to: updatedMove.destination, shouldPromote: updatedMove.shouldPromote)
        color.toggle()
    }

    mutating func undo() throws {
        guard let move = history.undo() else { return }

        reverseMove(move)
    }

    mutating func redo() throws {
        guard let move = history.redo() else { return }

        performMoveWithoutValidation(move)
    }

    private mutating func reverseMove(_ move: Move) {
        switch move.source {
        case let .board(sourceSquare):
            if case let .board(destinationSquare) = move.destination {
                board[sourceSquare] = move.piece
                board[destinationSquare] = nil

                if let capturedPiece = move.capturedPiece {
                    capturedPieces.removeLast()
                    board[destinationSquare] = capturedPiece
                }
            }
        case .capturedPiece:
            if case let .board(destinationSquare) = move.destination {
                capturedPieces.append(move.piece)
                board[destinationSquare] = nil
            }
        }
        color.toggle()
    }

    /// An error in move validation.
    enum MoveValidationError: Error {
        case boardPieceDoesNotExist
        case capturedPieceDoesNotExist
        case invalidPieceColor
        case friendlyPieceAlreadyExists
        case pieceCannotPromote
        case illegalBoardPiecePromotion
        case illegalCapturedPiecePromotion
        case illegalAttack
        case kingPieceIsChecked
        case pieceAlreadyPromoted
        case nifu
    }

    /// Validates `move`.
    func validate(_ move: Move) throws {
        try validateSource(move.source, piece: move.piece)
        try validateDestination(move.destination)
        if move.shouldPromote {
            try validatePromotion(
                source: move.source,
                destination: move.destination,
                piece: move.piece
            )
        }
        try validateAttack(
            source: move.source,
            destination: move.destination,
            piece: move.piece
        )
    }

    func isValid(for move: Move) -> Bool {
        do {
            try validate(move)
            return true
        } catch {
            return false
        }
    }

    /// Returns the valid moves for the current color.
    func validMoves() -> [Move] {
        (movesFromBoard + movesFromCapturedPieces).filter(isValid)
    }

    /// Returns the valid moves of `piece` from `source`.
    func validMoves(from source: Move.Source, piece: Piece) -> [Move] {
        let moves: [Move] = {
            switch source {
            case let .board(square):
                return boardPieceMoves(for: piece, from: square)
            case .capturedPiece:
                return capturedPieceMoves(for: piece)
            }
        }()
        return moves.filter(isValid)
    }

    func toSFEN() -> String {
        var boardString = ""
        for rank in Rank.allCases {
            var emptyCount = 0
            for file in File.allCases {
                let square = Square(file: file, rank: rank)
                if let piece = board[square] {
                    if emptyCount > 0 {
                        boardString += "\(emptyCount)"
                        emptyCount = 0
                    }
                    boardString += piece.sfenString
                } else {
                    emptyCount += 1
                }
            }
            if emptyCount > 0 {
                boardString += "\(emptyCount)"
            }
            if rank != .i {
                boardString += "/"
            }
        }

        var capturedPiecesString = ""
        var pieceCount = [String: Int]()
        for piece in capturedPieces {
            let str = piece.sfenString
            pieceCount[str, default: 0] += 1
        }
        for (char, count) in pieceCount.sorted(by: { $0.key < $1.key }) {
            if count > 1 {
                capturedPiecesString += "\(count)\(char)"
            } else {
                capturedPiecesString += "\(char)"
            }
        }
        if capturedPiecesString.isEmpty {
            capturedPiecesString = "-"
        }

        let colorString = color == .black ? "b" : "w"
        return "\(boardString) \(colorString) \(capturedPiecesString) 1"
    }
}

private extension Game {

    mutating func capturePieceIfNeeded(from destination: Move.Destination) {
        guard case let .board(square) = destination, var piece = board[square] else { return }

        board[square] = nil
        piece.capture(by: color)
        capturedPieces.append(piece)
    }

    mutating func remove(_ piece: Piece, from source: Move.Source) {
        switch source {
        case let .board(square):
            board[square] = nil
        case .capturedPiece:
            if let index = capturedPieces.firstIndex(of: piece) {
                capturedPieces.remove(at: index)
            }
        }
    }

    mutating func insert(_ piece: Piece, to destination: Move.Destination, shouldPromote: Bool) {
        switch destination {
        case let .board(square):
            var piece = piece
            if shouldPromote {
                piece.promote()
            }
            board[square] = piece
        }
    }

    func validateSource(_ source: Move.Source, piece: Piece) throws {
        switch source {
        case let .board(square):
            guard board[square] == piece else {
                throw MoveValidationError.boardPieceDoesNotExist
            }
        case .capturedPiece:
            guard capturedPieces.contains(piece) else {
                throw MoveValidationError.capturedPieceDoesNotExist
            }
        }

        guard piece.color == color else {
            throw MoveValidationError.invalidPieceColor
        }
    }

    func validateDestination(_ destination: Move.Destination) throws {
        switch destination {
        case let .board(square):
            // If a piece at the destination does not exist, no validation is required
            guard let piece = board[square] else { return }

            guard piece.color != color else {
                throw MoveValidationError.friendlyPieceAlreadyExists
            }
        }
    }

    func validatePromotion(source: Move.Source, destination: Move.Destination, piece: Piece) throws {
        guard !piece.isPromoted else {
            throw MoveValidationError.pieceAlreadyPromoted
        }
        guard piece.canPromote else {
            throw MoveValidationError.pieceCannotPromote
        }

        switch (source, destination) {
        case let (.board(sourceSquare), .board(destinationSquare)):
            let squares = Square.promotableCases(for: color)
            guard squares.contains(where: { $0 == sourceSquare || $0 == destinationSquare }) else {
                throw MoveValidationError.illegalBoardPiecePromotion
            }
        case (.capturedPiece, _):
            throw MoveValidationError.illegalCapturedPiecePromotion
        }
    }

    func validateAttack(source: Move.Source, destination: Move.Destination, piece: Piece) throws {
        switch (source, destination, piece) {
        case let (.board(sourceSquare), .board(destinationSquare), _):
            guard board.isAttackable(from: sourceSquare, to: destinationSquare) else {
                throw MoveValidationError.illegalAttack
            }
            guard !board.isKingCheckedByMovingPiece(from: sourceSquare, to: destinationSquare, for: color) else {
                throw MoveValidationError.kingPieceIsChecked
            }
        case let (.capturedPiece, .board(destinationSquare), piece):
            guard !board.isKingCheckedByMovingPiece(piece, to: destinationSquare, for: color) else {
                throw MoveValidationError.kingPieceIsChecked
            }
        }
    }

    func validateNifu(for move: Move) throws {
        if move.source != .capturedPiece {
            return
        }
        if case .pawn(.normal) = move.piece.kind {
            if case let .board(square) = move.destination {
                let file = square.file
                let pawnsInFile = board.occupiedSquares(for: color).filter { sq in
                    sq.file == file && {
                        if case .pawn(.normal) = board[sq]?.kind {
                            return true
                        }
                        return false
                    }()
                }
                if !pawnsInFile.isEmpty {
                    throw MoveValidationError.nifu
                }
                return
            }
        }
    }

    var movesFromBoard: [Move] {
        board.occupiedSquares(for: color).flatMap { boardPieceMoves(for: board[$0]!, from: $0) }
    }

    func boardPieceMoves(for piece: Piece, from square: Square) -> [Move] {
        board.attackableSuqares(from: square).flatMap { attackableSuqare in
            [true, false].map { shouldPromote in
                Move(
                    source: .board(square),
                    destination: .board(attackableSuqare),
                    piece: piece,
                    shouldPromote: shouldPromote
                )
            }
        }
    }

    var movesFromCapturedPieces: [Move] {
        capturedPieces.filter { $0.color == color }.flatMap { capturedPieceMoves(for: $0) }
    }

    func capturedPieceMoves(for piece: Piece) -> [Move] {
        board.emptySquares.map {
            Move(source: .capturedPiece, destination: .board($0), piece: piece)
        }
    }
}
