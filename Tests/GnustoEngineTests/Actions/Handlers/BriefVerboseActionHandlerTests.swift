import CustomDump
import Testing
@testable import GnustoEngine

@Suite("Brief and Verbose Action Handler Tests")
struct BriefVerboseActionHandlerTests {
    let briefHandler = BriefActionHandler()
    let verboseHandler = VerboseActionHandler()

    @Test("Brief sets brief mode")
    func testBriefSetsBriefMode() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(verb: .brief, rawInput: "brief")
        let context = ActionContext(command: command, engine: engine)

        // When
        try await briefHandler.validate(context: context)
        let result = try await briefHandler.process(context: context)

        // Then
        #expect(result.message == "Brief mode is now on. Location descriptions will be shown only when you first enter a location.")
        #expect(result.stateChanges.count == 1) // Should set brief mode
        #expect(result.sideEffects.isEmpty)
    }

    @Test("Brief clears verbose mode if set")
    func testBriefClearsVerboseMode() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        // First set verbose mode
        let verboseChange = await engine.setGlobal(.isVerboseMode, to: true)
        try await engine.apply(verboseChange)

        let command = Command(verb: .brief, rawInput: "brief")
        let context = ActionContext(command: command, engine: engine)

        // When
        try await briefHandler.validate(context: context)
        let result = try await briefHandler.process(context: context)

        // Then
        #expect(result.message == "Brief mode is now on. Location descriptions will be shown only when you first enter a location.")
        #expect(result.stateChanges.count == 2) // Should set brief mode and clear verbose mode
    }

    @Test("Verbose sets verbose mode")
    func testVerboseSetVerboseMode() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(verb: .verbose, rawInput: "verbose")
        let context = ActionContext(command: command, engine: engine)

        // When
        try await verboseHandler.validate(context: context)
        let result = try await verboseHandler.process(context: context)

        // Then
        #expect(result.message == "Verbose mode is now on. Full location descriptions will be shown every time you enter a location.")
        #expect(result.stateChanges.count == 1) // Should set verbose mode
        #expect(result.sideEffects.isEmpty)
    }

    @Test("Verbose clears brief mode if set")
    func testVerboseClearsBriefMode() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        // First set brief mode
        let briefChange = await engine.setGlobal(.isBriefMode, to: true)
        try await engine.apply(briefChange)

        let command = Command(verb: .verbose, rawInput: "verbose")
        let context = ActionContext(command: command, engine: engine)

        // When
        try await verboseHandler.validate(context: context)
        let result = try await verboseHandler.process(context: context)

        // Then
        #expect(result.message == "Verbose mode is now on. Full location descriptions will be shown every time you enter a location.")
        #expect(result.stateChanges.count == 2) // Should set verbose mode and clear brief mode
    }

    @Test("Brief and verbose require no validation")
    func testBriefVerboseRequireNoValidation() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let briefCommand = Command(verb: .brief, rawInput: "brief")
        let verboseCommand = Command(verb: .verbose, rawInput: "verbose")
        let briefContext = ActionContext(command: briefCommand, engine: engine)
        let verboseContext = ActionContext(command: verboseCommand, engine: engine)

        // When/Then - Should not throw
        try await briefHandler.validate(context: briefContext)
        try await verboseHandler.validate(context: verboseContext)
    }
}
