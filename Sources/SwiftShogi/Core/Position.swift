import Foundation

/// SFEN形式の初期局面設定の種類
public enum InitialPositionSFEN {
    /// 平手
    public static let standard = "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1"

    /// 空の盤面
    public static let empty = "9/9/9/9/9/9/9/9/9 b - 1"

    /// 香落ち
    public static let handicapLance = "lnsgkgsn1/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1"

    /// 右香落ち
    public static let handicapRightLance = "1nsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1"

    /// 角落ち
    public static let handicapBishop = "lnsgkgsnl/1r7/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1"

    /// 飛車落ち
    public static let handicapRook = "lnsgkgsnl/7b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1"

    /// 飛香落ち
    public static let handicapRookLance = "lnsgkgsn1/7b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1"

    /// 二枚落ち
    public static let handicap2Pieces = "lnsgkgsnl/9/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1"

    /// 四枚落ち
    public static let handicap4Pieces = "1nsgkgsn1/9/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1"

    /// 六枚落ち
    public static let handicap6Pieces = "2sgkgs2/9/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1"

    /// 八枚落ち
    public static let handicap8Pieces = "3gkg3/9/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1"

    /// 十枚落ち
    public static let handicap10Pieces = "4k4/9/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1"

    /// 詰将棋用の設定
    public static let tsumeShogi = "4k4/9/9/9/9/9/9/9/9 b 2r2b4g4s4n4l18p 1"

    /// 玉が2つある詰将棋用の設定
    public static let tsumeShogi2Kings = "4k4/9/9/9/9/9/9/9/4K4 b 2r2b4g4s4n4l18p 1"
}

/// 局面変更のオプション
public struct DoMoveOption {
    /// バリデーションを無視するかどうか
    public let ignoreValidation: Bool

    public init(ignoreValidation: Bool = false) {
        self.ignoreValidation = ignoreValidation
    }
}

/// 局面の更新内容を表す構造体
public struct PositionChange {
    /// 移動情報
    public struct MoveInfo {
        /// 移動元のマスまたは持ち駒
        public let from: Either<Square, Piece>

        /// 移動先のマスまたは駒台
        public let to: Either<Square, Color>

        public init(from: Either<Square, Piece>, to: Either<Square, Color>) {
            self.from = from
            self.to = to
        }

        public init(from: Square, to: Square) {
            self.from = .left(from)
            self.to = .left(to)
        }

        public init(from: Square, to: Color) {
            self.from = .left(from)
            self.to = .right(to)
        }

        public init(from: Piece, to: Square) {
            self.from = .right(from)
            self.to = .left(to)
        }

        public init(from: Piece, to: Color) {
            self.from = .right(from)
            self.to = .right(to)
        }
    }

    /// 移動情報
    public let move: MoveInfo?

    /// 指定したマスの駒をローテートします
    public let rotate: Square?

    public init(move: MoveInfo? = nil, rotate: Square? = nil) {
        self.move = move
        self.rotate = rotate
    }
}

/// 局面(読み取り専用)
public protocol ImmutablePosition {
    /// 盤面
    var board: ImmutableBoard { get }

    /// 手番
    var color: Color { get }

    /// 先手の持ち駒
    var blackHand: any ImmutableHand { get }

    /// 後手の持ち駒
    var whiteHand: any ImmutableHand { get }

    /// 王手がかかっているかどうかを判定します
    var isChecked: Bool { get }

    /// 指定した手番の持ち駒を取得します
    /// - Parameter color: 手番
    /// - Returns: 持ち駒
    func hand(color: Color) -> any ImmutableHand

    /// 現在の局面における指し手を生成します
    /// - Parameters:
    ///   - from: 移動元（盤上の駒または持ち駒）
    ///   - to: 移動先
    /// - Returns: 指し手（生成できない場合はnil）
    func createMove(from: Either<Square, PieceType>, to: Square) -> Move?

    /// USI形式の指し手から Move オブジェクトを生成します
    /// - Parameter usiMove: USI形式の指し手文字列
    /// - Returns: 指し手（無効な場合はnil）
    func createMoveByUSI(_ usiMove: String) -> Move?

    /// 打ち歩詰めかどうかを判定します
    /// - Parameter move: 指し手
    /// - Returns: 打ち歩詰めならtrue
    func isPawnDropMate(_ move: Move) -> Bool

    /// 指定したマスに利いている駒のマス目を列挙します
    /// - Parameter to: 対象のマス
    /// - Returns: 利いている駒のマス目一覧
    func listAttackers(to: Square) -> [Square]

    /// 指定したマスに利いている指定した駒のマス目を列挙します
    /// - Parameters:
    ///   - to: 対象のマス
    ///   - piece: 駒
    /// - Returns: 利いている駒のマス目一覧
    func listAttackersByPiece(to: Square, piece: Piece) -> [Square]

    /// 合法手かどうかを判定します
    /// - Parameter move: 指し手
    /// - Returns: 合法手ならtrue
    func isValidMove(_ move: Move) -> Bool

    /// 有効な編集作業かどうかを判定します
    /// - Parameters:
    ///   - from: 移動元のマスまたは持ち駒
    ///   - to: 移動先のマスまたは駒台
    /// - Returns: 有効な編集ならtrue
    func isValidEditing(from: Either<Square, Piece>, to: Either<Square, Color>) -> Bool

    /// SFEN形式の文字列を返します
    var sfen: String { get }

    /// 手数を指定してSFEN形式の文字列を取得します
    /// - Parameter nextPly: 手数
    /// - Returns: SFEN形式の文字列
    func getSFEN(nextPly: Int) -> String

    /// クローンを生成します
    func clone() -> Position
}

/// 局面
public class Position: ImmutablePosition {
    private var _board: Board
    private var _color: Color
    private var _blackHand: Hand
    private var _whiteHand: Hand

    /// 盤面
    public var board: ImmutableBoard {
        return _board
    }

    /// 手番
    public var color: Color {
        return _color
    }

    /// 先手の持ち駒
    public var blackHand: any ImmutableHand {
        return _blackHand
    }

    /// 後手の持ち駒
    public var whiteHand: any ImmutableHand {
        return _whiteHand
    }

    /// 王手がかかっているかどうかを判定します
    public var isChecked: Bool {
        return _board.isChecked(kingColor: _color, option: nil)
    }

    /// 初期化
    public init() {
        _board = Board()
        _color = .black
        _blackHand = Hand()
        _whiteHand = Hand()
    }

    /// 指定した手番の持ち駒を取得します
    /// - Parameter color: 手番
    /// - Returns: 持ち駒
    public func hand(color: Color) -> any ImmutableHand {
        return color == .black ? _blackHand : _whiteHand
    }

    /// 現在の局面における指し手を生成します
    /// - Parameters:
    ///   - from: 移動元（Squareまたは駒の種類）
    ///   - to: 移動先
    /// - Returns: 指し手（生成できない場合はnil）
    public func createMove(from: Either<Square, PieceType>, to: Square) -> Move? {
        switch from {
        case let .left(square):
            guard let piece = _board.at(square) else {
                return nil
            }
            let capturedPiece = _board.at(to)
            return Move(
                from: from,
                to: to,
                promote: false,
                color: _color,
                pieceType: piece.type,
                capturedPieceType: capturedPiece?.type
            )

        case let .right(pieceType):
            return Move(
                from: from,
                to: to,
                promote: false,
                color: _color,
                pieceType: pieceType,
                capturedPieceType: nil
            )
        }
    }

    /// USI形式の指し手から Move オブジェクトを生成します
    /// - Parameter usiMove: USI形式の指し手文字列
    /// - Returns: 指し手（無効な場合はnil）
    public func createMoveByUSI(_ usiMove: String) -> Move? {
        guard let (from, to, promote) = parseUSIMove(usiMove) else {
            return nil
        }

        guard var move = createMove(from: from, to: to) else {
            return nil
        }

        if promote {
            move = move.withPromote()
        }

        return move
    }

    /// 指定したマスから別のマスへ移動可能かどうかを判定します
    private func isMovable(from: Square, to: Square) -> Bool {
        let dx = to.x - from.x
        let dy = to.y - from.y

        let result = Direction.fromVector(x: dx, y: dy)
        if !result.valid {
            return false
        }

        guard let piece = _board.at(from) else {
            return false
        }

        guard let direction = result.direction else {
            return false
        }

        // 駒の移動タイプを取得
        let moveType = getMoveType(piece: piece, direction: direction)

        switch moveType {
        case .short:
            return result.distance == 1
        case .long:
            let delta = direction.delta
            var square = from.neighbor(dx: delta.x, dy: delta.y)

            while square.isValid {
                if square == to {
                    return true
                }

                if _board.at(square) != nil {
                    return false
                }

                square = square.neighbor(dx: delta.x, dy: delta.y)
            }

            return false
        case .none:
            return false
        }
    }

    /// 駒の移動タイプを取得する関数
    private func getMoveType(piece: Piece, direction: Direction) -> MoveType? {
        // 駒の種類と向きに応じた移動可能方向を判定
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

    /// 同じ筋に歩があるかチェックする関数
    private func pawnExists(color: Color, file: Int) -> Bool {
        for rank in 1 ... 9 {
            let square = Square(file: file, rank: rank)
            if let piece = _board.at(square),
               piece.type == .pawn,
               piece.color == color
            {
                return true
            }
        }
        return false
    }

    /// 打ち歩詰めかどうかを判定します
    /// - Parameter move: 指し手
    /// - Returns: 打ち歩詰めならtrue
    public func isPawnDropMate(_ move: Move) -> Bool {
        // 打ち歩でなければfalse
        if move.isFromBoard {
            return false
        }

        if case let .right(pieceType) = move.from, pieceType != .pawn {
            return false
        }

        // 移動先の上（相手から見ると下）に玉があるか確認
        let kingDirection: Direction = move.color == .black ? .up : .down
        let kingSquare = move.to.neighbor(direction: kingDirection)

        guard let king = _board.at(kingSquare),
              king.type == .king,
              king.color != move.color
        else {
            return false
        }

        // 玉が逃げられるかチェック
        for dir in Direction.allDirections where dir != .leftUpKnight && dir != .rightUpKnight &&
            dir != .leftDownKnight && dir != .rightDownKnight
        {
            let to = kingSquare.neighbor(direction: dir)
            if !to.isValid {
                continue
            }

            let piece = _board.at(to)
            if piece != nil && piece?.color == king.color {
                continue
            }

            // 逃げ先に自分の駒の利きがなければ、玉は逃げられる（打ち歩詰めではない）
            if !_board.hasPower(target: to, color: move.color, option: PowerDetectionOption(filled: move.to)) {
                return false
            }
        }

        // 他の駒で王手を防げるかチェック
        for square in _board.listSquaresByColor(color: king.color) {
            if square == kingSquare {
                continue
            }

            if isMovable(from: square, to: move.to) {
                let option = PowerDetectionOption(filled: move.to, ignore: square)
                if !_board.isChecked(kingColor: king.color, option: option) {
                    return false
                }
            }
        }

        // 打ち歩詰め
        return true
    }

    /// 指定したマスに利いている駒のマス目を列挙します
    /// - Parameter to: 対象のマス
    /// - Returns: 利いている駒のマス目一覧
    public func listAttackers(to: Square) -> [Square] {
        return _board.listNonEmptySquares().filter { square in
            isMovable(from: square, to: to)
        }
    }

    /// 指定したマスに利いている指定した駒のマス目を列挙します
    /// - Parameters:
    ///   - to: 対象のマス
    ///   - piece: 駒
    /// - Returns: 利いている駒のマス目一覧
    public func listAttackersByPiece(to: Square, piece: Piece) -> [Square] {
        return _board.listSquaresByPiece(target: piece).filter { square in
            isMovable(from: square, to: to)
        }
    }

    /// 配置が不可能な段かどうかを判定
    private func isInvalidRank(color: Color, type: PieceType, rank: Int) -> Bool {
        if color == .black {
            switch type {
            case .pawn, .lance:
                return rank == 1
            case .knight:
                return rank <= 2
            default:
                return false
            }
        } else {
            switch type {
            case .pawn, .lance:
                return rank == 9
            case .knight:
                return rank >= 8
            default:
                return false
            }
        }
    }

    /// 合法手かどうかを判定します
    /// - Parameter move: 指し手
    /// - Returns: 合法手ならtrue
    public func isValidMove(_ move: Move) -> Bool {
        // 盤上の駒を動かす場合
        if move.isFromBoard {
            if case let .left(fromSquare) = move.from {
                let target = _board.at(fromSquare)
                // 移動元に自分の駒がなければ無効
                guard let target = target, target.color == _color else {
                    return false
                }

                // 移動可能な方向でなければ無効
                if !isMovable(from: fromSquare, to: move.to) {
                    return false
                }

                // 移動先に自分の駒があれば無効
                if let captured = _board.at(move.to), captured.color == _color {
                    return false
                }

                // 成りの条件チェック
                if move.promote {
                    // 成れない駒なら無効
                    if !target.isPromotable {
                        return false
                    }

                    // 成れる段でなければ無効
                    if !isPromotableRank(color: _color, rank: fromSquare.rank) &&
                        !isPromotableRank(color: _color, rank: move.to.rank)
                    {
                        return false
                    }
                }
                // 成らない場合、歩や香車などが配置不可能な段に行こうとしていたら無効
                else if isInvalidRank(color: _color, type: target.type, rank: move.to.rank) {
                    return false
                }

                // 自分の玉が王手されているか（玉以外の駒を動かす場合）
                // または移動先のマスが相手の利きがあるか（玉を動かす場合）
                if move.pieceType != .king {
                    let option = PowerDetectionOption(filled: move.to, ignore: fromSquare)
                    if _board.isChecked(kingColor: _color, option: option) {
                        return false
                    }
                } else {
                    let option = PowerDetectionOption(ignore: fromSquare)
                    if _board.hasPower(target: move.to, color: _color.reversed(), option: option) {
                        return false
                    }
                }
            }
        }
        // 持ち駒を打つ場合
        else {
            // 成りフラグが立っていたら無効
            if move.promote {
                return false
            }

            // 手番が違ったら無効
            if move.color != _color {
                return false
            }

            // 持ち駒がない場合は無効
            if case let .right(pieceType) = move.from {
                let handObj = hand(color: _color)
                if let hand = handObj as? Hand {
                    if hand.count(pieceType: pieceType) <= 0 {
                        return false
                    }
                } else {
                    return false
                }
            } else {
                return false
            }

            // 移動先にすでに駒があれば無効
            if _board.at(move.to) != nil {
                return false
            }

            // 歩や香車などが配置不可能な段であれば無効
            if case let .right(pieceType) = move.from,
               isInvalidRank(color: _color, type: pieceType, rank: move.to.rank)
            {
                return false
            }

            // 二歩チェック（すでに同じ筋に歩があれば無効）
            if case let .right(pieceType) = move.from, pieceType == .pawn,
               pawnExists(color: _color, file: move.to.file)
            {
                return false
            }

            // 自分の玉が王手されたままになっていないか
            let option = PowerDetectionOption(filled: move.to)
            if _board.isChecked(kingColor: _color, option: option) {
                return false
            }

            // 打ち歩詰めならば無効
            if case let .right(pieceType) = move.from, pieceType == .pawn,
               isPawnDropMate(move)
            {
                return false
            }
        }

        return true
    }

    /// 指定した指し手で駒を動かします
    /// - Parameters:
    ///   - move: 指し手
    ///   - option: 実行オプション
    /// - Returns: 実行が成功したらtrue
    @discardableResult
    public func doMove(_ move: Move, option: DoMoveOption = DoMoveOption()) -> Bool {
        // バリデーションが有効で、合法手でなければ実行しない
        if !option.ignoreValidation && !isValidMove(move) {
            return false
        }

        // 盤上の駒を動かす場合
        if case let .left(square) = move.from {
            let target = _board.at(square)!
            let captured = _board.at(move.to)

            _board.remove(square: square)
            _board.set(square: move.to, piece: move.promote ? target.promoted() : target)

            // 相手の駒を取った場合、持ち駒に追加
            if let captured = captured, captured.type != .king {
                let unpromoted = captured.unpromoted()
                if _color == .black {
                    _blackHand.add(pieceType: unpromoted.type, count: 1)
                } else {
                    _whiteHand.add(pieceType: unpromoted.type, count: 1)
                }
            }
        }
        // 持ち駒を打つ場合
        else if case let .right(pieceType) = move.from {
            if _color == .black {
                _blackHand.reduce(pieceType: pieceType, count: 1)
            } else {
                _whiteHand.reduce(pieceType: pieceType, count: 1)
            }
            _board.set(square: move.to, piece: Piece(color: _color, type: pieceType))
        }

        // 手番を交代
        _color = _color.reversed()

        return true
    }

    /// 指定した指し手を元に戻します
    /// - Parameter move: 指し手
    public func undoMove(_ move: Move) {
        // 手番を戻す
        _color = _color.reversed()

        // 盤上の駒を動かした場合
        if case let .left(fromSquare) = move.from {
            // 移動元に駒を戻す
            _board.set(square: fromSquare, piece: Piece(color: _color, type: move.pieceType))

            // 取られた駒があれば移動先に戻す
            if let capturedType = move.capturedPieceType {
                let capturedPiece = Piece(color: _color.reversed(), type: capturedType)
                _board.set(square: move.to, piece: capturedPiece)

                // 自分の持ち駒から取った駒を減らす（玉は持ち駒にならない）
                if capturedType != .king {
                    let unpromoted = capturedPiece.unpromoted()
                    if _color == .black {
                        _blackHand.reduce(pieceType: unpromoted.type, count: 1)
                    } else {
                        _whiteHand.reduce(pieceType: unpromoted.type, count: 1)
                    }
                }
            } else {
                // 取られた駒がなければマスを空にする
                _board.remove(square: move.to)
            }
        }
        // 持ち駒を打った場合
        else if case let .right(pieceType) = move.from {
            // 移動先の駒を取り除く
            _board.remove(square: move.to)

            // 持ち駒を増やす
            if _color == .black {
                _blackHand.add(pieceType: pieceType, count: 1)
            } else {
                _whiteHand.add(pieceType: pieceType, count: 1)
            }
        }
    }

    /// 有効な編集作業かどうかを判定します
    /// - Parameters:
    ///   - from: 移動元のマスまたは持ち駒
    ///   - to: 移動先のマスまたは駒台
    /// - Returns: 有効な編集ならtrue
    public func isValidEditing(from: Either<Square, Piece>, to: Either<Square, Color>) -> Bool {
        switch from {
        case let .left(fromSquare):
            // 移動元に駒がなければ無効
            guard let piece = _board.at(fromSquare) else {
                return false
            }

            switch to {
            case let .left(toSquare):
                // 同じマスへの移動は無効
                if fromSquare == toSquare {
                    return false
                }
                return true

            case .right:
                // 玉は駒台に移動できない
                if piece.type == .king {
                    return false
                }
                return true
            }

        case let .right(piece):
            // 持ち駒がなければ無効
            let handObj = hand(color: piece.color)
            if let hand = handObj as? Hand {
                if hand.count(pieceType: piece.type) <= 0 {
                    return false
                }
            } else {
                return false
            }

            switch to {
            case let .left(toSquare):
                // 移動先にすでに駒があれば無効
                if _board.at(toSquare) != nil {
                    return false
                }
                return true

            case let .right(toColor):
                // 同じ駒台への移動は無効
                if piece.color == toColor {
                    return false
                }
                return true
            }
        }
    }

    /// 盤面を編集します
    /// - Parameter change: 編集内容
    /// - Returns: 編集が成功したらtrue
    @discardableResult
    public func edit(_ change: PositionChange) -> Bool {
        // 駒の移動
        if let moveInfo = change.move {
            // 有効性チェック
            if !isValidEditing(from: moveInfo.from, to: moveInfo.to) {
                return false
            }

            switch moveInfo.from {
            case let .left(fromSquare):
                let piece = _board.remove(square: fromSquare)!

                switch moveInfo.to {
                case let .left(toSquare):
                    _board.set(square: toSquare, piece: piece)

                case let .right(toColor):
                    // 駒を持ち駒に加える（成っている場合は不成に戻す）
                    let unpromoted = piece.unpromoted()
                    if toColor == .black {
                        _blackHand.add(pieceType: unpromoted.type, count: 1)
                    } else {
                        _whiteHand.add(pieceType: unpromoted.type, count: 1)
                    }
                }

            case let .right(piece):
                // 持ち駒を減らす
                if piece.color == .black {
                    _blackHand.reduce(pieceType: piece.type, count: 1)
                } else {
                    _whiteHand.reduce(pieceType: piece.type, count: 1)
                }

                switch moveInfo.to {
                case let .left(toSquare):
                    // 盤上に置く
                    _board.set(square: toSquare, piece: piece)

                case let .right(toColor):
                    // 別の駒台に移動
                    if toColor == .black {
                        _blackHand.add(pieceType: piece.type, count: 1)
                    } else {
                        _whiteHand.add(pieceType: piece.type, count: 1)
                    }
                }
            }
        }

        // 駒のローテート
        if let rotateSquare = change.rotate {
            if let piece = _board.at(rotateSquare) {
                _board.set(square: rotateSquare, piece: piece.rotate())
            }
        }

        return true
    }

    /// 手番を設定します
    /// - Parameter color: 手番
    public func setColor(_ color: Color) {
        _color = color
    }

    /// SFEN形式の文字列を返します
    public var sfen: String {
        return getSFEN(nextPly: 1)
    }

    /// 手数を指定してSFEN形式の文字列を取得します
    /// - Parameter nextPly: 手数
    /// - Returns: SFEN形式の文字列
    public func getSFEN(nextPly: Int) -> String {
        var result = "\(_board.sfen) \(_color.sfenNotation) "
        result += Hand.formatSFEN(black: _blackHand, white: _whiteHand)
        result += " \(max(nextPly, 1))"
        return result
    }

    /// SFENで盤面を初期化します
    /// - Parameter sfen: SFEN形式の文字列
    /// - Returns: 初期化が成功したらtrue
    @discardableResult
    public func resetBySFEN(_ sfen: String) -> Bool {
        if !Position.isValidSFEN(sfen) {
            return false
        }

        let sections = sfen.split(separator: " ")
        let sfenPrefix = sections[0] == "sfen"
        let startIndex = sfenPrefix ? 1 : 0

        // 盤面を初期化
        _board.resetBySFEN(String(sections[startIndex]))

        // 手番を設定
        _color = Color.fromSFEN(String(sections[startIndex + 1]))

        // 持ち駒を設定
        if let hands = Hand.parseSFEN(String(sections[startIndex + 2])) {
            _blackHand = hands.black
            _whiteHand = hands.white
        } else {
            return false
        }

        return true
    }

    /// 文字列が正しいSFEN形式であるか判定します
    /// - Parameter sfen: SFEN形式の文字列
    /// - Returns: 有効なSFENならtrue
    public static func isValidSFEN(_ sfen: String) -> Bool {
        let sections = sfen.split(separator: " ")
        if (sections.count == 5 || sections.count == 4) && sections[0] == "sfen" {
            // 先頭に "sfen" がある場合はスキップ
            let tmpSections = sections.dropFirst()
            if tmpSections.count < 3 {
                return false
            }
            return isValidSFENComponents(sections: Array(tmpSections))
        }

        if sections.count < 3 {
            return false
        }

        return isValidSFENComponents(sections: Array(sections))
    }

    /// SFEN形式の文字列の各コンポーネントが正しいか判定します
    /// - Parameter sections: SFEN形式の文字列のコンポーネント
    /// - Returns: 有効なSFENならtrue
    private static func isValidSFENComponents(sections: [Substring]) -> Bool {
        // 盤面チェック
        if !Board.isValidSFEN(String(sections[0])) {
            return false
        }

        // 手番チェック
        if !Color.isValidSFENColor(String(sections[1])) {
            return false
        }

        // 持ち駒チェック
        if !Hand.isValidSFEN(String(sections[2])) {
            return false
        }

        // 手数チェック（省略可能）
        if sections.count >= 4 && !sections[3].allSatisfy({ $0.isNumber }) {
            return false
        }

        return true
    }

    /// SFEN形式の文字列から局面を生成します
    /// - Parameter sfen: SFEN形式の文字列
    /// - Returns: 局面（無効な場合はnil）
    public static func fromSFEN(_ sfen: String) -> Position? {
        let position = Position()
        return position.resetBySFEN(sfen) ? position : nil
    }

    /// 初期局面の種類からSFEN形式の文字列を取得します
    /// - Parameter type: 初期局面の種類（文字列）
    /// - Returns: SFEN形式の文字列
    public static func initialPositionToSFEN(_ type: String) -> String {
        switch type {
        case "standard": return InitialPositionSFEN.standard
        case "empty": return InitialPositionSFEN.empty
        case "handicapLance": return InitialPositionSFEN.handicapLance
        case "handicapRightLance": return InitialPositionSFEN.handicapRightLance
        case "handicapBishop": return InitialPositionSFEN.handicapBishop
        case "handicapRook": return InitialPositionSFEN.handicapRook
        case "handicapRookLance": return InitialPositionSFEN.handicapRookLance
        case "handicap2Pieces": return InitialPositionSFEN.handicap2Pieces
        case "handicap4Pieces": return InitialPositionSFEN.handicap4Pieces
        case "handicap6Pieces": return InitialPositionSFEN.handicap6Pieces
        case "handicap8Pieces": return InitialPositionSFEN.handicap8Pieces
        case "handicap10Pieces": return InitialPositionSFEN.handicap10Pieces
        case "tsumeShogi": return InitialPositionSFEN.tsumeShogi
        case "tsumeShogi2Kings": return InitialPositionSFEN.tsumeShogi2Kings
        default: return InitialPositionSFEN.standard
        }
    }

    /// 別のオブジェクトからコピーします
    /// - Parameter position: コピー元の局面
    public func copyFrom(_ position: Position) {
        _board.copyFrom(board: position._board)
        _color = position._color
        _blackHand.copyFrom(position._blackHand)
        _whiteHand.copyFrom(position._whiteHand)
    }

    /// クローンを生成します
    public func clone() -> Position {
        let position = Position()
        position.copyFrom(self)
        return position
    }
}

/// 局面に存在する駒のカウント
public struct PieceCounts {
    public var pawn: Int = 0
    public var lance: Int = 0
    public var knight: Int = 0
    public var silver: Int = 0
    public var gold: Int = 0
    public var bishop: Int = 0
    public var rook: Int = 0
    public var king: Int = 0
    public var promPawn: Int = 0
    public var promLance: Int = 0
    public var promKnight: Int = 0
    public var promSilver: Int = 0
    public var horse: Int = 0
    public var dragon: Int = 0

    public init() {}

    public subscript(pieceType: PieceType) -> Int {
        get {
            switch pieceType {
            case .pawn: return pawn
            case .lance: return lance
            case .knight: return knight
            case .silver: return silver
            case .gold: return gold
            case .bishop: return bishop
            case .rook: return rook
            case .king: return king
            case .promPawn: return promPawn
            case .promLance: return promLance
            case .promKnight: return promKnight
            case .promSilver: return promSilver
            case .horse: return horse
            case .dragon: return dragon
            }
        }
        set {
            switch pieceType {
            case .pawn: pawn = newValue
            case .lance: lance = newValue
            case .knight: knight = newValue
            case .silver: silver = newValue
            case .gold: gold = newValue
            case .bishop: bishop = newValue
            case .rook: rook = newValue
            case .king: king = newValue
            case .promPawn: promPawn = newValue
            case .promLance: promLance = newValue
            case .promKnight: promKnight = newValue
            case .promSilver: promSilver = newValue
            case .horse: horse = newValue
            case .dragon: dragon = newValue
            }
        }
    }
}

/// 局面に存在する駒の数を数えます
/// - Parameter position: 局面
/// - Returns: 駒の数
public func countExistingPieces(_ position: ImmutablePosition) -> PieceCounts {
    var result = PieceCounts()

    // 盤上の駒をカウント
    for square in Square.allSquares {
        guard let piece = position.board.at(square) else { continue }
        result[piece.type] += 1
    }

    // 持ち駒をカウント
    let blackHandObj = position.hand(color: .black)
    if let blackHand = blackHandObj as? Hand {
        for (type, count) in blackHand {
            result[type] += count
        }
    }

    let whiteHandObj = position.hand(color: .white)
    if let whiteHand = whiteHandObj as? Hand {
        for (type, count) in whiteHand {
            result[type] += count
        }
    }

    return result
}

/// 局面に存在しない駒の数を数えます
/// - Parameter position: 局面
/// - Returns: 駒の数
public func countNotExistingPieces(_ position: ImmutablePosition) -> PieceCounts {
    let existed = countExistingPieces(position)
    var result = PieceCounts()

    // 各駒の総数から存在する駒の数を引く
    result.pawn = 18 - existed.pawn - existed.promPawn
    result.lance = 4 - existed.lance - existed.promLance
    result.knight = 4 - existed.knight - existed.promKnight
    result.silver = 4 - existed.silver - existed.promSilver
    result.gold = 4 - existed.gold
    result.bishop = 2 - existed.bishop - existed.horse
    result.rook = 2 - existed.rook - existed.dragon
    result.king = 2 - existed.king

    // 成駒は既に通常の駒でカウントされているため0
    result.promPawn = 0
    result.promLance = 0
    result.promKnight = 0
    result.promSilver = 0
    result.horse = 0
    result.dragon = 0

    return result
}

/// 入玉宣言ルール
public enum JishogiDeclarationRule: String {
    /// 24点法
    case general24

    /// 27点法
    case general27
}

/// 入玉宣言結果
public enum JishogiDeclarationResult: String {
    case win
    case lose
    case draw
}

/// 敵陣に侵入している駒を取得
/// - Parameters:
///   - board: 盤面
///   - color: 手番
/// - Returns: 侵入している駒の配列
private func invadingPieces(board: ImmutableBoard, color: Color) -> [Piece] {
    var pieces: [Piece] = []

    for square in Square.allSquares {
        // 敵陣（成れる段）でなければfalse
        if !isPromotableRank(color: color, rank: square.rank) {
            continue
        }

        // マスに駒がなければfalse
        guard let piece = board.at(square) else {
            continue
        }

        // 自分の駒で玉以外ならtrue
        if piece.color == color, piece.type != .king {
            pieces.append(piece)
        }
    }

    return pieces
}

/// 時将棋指し直し判定の点数を計算します
/// - Parameters:
///   - position: 局面
///   - color: 計算対象のプレイヤー
/// - Returns: 点数
public func countJishogiPoint(position: ImmutablePosition, color: Color) -> Int {
    var point = 0

    // 盤上の自分の駒をカウント
    for square in Square.allSquares {
        guard let piece = position.board.at(square) else { continue }
        if piece.color == color && piece.type != .king {
            let type = piece.unpromoted().type
            point += (type == .bishop || type == .rook) ? 5 : 1
        }
    }

    // 持ち駒をカウント
    let handObj = position.hand(color: color)
    if let hand = handObj as? Hand {
        point += hand.count(pieceType: .pawn)
        point += hand.count(pieceType: .lance)
        point += hand.count(pieceType: .knight)
        point += hand.count(pieceType: .silver)
        point += hand.count(pieceType: .gold)
        point += hand.count(pieceType: .bishop) * 5
        point += hand.count(pieceType: .rook) * 5
    }

    // 駒落ちの場合は上手に落とした駒を加点
    if color == .white {
        let notExisting = countNotExistingPieces(position)
        point += notExisting.pawn
        point += notExisting.lance
        point += notExisting.knight
        point += notExisting.silver
        point += notExisting.gold
        point += notExisting.bishop * 5
        point += notExisting.rook * 5
    }

    return point
}

/// 入玉宣言法に基づいて宣言する際の点数を計算します
/// - Parameters:
///   - position: 局面
///   - color: 宣言するプレイヤー
/// - Returns: 点数
public func countJishogiDeclarationPoint(position: ImmutablePosition, color: Color) -> Int {
    var point = 0

    // 敵陣に侵入している駒を加点
    for piece in invadingPieces(board: position.board, color: color) {
        let type = piece.unpromoted().type
        point += (type == .bishop || type == .rook) ? 5 : 1
    }

    // 持ち駒を加点
    let handObj = position.hand(color: color)
    if let hand = handObj as? Hand {
        point += hand.count(pieceType: .pawn)
        point += hand.count(pieceType: .lance)
        point += hand.count(pieceType: .knight)
        point += hand.count(pieceType: .silver)
        point += hand.count(pieceType: .gold)
        point += hand.count(pieceType: .bishop) * 5
        point += hand.count(pieceType: .rook) * 5
    }

    // 駒落ちの場合は上手に落とした駒を加点
    if color == .white {
        let notExisting = countNotExistingPieces(position)
        point += notExisting.pawn
        point += notExisting.lance
        point += notExisting.knight
        point += notExisting.silver
        point += notExisting.gold
        point += notExisting.bishop * 5
        point += notExisting.rook * 5
    }

    return point
}

/// 入玉宣言法に基づいて宣言した場合の結果を判定します
/// - Parameters:
///   - rule: 宣言ルール
///   - position: 局面
///   - color: 宣言するプレイヤー
/// - Returns: 宣言結果
public func judgeJishogiDeclaration(
    rule: JishogiDeclarationRule,
    position: ImmutablePosition,
    color: Color
) -> JishogiDeclarationResult {
    // 自分の手番か
    if position.color != color {
        return .lose
    }

    // 玉が敵陣に入っているか
    guard let king = position.board.findKing(color: color),
          isPromotableRank(color: color, rank: king.rank)
    else {
        return .lose
    }

    // 王手されていないか
    if position.board.isChecked(kingColor: color, option: nil) {
        return .lose
    }

    // 敵陣に10枚以上駒が侵入しているか
    if invadingPieces(board: position.board, color: color).count < 10 {
        return .lose
    }

    // 点数を計算
    let point = countJishogiDeclarationPoint(position: position, color: color)

    // 24点法
    if rule == .general24 {
        if point >= 31 {
            return .win
        } else if point >= 24 {
            return .draw
        } else {
            return .lose
        }
    }

    // 27点法
    if color == .black {
        // 先手は28点以上で勝ち
        return point >= 28 ? .win : .draw
    } else {
        // 後手は27点以上で勝ち
        return point >= 27 ? .win : .draw
    }
}

/// 成れる段かどうかを判定
/// - Parameters:
///   - color: 手番
///   - rank: 段
/// - Returns: 成れる段ならtrue
public func isPromotableRank(color: Color, rank: Int) -> Bool {
    if color == .black {
        return rank <= 3
    }
    return rank >= 7
}
