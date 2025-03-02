import Foundation

/// Node representing a single move in a KIF tree
public class KifNode: Identifiable, Equatable, Hashable {
    /// Core properties from both node types
    public let move: Move? // The actual move object (nil for root)
    public let moveNumber: Int // Move number in the game
    public let kifMove: String // KIF notation of the move
    public let usiMove: String // USI notation of the move

    /// Tree structure
    public weak var parent: KifNode? // Parent node (nil for root)
    public var children: [KifNode] = [] // Child nodes representing subsequent moves
    public var selectedChildIndex: Int? // Selected branch index

    /// Initialization
    public init(move: Move? = nil, moveNumber: Int = 0, kifMove: String = "", usiMove: String = "", parent: KifNode? = nil) {
        self.move = move
        self.moveNumber = moveNumber
        self.kifMove = kifMove
        self.usiMove = usiMove
        self.parent = parent
    }

    /// A unique identifier combining the move chain
    public var id: String {
        if let parent = parent {
            return parent.id + "/" + (kifMove.isEmpty ? "ROOT" : kifMove)
        } else {
            return kifMove.isEmpty ? "ROOT" : kifMove
        }
    }

    public static func == (lhs: KifNode, rhs: KifNode) -> Bool {
        return lhs.id == rhs.id && lhs.children == rhs.children
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(children.count)
    }
}

/// Unified KIF tree that manages game history using a tree structure
public class KifTree {
    public let root: KifNode
    public private(set) var current: KifNode

    public init() {
        root = KifNode(moveNumber: 0, kifMove: "", usiMove: "")
        current = root
    }

    // MARK: - Navigation Properties

    /// Returns the index of the current move.
    /// Returns -1 when at the initial position (no move has been made).
    public var currentIndex: Int {
        return currentBranchMoves.count - 1
    }

    /// Returns the move count at the current branch.
    public var count: Int {
        return currentBranchAllMoves.count
    }

    /// Returns the move at the current node (nil for the root).
    public var currentMove: Move? {
        return current.move
    }

    /// Returns the selected branch from the root to the current move.
    public var currentBranchMoves: [Move] {
        var moves: [Move] = []
        var node: KifNode? = current
        while let n = node, let move = n.move {
            moves.insert(move, at: 0)
            node = n.parent
        }
        return moves
    }

    /// Returns all moves from the root following the selected branch.
    public var currentBranchAllMoves: [Move] {
        var branch: [Move] = []
        var node: KifNode = root
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

    // MARK: - Navigation Methods

    /// Sets the current node
    public func setCurrentNode(_ newNode: KifNode) {
        current = newNode
    }

    /// Returns the nodes available as branches at the specified level.
    public func branchNodes(at level: Int) -> [KifNode] {
        var node = root
        var currentLevel = 0

        while currentLevel < level, let selectedIndex = node.selectedChildIndex, selectedIndex < node.children.count {
            node = node.children[selectedIndex]
            currentLevel += 1
        }
        return node.children
    }

    /// Switches the branch selection
    public func switchBranch(to candidate: KifNode) {
        var node: KifNode = candidate
        while let parent = node.parent {
            if let index = parent.children.firstIndex(of: node) {
                parent.selectedChildIndex = index
            }
            node = parent
        }
    }

    // MARK: - Move Management

    /// Adds a new move as a branch from the current position.
    public func addMove(_ move: Move?) {
        let newMoveNumber = current.moveNumber + 1

        if let kifMove = move?.toKIFMove, let usiMove = move?.toUSIMove {
            // If a child with the same move already exists, follow it
            if let index = current.children.firstIndex(where: { $0.kifMove == move?.toKIFMove }) {
                current.selectedChildIndex = index
                current = current.children[index]
            } else {
                let newNode = KifNode(move: move, moveNumber: newMoveNumber, kifMove: kifMove, usiMove: usiMove, parent: current)
                current.children.append(newNode)
                current.selectedChildIndex = current.children.count - 1
                current = newNode
            }
        }
    }

    /// Undoes the last move
    public func undo() -> Move? {
        guard let parent = current.parent else { return nil }
        let undoneMove = current.move
        current = parent
        return undoneMove
    }

    /// Redoes a move
    public func redo(branch index: Int? = nil) -> Move? {
        guard !current.children.isEmpty else { return nil }
        let branchIndex = index ?? current.selectedChildIndex ?? 0
        guard current.children.indices.contains(branchIndex) else { return nil }
        current.selectedChildIndex = branchIndex
        current = current.children[branchIndex]
        return current.move
    }

    /// Resets the tree
    public func reset() {
        current = root
        root.children.removeAll()
        root.selectedChildIndex = nil
    }

    /// Finds a node with the given move number
    public func findNode(withMoveNumber moveNumber: Int) -> KifNode? {
        return findNode(in: root, withMoveNumber: moveNumber)
    }

    private func findNode(in node: KifNode, withMoveNumber moveNumber: Int) -> KifNode? {
        if node.moveNumber == moveNumber {
            return node
        }
        for child in node.children {
            if let found = findNode(in: child, withMoveNumber: moveNumber) {
                return found
            }
        }
        return nil
    }

    // MARK: - Game Integration Methods

    /// Applies the tree to a game, following the main branch
    public func apply(to game: inout Game) {
        applyMainBranch(to: &game)
        applyVariationBranch(to: &game)
    }

    /// Applies the main branch moves to the game
    public func applyMainBranch(to game: inout Game) {
        var node = root.children.first
        while let current = node {
            if current.usiMove == "resign" { break }
            if let move = game.createMove(fromUSI: current.usiMove) {
                do {
                    try game.perform(move)
                } catch {
                    print("Failed to perform main branch move \(current.usiMove): \(error)")
                }
            }

            // Follow the selected branch
            if let selectedIndex = current.selectedChildIndex, selectedIndex < current.children.count {
                node = current.children[selectedIndex]
            } else if !current.children.isEmpty {
                node = current.children.first
            } else {
                node = nil
            }
        }
    }

    /// Applies a variation branch to the game
    public func applyVariationBranch(to _: inout Game) {}

    // MARK: - Debug Methods

    /// Prints debug information about the tree structure
    public func printDebugInfo() {
        print("\n======= 棋譜デバッグ情報 =======")
        print("\n----- メインライン -----")
        var mainLineMoves: [String] = []
        var currentNode = root
        while let selectedIndex = currentNode.selectedChildIndex, selectedIndex < currentNode.children.count {
            let next = currentNode.children[selectedIndex]
            mainLineMoves.append("\(next.moveNumber). \(next.kifMove)")
            currentNode = next
        }
        print(mainLineMoves.joined(separator: " -> "))

        print("\n----- 棋譜木構造 -----")
        printStructure(root, level: 0, isVariation: false)

        print("\n======= デバッグ情報終了 =======")
    }

    private func printStructure(_ node: KifNode, level: Int, isVariation: Bool) {
        let indent = String(repeating: "  ", count: level)

        if node === root {
            print("\(indent)◆ ルートノード")
        } else {
            let nodeType = isVariation ? "● 分岐" : "○ メイン"
            let parentInfo = node.parent != nil ?
                "(親: \(node.parent?.moveNumber ?? -1)手目 \(node.parent?.kifMove ?? "なし"))" : "(親: なし)"

            print("\(indent)\(nodeType) \(node.moveNumber)手目: \(node.kifMove) [USI: \(node.usiMove)] \(parentInfo)")
        }

        // For the main branch, follow the selected child
        if let selectedIndex = node.selectedChildIndex, selectedIndex < node.children.count, !isVariation {
            printStructure(node.children[selectedIndex], level: level, isVariation: false)

            // Print other children as variations
            for (index, child) in node.children.enumerated() {
                if index != selectedIndex {
                    print("\(indent)  └─ 分岐\(index + 1):")
                    printStructure(child, level: level + 2, isVariation: true)
                }
            }
        } else {
            // For variations, print all children
            for (index, child) in node.children.enumerated() {
                print("\(indent)  └─ 分岐\(index + 1):")
                printStructure(child, level: level + 2, isVariation: true)
            }
        }
    }
}

// MARK: - KIF Parser

/// Parser for KIF format notation
public class KifParser {
    // Storage for conversion
    private var lastToSquare: String?

    // Conversion maps
    public let fileMap: [String: String] = ["1": "１", "2": "２", "3": "３", "4": "４", "5": "５", "6": "６", "7": "７", "8": "８", "9": "９"]
    public let rankMap: [String: String] = ["a": "一", "b": "二", "c": "三", "d": "四", "e": "五", "f": "六", "g": "七", "h": "八", "i": "九"]
    public let pieceMap: [String: String] = [
        "p": "歩", "l": "香", "n": "桂", "s": "銀", "g": "金", "b": "角", "r": "飛", "k": "玉",
        "+p": "と", "+l": "成香", "+n": "成桂", "+s": "成銀", "+b": "馬", "+r": "龍",
        "P": "歩", "L": "香", "N": "桂", "S": "銀", "G": "金", "B": "角", "R": "飛", "K": "玉",
        "+P": "と", "+L": "成香", "+N": "成桂", "+S": "成銀", "+B": "馬", "+R": "龍",
    ]

    // MARK: - Section Types

    /// Structure to represent a section in the KIF file
    public struct KifSection {
        public let type: SectionType
        public let branchMoveNumber: Int
        public let moves: [(moveNumber: Int, kifMove: String)]

        public enum SectionType {
            case mainLine
            case variation
        }
    }

    /// Structure to hold branch information
    public struct BranchInfo {
        public let branchMoveNumber: Int
        public let parentSectionIndex: Int
        public let sectionIndex: Int
    }

    // MARK: - Format Detection

    /// Checks if the provided string is in KIF format
    public func isKIFFormat(_ kifu: String) -> Bool {
        // Check if the text contains the typical KIF header line
        if kifu.contains("手数----指手---------消費時間--") {
            return true
        }

        // Alternatively, check if the first non-empty line starts with a number (move number)
        let lines = kifu.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let firstNonEmpty = lines.first(where: { !$0.isEmpty }) {
            let regex = try! NSRegularExpression(pattern: "^[0-9]+\\s")
            if regex.firstMatch(in: firstNonEmpty, range: NSRange(firstNonEmpty.startIndex..., in: firstNonEmpty)) != nil {
                return true
            }
        }
        return false
    }

    // MARK: - Parsing

    /// Parse KIF format notation into a tree structure
    public func parseKif(kifString: String) -> KifTree {
        let lines = kifString.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        let kifTree = KifTree()

        // Extract all sections (main line and variations) from the KIF file
        let sections = extractSections(from: lines)

        // Analyze the branch structure to determine parent-child relationships
        let branchInfos = analyzeBranchStructure(sections: sections)

        // Build the main line of the game
        if let mainSection = sections.first(where: { $0.type == .mainLine }) {
            buildMainLine(section: mainSection, kifTree: kifTree)
        }

        // Build the variation tree structure using the branch information
        buildVariations(sections: sections, branchInfos: branchInfos, kifTree: kifTree)

        return kifTree
    }

    // MARK: - Section Processing

    /// Extract all sections (main line and variations) from the KIF file
    private func extractSections(from lines: [String]) -> [KifSection] {
        var sections: [KifSection] = []
        var currentIndex = 0

        // Skip header lines until the move header line
        while currentIndex < lines.count, !lines[currentIndex].contains("手数----指手") {
            currentIndex += 1
        }
        currentIndex += 1 // Skip the header line itself

        // Determine the range of the main line
        let mainLineStartIndex = currentIndex
        var mainLineEndIndex = currentIndex
        while mainLineEndIndex < lines.count, !lines[mainLineEndIndex].hasPrefix("変化：") {
            mainLineEndIndex += 1
        }

        // Create the main line section
        let mainLineMoves = lines[mainLineStartIndex ..< mainLineEndIndex].compactMap { extractMoveInfo(from: $0) }
        sections.append(KifSection(type: .mainLine, branchMoveNumber: 0, moves: mainLineMoves))

        // Extract variation sections
        currentIndex = mainLineEndIndex
        while currentIndex < lines.count {
            if lines[currentIndex].hasPrefix("変化：") {
                let branchMoveStr = lines[currentIndex].replacingOccurrences(of: "変化：", with: "")
                    .replacingOccurrences(of: "手", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if let branchMoveNumber = Int(branchMoveStr) {
                    let variationStartIndex = currentIndex + 1
                    var variationEndIndex = variationStartIndex

                    // Find the end of this variation (next variation or end of file)
                    while variationEndIndex < lines.count && !lines[variationEndIndex].hasPrefix("変化：") {
                        variationEndIndex += 1
                    }

                    // Extract moves in this variation
                    let variationMoves = lines[variationStartIndex ..< variationEndIndex].compactMap { extractMoveInfo(from: $0) }
                    sections.append(KifSection(type: .variation, branchMoveNumber: branchMoveNumber, moves: variationMoves))

                    currentIndex = variationEndIndex
                } else {
                    // Invalid variation format, skip this line
                    currentIndex += 1
                }
            } else {
                // Not a relevant section header, skip this line
                currentIndex += 1
            }
        }

        return sections
    }

    /// Analyze the branch structure to determine parent-child relationships
    private func analyzeBranchStructure(sections: [KifSection]) -> [BranchInfo] {
        var branchInfos: [BranchInfo] = []

        // Index of the main line (usually 0)
        let mainLineIndex = sections.firstIndex { $0.type == .mainLine } ?? 0

        // Sort variation sections by branch move number (ascending)
        let sortedSectionIndices = sections.enumerated()
            .filter { $0.element.type == .variation }
            .sorted { $0.element.branchMoveNumber < $1.element.branchMoveNumber }
            .map { $0.offset }

        // Dictionary to track move numbers in each section
        var sectionMoveRanges: [Int: Set<Int>] = [:]

        // Initialize move numbers for the main line
        if let mainSection = sections.first(where: { $0.type == .mainLine }) {
            let moveNumbers = Set(mainSection.moves.map { $0.moveNumber })
            sectionMoveRanges[mainLineIndex] = moveNumbers
        }

        // For each variation section, determine its parent
        for sectionIndex in sortedSectionIndices {
            let section = sections[sectionIndex]
            let branchMoveNumber = section.branchMoveNumber

            // Record move numbers in this variation
            let sectionMoves = Set(section.moves.map { $0.moveNumber })
            sectionMoveRanges[sectionIndex] = sectionMoves

            // Default parent is the main line
            var parentSectionIndex = mainLineIndex

            // Find the section that contains the branch move number
            for candidateIndex in [mainLineIndex] + sortedSectionIndices {
                // Skip self or sections processed later (with higher branch move numbers)
                if candidateIndex == sectionIndex ||
                    (candidateIndex != mainLineIndex &&
                        sections[candidateIndex].branchMoveNumber >= branchMoveNumber)
                {
                    continue
                }

                // Check if this candidate section contains the branch move number
                if let candidateMoves = sectionMoveRanges[candidateIndex],
                   candidateMoves.contains(branchMoveNumber)
                {
                    // Choose the deepest section (highest branch move number) as parent
                    if sections[candidateIndex].branchMoveNumber > sections[parentSectionIndex].branchMoveNumber {
                        parentSectionIndex = candidateIndex
                    }
                }
            }

            // Add branch information
            branchInfos.append(BranchInfo(
                branchMoveNumber: branchMoveNumber,
                parentSectionIndex: parentSectionIndex,
                sectionIndex: sectionIndex
            ))
        }

        return branchInfos
    }

    // MARK: - Tree Building

    /// Build the main line of the game
    private func buildMainLine(section: KifSection, kifTree: KifTree) {
        var currentNode = kifTree.root

        for move in section.moves {
            let usiMove = kifToUSI(move.kifMove)
            let newNode = KifNode(
                moveNumber: move.moveNumber,
                kifMove: move.kifMove,
                usiMove: usiMove,
                parent: currentNode
            )

            currentNode.children.append(newNode)
            currentNode.selectedChildIndex = 0
            currentNode = newNode
        }
    }

    /// Build the variation tree structure
    private func buildVariations(sections: [KifSection], branchInfos: [BranchInfo], kifTree: KifTree) {
        // Map to track all nodes in each section (for parent-child relationship tracking)
        var sectionNodesMap: [Int: [KifNode]] = [:]

        // Process variations in order (from shallow to deep branches)
        for branchInfo in branchInfos {
            let sectionIndex = branchInfo.sectionIndex
            let section = sections[sectionIndex]
            let parentSectionIndex = branchInfo.parentSectionIndex
            let branchMoveNumber = branchInfo.branchMoveNumber

            // Get the first move of this variation
            guard !section.moves.isEmpty else { continue }
            let firstMove = section.moves.first!

            // Find the parent node for this branch point
            var branchParentNode: KifNode?

            if parentSectionIndex == 0 {
                // If branching from the main line
                branchParentNode = findNodeByMoveNumber(branchMoveNumber - 1, startingFrom: kifTree.root)
            } else {
                // If branching from another variation
                if let parentNodes = sectionNodesMap[parentSectionIndex] {
                    // First try to find the exact node with the right move number
                    branchParentNode = parentNodes.first { node in
                        node.moveNumber == branchMoveNumber - 1
                    }

                    // If not found, search from the first node of the parent section
                    if branchParentNode == nil, let startNode = parentNodes.first {
                        branchParentNode = findNodeByMoveNumber(branchMoveNumber - 1, startingFrom: startNode)
                    }
                }
            }

            // Skip if the parent node is not found
            guard let parentNode = branchParentNode else { continue }

            // Create the first node of the variation
            let usiMove = kifToUSI(firstMove.kifMove)
            let variationNode = KifNode(
                moveNumber: firstMove.moveNumber,
                kifMove: firstMove.kifMove,
                usiMove: usiMove,
                parent: parentNode
            )

            // Add to parent's variations list
            parentNode.children.append(variationNode)

            // Record this node in the section's nodes map
            if sectionNodesMap[sectionIndex] == nil {
                sectionNodesMap[sectionIndex] = [variationNode]
            } else {
                sectionNodesMap[sectionIndex]!.append(variationNode)
            }

            // Add the remaining moves in the variation
            var currentNode = variationNode
            for i in 1 ..< section.moves.count {
                let move = section.moves[i]
                let usiMove = kifToUSI(move.kifMove)
                let newNode = KifNode(
                    moveNumber: move.moveNumber,
                    kifMove: move.kifMove,
                    usiMove: usiMove,
                    parent: currentNode
                )

                currentNode.children.append(newNode)
                currentNode.selectedChildIndex = 0
                currentNode = newNode

                // Record each node in the section's nodes map
                sectionNodesMap[sectionIndex]!.append(newNode)
            }
        }
    }

    /// Find a node with a specific move number starting from a given node
    private func findNodeByMoveNumber(_ moveNumber: Int, startingFrom startNode: KifNode) -> KifNode? {
        // Special case: looking for the root node (move 0)
        if moveNumber == 0 {
            return startNode
        }

        // If the start node's move number is already >= the target, backtrack to find it
        if startNode.moveNumber >= moveNumber {
            var current: KifNode? = startNode
            while let node = current, node.moveNumber > moveNumber {
                current = node.parent
            }
            if let node = current, node.moveNumber == moveNumber {
                return node
            }
        }

        // Breadth-first search to find the node
        var queue: [KifNode] = [startNode]
        var visited: Set<ObjectIdentifier> = []

        while !queue.isEmpty {
            let node = queue.removeFirst()
            let nodeId = ObjectIdentifier(node)

            // Skip already visited nodes
            if visited.contains(nodeId) {
                continue
            }
            visited.insert(nodeId)

            // Node found
            if node.moveNumber == moveNumber {
                return node
            }

            // Add children to queue (only if their move numbers are <= target)
            for child in node.children where child.moveNumber <= moveNumber {
                queue.append(child)
            }
        }

        // Second pass: search all nodes from the start node (without move number filtering)
        queue = [startNode]
        visited.removeAll()

        while !queue.isEmpty {
            let node = queue.removeFirst()
            let nodeId = ObjectIdentifier(node)

            if visited.contains(nodeId) {
                continue
            }
            visited.insert(nodeId)

            if node.moveNumber == moveNumber {
                return node
            }

            for child in node.children {
                queue.append(child)
            }
        }

        // Node not found
        return nil
    }

    /// Extract move information from a line in the KIF file
    private func extractMoveInfo(from line: String) -> (moveNumber: Int, kifMove: String)? {
        let pattern = #"^\s*(\d+)\s+(.+?)(?:\s+\(.+\))?\s*\+?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let nsLine = line as NSString
        guard let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) else {
            return nil
        }

        let moveNumberRange = match.range(at: 1)
        let kifMoveRange = match.range(at: 2)

        guard moveNumberRange.location != NSNotFound, kifMoveRange.location != NSNotFound else {
            return nil
        }

        let moveNumberStr = nsLine.substring(with: moveNumberRange)
        let kifMove = nsLine.substring(with: kifMoveRange)

        guard let moveNumber = Int(moveNumberStr) else { return nil }

        return (moveNumber, kifMove)
    }

    // MARK: - Notation Conversion

    /// Convert KIF move notation to USI format
    public func kifToUSI(_ kifMove: String) -> String {
        // Maps KIF file (Kanji digit) to USI file (1-9)
        let kifToFile: [String: String] = [
            "１": "1", "２": "2", "３": "3", "４": "4", "５": "5",
            "６": "6", "７": "7", "８": "8", "９": "9",
        ]

        // Maps KIF rank (Kanji) to USI rank (a-i)
        let kifToRank: [String: String] = [
            "一": "a", "二": "b", "三": "c", "四": "d", "五": "e",
            "六": "f", "七": "g", "八": "h", "九": "i",
        ]

        // For dropping pieces (cannot drop promoted pieces)
        let pieceToUSI: [String: String] = [
            "歩": "P", "香": "L", "桂": "N", "銀": "S", "金": "G",
            "角": "B", "飛": "R", "玉": "K",
        ]

        // Trim spaces
        let trimmedMove = kifMove.trimmingCharacters(in: .whitespacesAndNewlines)

        // Resignation check
        if trimmedMove == "投了" {
            return "resign"
        }

        // --- 1) "同" pattern ---
        // e.g. "同　歩(44)", "同　銀成(54)", "同　馬(66)", "同　角成(88)"
        let samePattern = #"^同\s?(馬|龍|と|成桂|成香|成銀|歩|香|桂|銀|金|角|飛|玉)?(?:成)?\((\d{2})\)"#
        if let match = try? NSRegularExpression(pattern: samePattern)
            .firstMatch(in: trimmedMove, range: NSRange(trimmedMove.startIndex..., in: trimmedMove)),
            match.numberOfRanges == 3
        {
            let nsStr = trimmedMove as NSString
            // Captured piece name (could be "", "歩", "馬", "成桂", etc.)
            let pieceName = match.range(at: 1).location != NSNotFound
                ? nsStr.substring(with: match.range(at: 1))
                : ""
            let fromDigits = nsStr.substring(with: match.range(at: 2))

            guard fromDigits.count == 2,
                  let fromFileInt = Int(String(fromDigits.prefix(1))),
                  let fromRankInt = Int(String(fromDigits.suffix(1))),
                  let lastToSquare = lastToSquare
            else {
                return ""
            }

            // USI from-square
            let usiFrom = "\(fromFileInt)\(Character(UnicodeScalar(96 + fromRankInt)!))"

            // Check if it's newly promoted or already promoted
            var isPromotion = false

            // List of pieces that indicate "already promoted" => no "+"
            let alreadyPromotedList = ["成桂", "成銀", "成香", "馬", "龍", "と"]

            if alreadyPromotedList.contains(pieceName) {
                // e.g. "同　成桂(33)", "同　馬(66)" => no "+"
                isPromotion = false
            } else {
                // If the string contains something like "角成(", "歩成(", etc., treat as new promotion
                if trimmedMove.contains("成(") {
                    isPromotion = true
                }
            }

            // Build the USI move
            let usiMove = isPromotion
                ? (usiFrom + lastToSquare + "+")
                : (usiFrom + lastToSquare)

            // "same" uses lastToSquare as destination
            self.lastToSquare = lastToSquare
            return usiMove
        }

        // --- 2) Drop pattern ---
        // e.g. "８八角打", "３三歩打"
        let dropPattern = #"([１-９])([一二三四五六七八九])([歩香桂銀金角飛玉])打"#
        if let match = try? NSRegularExpression(pattern: dropPattern)
            .firstMatch(in: trimmedMove, range: NSRange(trimmedMove.startIndex..., in: trimmedMove)),
            match.numberOfRanges == 4
        {
            let nsStr = trimmedMove as NSString
            let fileK = nsStr.substring(with: match.range(at: 1))
            let rankK = nsStr.substring(with: match.range(at: 2))
            let pieceK = nsStr.substring(with: match.range(at: 3))

            guard let usiFile = kifToFile[fileK],
                  let usiRank = kifToRank[rankK],
                  let usiPiece = pieceToUSI[pieceK]
            else {
                return ""
            }
            let usiTo = "\(usiFile)\(usiRank)"
            let usiMove = "\(usiPiece)*\(usiTo)"
            lastToSquare = usiTo
            return usiMove
        }

        // --- 3) Newly promoted pattern ---
        // e.g. "４五歩成(46)", "３三角成(22)"
        let promotePattern = #"([１-９])([一二三四五六七八九])(?:歩|香|桂|銀|金|角|飛|玉)?成\((\d)(\d)\)"#
        if let match = try? NSRegularExpression(pattern: promotePattern)
            .firstMatch(in: trimmedMove, range: NSRange(trimmedMove.startIndex..., in: trimmedMove)),
            match.numberOfRanges == 5
        {
            let nsStr = trimmedMove as NSString
            let toFileK = nsStr.substring(with: match.range(at: 1))
            let toRankK = nsStr.substring(with: match.range(at: 2))
            let fromFile = nsStr.substring(with: match.range(at: 3))
            let fromRank = nsStr.substring(with: match.range(at: 4))

            guard let usiToFile = kifToFile[toFileK],
                  let usiToRank = kifToRank[toRankK],
                  let fFileInt = Int(fromFile),
                  let fRankInt = Int(fromRank)
            else {
                return ""
            }

            let usiFrom = "\(fFileInt)\(Character(UnicodeScalar(96 + fRankInt)!))"
            let usiTo = "\(usiToFile)\(usiToRank)"

            // Append "+"
            let usiMove = usiFrom + usiTo + "+"
            lastToSquare = usiTo
            return usiMove
        }

        // --- 4) Normal pattern (including already-promoted piece) ---
        // e.g. "７六歩(77)", "８九馬(99)", "４二成桂(33)", "３三と(22)"
        let normalPattern =
            #"^([１-９])([一二三四五六七八九])(馬|龍|と|成桂|成銀|成香|歩|香|桂|銀|金|角|飛|玉)?\((\d)(\d)\)"#

        if let match = try? NSRegularExpression(pattern: normalPattern)
            .firstMatch(in: trimmedMove, range: NSRange(trimmedMove.startIndex..., in: trimmedMove)),
            match.numberOfRanges == 6
        {
            let nsStr = trimmedMove as NSString
            let toFileK = nsStr.substring(with: match.range(at: 1))
            let toRankK = nsStr.substring(with: match.range(at: 2))
            let fromFile = nsStr.substring(with: match.range(at: 4))
            let fromRank = nsStr.substring(with: match.range(at: 5))

            guard let usiToFile = kifToFile[toFileK],
                  let usiToRank = kifToRank[toRankK],
                  let fFileInt = Int(fromFile),
                  let fRankInt = Int(fromRank)
            else {
                return ""
            }

            // Normal piece move (no new promotion)
            let usiFrom = "\(fFileInt)\(Character(UnicodeScalar(96 + fRankInt)!))"
            let usiTo = "\(usiToFile)\(usiToRank)"
            let usiMove = usiFrom + usiTo

            lastToSquare = usiTo
            return usiMove
        }

        // If no pattern matches, return empty
        return ""
    }

    /// Convert USI move to KIF notation
    public func usiToKIF(usiMove: String, turn: Color, board: Board) -> String {
        let color = turn == .black ? "☗" : "☖"

        guard usiMove.count >= 4 else { return "" }

        if usiMove == "resign" {
            return "投了"
        }

        // Handle drop moves
        if usiMove.contains("*") {
            let components = usiMove.split(separator: "*")
            guard components.count == 2,
                  let pieceType = pieceMap[String(components[0])],
                  let destFile = fileMap[String(components[1].prefix(1))],
                  let destRank = rankMap[String(components[1].suffix(1))]
            else {
                return ""
            }
            return "\(color)\(destFile)\(destRank)\(pieceType)打"
        }

        // Handle board piece move
        guard let srcFile = File(rawValue: 9 - Int(String(usiMove.prefix(1)))!),
              let srcRank = Rank(rawValue: Int(Character(String(usiMove[usiMove.index(usiMove.startIndex, offsetBy: 1)])).asciiValue! - 97)),
              let destFile = fileMap[String(usiMove[usiMove.index(usiMove.startIndex, offsetBy: 2)])],
              let destRank = rankMap[String(usiMove[usiMove.index(usiMove.startIndex, offsetBy: 3)])]
        else {
            return ""
        }

        let srcSquare = Square(file: srcFile, rank: srcRank)
        let srcSquareStr = "\(srcSquare.file.kifString)\(srcSquare.rank.numString)"
        guard let piece = board[srcSquare] else { return "" }
        let pieceString = pieceMap[piece.sfenString] ?? ""

        return "\(color)\(destFile)\(destRank)\(pieceString)\(usiMove.hasSuffix("+") ? "成" : "")(\(srcSquareStr))"
    }
}
