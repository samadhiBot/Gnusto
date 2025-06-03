import Foundation
import SwiftParser
import SwiftSyntax

struct Scanner {
    let source: String

    /// Parses a single Swift source string and extracts game data patterns.
    func process() -> GameData {
        let tree = Parser.parse(source: source)
        let gameCollector = GameDataCollector(viewMode: .sourceAccurate)
        gameCollector.walk(tree)
        return gameCollector.gameData
    }
}
