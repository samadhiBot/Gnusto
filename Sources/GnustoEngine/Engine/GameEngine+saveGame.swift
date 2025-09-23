import Foundation

extension GameEngine {
    /// Saves the current game state.
    ///
    /// Serializes the current game state to a JSON file in the user's saves directory.
    /// If no save name is provided, uses "quicksave" as the default name.
    ///
    /// - Parameter saveName: Optional name for the save file. Defaults to "quicksave".
    /// - Throws: FileManager or encoding errors if the save operation fails.
    public func saveGame(saveName: String = "quicksave") async throws -> URL {
        let saveData = try JSONEncoder.sorted().encode(gameState)
        let saveURL = try filesystemHandler.saveFileURL(game: abbreviatedTitle, filename: saveName)
        try saveData.write(to: saveURL, options: [.atomic])
        return saveURL
    }

    /// Restores a previously saved game state.
    ///
    /// Deserializes a game state from a JSON file in the user's saves directory and
    /// replaces the current game state. If no save name is provided, attempts to
    /// restore from "quicksave".
    ///
    /// - Parameter saveName: Optional name of the save file to restore. Defaults to "quicksave".
    /// - Throws: FileManager, decoding, or file not found errors if the restore operation fails.
    public func restoreGame(saveName: String = "quicksave") async throws {
        let saveURL = try filesystemHandler.saveFileURL(game: abbreviatedTitle, filename: saveName)

        guard FileManager.default.fileExists(atPath: saveURL.path) else {
            throw NSError(
                domain: "GnustoEngine",
                code: 2_001,
                userInfo: [NSLocalizedDescriptionKey: "Save file '\(saveName)' not found."]
            )
        }

        let saveData = try Data(contentsOf: saveURL)
        let restoredState = try JSONDecoder().decode(GameState.self, from: saveData)

        // Replace the current game state with the restored state
        gameState = restoredState
    }

    /// Lists all available save files.
    ///
    /// - Returns: An array of save file names (without the .gnusto extension).
    /// - Throws: FileManager errors if the saves directory cannot be accessed.
    public func listSaveFiles() async throws -> [String] {
        let saveDirectory = try filesystemHandler.gnustoDirectory(for: abbreviatedTitle)

        guard FileManager.default.fileExists(atPath: saveDirectory.path) else {
            return []  // No saves directory means no save files
        }

        let saveFiles = try FileManager.default.contentsOfDirectory(
            at: saveDirectory, includingPropertiesForKeys: nil)

        return
            saveFiles
            .filter { $0.pathExtension == "gnusto" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }

    /// Deletes a save file with the given name.
    ///
    /// - Parameter saveName: The name of the save file to delete (without extension).
    /// - Throws: FileManager errors if the file cannot be deleted or doesn't exist.
    public func deleteSaveFile(saveName: String) async throws {
        let saveURL = try filesystemHandler.saveFileURL(game: abbreviatedTitle, filename: saveName)

        guard FileManager.default.fileExists(atPath: saveURL.path) else {
            throw NSError(
                domain: "GnustoEngine",
                code: 2_001,
                userInfo: [NSLocalizedDescriptionKey: "Save file '\(saveName)' not found."]
            )
        }

        try FileManager.default.removeItem(at: saveURL)
    }
}
