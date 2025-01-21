public class History {
    private var moves: [Move] = []
    private var currentIndex: Int = -1

    public var currentMove: Move? {
        guard currentIndex >= 0, currentIndex < moves.count else { return nil }
        return moves[currentIndex]
    }

    public var currentMoveIndex: Int {
        return currentIndex
    }

    public var allHistory: [Move] {
        return moves
    }

    func addMove(_ move: Move) {
        if currentIndex < moves.count - 1 {
            moves = Array(moves.prefix(currentIndex + 1))
        }
        moves.append(move)
        currentIndex += 1
    }

    func undo() -> Move? {
        guard currentIndex >= -1 else { return nil }
        let move: Move? = currentIndex >= 0 ? moves[currentIndex] : nil
        if currentIndex > -1 {
            currentIndex -= 1
        }
        return move
    }

    func redo() -> Move? {
        guard currentIndex < moves.count - 1 else { return nil }
        currentIndex += 1
        return moves[currentIndex]
    }

    func reset() {
        moves.removeAll()
        currentIndex = -1
    }
}
