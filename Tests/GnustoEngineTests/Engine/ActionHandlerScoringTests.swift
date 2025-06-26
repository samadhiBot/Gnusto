import CustomDump
import Testing

@testable import GnustoEngine

/// Tests for the sophisticated action handler scoring system that ensures
/// the most specific matching handler is selected for each command.
struct ActionHandlerScoringTests {

    // MARK: - Test Action Handlers

    /// Mock handler that accepts any verb with basic syntax
    private struct GenericVerbHandler: ActionHandler {
        let verbs: [VerbID] = [.take]
        let syntax: [SyntaxRule] = [.match(.verb, .directObject)]
        let requiresLight: Bool = false

        func process(command: Command, engine: GameEngine) async throws -> ActionResult {
            ActionResult("Generic take handler used.")
        }
    }

    /// Mock handler with specific verb requirement
    private struct SpecificVerbHandler: ActionHandler {
        let verbs: [VerbID] = []  // No verbs - relies on syntax rules
        let syntax: [SyntaxRule] = [.match(.take, .directObject)]
        let requiresLight: Bool = false

        func process(command: Command, engine: GameEngine) async throws -> ActionResult {
            ActionResult("Specific take handler used.")
        }
    }

    /// Mock handler with particle requirement
    private struct ParticleHandler: ActionHandler {
        let verbs: [VerbID] = [.turn]
        let syntax: [SyntaxRule] = [.match(.verb, .on, .directObject)]
        let requiresLight: Bool = false

        func process(command: Command, engine: GameEngine) async throws -> ActionResult {
            ActionResult("Turn on handler used.")
        }
    }

    /// Mock handler with multiple object requirement
    private struct MultiObjectHandler: ActionHandler {
        let verbs: [VerbID] = [.take]
        let syntax: [SyntaxRule] = [.match(.verb, .directObjects)]
        let requiresLight: Bool = false

        func process(command: Command, engine: GameEngine) async throws -> ActionResult {
            ActionResult("Multi-object take handler used.")
        }
    }

    /// Mock handler with indirect object requirement
    private struct IndirectObjectHandler: ActionHandler {
        let verbs: [VerbID] = [.put]
        let syntax: [SyntaxRule] = [.match(.verb, .directObject, .in, .indirectObject)]
        let requiresLight: Bool = false

        func process(command: Command, engine: GameEngine) async throws -> ActionResult {
            ActionResult("Put in handler used.")
        }
    }

    /// Mock handler with direction requirement
    private struct DirectionHandler: ActionHandler {
        let verbs: [VerbID] = [.go]
        let syntax: [SyntaxRule] = [.match(.verb, .direction)]
        let requiresLight: Bool = false

        func process(command: Command, engine: GameEngine) async throws -> ActionResult {
            ActionResult("Go direction handler used.")
        }
    }

    // MARK: - Basic Scoring Tests

    @Test("Specific verb handler beats generic verb handler")
    func testSpecificVerbBeatsGeneric() async throws {
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
                GenericVerbHandler(),  // Score: 100 + 5 (syntax) + 10 (direct object) = 115
                SpecificVerbHandler(),  // Score: 200 + 5 (syntax) + 10 (direct object) = 215
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "take test item"
        try await engine.execute("take test item")

        // Then: Specific handler should be chosen (higher score)
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take test item
            Specific take handler used.
            """)
    }

    @Test("Handler with required particle beats handler without")
    func testParticleRequirementScoring() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lamp,
            customActionHandlers: [
                GenericVerbHandler(),  // Would score 0 for "turn on lamp" (wrong verb)
                ParticleHandler(),  // Score: 100 + 5 (syntax) + 10 (direct object) + 20 (particle) = 135
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "turn on lamp"
        try await engine.execute("turn on lamp")

        // Then: Particle handler should be chosen
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn on lamp
            Turn on handler used.
            """)
    }

    @Test("Handler without required objects scores zero")
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
                GenericVerbHandler()  // Requires direct object but "take" has none
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "take" (no object)
        try await engine.execute("take")

        // Then: Should get error about unknown verb (no handler can handle it)
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take
            I don't know the verb 'take'.
            """)
    }

    @Test("Handler with wrong particle requirement scores zero")
    func testWrongParticleRequirement() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lamp,
            customActionHandlers: [
                ParticleHandler()  // Expects "turn on" but command is "turn off"
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "turn off lamp" (wrong particle)
        try await engine.execute("turn off lamp")

        // Then: Should get error about unknown verb
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lamp
            I don't know the verb 'turn'.
            """)
    }

    // MARK: - Complex Scoring Scenarios

    @Test("Multiple handlers with different requirements")
    func testMultipleHandlerComparison() async throws {
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

        // Handler that matches but with lower specificity
        struct LowerSpecHandler: ActionHandler {
            let verbs: [VerbID] = [.take]
            let syntax: [SyntaxRule] = [.match(.verb, .directObject)]
            let requiresLight: Bool = false

            func process(command: Command, engine: GameEngine) async throws -> ActionResult {
                ActionResult("Lower spec handler used.")
            }
        }

        // Handler that matches with higher specificity
        struct HigherSpecHandler: ActionHandler {
            let verbs: [VerbID] = []
            let syntax: [SyntaxRule] = [.match(.take, .directObject)]
            let requiresLight: Bool = false

            func process(command: Command, engine: GameEngine) async throws -> ActionResult {
                ActionResult("Higher spec handler used.")
            }
        }

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: testItem,
            customActionHandlers: [
                LowerSpecHandler(),  // Score: 100 + 5 + 10 = 115
                HigherSpecHandler(),  // Score: 200 + 5 + 10 = 215
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "take test item"
        try await engine.execute("take test item")

        // Then: Higher specificity handler should be chosen
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take test item
            Higher spec handler used.
            """)
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
                // Put specific handler FIRST this time
                SpecificVerbHandler(),  // Score: 200 + 5 + 10 = 215
                GenericVerbHandler(),  // Score: 100 + 5 + 10 = 115
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "take test item"
        try await engine.execute("take test item")

        // Then: Specific handler should still be chosen (order doesn't matter)
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take test item
            Specific take handler used.
            """)
    }

    @Test("Complex command with indirect object and particle")
    func testComplexCommandScoring() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let key = Item(
            id: "key",
            .name("key"),
            .isTakable,
            .in(.player)
        )

        let box = Item(
            id: "box",
            .name("box"),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        // Handler that matches but without particle requirement
        struct SimpleHandler: ActionHandler {
            let verbs: [VerbID] = [.put]
            let syntax: [SyntaxRule] = [.match(.verb, .directObject)]
            let requiresLight: Bool = false

            func process(command: Command, engine: GameEngine) async throws -> ActionResult {
                ActionResult("Simple put handler used.")
            }
        }

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: key, box,
            customActionHandlers: [
                SimpleHandler(),  // Score: 100 + 5 + 10 = 115
                IndirectObjectHandler(),  // Score: 100 + 5 + 10 + 10 + 20 = 145
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "put key in box"
        try await engine.execute("put key in box")

        // Then: Handler with indirect object and particle should be chosen
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put key in box
            Put in handler used.
            """)
    }

    @Test("Direction-based command scoring")
    func testDirectionCommandScoring() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .exits([.north: Exit(destination: "northRoom")]),
            .inherentlyLit
        )

        let northRoom = Location(
            id: "northRoom",
            .name("North Room"),
            .inherentlyLit
        )

        // Handler that matches go verb but doesn't expect direction
        struct SimpleGoHandler: ActionHandler {
            let verbs: [VerbID] = [.go]
            let syntax: [SyntaxRule] = [.match(.verb)]
            let requiresLight: Bool = false

            func process(command: Command, engine: GameEngine) async throws -> ActionResult {
                ActionResult("Simple go handler used.")
            }
        }

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, northRoom,
            customActionHandlers: [
                SimpleGoHandler(),  // Score: 100 + 5 = 105
                DirectionHandler(),  // Score: 100 + 5 + 10 = 115
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "go north"
        try await engine.execute("go north")

        // Then: Direction handler should be chosen
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go north
            Go direction handler used.
            """)
    }

    // MARK: - Edge Cases

    @Test("Handler with no verbs and no syntax scores zero")
    func testEmptyHandlerScoring() async throws {
        struct EmptyHandler: ActionHandler {
            let verbs: [VerbID] = []
            let syntax: [SyntaxRule] = []
            let requiresLight: Bool = false

            func process(command: Command, engine: GameEngine) async throws -> ActionResult {
                ActionResult("Empty handler used.")
            }
        }

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            customActionHandlers: [
                EmptyHandler()  // Score: 0 (no verbs, no syntax)
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute any command
        try await engine.execute("test")

        // Then: Should get unknown verb error (empty handler can't match)
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > test
            I don't know the verb 'test'.
            """)
    }

    @Test("Handler with verbs but no matching verb scores zero")
    func testNonMatchingVerbScoring() async throws {
        struct WrongVerbHandler: ActionHandler {
            let verbs: [VerbID] = [.drop]  // Handler for "drop" but command is "take"
            let syntax: [SyntaxRule] = [.match(.verb, .directObject)]
            let requiresLight: Bool = false

            func process(command: Command, engine: GameEngine) async throws -> ActionResult {
                ActionResult("Wrong verb handler used.")
            }
        }

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
                WrongVerbHandler()  // Score: 0 (verb doesn't match)
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "take test item"
        try await engine.execute("take test item")

        // Then: Should get unknown verb error
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take test item
            I don't know the verb 'take'.
            """)
    }

    @Test("Multiple syntax rules - best matching rule wins")
    func testMultipleSyntaxRules() async throws {
        struct MultiSyntaxHandler: ActionHandler {
            let verbs: [VerbID] = [.turn]
            let syntax: [SyntaxRule] = [
                .match(.verb, .directObject),  // Score: 100 + 5 + 10 = 115
                .match(.verb, .on, .directObject),  // Score: 100 + 5 + 10 + 20 = 135
            ]
            let requiresLight: Bool = false

            func process(command: Command, engine: GameEngine) async throws -> ActionResult {
                ActionResult("Multi-syntax handler used.")
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
        expectNoDifference(
            output,
            """
            > turn on lamp
            Multi-syntax handler used.
            """)
    }

    @Test("Case insensitive particle matching")
    func testCaseInsensitiveParticles() async throws {
        struct CaseSensitiveHandler: ActionHandler {
            let verbs: [VerbID] = [.turn]
            let syntax: [SyntaxRule] = [.match(.verb, .on, .directObject)]
            let requiresLight: Bool = false

            func process(command: Command, engine: GameEngine) async throws -> ActionResult {
                ActionResult("Case insensitive handler used.")
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
                CaseSensitiveHandler()
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute "turn ON lamp" (uppercase particle)
        try await engine.execute("turn ON lamp")

        // Then: Should match despite case difference
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn ON lamp
            Case insensitive handler used.
            """)
    }
}
