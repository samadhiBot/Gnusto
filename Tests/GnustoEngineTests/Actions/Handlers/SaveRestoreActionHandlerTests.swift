import CustomDump
import Testing
@testable import GnustoEngine

@Suite("Save and Restore Action Handler Tests")
struct SaveRestoreActionHandlerTests {
    let saveHandler = SaveActionHandler()
    let restoreHandler = RestoreActionHandler()

    @Test("Save attempts to save game")
    func testSaveAttemptsToSaveGame() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(verb: .save, rawInput: "save")
        let context = ActionContext(command: command, engine: engine)

        // When
        try await saveHandler.validate(context: context)
        let result = try await saveHandler.process(context: context)

        // Then
        // Since save functionality is not yet implemented, it should return an error message
        #expect(result.message == "Save failed: Save functionality not yet implemented.")
        #expect(result.changes.isEmpty)
        #expect(result.effects.isEmpty)
    }

    @Test("Restore attempts to restore game")
    func testRestoreAttemptsToRestoreGame() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(verb: .restore, rawInput: "restore")
        let context = ActionContext(command: command, engine: engine)

        // When
        try await restoreHandler.validate(context: context)
        let result = try await restoreHandler.process(context: context)

        // Then
        // Since restore functionality is not yet implemented, it should return an error message
        #expect(result.message == "Restore failed: Restore functionality not yet implemented.")
        #expect(result.changes.isEmpty)
        #expect(result.effects.isEmpty)
    }

    @Test("Save and restore require no validation")
    func testSaveRestoreRequireNoValidation() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let saveCommand = Command(verb: .save, rawInput: "save")
        let restoreCommand = Command(verb: .restore, rawInput: "restore")
        let saveContext = ActionContext(command: saveCommand, engine: engine)
        let restoreContext = ActionContext(command: restoreCommand, engine: engine)

        // When/Then - Should not throw
        try await saveHandler.validate(context: saveContext)
        try await restoreHandler.validate(context: restoreContext)
    }
}
