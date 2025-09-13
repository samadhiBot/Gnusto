import SwiftParser

struct Scanner {
    private let source: String

    init(source: String) {
        self.source = source
    }

    /// Parses a single Swift source string and extracts game data patterns.
    func process() -> GameData {
        let gameCollector = GameDataCollector()
        gameCollector.collect(from: source)
        return gameCollector.gameData
    }
}
