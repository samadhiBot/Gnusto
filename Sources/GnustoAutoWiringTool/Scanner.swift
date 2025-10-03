import SwiftParser

struct Scanner {
    private let source: String
    private let fileName: String

    init(source: String, fileName: String) {
        self.source = source
        self.fileName = fileName
    }

    /// Parses a single Swift source string and extracts game data patterns.
    func process() -> GameData {
        let gameCollector = GameDataCollector()
        gameCollector.collect(from: source, fileName: fileName)
        return gameCollector.gameData
    }
}
