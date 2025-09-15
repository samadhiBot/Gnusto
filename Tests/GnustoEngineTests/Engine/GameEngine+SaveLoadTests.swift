import CustomDump
import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

struct GameEngineSaveLoadTests {

    // MARK: - Save Game Tests

    @Test("GameEngine saves game state to filesystem")
    func testSaveGame() async throws {
        // Given: A game engine with test filesystem handler and some game state changes
        let testHandler = TestFilesystemHandler()
        let (engine, _) = await GameEngine.test(filesystemHandler: testHandler)

        // Make some changes to the game state
        try await engine.execute("score")
        try await engine.apply(
            engine.player.updateScore(by: 10)
        )

        // When: Saving the game
        let testsaveURL = try await engine.saveGame(saveName: "testsave")

        // Then: Save file should exist in test directory
        #expect(FileManager.default.fileExists(atPath: testsaveURL.path()))

        // And: File should contain valid game state data
        let saveData = try Data(contentsOf: testsaveURL)
        let decodedState = try JSONDecoder().decode(GameState.self, from: saveData)
        #expect(decodedState.player.score == 10)
        #expect(testsaveURL.lastPathComponent == "testsave.gnusto")

        // Cleanup
        try testHandler.cleanup()
    }

    @Test("GameEngine saves game with default quicksave name")
    func testSaveGameDefaultName() async throws {
        // Given: A game engine with test filesystem handler
        let testHandler = TestFilesystemHandler()
        let (engine, _) = await GameEngine.test(filesystemHandler: testHandler)

        // When: Saving without specifying a name
        let quicksaveURL = try await engine.saveGame()

        // Then: Should create quicksave file
        #expect(FileManager.default.fileExists(atPath: quicksaveURL.path()))
        #expect(quicksaveURL.lastPathComponent == "quicksave.gnusto")

        // Cleanup
        try testHandler.cleanup()
    }

    @Test("GameEngine creates save directory if it doesn't exist")
    func testSaveGameCreatesDirectory() async throws {
        // Given: A game engine with test filesystem handler (directory doesn't exist yet)
        let testHandler = TestFilesystemHandler()
        let (engine, _) = await GameEngine.test(filesystemHandler: testHandler)

        // When: Saving the game (should create directory structure)
        let newsaveURL = try await engine.saveGame(saveName: "newsave")

        // Then: Save directory should be created
        let gameDir = try testHandler.gnustoDirectory(for: engine.abbreviatedTitle)
        #expect(FileManager.default.fileExists(atPath: gameDir.path()))

        // And: Save file should exist
        #expect(FileManager.default.fileExists(atPath: newsaveURL.path()))

        // Cleanup
        try testHandler.cleanup()
    }

    // MARK: - Restore Game Tests

    @Test("GameEngine restores game state from filesystem")
    func testRestoreGame() async throws {
        // Given: A game engine and a saved game with modified state
        let foyer = Location(
            id: "foyer",
            .name("Foyer of the Opera House"),
            .inherentlyLit
        )
        let westOfHouse = Location(
            id: "westOfHouse",
            .name("West of House"),
            .inherentlyLit
        )
        let game = MinimalGame(
            locations: foyer, westOfHouse
        )
        let testHandler = TestFilesystemHandler()
        let (engine, _) = await GameEngine.test(
            blueprint: game,
            filesystemHandler: testHandler
        )

        // Modify state and save
        try await engine.apply(
            engine.player.updateScore(by: 25)
        )
        try await engine.apply(engine.player.move(to: "foyer"))
        let _ = try await engine.saveGame(saveName: "testrestore")

        // Reset state to verify restoration
        try await engine.apply(
            engine.player.updateScore(by: -25)
        )  // Reset to 0
        try await engine.apply(engine.player.move(to: "westOfHouse"))

        // When: Restoring the game
        try await engine.restoreGame(saveName: "testrestore")

        // Then: State should be restored to saved values
        let currentScore = await engine.player.score
        let currentLocation = try await engine.player.location.id
        #expect(currentScore == 25)
        #expect(currentLocation == "foyer")

        // Cleanup
        try testHandler.cleanup()
    }

    @Test("GameEngine restores from default quicksave")
    func testRestoreGameDefaultName() async throws {
        // Given: A game engine with a quicksave file
        let testHandler = TestFilesystemHandler()
        let (engine, _) = await GameEngine.test(filesystemHandler: testHandler)

        try await engine.apply(
            engine.player.updateScore(by: 15)
        )
        let quicksaveURL = try await engine.saveGame()  // Uses default "quicksave" name

        #expect(quicksaveURL.lastPathComponent == "quicksave.gnusto")

        // Reset state
        try await engine.apply(
            engine.player.updateScore(by: -15)
        )  // Reset to 0

        // When: Restoring without specifying name
        try await engine.restoreGame()

        // Then: Should restore from quicksave
        let currentScore = await engine.player.score
        #expect(currentScore == 15)

        // Cleanup
        try testHandler.cleanup()
    }

    @Test("GameEngine throws error when restoring non-existent save")
    func testRestoreNonExistentSave() async throws {
        // Given: A game engine with test filesystem handler
        let testHandler = TestFilesystemHandler()
        let (engine, _) = await GameEngine.test(filesystemHandler: testHandler)

        // When/Then: Attempting to restore non-existent save should throw
        await #expect(throws: NSError.self) {
            try await engine.restoreGame(saveName: "nonexistent")
        }

        // Cleanup
        try testHandler.cleanup()
    }

    // MARK: - List Save Files Tests

    @Test("GameEngine lists existing save files")
    func testListSaveFiles() async throws {
        // Given: A game engine with multiple save files
        let testHandler = TestFilesystemHandler()
        let (engine, _) = await GameEngine.test(filesystemHandler: testHandler)

        // Create multiple saves
        let save1URL = try await engine.saveGame(saveName: "save1")
        let save2URL = try await engine.saveGame(saveName: "save2")
        let quicksaveURL = try await engine.saveGame(saveName: "quicksave")

        #expect(save1URL.lastPathComponent == "save1.gnusto")
        #expect(save2URL.lastPathComponent == "save2.gnusto")
        #expect(quicksaveURL.lastPathComponent == "quicksave.gnusto")

        // When: Listing save files
        let saveFiles = try await engine.listSaveFiles()

        // Then: Should include all save files (without extensions)
        #expect(saveFiles.count == 3)
        #expect(saveFiles.contains("save1"))
        #expect(saveFiles.contains("save2"))
        #expect(saveFiles.contains("quicksave"))

        // Cleanup
        try testHandler.cleanup()
    }

    @Test("GameEngine returns empty list when no saves exist")
    func testListSaveFilesEmpty() async throws {
        // Given: A game engine with no save files
        let testHandler = TestFilesystemHandler()
        let (engine, _) = await GameEngine.test(filesystemHandler: testHandler)

        // When: Listing save files
        let saveFiles = try await engine.listSaveFiles()

        // Then: Should return empty array
        #expect(saveFiles.isEmpty)

        // Cleanup
        try testHandler.cleanup()
    }

    // MARK: - Delete Save Files Tests

    @Test("GameEngine deletes existing save files")
    func testDeleteSaveFile() async throws {
        // Given: A game engine with a save file
        let testHandler = TestFilesystemHandler()
        let (engine, _) = await GameEngine.test(filesystemHandler: testHandler)

        let todeleteURL = try await engine.saveGame(saveName: "todelete")

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: todeleteURL.path()))

        // When: Deleting the save file
        try await engine.deleteSaveFile(saveName: "todelete")

        // Then: File should no longer exist
        #expect(!FileManager.default.fileExists(atPath: todeleteURL.path()))

        // And: Should not be in list of save files
        let remainingSaves = try await engine.listSaveFiles()
        #expect(!remainingSaves.contains("todelete"))

        // Cleanup
        try testHandler.cleanup()
    }

    @Test("GameEngine throws error when deleting non-existent save")
    func testDeleteNonExistentSave() async throws {
        // Given: A game engine with test filesystem handler
        let testHandler = TestFilesystemHandler()
        let (engine, _) = await GameEngine.test(filesystemHandler: testHandler)

        // When/Then: Attempting to delete non-existent save should throw
        await #expect(throws: NSError.self) {
            try await engine.deleteSaveFile(saveName: "nonexistent")
        }

        // Cleanup
        try testHandler.cleanup()
    }

    // MARK: - Transcript Tests

    @Test("GameEngine creates transcript files using filesystem handler")
    func testTranscriptCreation() async throws {
        // Given: A game engine with test filesystem handler
        let testHandler = TestFilesystemHandler()
        let (engine, _) = await GameEngine.test(filesystemHandler: testHandler)

        // When: Starting a transcript
        try await engine.startTranscript()
        let transcriptURL = try await engine.transcriptURL

        // Then: Transcript file should be created in test directory
        #expect(FileManager.default.fileExists(atPath: transcriptURL.path()))
        #expect(transcriptURL.pathExtension == "md")
        #expect(transcriptURL.lastPathComponent.hasPrefix("transcript-"))

        // And: Should be in the game directory
        let gameDir = try testHandler.gnustoDirectory(for: engine.abbreviatedTitle)
        #expect(transcriptURL.deletingLastPathComponent() == gameDir)

        // Cleanup
        try testHandler.cleanup()
    }

    // MARK: - Integration Tests

    @Test("GameEngine save/load preserves complete game state")
    func testSaveLoadCompleteState() async throws {
        // Given: A game with complex state changes
        let testHandler = TestFilesystemHandler()
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(items: testItem)

        let (engine, _) = await GameEngine.test(blueprint: game, filesystemHandler: testHandler)

        // Make complex state changes
        try await engine.execute("take test item")
        try await engine.apply(
            engine.player.updateScore(by: 50)
        )

        // When: Saving and then restoring
        let complexURL = try await engine.saveGame(saveName: "complex")

        #expect(complexURL.lastPathComponent == "complex.gnusto")

        // Modify state after save
        try await engine.execute("drop test item")
        try await engine.apply(
            engine.player.updateScore(by: -50)
        )  // Reset to 0

        // Restore the save
        try await engine.restoreGame(saveName: "complex")

        // Then: All state should be restored correctly
        let playerScore = await engine.player.score
        let testItemLocation = try await engine.item("testItem").parent

        #expect(playerScore == 50)
        #expect(testItemLocation == .player)

        // Cleanup
        try testHandler.cleanup()
    }

    @Test("GameEngine filesystem operations are isolated between tests")
    func testFilesystemIsolation() async throws {
        // Given: Two separate test filesystem handlers
        let handler1 = TestFilesystemHandler()
        let handler2 = TestFilesystemHandler()

        let (engine1, _) = await GameEngine.test(filesystemHandler: handler1)
        let (engine2, _) = await GameEngine.test(filesystemHandler: handler2)

        // When: Each engine saves files
        let engine1saveURL = try await engine1.saveGame(saveName: "engine1save")
        let engine2saveURL = try await engine2.saveGame(saveName: "engine2save")

        #expect(engine1saveURL.lastPathComponent == "engine1save.gnusto")
        #expect(engine2saveURL.lastPathComponent == "engine2save.gnusto")

        // Then: Each engine should only see its own saves
        let saves1 = try await engine1.listSaveFiles()
        let saves2 = try await engine2.listSaveFiles()

        #expect(saves1.contains("engine1save"))
        #expect(!saves1.contains("engine2save"))
        #expect(saves2.contains("engine2save"))
        #expect(!saves2.contains("engine1save"))

        // And: Cleanup should be isolated
        try handler1.cleanup()

        // Engine2's files should still exist
        let saves2AfterCleanup = try await engine2.listSaveFiles()
        #expect(saves2AfterCleanup.contains("engine2save"))

        // Cleanup
        try handler2.cleanup()
    }

    @Test("GameEngine handles file encoding and decoding correctly")
    func testFileEncodingDecoding() async throws {
        // Given: A game engine with special characters in state
        let testHandler = TestFilesystemHandler()
        let (engine, _) = await GameEngine.test(filesystemHandler: testHandler)

        // Add some complex state that might have encoding issues
        try await engine.apply(
            engine.player.updateScore(by: 123)
        )

        // When: Saving and restoring
        let encodingTestURL = try await engine.saveGame(saveName: "encoding_test")

        #expect(encodingTestURL.lastPathComponent == "encoding_test.gnusto")

        // Clear the score
        try await engine.apply(
            engine.player.updateScore(by: -123)
        )

        // Restore
        try await engine.restoreGame(saveName: "encoding_test")

        // Then: Score should be preserved
        let restoredScore = await engine.player.score
        #expect(restoredScore == 123)

        // Cleanup
        try testHandler.cleanup()
    }
}
