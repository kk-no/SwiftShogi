import Foundation

/// 盤面からのSFEN文字への変換用
private func sfenCharToNumber(_ sfen: Character) -> Int? {
    switch sfen {
    case "1": return 1
    case "2": return 2
    case "3": return 3
    case "4": return 4
    case "5": return 5
    case "6": return 6
    case "7": return 7
    case "8": return 8
    case "9": return 9
    default: return nil
    }
}

/// 利き判定のオプション
public struct PowerDetectionOption {
    /// このマスは埋まっているとみなす
    var filled: Square?
    /// このマスを無視する
    var ignore: Square?
}

/// 盤面 (読み取り専用)
public protocol ImmutableBoard {
    /// 指定したマスの駒を取得します。
    func at(_ square: Square) -> Piece?

    /// 空ではないマスの一覧を取得します。
    func listNonEmptySquares() -> [Square]

    /// 指定した手番の玉のマスを返します。
    func findKing(color: Color) -> Square?

    /// 指定したマスに指定した手番の駒の利きがあるかどうかを判定します。
    func hasPower(target: Square, color: Color, option: PowerDetectionOption?) -> Bool

    /// 指定した手番の玉に対して王手がかかっているかどうかを判定します。
    func isChecked(kingColor: Color, option: PowerDetectionOption?) -> Bool

    /// SFEN形式の文字列を取得します。
    var sfen: String { get }
}

/// 盤面
public class Board: ImmutableBoard {
    /// 盤面の全マス
    private var squares: [Piece?] = Array(repeating: nil, count: 81)

    /// 初期化
    public init() {
        resetBySFEN("lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL")
    }

    /// 指定したマスの駒を取得します。
    public func at(_ square: Square) -> Piece? {
        return squares[square.index]
    }

    /// 指定したマスに駒を配置します。
    public func set(square: Square, piece: Piece) {
        squares[square.index] = piece
    }

    /// 指定した2マスの駒を入れ替えます。
    public func swap(square1: Square, square2: Square) {
        let tmp = squares[square1.index]
        squares[square1.index] = squares[square2.index]
        squares[square2.index] = tmp
    }

    /// 指定したマスの駒を取り除きます。
    @discardableResult
    public func remove(square: Square) -> Piece? {
        let removed = squares[square.index]
        squares[square.index] = nil
        return removed
    }

    /// 空ではないマスの一覧を取得します。
    public func listNonEmptySquares() -> [Square] {
        return Square.allSquares.filter { squares[$0.index] != nil }
    }

    /// 指定した手番の駒があるマスの一覧を取得します。
    public func listSquaresByColor(color: Color) -> [Square] {
        return Square.allSquares.filter { square in
            if let piece = squares[square.index] {
                return piece.color == color
            }
            return false
        }
    }

    /// 指定した駒があるマスの一覧を取得します。
    public func listSquaresByPiece(target: Piece) -> [Square] {
        return Square.allSquares.filter { square in
            if let piece = squares[square.index] {
                return piece == target
            }
            return false
        }
    }

    /// 全てのマスの駒を取り除きます。
    public func clear() {
        for square in Square.allSquares {
            squares[square.index] = nil
        }
    }

    /// SFEN形式の文字列を取得します。
    public var sfen: String {
        var result = ""
        var empty = 0

        for y in 0 ..< 9 {
            for x in 0 ..< 9 {
                let piece = at(Square.fromXY(x: x, y: y))
                if let piece = piece {
                    if empty > 0 {
                        result += String(empty)
                        empty = 0
                    }
                    result += piece.sfen
                } else {
                    empty += 1
                }
            }

            if empty > 0 {
                result += String(empty)
                empty = 0
            }

            if y != 8 {
                result += "/"
            }
        }

        return result
    }

    /// SFENで盤面を初期化します。
    @discardableResult
    public func resetBySFEN(_ sfen: String) -> Bool {
        if !Board.isValidSFEN(sfen) {
            return false
        }

        clear()
        let rows = sfen.split(separator: "/")

        for y in 0 ..< 9 {
            var x = 0
            var i = 0

            while i < rows[y].count {
                let index = rows[y].index(rows[y].startIndex, offsetBy: i)
                var c = String(rows[y][index])

                if c == "+" {
                    i += 1
                    if i >= rows[y].count {
                        return false
                    }
                    let nextIndex = rows[y].index(rows[y].startIndex, offsetBy: i)
                    let nextChar = String(rows[y][nextIndex])
                    c += nextChar
                }

                if c.count == 1, let n = sfenCharToNumber(Character(c)) {
                    x += n
                } else if let piece = Piece.fromSFEN(c) {
                    set(square: Square.fromXY(x: x, y: y), piece: piece)
                    x += 1
                }

                i += 1
            }
        }

        return true
    }

    /// 指定した手番の玉のマスを返します。
    public func findKing(color: Color) -> Square? {
        let king = Piece(color: color, type: .king)
        return Square.allSquares.first { square in
            if let piece = at(square) {
                return piece == king
            }
            return false
        }
    }

    /// 指定したマスに指定した手番の駒の利きがあるかどうかを判定します。
    public func hasPower(target: Square, color: Color, option: PowerDetectionOption? = nil) -> Bool {
        return Direction.allDirections.contains { dir in
            var step = 0
            var square = target.neighbor(direction: dir)

            while square.isValid {
                step += 1

                if let filled = option?.filled, square == filled {
                    break
                }

                if let ignore = option?.ignore, square == ignore {
                    square = square.neighbor(direction: dir)
                    continue
                }

                if let piece = at(square) {
                    if piece.color != color {
                        return false
                    }

                    // ここで移動可能かどうかを判定する
                    // 元のresolveMoveTypeに相当するロジックを実装
                    let rdir = dir.reversed
                    let moveType = getMoveType(piece: piece, direction: rdir)

                    return moveType == .long || (moveType == .short && step == 1)
                }

                square = square.neighbor(direction: dir)
            }

            return false
        }
    }

    /// 駒の移動タイプを取得する関数
    private func getMoveType(piece: Piece, direction: Direction) -> MoveType? {
        // 駒の種類と向きに応じた移動可能方向を判定
        // Directionクラスとの一貫性を保つ実装
        let pieceColor = piece.color
        let pieceType = piece.type

        // 先手の場合
        if pieceColor == .black {
            switch pieceType {
            case .pawn:
                return direction == .up ? .short : nil
            case .lance:
                return direction == .up ? .long : nil
            case .knight:
                return (direction == .leftUpKnight || direction == .rightUpKnight) ? .short : nil
            case .silver:
                return (direction == .leftUp || direction == .up || direction == .rightUp ||
                    direction == .leftDown || direction == .rightDown) ? .short : nil
            case .gold, .promPawn, .promLance, .promKnight, .promSilver:
                return (direction == .leftUp || direction == .up || direction == .rightUp ||
                    direction == .left || direction == .right || direction == .down) ? .short : nil
            case .bishop:
                return (direction == .leftUp || direction == .rightUp ||
                    direction == .leftDown || direction == .rightDown) ? .long : nil
            case .rook:
                return (direction == .up || direction == .down ||
                    direction == .left || direction == .right) ? .long : nil
            case .king:
                return Direction.allDirections.filter { $0 != .leftUpKnight && $0 != .rightUpKnight &&
                    $0 != .leftDownKnight && $0 != .rightDownKnight
                }
                .contains(direction) ? .short : nil
            case .horse:
                if direction == .leftUp || direction == .rightUp ||
                    direction == .leftDown || direction == .rightDown
                {
                    return .long
                }
                return (direction == .up || direction == .down ||
                    direction == .left || direction == .right) ? .short : nil
            case .dragon:
                if direction == .up || direction == .down ||
                    direction == .left || direction == .right
                {
                    return .long
                }
                return (direction == .leftUp || direction == .rightUp ||
                    direction == .leftDown || direction == .rightDown) ? .short : nil
            }
        }
        // 後手の場合
        else {
            switch pieceType {
            case .pawn:
                return direction == .down ? .short : nil
            case .lance:
                return direction == .down ? .long : nil
            case .knight:
                return (direction == .leftDownKnight || direction == .rightDownKnight) ? .short : nil
            case .silver:
                return (direction == .leftDown || direction == .down || direction == .rightDown ||
                    direction == .leftUp || direction == .rightUp) ? .short : nil
            case .gold, .promPawn, .promLance, .promKnight, .promSilver:
                return (direction == .leftDown || direction == .down || direction == .rightDown ||
                    direction == .left || direction == .right || direction == .up) ? .short : nil
            case .bishop:
                return (direction == .leftDown || direction == .rightDown ||
                    direction == .leftUp || direction == .rightUp) ? .long : nil
            case .rook:
                return (direction == .down || direction == .up ||
                    direction == .left || direction == .right) ? .long : nil
            case .king:
                return Direction.allDirections.filter { $0 != .leftUpKnight && $0 != .rightUpKnight &&
                    $0 != .leftDownKnight && $0 != .rightDownKnight
                }
                .contains(direction) ? .short : nil
            case .horse:
                if direction == .leftDown || direction == .rightDown ||
                    direction == .leftUp || direction == .rightUp
                {
                    return .long
                }
                return (direction == .down || direction == .up ||
                    direction == .left || direction == .right) ? .short : nil
            case .dragon:
                if direction == .down || direction == .up ||
                    direction == .left || direction == .right
                {
                    return .long
                }
                return (direction == .leftDown || direction == .rightDown ||
                    direction == .leftUp || direction == .rightUp) ? .short : nil
            }
        }
    }

    /// 指定した手番の玉に対して王手がかかっているかどうかを判定します。
    public func isChecked(kingColor: Color, option: PowerDetectionOption? = nil) -> Bool {
        guard let square = findKing(color: kingColor) else {
            return false
        }

        let powerOption = PowerDetectionOption(
            filled: option?.filled,
            ignore: option?.ignore
        )

        return hasPower(target: square, color: kingColor.reversed(), option: powerOption)
    }

    /// 文字列が正しいSFEN形式であるか判定します。
    public static func isValidSFEN(_ sfen: String) -> Bool {
        let rows = sfen.split(separator: "/")

        if rows.count != 9 {
            return false
        }

        for y in 0 ..< 9 {
            var x = 0
            var i = 0

            while i < rows[y].count {
                let index = rows[y].index(rows[y].startIndex, offsetBy: i)
                var c = String(rows[y][index])

                if c == "+" {
                    i += 1
                    if i >= rows[y].count {
                        return false
                    }
                    let nextIndex = rows[y].index(rows[y].startIndex, offsetBy: i)
                    let nextChar = String(rows[y][nextIndex])
                    c += nextChar
                }

                if c.count == 1, let n = sfenCharToNumber(Character(c)) {
                    x += n
                } else if Piece.isValidSFEN(c) {
                    x += 1
                } else {
                    return false
                }

                i += 1
            }

            if x != 9 {
                return false
            }
        }

        return true
    }

    /// 別のオブジェクトから盤面をコピーします。
    public func copyFrom(board: Board) {
        for square in Square.allSquares {
            squares[square.index] = board.at(square)
        }
    }
}
