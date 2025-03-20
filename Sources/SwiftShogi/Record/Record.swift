import Foundation

/// USI形式の出力オプション
public struct USIFormatOptions {
    /// 平手の場合に "startpos" を使用するかを指定します。デフォルトは true です。
    public let startpos: Bool

    /// 投了 "resign" を出力に含めるかどうかを表します。デフォルトは false です。
    public let resign: Bool

    /// 全ての指し手を含めるかどうかを指定します。デフォルトは false です。
    public let allMoves: Bool

    public init(startpos: Bool = true, resign: Bool = false, allMoves: Bool = false) {
        self.startpos = startpos
        self.resign = resign
        self.allMoves = allMoves
    }
}

/// 棋譜(読み取り専用)プロトコル
public protocol ImmutableRecord {
    /// メタデータ
    var metadata: ImmutableRecordMetadata { get }

    /// 初期局面
    var initialPosition: ImmutablePosition { get }

    /// 現在の局面
    var position: ImmutablePosition { get }

    /// 初期局面のノード
    var first: ImmutableNode { get }

    /// 現在の局面のノード
    var current: ImmutableNode { get }

    /// アクティブな経路の指し手の一覧
    var moves: [ImmutableNode] { get }

    /// 現在の局面までの指し手の一覧
    var movesBefore: [ImmutableNode] { get }

    /// アクティブな経路の総手数
    var length: Int { get }

    /// 最初の兄弟ノード
    var branchBegin: ImmutableNode { get }

    /// 千日手かどうか
    var repetition: Bool { get }

    /// 指定された局面が何回現れたかを返します
    func getRepetitionCount(position: ImmutablePosition) -> Int

    /// 連続王手の千日手かどうか
    var perpetualCheck: Color? { get }

    /// USI形式の文字列
    var usi: String { get }

    /// USI形式の文字列を取得します
    func getUSI(options: USIFormatOptions?) -> String

    /// SFEN形式の文字列
    var sfen: String { get }

    /// USEN形式の文字列とブランチインデックス
    var usen: (String, Int) { get }

    /// しおりの一覧
    var bookmarks: [String] { get }

    /// 全てのノードを訪問します
    func forEach(handler: (ImmutableNode, ImmutablePosition) -> Void)

    /// イベントを監視します
    func on(event: String, handler: @escaping () -> Void)
}

// Sequence protocol support for Record
extension Record: Sequence {
    public typealias Element = (node: ImmutableNode, position: ImmutablePosition)

    public func makeIterator() -> AnyIterator<Element> {
        let pos = _initialPosition.clone()
        var stack: [(NodeImpl, Bool)] = [(_first, false)] // (node, visited)

        return AnyIterator {
            while !stack.isEmpty {
                let (node, visited) = stack.removeLast()

                if !visited {
                    // Mark for visit
                    stack.append((node, true))

                    if let branch = node.branchNode {
                        stack.append((branch, false))
                    }

                    if let next = node.nextNode {
                        if let move = node.move as? Move {
                            pos.doMove(move, option: DoMoveOption(ignoreValidation: true))
                        }
                        stack.append((next, false))
                        continue
                    }
                } else {
                    // Return the node and position
                    let result = (node: node as ImmutableNode, position: pos as ImmutablePosition)

                    // Restore position state when returning to parent
                    if let move = node.move as? Move {
                        pos.undoMove(move)
                    }

                    return result
                }
            }
            return nil
        }
    }
}

/// 棋譜
public class Record: ImmutableRecord {
    public var metadata: ImmutableRecordMetadata {
        get { return _metadata }
        set {
            if let newMetadata = newValue as? RecordMetadata {
                _metadata = newMetadata
            } else {
                // 万が一RecordMetadataでなかった場合の処理
                let newRecordMetadata = RecordMetadata()
                _metadata = newRecordMetadata
            }
        }
    }

    private var _metadata: RecordMetadata = .init()
    private var _initialPosition: Position
    private var _position: Position
    private var _first: NodeImpl
    private var _current: NodeImpl
    private var repetitionCounts: [String: Int] = [:]
    private var repetitionStart: [String: Int] = [:]
    private var onChangePosition: () -> Void = {}

    // USENの駒の位置テーブル
    private let usenHandTable: [PieceType: Int] = [
        .pawn: 81 + 10,
        .lance: 81 + 11,
        .knight: 81 + 12,
        .silver: 81 + 13,
        .gold: 81 + 9,
        .bishop: 81 + 14,
        .rook: 81 + 15,
        .king: 81 + 8,
        .promPawn: 81 + 2,
        .promLance: 81 + 3,
        .promKnight: 81 + 4,
        .promSilver: 81 + 5,
        .horse: 81 + 6,
        .dragon: 81 + 7,
    ]

    /// 初期化
    /// - Parameter position: 初期局面（省略時は平手）
    public init(position: Position? = nil) {
        _metadata = RecordMetadata()
        _initialPosition = position?.clone() ?? Position()
        _position = _initialPosition.clone()
        _first = NodeImpl.newRootEntry(color: _initialPosition.color)
        _current = _first
        incrementRepetition()
    }

    /// 初期局面
    public var initialPosition: ImmutablePosition {
        return _initialPosition
    }

    /// 現在の局面
    public var position: ImmutablePosition {
        return _position
    }

    /// 初期局面のノード
    public var first: ImmutableNode {
        return _first
    }

    /// 現在の局面のノード
    public var current: ImmutableNode {
        return _current
    }

    /// アクティブな経路の指し手の一覧
    public var moves: [ImmutableNode] {
        var result = movesBefore

        var p = _current.nextNode
        while p != nil {
            while p != nil && !p!.activeBranch {
                p = p?.branchNode
            }
            if let p = p {
                result.append(p)
            }
            p = p?.nextNode
        }

        return result
    }

    /// 現在の局面までの指し手の一覧
    public var movesBefore: [ImmutableNode] {
        return _movesBefore
    }

    private var _movesBefore: [NodeImpl] {
        var result: [NodeImpl] = []
        result.append(_current)

        var p = _current.prevNode
        while p != nil {
            result.insert(p!, at: 0)
            p = p?.prevNode
        }

        return result
    }

    /// アクティブな経路の総手数
    public var length: Int {
        var len = _current.ply

        var p = _current.nextNode
        while p != nil {
            while p != nil && !p!.activeBranch {
                p = p?.branchNode
            }
            if let p = p {
                len = p.ply
            }
            p = p?.nextNode
        }

        return len
    }

    /// 最初の兄弟ノード
    public var branchBegin: ImmutableNode {
        return _current.prevNode?.nextNode ?? _current
    }

    /// 指定した局面で棋譜を初期化します
    /// - Parameter position: 局面
    public func clear(position: Position? = nil) {
        metadata = RecordMetadata()

        if let position = position {
            _initialPosition = position.clone()
        }

        _position = _initialPosition.clone()
        _first = NodeImpl.newRootEntry(color: _initialPosition.color)
        _current = _first
        repetitionCounts = [:]
        repetitionStart = [:]
        incrementRepetition()
        onChangePosition()
    }

    /// 指し手を追加して1手先に進みます
    /// - Parameters:
    ///   - move: 指し手または特殊な指し手
    ///   - option: 実行オプション
    /// - Returns: 成功したかどうか
    @discardableResult
    public func append(_ move: Any, option: DoMoveOption = DoMoveOption()) -> Bool {
        if _append(move, option: option) {
            onChangePosition()
            return true
        }
        return false
    }

    @discardableResult
    private func _append(_ moveObj: Any, option: DoMoveOption = DoMoveOption()) -> Bool {
        // SpecialMoveTypeをSpecialMoveに変換
        var move = moveObj
        if let type = moveObj as? SpecialMoveType {
            move = specialMove(type)
        }

        // 指し手を表す文字列を取得する
        let lastMove = _current.move is Move ? (_current.move as! Move) : nil
        let displayText: String

        if let moveMove = move as? Move {
            displayText = TextUtil.formatMove(position: _position, move: moveMove, options: ["lastMove": lastMove as Any])
        } else if let specialMove = move as? SpecialMove {
            displayText = TextUtil.formatSpecialMove(specialMove.name)
        } else {
            return false
        }

        // 局面を動かす
        var isCheck = false
        if let moveMove = move as? Move {
            if !_position.doMove(moveMove, option: option) {
                return false
            }
            incrementRepetition()
            isCheck = _position.isChecked
        }

        // 特殊な指し手のノードの場合は前のノードに戻る
        if _current !== _first, !(_current.move is Move) {
            _goBack()
        }

        // 最終ノードの場合は単に新しいノードを追加する
        if _current.nextNode == nil {
            let newNode = NodeImpl(
                ply: _current.ply + 1,
                prev: _current,
                branchIndex: 0,
                activeBranch: true,
                nextColor: _position.color,
                move: move,
                isCheck: isCheck,
                displayText: displayText
            )

            _current.nextNode = newNode
            _current = newNode
            _current.setElapsedMs(0)
            return true
        }

        // 既存の兄弟ノードから選択を解除する
        var p = _current.nextNode
        while let node = p {
            node.activeBranch = false
            p = node.branchNode
        }

        // 同じ指し手が既に存在する場合はそのノードへ移動して終わる
        var lastBranch = _current.nextNode!
        p = _current.nextNode

        while let node = p {
            if areSameMoves(node.move, move) {
                _current = node
                _current.activeBranch = true
                return true
            }
            lastBranch = node
            p = node.branchNode
        }

        // 兄弟ノードを追加する
        let newNode = NodeImpl(
            ply: _current.ply + 1,
            prev: _current,
            branchIndex: lastBranch.branchIndex + 1,
            activeBranch: true,
            nextColor: _position.color,
            move: move,
            isCheck: isCheck,
            displayText: displayText
        )

        newNode.setElapsedMs(0)
        lastBranch.branchNode = newNode
        _current = newNode
        return true
    }

    /// 1手前に戻ります
    /// - Returns: 戻れたかどうか
    @discardableResult
    public func goBack() -> Bool {
        if _goBack() {
            onChangePosition()
            return true
        }
        return false
    }

    /// 1手前に戻ります
    /// - Returns: 戻れたかどうか
    @discardableResult
    private func _goBack() -> Bool {
        if let prev = _current.prevNode {
            if let move = _current.move as? Move {
                decrementRepetition()
                _position.undoMove(move)
            }
            _current = prev
            return true
        }
        return false
    }

    /// 1手先に進みます
    /// - Returns: 進めたかどうか
    @discardableResult
    public func goForward() -> Bool {
        if _goForward() {
            onChangePosition()
            return true
        }
        return false
    }

    @discardableResult
    private func _goForward() -> Bool {
        if let next = _current.nextNode {
            _current = next

            while !_current.activeBranch, let branch = _current.branchNode {
                _current = branch
            }

            if let move = _current.move as? Move {
                _position.doMove(move, option: DoMoveOption(ignoreValidation: true))
                incrementRepetition()
            }

            return true
        }

        return false
    }

    /// アクティブな経路上で指定した手数まで移動します
    /// - Parameter ply: 手数
    public func goto(_ ply: Int) {
        let orgPly = _current.ply
        _goto(ply)

        if orgPly != _current.ply {
            onChangePosition()
        }
    }

    private func _goto(_ ply: Int) {
        while ply < _current.ply {
            if !_goBack() {
                break
            }
        }

        while ply > _current.ply {
            if !_goForward() {
                break
            }
        }
    }

    /// 全ての分岐選択を初期化して最初のノードをアクティブにします
    public func resetAllBranchSelection() {
        _forEach { node, _ in
            if let mutableNode = node as? NodeImpl {
                mutableNode.activeBranch = mutableNode.isFirstBranch
            }
        }

        if let prevNext = _current.prevNode?.nextNode {
            _current = prevNext
        }
    }

    /// インデクスを指定して兄弟ノードを選択します
    /// - Parameter index: インデックス
    /// - Returns: 選択できたかどうか
    @discardableResult
    public func switchBranchByIndex(_ index: Int) -> Bool {
        if _current.branchIndex == index {
            return true
        }

        guard let prev = _current.prevNode else {
            return false
        }

        var found = false
        var p = prev.nextNode

        while let node = p {
            if node.branchIndex == index {
                node.activeBranch = true

                if let currentMove = _current.move as? Move {
                    decrementRepetition()
                    _position.undoMove(currentMove)
                }

                _current = node

                if let currentMove = _current.move as? Move {
                    _position.doMove(currentMove, option: DoMoveOption(ignoreValidation: true))
                    incrementRepetition()
                }

                found = true
            } else {
                node.activeBranch = false
            }

            p = node.branchNode
        }

        if found {
            onChangePosition()
        }

        return found
    }

    private func incrementRepetition() {
        let sfen = _position.sfen
        repetitionCounts[sfen] = (repetitionCounts[sfen] ?? 0) + 1
        if repetitionCounts[sfen] == 1 {
            repetitionStart[sfen] = _current.ply
        }
    }

    private func decrementRepetition() {
        let sfen = _position.sfen
        guard let count = repetitionCounts[sfen], count > 0 else {
            return
        }

        repetitionCounts[sfen] = count - 1
        if count == 1 {
            repetitionCounts.removeValue(forKey: sfen)
            repetitionStart.removeValue(forKey: sfen)
        }
    }

    /// 千日手かどうか
    public var repetition: Bool {
        return getRepetitionCount(position: _position) >= 4
    }

    /// 指定された局面が何回現れたかを返します
    /// - Parameter position: 局面
    /// - Returns: 出現回数
    public func getRepetitionCount(position: ImmutablePosition) -> Int {
        return repetitionCounts[position.sfen] ?? 0
    }

    /// 連続王手の千日手かどうか
    public var perpetualCheck: Color? {
        guard repetition else {
            return nil
        }

        let sfen = _position.sfen
        guard let since = repetitionStart[sfen] else {
            return nil
        }

        var black = true
        var white = true
        var color = _position.color

        var p = _current
        while p.ply >= since {
            color = color.reversed()

            if !p.isCheck {
                if color == .black {
                    black = false
                } else {
                    white = false
                }
            }

            guard let prev = p.prevNode else {
                break
            }
            p = prev
        }

        return black ? .black : (white ? .white : nil)
    }

    // MARK: - USI 関連

    /// USI形式の文字列
    public var usi: String {
        return getUSI(options: nil)
    }

    /// USI形式の文字列を取得します
    /// - Parameter options: オプション
    /// - Returns: USI文字列
    public func getUSI(options: USIFormatOptions? = nil) -> String {
        let sfen = _initialPosition.sfen
        let useStartpos = (options?.startpos != false) && (sfen == InitialPositionSFEN.standard)
        let position = "position " + (useStartpos ? "startpos" : "sfen \(sfen)")

        var moves: [String] = []
        var p: ImmutableNode? = _first

        while true {
            while p != nil && !(p!.activeBranch) {
                p = p!.branch
            }

            guard let node = p else {
                break
            }

            if let move = node.move as? Move {
                moves.append(move.usi)
            } else if let options = options, options.resign,
                      let specialMove = node.move as? SpecialMove,
                      specialMove.name == SpecialMoveType.resign.rawValue
            {
                moves.append("resign")
            }

            if node.next == nil || (!(options?.allMoves ?? false) && node === _current) {
                break
            }

            p = node.next
        }

        if moves.isEmpty {
            return position
        }

        return ([position, "moves"] + moves).joined(separator: " ")
    }

    /// SFEN形式の文字列
    public var sfen: String {
        return _position.getSFEN(nextPly: _current.ply + 1)
    }

    // MARK: - USEN形式の出力

    /// USEN形式の文字列とブランチインデックス
    public var usen: (String, Int) {
        let result = _calculateUsen()
        return result
    }

    private func _calculateUsen() -> (String, Int) {
        let sfen = _initialPosition.sfen
        let isStandard = sfen == InitialPositionSFEN.standard

        // 初期局面のエンコード
        var usenBase = isStandard ? "" :
            sfen.replacingOccurrences(of: " 1$", with: "")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: ".")
            .replacingOccurrences(of: "+", with: "z")

        // 指し手の収集
        var moves = "0."
        var special = ""
        var lastPly = 0
        var bi = 0
        var branchIndex = 0

        for element in self {
            let node = element.node
            // 初期局面はスキップ
            if node.ply == 0 {
                continue
            }

            // 途中で分岐がある場合は区切りを入れる
            if lastPly + 1 != node.ply {
                usenBase += "~\(moves).\(special)"
                moves = "\(node.ply - 1)."
                bi += 1
            }

            // 現在のノードの分岐インデックスを記録
            if current === node {
                branchIndex = bi
            }

            // 特殊な指し手の場合
            if let specialMove = node.move as? SpecialMove {
                switch specialMove.name {
                case SpecialMoveType.resign.rawValue:
                    special = "r"
                case SpecialMoveType.timeout.rawValue:
                    special = "t"
                case SpecialMoveType.maxMoves.rawValue,
                     SpecialMoveType.impass.rawValue,
                     SpecialMoveType.draw.rawValue:
                    special = "j"
                default:
                    // その他は全て中断扱い
                    special = "p"
                }
                continue
            }

            // 通常の指し手の場合
            if let move = node.move as? Move {
                let from: Int

                switch move.from {
                case let .left(square):
                    from = (square.rank - 1) * 9 + (square.file - 1)
                case let .right(pieceType):
                    from = usenHandTable[pieceType] ?? 0
                }

                let to = (move.to.rank - 1) * 9 + (move.to.file - 1)
                let m = (from * 81 + to) * 2 + (move.promote ? 1 : 0)

                moves += m.toString(radix: 36, padding: 3)
                lastPly = node.ply
            }
        }

        // 最後の手を追加
        usenBase += "~\(moves).\(special)"

        return (usenBase, branchIndex)
    }

    /// しおりの一覧
    public var bookmarks: [String] {
        var result: [String] = []
        var existed: [String: Bool] = [:]

        _forEach { node, _ in
            if !node.bookmark.isEmpty && existed[node.bookmark] == nil {
                result.append(node.bookmark)
                existed[node.bookmark] = true
            }
        }

        return result
    }

    // MARK: - ノード探索

    /// 全てのノードを訪問します
    public func forEach(handler: (ImmutableNode, ImmutablePosition) -> Void) {
        _forEach(handler)
    }

    /// 全てのノードを訪問して条件に合うノードを探します
    private func find(_ predicate: (ImmutableNode, ImmutablePosition) -> Bool) -> NodeImpl? {
        let pos = _initialPosition.clone()
        var p = _first

        // 深さ優先探索
        while true {
            if predicate(p, pos) {
                return p
            }

            if let next = p.nextNode {
                if let move = p.move as? Move {
                    pos.doMove(move, option: DoMoveOption(ignoreValidation: true))
                }
                p = next
                continue
            }

            var found = false
            while p.branchNode == nil {
                guard let prev = p.prevNode else {
                    return nil // 終了
                }

                if let move = prev.move as? Move {
                    pos.undoMove(move)
                }

                p = prev

                if p.branchNode != nil {
                    found = true
                    break
                }
            }

            if !found, let branch = p.branchNode {
                p = branch
            } else {
                return nil
            }
        }
    }

    /// 全てのノードを訪問します
    private func _forEach(_ handler: (ImmutableNode, ImmutablePosition) -> Void) {
        let pos = _initialPosition.clone()
        var stack: [(NodeImpl, Bool)] = [(_first, false)] // (ノード, 処理済みか)

        while !stack.isEmpty {
            let (node, visited) = stack.removeLast()

            if !visited {
                // まだ処理していない場合は子を追加してから自分を再追加
                stack.append((node, true))

                if let branch = node.branchNode {
                    stack.append((branch, false))
                }

                if let next = node.nextNode {
                    if let move = node.move as? Move {
                        pos.doMove(move, option: DoMoveOption(ignoreValidation: true))
                    }
                    stack.append((next, false))
                    continue
                }
            } else {
                // 処理済みなら実行
                handler(node, pos)

                // 親に戻る前に状態を元に戻す
                if let move = node.move as? Move {
                    pos.undoMove(move)
                }
            }
        }
    }

    /// イベントを監視します
    public func on(event: String, handler: @escaping () -> Void) {
        switch event {
        case "changePosition":
            onChangePosition = handler
        default:
            break
        }
    }

    // MARK: - USI形式からの棋譜生成

    /// USI形式の文字列から次の手番を取得します
    /// - Parameter usi: USI形式の文字列
    /// - Returns: 次の手番
    public static func getNextColorFromUSI(_ usi: String) -> Color {
        let sections = usi.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
        let baseColor: Color

        if sections.count > 1 && (sections[1] == "startpos" || (sections.count > 3 && sections[3] == "b")) {
            baseColor = .black
        } else {
            baseColor = .white
        }

        let firstMoveIndex: Int
        if sections.count > 1 && sections[1] == "startpos" {
            firstMoveIndex = sections.count > 2 && sections[2] == "moves" ? 3 : 2
        } else {
            firstMoveIndex = sections.count > 6 && sections[6] == "moves" ? 7 : 6
        }

        return (sections.count - firstMoveIndex) % 2 == 0 ? baseColor : baseColor.reversed()
    }

    /// USI形式の文字列から棋譜を読み込みます
    /// - Parameter usi: USI形式の文字列
    /// - Returns: 棋譜またはエラー
    public static func newByUSI(_ usi: String) -> Record {
        let prefixPositionStartpos = "position startpos "
        let prefixPositionSFEN = "position sfen "
        let prefixStartpos = "startpos "
        let prefixSFEN = "sfen "
        let prefixMoves = "moves "

        if usi.hasPrefix(prefixPositionStartpos) {
            let position = Position()
            return newByUSIMoves(position, String(usi.dropFirst(prefixPositionStartpos.count)))
        } else if usi.hasPrefix(prefixPositionSFEN) {
            return newByUSIFromSFEN(String(usi.dropFirst(prefixPositionSFEN.count)))
        } else if usi.hasPrefix(prefixStartpos) {
            let position = Position()
            return newByUSIMoves(position, String(usi.dropFirst(prefixStartpos.count)))
        } else if usi.hasPrefix(prefixSFEN) {
            return newByUSIFromSFEN(String(usi.dropFirst(prefixSFEN.count)))
        } else if usi.hasPrefix(prefixMoves) {
            let position = Position()
            return newByUSIMoves(position, usi)
        } else {
            // 有効なUSIではない場合も空の棋譜を返す
            return Record()
        }
    }

    /// SFEN部分からの読み込み
    private static func newByUSIFromSFEN(_ data: String) -> Record {
        let sections = data.split(separator: " ")
        guard sections.count >= 3 else {
            return Record()
        }

        let movesIndex = sections.count == 3 || sections[3] == "moves" ? 3 : 4
        let sfenPart = sections[0 ..< movesIndex].joined(separator: " ")

        guard let position = Position.fromSFEN(sfenPart) else {
            return Record()
        }

        if movesIndex < sections.count {
            let movesPart = sections[movesIndex...].joined(separator: " ")
            return newByUSIMoves(position, movesPart)
        }

        return Record(position: position)
    }

    /// 指し手部分の読み込み
    private static func newByUSIMoves(_ position: Position, _ data: String) -> Record {
        let record = Record(position: position)

        if data.isEmpty {
            return record
        }

        let sections = data.split(separator: " ")
        guard sections.count > 0, sections[0] == "moves" else {
            return record
        }

        for i in 1 ..< sections.count {
            let section = sections[i]

            if section == "resign" {
                record.append(specialMove(.resign))
                break
            }

            if let move = record.position.createMoveByUSI(String(section)) {
                record.append(move, option: DoMoveOption(ignoreValidation: true))
            } else {
                break
            }
        }

        return record
    }

    /// USEN (Url Safe sfen-Extended Notation) 形式の文字列から棋譜を読み込みます
    /// - Parameters:
    ///   - usen: USEN形式の文字列
    ///   - branchIndex: 分岐インデックス
    ///   - ply: 手数
    /// - Returns: 棋譜
    public static func newByUSEN(usen: String, branchIndex: Int? = nil, ply: Int? = nil) -> Record {
        let sections = usen.split(separator: "~")
        guard sections.count >= 2 else {
            return Record()
        }

        // 初期局面の復元
        let sfenBase = sections[0]
        let sfen: String
        if sfenBase.isEmpty {
            sfen = InitialPositionSFEN.standard
        } else {
            sfen = sfenBase
                .replacingOccurrences(of: "_", with: "/")
                .replacingOccurrences(of: ".", with: " ")
                .replacingOccurrences(of: "z", with: "+") + " 1"
        }

        guard let position = Position.fromSFEN(sfen) else {
            return Record()
        }

        let record = Record(position: position)
        let usenHandReverseTable: [Int: PieceType] = [
            81 + 10: .pawn,
            81 + 11: .lance,
            81 + 12: .knight,
            81 + 13: .silver,
            81 + 9: .gold,
            81 + 14: .bishop,
            81 + 15: .rook,
            81 + 8: .king,
            81 + 2: .promPawn,
            81 + 3: .promLance,
            81 + 4: .promKnight,
            81 + 5: .promSilver,
            81 + 6: .horse,
            81 + 7: .dragon,
        ]

        var activeNode = record.first

        // 各セクションの処理
        for (si, section) in sections.enumerated() where si > 0 {
            let parts = section.split(separator: ".")
            guard parts.count >= 2, let n = Int(String(parts[0])) else {
                continue
            }

            let movesStr = String(parts[1])
            let special = parts.count > 2 ? String(parts[2]) : ""

            record.goto(n)

            // 指し手の追加
            for i in stride(from: 0, to: movesStr.count, by: 3) {
                guard i + 3 <= movesStr.count else {
                    break
                }

                let startIndex = movesStr.index(movesStr.startIndex, offsetBy: i)
                let endIndex = movesStr.index(movesStr.startIndex, offsetBy: i + 3)
                let chunk = String(movesStr[startIndex ..< endIndex])

                guard let m = Int(chunk, radix: 36) else {
                    continue
                }

                let f = m / 162
                let from: Either<Square, PieceType>

                if f < 81 {
                    let file = (f % 9) + 1
                    let rank = (f / 9) + 1
                    from = .left(Square(file: file, rank: rank))
                } else if let pieceType = usenHandReverseTable[f] {
                    from = .right(pieceType)
                } else {
                    continue
                }

                let t = (m % 162) / 2
                let file = (t % 9) + 1
                let rank = (t / 9) + 1
                let to = Square(file: file, rank: rank)

                let promote = m % 2 == 1

                if let move = record.position.createMove(from: from, to: to) {
                    let finalMove = promote ? move.withPromote() : move
                    record.append(finalMove, option: DoMoveOption(ignoreValidation: true))

                    if si - 1 == branchIndex && record.current.ply == ply {
                        activeNode = record.current
                    }
                }
            }

            // 特殊な指し手の追加
            if !special.isEmpty {
                var specialMoveType: SpecialMoveType?

                switch special {
                case "r": specialMoveType = .resign
                case "t": specialMoveType = .timeout
                case "j": specialMoveType = .impass
                case "p": specialMoveType = .interrupt
                default: break
                }

                if let type = specialMoveType {
                    record.append(specialMove(type))

                    if si - 1 == branchIndex && record.current.ply == ply {
                        activeNode = record.current
                    }
                }
            }
        }

        // 活性ノードを設定
        if !(activeNode === record.first) {
            var route: [ImmutableNode] = []
            var p: ImmutableNode? = activeNode

            while p != nil {
                route.insert(p!, at: 0)
                p = p?.prev
            }

            record.goto(0)
            for i in 1 ..< route.count {
                record.append(route[i].move, option: DoMoveOption(ignoreValidation: true))
            }
        } else {
            record.goto(0)
        }

        return record
    }
}

// MARK: - Int拡張

private extension Int {
    func toString(radix: Int, padding: Int) -> String {
        let str = String(self, radix: radix)
        return String(repeating: "0", count: Swift.max(0, padding - str.count)) + str
    }
}
