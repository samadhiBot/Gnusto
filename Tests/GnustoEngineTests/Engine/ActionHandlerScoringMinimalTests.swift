import Testing

@testable import GnustoEngine

/// Minimal tests for the sophisticated action handler scoring system that ensures
/// the most specific matching handler is selected for each command.
///
/// These tests focus on the core scoring logic without relying on complex game state
/// or external dependencies that might have compilation issues.
struct ActionHandlerScoringMinimalTests {

    // MARK: - Test Action Handlers

    /// Simple handler that matches basic verb with direct object
    private struct BasicTakeHandler: ActionHandler {
        let verbs: [Verb] = [.take]
        let syntax: [SyntaxRule] = [.match(.verb, .directObject)]
        let requiresLight: Bool = false

        func process(command: Command, engine: GameEngine) async throws -> ActionResult {
            ActionResult("Basic take used.")
        }
    }

    /// Handler with specific verb requirement (higher specificity)
    private struct SpecificTakeHandler: ActionHandler {
        let verbs: [Verb] = []
        let syntax: [SyntaxRule] = [.match(.take, .directObject)]
        let requiresLight: Bool = false

        func process(command: Command, engine: GameEngine) async throws -> ActionResult {
            ActionResult("Specific take used.")
        }
    }

    /// Handler with particle requirement
    private struct TurnOnHandler: ActionHandler {
        let verbs: [Verb] = [.turn]
        let syntax: [SyntaxRule] = [.match(.verb, .on, .directObject)]
        let requiresLight: Bool = false

        func process(command: Command, engine: GameEngine) async throws -> ActionResult {
            ActionResult("Turn on used.")
        }
    }

    // MARK: - Basic Scoring Tests

    @Test("Specific verb handler beats basic verb handler")
    func testSpecificVerbBeatsBasic() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: testItem,
            customActionHandlers: [
                BasicTakeHandler(),  // Should score: 100 (verb match) + 5 (syntax) + 10 (direct object) = 115
                SpecificTakeHandler(),  // Should score: 200 (specific verb) + 5 (syntax) + 10 (direct object) = 215
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "take test item"
        try await engine.execute("take test item")

        // Then: Specific handler should be chosen (higher score)
        let output = await mockIO.flush()
        #expect(output.contains("Specific take used"))
    }

    @Test("Handler with particle requirement scores higher")
    func testParticleRequirementScoring() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("lamp"),
            .isDevice,
            .isTakable,
            .in(.player)
        )

        /// Basic turn handler without particle
        struct BasicTurnHandler: ActionHandler {
            let verbs: [Verb] = [.turn]
            let syntax: [SyntaxRule] = [.match(.verb, .directObject)]
            let requiresLight: Bool = false

            func process(command: Command, engine: GameEngine) async throws -> ActionResult {
                ActionResult("Basic turn used.")
            }
        }

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lamp,
            customActionHandlers: [
                BasicTurnHandler(),  // Should score: 100 + 5 + 10 = 115
                TurnOnHandler(),  // Should score: 100 + 5 + 10 + 20 (particle) = 135
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "turn on lamp"
        try await engine.execute("turn on lamp")

        // Then: Handler with particle should be chosen
        let output = await mockIO.flush()
        #expect(output.contains("Turn on used"))
    }

    @Test("Handler with missing required object scores zero")
    func testMissingObjectRequirement() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            customActionHandlers: [
                BasicTakeHandler()  // Requires direct object but "take" has none
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "take" (no object)
        try await engine.execute("take")

        // Then: Should get error about unknown verb (no handler can handle it)
        let output = await mockIO.flush()
        #expect(output.contains("I don't know the verb 'take'"))
    }

    @Test("Handler with wrong particle scores zero")
    func testWrongParticleRequirement() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("lamp"),
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lamp,
            customActionHandlers: [
                TurnOnHandler()  // Expects "turn on" but command is "turn off"
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "turn off lamp" (wrong particle)
        try await engine.execute("turn off lamp")

        // Then: Should get error about unknown verb
        let output = await mockIO.flush()
        #expect(output.contains("I don't know the verb 'turn'"))
    }

    @Test("Handler order doesn't matter - best score wins")
    func testHandlerOrderIrrelevant() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: testItem,
            customActionHandlers: [
                // Put specific handler FIRST this time to test order independence
                SpecificTakeHandler(),  // Score: 215
                BasicTakeHandler(),  // Score: 115
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "take test item"
        try await engine.execute("take test item")

        // Then: Specific handler should still be chosen (order doesn't matter)
        let output = await mockIO.flush()
        #expect(output.contains("Specific take used"))
    }

    @Test("Multiple syntax rules - best matching rule wins")
    func testMultipleSyntaxRules() async throws {
        /// Handler with multiple syntax patterns
        struct MultiSyntaxHandler: ActionHandler {
            let verbs: [Verb] = [.turn]
            let syntax: [SyntaxRule] = [
                .match(.verb, .directObject),  // Score: 100 + 5 + 10 = 115
                .match(.verb, .on, .directObject),  // Score: 100 + 5 + 10 + 20 = 135
            ]
            let requiresLight: Bool = false

            func process(command: Command, engine: GameEngine) async throws -> ActionResult {
                ActionResult("Multi-syntax used.")
            }
        }

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("lamp"),
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lamp,
            customActionHandlers: [
                MultiSyntaxHandler()  // Should score 135 for "turn on lamp"
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "turn on lamp" (matches higher-scoring syntax rule)
        try await engine.execute("turn on lamp")

        // Then: Handler should be chosen with best matching rule
        let output = await mockIO.flush()
        #expect(output.contains("Multi-syntax used"))
    }

    @Test("Case insensitive particle matching works")
    func testCaseInsensitiveParticles() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("lamp"),
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lamp,
            customActionHandlers: [
                TurnOnHandler()
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "turn ON lamp" (uppercase particle)
        try await engine.execute("turn ON lamp")

        // Then: Should match despite case difference
        let output = await mockIO.flush()
        #expect(output.contains("Turn on used"))
    }
}
