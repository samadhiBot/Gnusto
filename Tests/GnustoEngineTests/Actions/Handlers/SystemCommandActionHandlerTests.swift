import Testing
@testable import GnustoEngine

/// Tests for system command action handlers: RESTART, SCRIPT, UNSCRIPT
@Suite("System Command Action Handler Tests")
struct SystemCommandActionHandlerTests {

    // MARK: - RESTART Tests

    @Test("RESTART command quits the game with confirmation message")
    func testRestartQuitsGame() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = RestartActionHandler()
        let command = Command(verb: .restart, rawInput: "restart")
        let context = ActionContext(command: command, engine: engine)

        // When
        try await handler.validate(context: context)
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message != nil)
        #expect(result.message!.contains("Are you sure you want to restart"))
        #expect(result.message!.contains("Game will restart"))
        #expect(await engine.shouldQuit)
    }

    @Test("RESTART requires no validation")
    func testRestartValidation() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = RestartActionHandler()
        let command = Command(verb: .restart, rawInput: "restart")
        let context = ActionContext(command: command, engine: engine)

        // When/Then - should not throw
        try await handler.validate(context: context)
    }

    // MARK: - SCRIPT Tests

    @Test("SCRIPT command starts transcript recording")
    func testScriptStartsRecording() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = ScriptActionHandler()
        let command = Command(verb: .script, rawInput: "script")
        let context = ActionContext(command: command, engine: engine)

        // Ensure scripting is not initially active
        #expect(await engine.hasGlobal(.isScripting) == false)

        // When
        try await handler.validate(context: context)
        let result = try await handler.process(context: context)

        // Apply state changes to verify flag is set
        for change in result.changes {
            try await engine.apply(change)
        }

        // Then
        #expect(result.message != nil)
        #expect(result.message!.contains("file name"))
        #expect(result.message!.contains("transcript"))
        #expect(await engine.hasGlobal(.isScripting) == true)
        #expect(result.changes.count == 1)
    }

    @Test("SCRIPT validation fails when already scripting")
    func testScriptValidationFailsWhenAlreadyScripting() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Set scripting flag to true
        let scriptingChange = await engine.setGlobal(.isScripting, to: true)
        try await engine.apply(scriptingChange)

        let handler = ScriptActionHandler()
        let command = Command(verb: .script, rawInput: "script")
        let context = ActionContext(command: command, engine: engine)

        // When/Then
        do {
            try await handler.validate(context: context)
            #expect(Bool(false), "Expected validation to fail when already scripting")
        } catch let error as ActionResponse {
            if case .prerequisiteNotMet(let message) = error {
                #expect(message.contains("already on"))
            } else {
                #expect(Bool(false), "Expected prerequisiteNotMet error, got: \(error)")
            }
        }
    }

    // MARK: - UNSCRIPT Tests

    @Test("UNSCRIPT command stops transcript recording")
    func testUnscriptStopsRecording() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Set scripting flag to true first
        let scriptingChange = await engine.setGlobal(.isScripting, to: true)
        try await engine.apply(scriptingChange)
        #expect(await engine.hasGlobal(.isScripting) == true)

        let handler = UnscriptActionHandler()
        let command = Command(verb: .unscript, rawInput: "unscript")
        let context = ActionContext(command: command, engine: engine)

        // When
        try await handler.validate(context: context)
        let result = try await handler.process(context: context)

        // Apply state changes to verify flag is cleared
        for change in result.changes {
            try await engine.apply(change)
        }

        // Then
        #expect(result.message != nil)
        #expect(result.message!.contains("ended"))
        #expect(await engine.hasGlobal(.isScripting) == false)
        #expect(result.changes.count == 1)
    }

    @Test("UNSCRIPT validation fails when not scripting")
    func testUnscriptValidationFailsWhenNotScripting() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Ensure scripting is not active
        #expect(await engine.hasGlobal(.isScripting) == false)

        let handler = UnscriptActionHandler()
        let command = Command(verb: .unscript, rawInput: "unscript")
        let context = ActionContext(command: command, engine: engine)

        // When/Then
        do {
            try await handler.validate(context: context)
            #expect(Bool(false), "Expected validation to fail when not scripting")
        } catch let error as ActionResponse {
            if case .prerequisiteNotMet(let message) = error {
                #expect(message.contains("not currently on"))
            } else {
                #expect(Bool(false), "Expected prerequisiteNotMet error, got: \(error)")
            }
        }
    }

    // MARK: - Integration Tests

    @Test("SCRIPT and UNSCRIPT work together correctly")
    func testScriptUnscriptIntegration() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let scriptHandler = ScriptActionHandler()
        let unscriptHandler = UnscriptActionHandler()

        // Initially not scripting
        #expect(await engine.hasGlobal(.isScripting) == false)

        // When - Start scripting
        let scriptCommand = Command(verb: .script, rawInput: "script")
        let scriptContext = ActionContext(command: scriptCommand, engine: engine)

        try await scriptHandler.validate(context: scriptContext)
        let scriptResult = try await scriptHandler.process(context: scriptContext)

        for change in scriptResult.changes {
            try await engine.apply(change)
        }

        // Then - Should be scripting
        #expect(await engine.hasGlobal(.isScripting) == true)

        // When - Stop scripting
        let unscriptCommand = Command(verb: .unscript, rawInput: "unscript")
        let unscriptContext = ActionContext(command: unscriptCommand, engine: engine)

        try await unscriptHandler.validate(context: unscriptContext)
        let unscriptResult = try await unscriptHandler.process(context: unscriptContext)

        for change in unscriptResult.changes {
            try await engine.apply(change)
        }

        // Then - Should not be scripting
        #expect(await engine.hasGlobal(.isScripting) == false)
    }
}
