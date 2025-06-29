import CustomDump
import Testing

@testable import GnustoEngine

@Suite("Action Handler Scoring  Tests")
struct ActionHandlerScoringTests {

    // MARK: - Test Handlers for Scoring

    /// A handler that uses generic .verb syntax
    struct GenericVerbHandler: ActionHandler {
        let verbs: [Verb] = [.take]
        let syntax: [SyntaxRule] = [
            .match(.verb, .directObject)
        ]
        let requiresLight: Bool = false

        func process(command: Command, engine: GameEngine) async throws -> ActionResult {
            ActionResult("Generic verb handler")
        }
    }

    /// A handler that uses specific verb syntax
    struct SpecificVerbHandler: ActionHandler {
        let verbs: [Verb] = []  // Empty - uses specific verbs in syntax
        let syntax: [SyntaxRule] = [
            .match(.take, .directObject)
        ]
        let requiresLight: Bool = false

        func process(command: Command, engine: GameEngine) async throws -> ActionResult {
            ActionResult("Specific verb handler")
        }
    }

    /// A handler that requires particles
    struct ParticleHandler: ActionHandler {
        let verbs: [Verb] = []
        let syntax: [SyntaxRule] = [
            .match(.put, .directObject, .in, .indirectObject)
        ]
        let requiresLight: Bool = false

        func process(command: Command, engine: GameEngine) async throws -> ActionResult {
            ActionResult("Particle handler")
        }
    }

    /// A handler with multiple syntax rules
    struct MultiRuleHandler: ActionHandler {
        let verbs: [Verb] = [.turn]
        let syntax: [SyntaxRule] = [
            .match(.verb, .directObject),  // Generic: 115
            .match(.verb, .on, .directObject),  // With particle: 135
            .match(.turn, .on, .directObject),  // Specific + particle: 235
        ]
        let requiresLight: Bool = false

        func process(command: Command, engine: GameEngine) async throws -> ActionResult {
            ActionResult("Multi-rule handler")
        }
    }

    // MARK: - Basic Scoring Tests

    @Test("scoreHandlerForCommand - basic verb match")
    func testBasicVerbMatch() async throws {
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
            items: testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = GenericVerbHandler()
        let command = Command(
            verb: .take,
            directObject: .item("testItem")
        )

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        // Expected: 100 (verb match) + 5 (has syntax) + 10 (direct object) = 115
        #expect(score == 115)
    }

    @Test("scoreHandlerForCommand - specific verb beats generic")
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
            items: testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let genericHandler = GenericVerbHandler()
        let specificHandler = SpecificVerbHandler()
        let command = Command(
            verb: .take,
            directObject: .item("testItem")
        )

        let genericScore = await engine.scoreHandlerForCommand(
            handler: genericHandler, command: command)
        let specificScore = await engine.scoreHandlerForCommand(
            handler: specificHandler, command: command)

        // Generic: 100 + 5 + 10 = 115
        // Specific: 200 + 5 + 10 = 215
        #expect(genericScore == 115)
        #expect(specificScore == 215)
        #expect(specificScore > genericScore)
    }

    @Test("scoreHandlerForCommand - particle matching bonus")
    func testParticleMatchingBonus() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("box"),
            .isContainer,
            .in(.location("testRoom"))
        )

        let key = Item(
            id: "key",
            .name("key"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, key
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = ParticleHandler()
        let command = Command(
            verb: .put,
            directObject: .item("key"),
            indirectObject: .item("box"),
            preposition: "in"
        )

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        // Expected: 200 (specific .put) + 5 (syntax) + 10 (direct obj) + 10 (indirect obj) + 20 (particle) = 245
        #expect(score == 245)
    }

    @Test("scoreHandlerForCommand - missing required particle fails")
    func testMissingRequiredParticleFails() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("box"),
            .isContainer,
            .in(.location("testRoom"))
        )

        let key = Item(
            id: "key",
            .name("key"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, key
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = ParticleHandler()
        let command = Command(
            verb: .put,
            directObject: .item("key"),
            indirectObject: .item("box")
            // No preposition - should fail
        )

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        // Should fail because required particle "in" is missing
        #expect(score == 0)
    }

    @Test("scoreHandlerForCommand - wrong particle fails")
    func testWrongParticleFails() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("box"),
            .isContainer,
            .in(.location("testRoom"))
        )

        let key = Item(
            id: "key",
            .name("key"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, key
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = ParticleHandler()
        let command = Command(
            verb: .put,
            directObject: .item("key"),
            indirectObject: .item("box"),
            preposition: "on"  // Wrong particle - expects "in"
        )

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        // Should fail because wrong particle
        #expect(score == 0)
    }

    @Test("scoreHandlerForCommand - missing required object fails")
    func testMissingRequiredObjectFails() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = GenericVerbHandler()
        let command = Command(verb: .take)  // Missing required direct object

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        // Should fail because required direct object is missing
        #expect(score == 0)
    }

    @Test("scoreHandlerForCommand - verb mismatch fails")
    func testVerbMismatchFails() async throws {
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
            items: testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = GenericVerbHandler()  // Expects .take
        let command = Command(
            verb: .drop,  // Wrong verb
            directObject: .item("testItem")
        )

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        // Should fail because verb doesn't match
        #expect(score == 0)
    }

    // MARK: - Multiple Syntax Rule Tests

    @Test("scoreHandlerForCommand - best rule wins")
    func testBestRuleWins() async throws {
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
            items: lamp
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = MultiRuleHandler()

        // Test command that should match the highest-scoring rule
        let command = Command(
            verb: .turn,
            directObject: .item("lamp"),
            preposition: "on"
        )

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        // Should use the highest-scoring rule: .match(.turn, .on, .directObject)
        // Expected: 200 (specific .turn) + 5 (syntax) + 10 (direct obj) + 20 (particle) = 235
        #expect(score == 235)
    }

    @Test("scoreHandlerForCommand - fallback to lower scoring rule")
    func testFallbackToLowerScoringRule() async throws {
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
            items: lamp
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = MultiRuleHandler()

        // Test command without particle - should use generic rule
        let command = Command(
            verb: .turn,
            directObject: .item("lamp")
            // No preposition
        )

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        // Should use the generic rule: .match(.verb, .directObject)
        // Expected: 100 (generic .verb) + 5 (syntax) + 10 (direct obj) = 115
        #expect(score == 115)
    }

    // MARK: - Syntax Rule Scoring Tests

    @Test("scoreSyntaxRuleForCommand - specific verb rule")
    func testScoreSyntaxRuleSpecificVerb() async throws {
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
            items: testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let rule = SyntaxRule(pattern: [.specificVerb(.take), .directObject])
        let command = Command(
            verb: .take,
            directObject: .item("testItem")
        )

        let score = await engine.scoreSyntaxRuleForCommand(syntaxRule: rule, command: command)

        // Expected: 200 (specific verb) + 10 (direct object) = 210
        #expect(score == 210)
    }

    @Test("scoreSyntaxRuleForCommand - generic verb rule")
    func testScoreSyntaxRuleGenericVerb() async throws {
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
            items: testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let rule = SyntaxRule(pattern: [.verb, .directObject])
        let command = Command(
            verb: .take,
            directObject: .item("testItem")
        )

        let score = await engine.scoreSyntaxRuleForCommand(syntaxRule: rule, command: command)

        // Expected: 100 (generic verb) + 10 (direct object) = 110
        #expect(score == 110)
    }

    @Test("scoreSyntaxRuleForCommand - particle rule")
    func testScoreSyntaxRuleParticle() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("box"),
            .isContainer,
            .in(.location("testRoom"))
        )

        let key = Item(
            id: "key",
            .name("key"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, key
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let rule = SyntaxRule(pattern: [
            .specificVerb(.put), .directObject, .particle("in"), .indirectObject,
        ])
        let command = Command(
            verb: .put,
            directObject: .item("key"),
            indirectObject: .item("box"),
            preposition: "in"
        )

        let score = await engine.scoreSyntaxRuleForCommand(syntaxRule: rule, command: command)

        // Expected: 200 (specific verb) + 10 (direct obj) + 20 (particle) + 10 (indirect obj) = 240
        #expect(score == 240)
    }

    @Test("scoreSyntaxRuleForCommand - wrong specific verb fails")
    func testScoreSyntaxRuleWrongSpecificVerbFails() async throws {
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
            items: testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let rule = SyntaxRule(pattern: [.specificVerb(.take), .directObject])
        let command = Command(
            verb: .drop,  // Wrong verb
            directObject: .item("testItem")
        )

        let score = await engine.scoreSyntaxRuleForCommand(syntaxRule: rule, command: command)

        // Should fail because specific verb doesn't match
        #expect(score == 0)
    }

    // MARK: - Handler Finding Tests

    @Test("findActionHandler - selects highest scoring handler")
    func testFindActionHandlerSelectsHighestScoring() async throws {
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
                GenericVerbHandler(),  // Score: 115
                SpecificVerbHandler(),  // Score: 215 (should win)
            ]
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .take,
            directObject: .item("testItem")
        )

        let selectedHandler = await engine.findActionHandler(for: command)

        #expect(selectedHandler is SpecificVerbHandler)
    }

    @Test("findActionHandler - returns nil when no handlers match")
    func testFindActionHandlerReturnsNilWhenNoMatch() async throws {
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
                GenericVerbHandler()  // Only handles .take
            ]
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .drop,  // No handler for .drop
            directObject: .item("testItem")
        )

        let selectedHandler = await engine.findActionHandler(for: command)

        #expect(selectedHandler == nil)
    }

    // MARK: - Utility Function Tests

    @Test("couldHandlerMatchCommand - positive case")
    func testCouldHandlerMatchCommandPositive() async throws {
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
            items: testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = GenericVerbHandler()
        let command = Command(
            verb: .take,
            directObject: .item("testItem")
        )

        let couldMatch = await engine.couldHandlerMatchCommand(handler, command)

        #expect(couldMatch == true)
    }

    @Test("couldHandlerMatchCommand - negative case")
    func testCouldHandlerMatchCommandNegative() async throws {
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
            items: testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = GenericVerbHandler()
        let command = Command(
            verb: .drop,  // Wrong verb
            directObject: .item("testItem")
        )

        let couldMatch = await engine.couldHandlerMatchCommand(handler, command)

        #expect(couldMatch == false)
    }

    @Test("couldSyntaxRuleMatchCommand - positive case")
    func testCouldSyntaxRuleMatchCommandPositive() async throws {
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
            items: testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let rule = SyntaxRule(pattern: [.specificVerb(.take), .directObject])
        let command = Command(
            verb: .take,
            directObject: .item("testItem")
        )

        let couldMatch = await engine.couldSyntaxRuleMatchCommand(rule, command)

        #expect(couldMatch == true)
    }

    @Test("couldSyntaxRuleMatchCommand - negative case")
    func testCouldSyntaxRuleMatchCommandNegative() async throws {
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
            items: testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let rule = SyntaxRule(pattern: [.specificVerb(.take), .directObject])
        let command = Command(
            verb: .drop,  // Wrong verb
            directObject: .item("testItem")
        )

        let couldMatch = await engine.couldSyntaxRuleMatchCommand(rule, command)

        #expect(couldMatch == false)
    }

    // MARK: - Real World Example Tests

    @Test("ClimbActionHandler vs ClimbOnActionHandler scoring")
    func testClimbHandlerScoring() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: table
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let climbHandler = ClimbActionHandler()
        let climbOnHandler = ClimbOnActionHandler()

        // Test "climb on table" command with proper preposition
        let commandWithPreposition = Command(
            verb: .climb,
            directObject: .item("table"),
            preposition: "on"
        )

        let climbScore = await engine.scoreHandlerForCommand(
            handler: climbHandler, command: commandWithPreposition)
        let climbOnScore = await engine.scoreHandlerForCommand(
            handler: climbOnHandler, command: commandWithPreposition)

        // ClimbOnActionHandler should score higher due to specific verb + particle match
        // ClimbOnActionHandler: 200 (specific .climb) + 5 (syntax) + 10 (directObject) + 20 (particle "on") = 235
        // ClimbActionHandler: 100 (generic .verb) + 5 (syntax) + 10 (directObject) = 115
        #expect(climbOnScore == 235)
        #expect(climbScore == 115)
        #expect(climbOnScore > climbScore)

        // Test "climb table" command without preposition
        let commandWithoutPreposition = Command(
            verb: .climb,
            directObject: .item("table")
        )

        let climbScoreNoPrep = await engine.scoreHandlerForCommand(
            handler: climbHandler, command: commandWithoutPreposition)
        let climbOnScoreNoPrep = await engine.scoreHandlerForCommand(
            handler: climbOnHandler, command: commandWithoutPreposition)

        // ClimbOnActionHandler should fail (score 0) because it requires "on" particle
        // ClimbActionHandler should succeed: 100 + 5 + 10 = 115
        #expect(climbOnScoreNoPrep == 0)
        #expect(climbScoreNoPrep == 115)
        #expect(climbScoreNoPrep > climbOnScoreNoPrep)
    }

    // MARK: - Edge Cases

    @Test("scoreHandlerForCommand - handler with no verbs or syntax")
    func testHandlerWithNoVerbsOrSyntax() async throws {
        struct EmptyHandler: ActionHandler {
            let verbs: [Verb] = []
            let syntax: [SyntaxRule] = []
            let requiresLight: Bool = false

            func process(command: Command, engine: GameEngine) async throws -> ActionResult {
                ActionResult("Empty handler")
            }
        }

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = EmptyHandler()
        let command = Command(verb: .take)

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        // Should fail because handler has no verbs AND no syntax rules
        #expect(score == 0)
    }

    @Test("scoreHandlerForCommand - case insensitive particle matching")
    func testCaseInsensitiveParticleMatching() async throws {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("box"),
            .isContainer,
            .in(.location("testRoom"))
        )

        let key = Item(
            id: "key",
            .name("key"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, key
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = ParticleHandler()

        // Test with uppercase particle
        let commandUppercase = Command(
            verb: .put,
            directObject: .item("key"),
            indirectObject: .item("box"),
            preposition: "IN"  // Uppercase
        )

        let scoreUppercase = await engine.scoreHandlerForCommand(
            handler: handler, command: commandUppercase)

        // Test with lowercase particle
        let commandLowercase = Command(
            verb: .put,
            directObject: .item("key"),
            indirectObject: .item("box"),
            preposition: "in"  // Lowercase
        )

        let scoreLowercase = await engine.scoreHandlerForCommand(
            handler: handler, command: commandLowercase)

        // Both should work - particle matching is case insensitive
        #expect(scoreUppercase == 245)
        #expect(scoreLowercase == 245)
        #expect(scoreUppercase == scoreLowercase)
    }
}
