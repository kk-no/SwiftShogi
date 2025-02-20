public enum File: Int, CaseIterable {
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
}

public extension File {
    // The internal board and the actual board are reversed.
    var kifString: String {
        switch self {
        case .one: return "9"
        case .two: return "8"
        case .three: return "7"
        case .four: return "6"
        case .five: return "5"
        case .six: return "4"
        case .seven: return "3"
        case .eight: return "2"
        case .nine: return "1"
        }
    }

    var kifStringWide: String {
        switch self {
        case .one: return "９"
        case .two: return "８"
        case .three: return "７"
        case .four: return "６"
        case .five: return "５"
        case .six: return "４"
        case .seven: return "３"
        case .eight: return "２"
        case .nine: return "１"
        }
    }
}

public enum Rank: Int, CaseIterable {
    case a
    case b
    case c
    case d
    case e
    case f
    case g
    case h
    case i
}

public extension Rank {
    var numString: String {
        switch self {
        case .a: return "1"
        case .b: return "2"
        case .c: return "3"
        case .d: return "4"
        case .e: return "5"
        case .f: return "6"
        case .g: return "7"
        case .h: return "8"
        case .i: return "9"
        }
    }

    var kifString: String {
        switch self {
        case .a: return "一"
        case .b: return "二"
        case .c: return "三"
        case .d: return "四"
        case .e: return "五"
        case .f: return "六"
        case .g: return "七"
        case .h: return "八"
        case .i: return "九"
        }
    }
}

public enum Square: Int, CaseIterable {
    case oneA, oneB, oneC, oneD, oneE, oneF, oneG, oneH, oneI
    case twoA, twoB, twoC, twoD, twoE, twoF, twoG, twoH, twoI
    case threeA, threeB, threeC, threeD, threeE, threeF, threeG, threeH, threeI
    case fourA, fourB, fourC, fourD, fourE, fourF, fourG, fourH, fourI
    case fiveA, fiveB, fiveC, fiveD, fiveE, fiveF, fiveG, fiveH, fiveI
    case sixA, sixB, sixC, sixD, sixE, sixF, sixG, sixH, sixI
    case sevenA, sevenB, sevenC, sevenD, sevenE, sevenF, sevenG, sevenH, sevenI
    case eightA, eightB, eightC, eightD, eightE, eightF, eightG, eightH, eightI
    case nineA, nineB, nineC, nineD, nineE, nineF, nineG, nineH, nineI
}

public extension Square {
    init(file: File, rank: Rank) {
        self = Self.allCases.first { $0.file == file && $0.rank == rank }!
    }

    init?(usiFile: String, usiRank: String) {
        guard let rankChar = usiRank.first,
              let rankAscii = rankChar.asciiValue,
              let rank = Rank(rawValue: Int(rankAscii - 97))
        else {
            return nil
        }

        guard let fileNumber = Int(usiFile),
              let fileEnum = File(rawValue: 9 - fileNumber)
        else {
            return nil
        }

        self.init(file: fileEnum, rank: rank)
    }

    init?(usiString: String) {
        guard usiString.count == 2 else { return nil }

        let file = String(usiString.prefix(1))
        let rank = String(usiString.suffix(1))

        self.init(usiFile: file, usiRank: rank)
    }

    var file: File { File(rawValue: rawValue / File.allCases.count)! }
    var rank: Rank { Rank(rawValue: rawValue % Rank.allCases.count)! }
    var usiString: String {
        let fileString = "\(9 - file.rawValue)"
        let rankString = "\(Character(UnicodeScalar(rank.rawValue + 97)!))"
        return fileString + rankString
    }

    static func cases(at file: File) -> [Self] { allCases.filter { $0.file == file } }
    static func cases(at rank: Rank) -> [Self] { allCases.filter { $0.rank == rank } }

    static func promotableCases(for color: Color) -> [Self] {
        let ranks: [Rank] = color.isBlack ? [.a, .b, .c] : [.g, .h, .i]
        return allCases.filter { ranks.contains($0.rank) }
    }
}
