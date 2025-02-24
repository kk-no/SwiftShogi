import SwiftUI

/// Node representing a single move in the game tree.
/// The root node represents the initial position and has a nil move.
public class HistoryNode: Identifiable, Equatable, Hashable {
    /// The move associated with this node (nil for the root).
    public let move: Move?
    /// The move number for this node (nil for the root).
    public let moveNumber: Int?
    /// Parent node; nil for the root.
    public weak var parent: HistoryNode?
    /// Child nodes representing subsequent moves.
    public var children: [HistoryNode] = []
    /// Selected branch index.
    public var selectedChildIndex: Int?

    /// A unique identifier combining the move chain.
    public var id: String {
        if let parent = parent {
            return parent.id + "/" + (move?.toKIFMove ?? "")
        } else {
            return move?.toKIFMove ?? ""
        }
    }

    public init(move: Move? = nil, moveNumber: Int? = nil, parent: HistoryNode? = nil) {
        self.move = move
        self.moveNumber = moveNumber
        self.parent = parent
    }

    public static func == (lhs: HistoryNode, rhs: HistoryNode) -> Bool {
        return lhs.id == rhs.id && lhs.children == rhs.children
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(children.count)
    }
}

/// Manages the game history using a tree structure.
public class History {
    private let root: HistoryNode = .init() // Initial position (no move)
    public private(set) var current: HistoryNode

    public init() {
        current = root
    }

    /// Returns the index of the current move.
    /// Returns -1 when at the initial position (no move has been made).
    public var currentIndex: Int {
        return currentBranchMoves.count - 1
    }

    /// Returns the all move count at the current branch (nil for the root).
    public var count: Int {
        return currentBranchAllMoves.count
    }

    /// Returns the move at the current node (nil for the root).
    public var currentMove: Move? {
        return current.move
    }

    /// Returns the entire history tree as the root node.
    public var allHistory: HistoryNode {
        return root
    }

    /// Returns the selected branch from the root to the current move.
    public var currentBranchMoves: [Move] {
        var moves: [Move] = []
        var node: HistoryNode? = current
        while let n = node, let move = n.move {
            moves.insert(move, at: 0)
            node = n.parent
        }
        return moves
    }

    /// Returns all moves from the root following the selected branch.
    public var currentBranchAllMoves: [Move] {
        var branch: [Move] = []
        var node: HistoryNode = allHistory // start from the root
        while !node.children.isEmpty {
            let selectedIndex = node.selectedChildIndex ?? 0
            guard selectedIndex < node.children.count else { break }
            let child = node.children[selectedIndex]
            if let move = child.move {
                branch.append(move)
            }
            node = child
        }
        return branch
    }

    public func setCurrentNode(_ newNode: HistoryNode) {
        current = newNode
    }

    /// Returns the nodes available as branches at the specified level.
    /// Level is 0-based: level 0 corresponds to the root's children (first move).
    public func branchNodes(at level: Int) -> [HistoryNode] {
        // Start at the root (initial position)
        var node = allHistory
        var currentLevel = 0

        // Traverse along the selected branch until reaching the parent node of the specified level.
        // (If selectedChildIndex is not set, default to the first child.)
        while currentLevel < level, let selectedIndex = node.selectedChildIndex, selectedIndex < node.children.count {
            node = node.children[selectedIndex]
            currentLevel += 1
        }
        return node.children
    }

    /// Switches the branch selection so that the path from the root follows the candidate node.
    /// It does so by updating all parent nodes' selectedChildIndex along the candidate's path.
    public func switchBranch(to candidate: HistoryNode) {
        var node: HistoryNode = candidate
        // Traverse upward until reaching the root.
        while let parent = node.parent {
            if let index = parent.children.firstIndex(of: node) {
                parent.selectedChildIndex = index
            }
            node = parent
        }
    }

    /// Adds a new move as a branch from the current position.
    /// The move number is computed as (current.moveNumber ?? 0) + 1.
    public func addMove(_ move: Move) {
        // Compute the new move's number.
        let newMoveNumber = (current.moveNumber ?? 0) + 1

        // If a child with the same move (based on toKIFMove) already exists, follow it.
        if let index = current.children.firstIndex(where: { $0.move?.toKIFMove == move.toKIFMove }) {
            current.selectedChildIndex = index
            current = current.children[index]
        } else {
            let newNode = HistoryNode(move: move, moveNumber: newMoveNumber, parent: current)
            current.children.append(newNode)
            current.selectedChildIndex = current.children.count - 1
            current = newNode
        }
    }

    /// Undoes the last move by moving to the parent node.
    /// Returns the undone move, or nil if already at the root.
    public func undo() -> Move? {
        guard let parent = current.parent else { return nil }
        let undoneMove = current.move
        current = parent
        return undoneMove
    }

    // Redoes a move by selecting a branch from the current node.
    // If no branch index is provided, it follows the previously selected branch (or defaults to the first branch).
    public func redo(branch index: Int? = nil) -> Move? {
        // Ensure there is at least one child (redo candidate).
        guard !current.children.isEmpty else { return nil }
        // Use the provided branch index or the parent's stored selectedChildIndex, defaulting to 0.
        let branchIndex = index ?? current.selectedChildIndex ?? 0
        guard current.children.indices.contains(branchIndex) else { return nil }
        // Update the parent's selectedChildIndex and move to that child node.
        current.selectedChildIndex = branchIndex
        current = current.children[branchIndex]
        return current.move
    }

    /// Resets the history to the initial position.
    public func reset() {
        current = root
        root.children.removeAll()
        root.selectedChildIndex = nil
    }

    /// Recursively searches the history tree for a node with the given moveNumber.
    public func findNode(withMoveNumber moveNumber: Int) -> HistoryNode? {
        return findHistoryNode(in: allHistory, withMoveNumber: moveNumber)
    }

    private func findHistoryNode(in node: HistoryNode, withMoveNumber moveNumber: Int) -> HistoryNode? {
        if let nodeMoveNumber = node.moveNumber, nodeMoveNumber == moveNumber {
            return node
        }
        for child in node.children {
            if let found = findHistoryNode(in: child, withMoveNumber: moveNumber) {
                return found
            }
        }
        return nil
    }
}
