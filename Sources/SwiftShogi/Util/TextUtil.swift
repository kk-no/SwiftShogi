import Foundation

/// 文字列から数値を変換するマッピング
private let stringToNumberMap: [String: Int] = [
    "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9,
    "１": 1, "２": 2, "３": 3, "４": 4, "５": 5, "６": 6, "７": 7, "８": 8, "９": 9,
    "一": 1, "二": 2, "三": 3, "四": 4, "五": 5, "六": 6, "七": 7, "八": 8, "九": 9,
    "十": 10, "十一": 11, "十二": 12, "十三": 13, "十四": 14, "十五": 15, "十六": 16, "十七": 17, "十八": 18,
]

/// 漢字から駒の種類を変換するマッピング
private let stringToPieceTypeMap: [String: PieceType] = [
    "王": .king, "玉": .king,
    "飛": .rook, "龍": .dragon, "竜": .dragon,
    "角": .bishop, "馬": .horse,
    "金": .gold,
    "銀": .silver, "成銀": .promSilver, "全": .promSilver,
    "桂": .knight, "成桂": .promKnight, "圭": .promKnight,
    "香": .lance, "成香": .promLance, "杏": .promLance,
    "歩": .pawn, "と": .promPawn,
]

/// 移動用の駒の文字列表現マッピング
private let pieceTypeToStringForMoveMap: [PieceType: String] = [
    .king: "玉", .rook: "飛", .dragon: "龍", .bishop: "角", .horse: "馬",
    .gold: "金", .silver: "銀", .promSilver: "成銀", .knight: "桂", .promKnight: "成桂",
    .lance: "香", .promLance: "成香", .pawn: "歩", .promPawn: "と",
]

/// 盤面表示用の駒の文字列表現マッピング
private let pieceTypeToStringForBoardMap: [PieceType: String] = [
    .king: "玉", .rook: "飛", .dragon: "龍", .bishop: "角", .horse: "馬",
    .gold: "金", .silver: "銀", .promSilver: "全", .knight: "桂", .promKnight: "圭",
    .lance: "香", .promLance: "杏", .pawn: "歩", .promPawn: "と",
]

/// 漢数字の配列（1-18）
private let kanjiNumberStrings = [
    "一", "二", "三", "四", "五", "六", "七", "八", "九",
    "十", "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八",
]

/// 全角数字の配列（1-9）
private let fileStrings = ["１", "２", "３", "４", "５", "６", "７", "８", "９"]

/// テキスト変換ユーティリティ
public enum TextUtil {
    /// 文字列を数値に変換します
    /// - Parameter s: 変換する文字列
    /// - Returns: 対応する数値（変換できない場合はnil）
    public static func stringToNumber(_ s: String) -> Int? {
        return stringToNumberMap[s]
    }

    /// 漢字を駒の種類に変換します
    /// - Parameter piece: 駒を表す漢字
    /// - Returns: 対応する駒の種類（変換できない場合はnil）
    public static func stringToPieceType(_ piece: String) -> PieceType? {
        return stringToPieceTypeMap[piece]
    }

    /// 数値を漢数字に変換します
    /// - Parameter n: 変換する数値（1-18）
    /// - Returns: 対応する漢数字
    public static func numberToKanji(_ n: Int) -> String {
        guard n >= 1 && n <= 18 else { return "" }
        return kanjiNumberStrings[n - 1]
    }

    /// 筋を全角数字に変換します
    /// - Parameter file: 筋（1-9）
    /// - Returns: 対応する全角数字
    public static func fileToMultiByteChar(_ file: Int) -> String {
        guard file >= 1 && file <= 9 else { return "" }
        return fileStrings[file - 1]
    }

    /// 段を漢数字に変換します
    /// - Parameter rank: 段（1-9）
    /// - Returns: 対応する漢数字
    public static func rankToKanji(_ rank: Int) -> String {
        guard rank >= 1 && rank <= 9 else { return "" }
        return kanjiNumberStrings[rank - 1]
    }

    /// 駒の種類を指し手用の文字列に変換します
    /// - Parameter pieceType: 駒の種類
    /// - Returns: 対応する文字列
    public static func pieceTypeToStringForMove(_ pieceType: PieceType) -> String {
        return pieceTypeToStringForMoveMap[pieceType] ?? ""
    }

    /// 駒の種類を盤面表示用の文字列に変換します
    /// - Parameter pieceType: 駒の種類
    /// - Returns: 対応する文字列
    public static func pieceTypeToStringForBoard(_ pieceType: PieceType) -> String {
        return pieceTypeToStringForBoardMap[pieceType] ?? ""
    }

    /// 特殊な指し手の表示用の文字列を返します
    /// - Parameter specialMoveType: 特殊な指し手の種類
    /// - Returns: 対応する文字列
    public static func formatSpecialMove(_ specialMoveType: String) -> String {
        switch specialMoveType {
        case "start": return "開始局面"
        case "resign": return "投了"
        case "interrupt": return "中断"
        case "maxMoves": return "最大手数"
        case "impass": return "持将棋"
        case "draw": return "引き分け"
        case "repetitionDraw": return "千日手"
        case "mate": return "詰み"
        case "noMate": return "不詰"
        case "timeout": return "切れ負け"
        case "foulWin": return "反則勝ち"
        case "foulLose": return "反則負け"
        case "enteringOfKing": return "入玉"
        case "winByDefault": return "不戦勝"
        case "loseByDefault": return "不戦敗"
        case "try": return "トライ"
        default: return specialMoveType
        }
    }
}
