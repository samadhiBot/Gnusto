import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("Action Handler Scoring  Tests")
struct ActionHandlerScoringTests {

    // MARK: - Test Handlers for Scoring

    /// A handler that uses generic .verb syntax
    struct GenericVerbHandler: ActionHandler {
        let synonyms: [Verb] = [.take]
        let syntax: [SyntaxRule] = [
            .match(.verb, .directObject)
        ]
        let requiresLight: Bool = false

        func process(context: ActionContext) async throws -> ActionResult {
            ActionResult("Generic verb handler")
        }
    }

    /// A handler that uses specific verb syntax
    struct SpecificVerbHandler: ActionHandler {
        let synonyms: [Verb] = []  // Empty - uses specific verbs in syntax
        let syntax: [SyntaxRule] = [
            .match(.take, .directObject)
        ]
        let requiresLight: Bool = false

        func process(context: ActionContext) async throws -> ActionResult {
            ActionResult("Specific verb handler")
        }
    }

    /// A handler that requires particles
    struct ParticleHandler: ActionHandler {
        let synonyms: [Verb] = []
        let syntax: [SyntaxRule] = [
            .match(.put, .directObject, .in, .indirectObject)
        ]
        let requiresLight: Bool = false

        func process(context: ActionContext) async throws -> ActionResult {
            ActionResult("Particle handler")
        }
    }

    /// A handler with multiple syntax rules
    struct MultiRuleHandler: ActionHandler {
        let synonyms: [Verb] = [.turn]
        let syntax: [SyntaxRule] = [
            .match(.verb, .directObject),
            .match(.verb, .on, .directObject),
            .match(.turn, .on, .directObject),
        ]
        let requiresLight: Bool = false

        func process(context: ActionContext) async throws -> ActionResult {
            ActionResult("Multi-rule handler")
        }
    }

    // MARK: - Basic Scoring Tests

    @Test("scoreHandlerForCommand - basic verb + DO match")
    func testBasicVerbMatch() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = GenericVerbHandler()
        let command = await Command(
            verb: .take,
            directObject: .item(testItem.proxy(engine))
        )

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        #expect(score == 10)
    }

    @Test("scoreHandlerForCommand - specific verb beats generic")
    func testSpecificVerbBeatsGeneric() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let genericHandler = GenericVerbHandler()
        let specificHandler = SpecificVerbHandler()
        let command = await Command(
            verb: .take,
            directObject: .item(testItem.proxy(engine))
        )

        let genericScore = await engine.scoreHandlerForCommand(
            handler: genericHandler,
            command: command
        )
        let specificScore = await engine.scoreHandlerForCommand(
            handler: specificHandler,
            command: command
        )

        #expect(genericScore == 10)
        #expect(specificScore == 11)
        #expect(specificScore > genericScore)
    }

    @Test("scoreHandlerForCommand - particle matching bonus")
    func testParticleMatchingBonus() async throws {
        let box = Item("box")
            .name("box")
            .isContainer
            .in(.startRoom)

        let key = Item("key")
            .name("key")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: box, key
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = ParticleHandler()
        let command = await Command(
            verb: .put,
            directObject: .item(key.proxy(engine)),
            indirectObject: .item(box.proxy(engine)),
            preposition: "in"
        )

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        #expect(score == 20)
    }

    @Test("scoreHandlerForCommand - missing required particle fails")
    func testMissingRequiredParticleFails() async throws {
        let box = Item("box")
            .name("box")
            .isContainer
            .in(.startRoom)

        let key = Item("key")
            .name("key")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: box, key
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = ParticleHandler()
        let command = await Command(
            verb: .put,
            directObject: .item(key.proxy(engine)),
            indirectObject: .item(box.proxy(engine))
        )

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        #expect(score == 8)
    }

    @Test("scoreHandlerForCommand - wrong particle fails")
    func testWrongParticleFails() async throws {
        let box = Item("box")
            .name("box")
            .isContainer
            .in(.startRoom)

        let key = Item("key")
            .name("key")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: box, key
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = ParticleHandler()
        let command = await Command(
            verb: .put,
            directObject: .item(key.proxy(engine)),
            indirectObject: .item(box.proxy(engine)),
            preposition: "on"  // Wrong particle - expects "in"
        )

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        #expect(score == 8)
    }

    @Test("scoreHandlerForCommand - missing required object fails")
    func testMissingRequiredObjectFails() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = GenericVerbHandler()
        let command = Command(verb: .take)

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        #expect(score == 8)
    }

    @Test("scoreHandlerForCommand - verb mismatch fails")
    func testVerbMismatchFails() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = GenericVerbHandler()  // Expects .take
        let command = await Command(
            verb: "xyz123",  // Wrong verb
            directObject: .item(testItem.proxy(engine))
        )

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        #expect(score == 0)
    }

    // MARK: - Multiple Syntax Rule Tests

    @Test("scoreHandlerForCommand - best rule wins")
    func testBestRuleWins() async throws {
        let lamp = Item("lamp")
            .name("lamp")
            .isDevice
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: lamp
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = MultiRuleHandler()

        let command = await Command(
            verb: .turn,
            directObject: .item(lamp.proxy(engine)),
            preposition: "on"
        )

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        #expect(score == 17)
    }

    @Test("scoreHandlerForCommand - fallback to lower scoring rule")
    func testFallbackToLowerScoringRule() async throws {
        let lamp = Item("lamp")
            .name("lamp")
            .isDevice
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: lamp
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = MultiRuleHandler()

        let command = await Command(
            verb: .turn,
            directObject: .item(lamp.proxy(engine))
            // No preposition
        )

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        #expect(score == 10)
    }

    // MARK: - Syntax Rule Scoring Tests

    @Test("scoreSyntaxRuleForCommand - specific verb rule")
    func testScoreSyntaxRuleSpecificVerb() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let rule = SyntaxRule.match(.specificVerb(.take), .directObject)
        let command = await Command(
            verb: .take,
            directObject: .item(testItem.proxy(engine))
        )

        let score = await engine.scoreSyntaxRuleForCommand(syntaxRule: rule, command: command)

        #expect(score == 11)
    }

    @Test("scoreSyntaxRuleForCommand - generic verb rule")
    func testScoreSyntaxRuleGenericVerb() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let rule = SyntaxRule.match(.verb, .directObject)
        let command = await Command(
            verb: .take,
            directObject: .item(testItem.proxy(engine))
        )

        let score = await engine.scoreSyntaxRuleForCommand(syntaxRule: rule, command: command)

        #expect(score == 0)
    }

    @Test("scoreSyntaxRuleForCommand - particle rule")
    func testScoreSyntaxRuleParticle() async throws {
        let box = Item("box")
            .name("box")
            .isContainer
            .in(.startRoom)

        let key = Item("key")
            .name("key")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: box, key
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let rule = SyntaxRule.match(
            .specificVerb(.put), .directObject, .particle("in"), .indirectObject,
        )
        let command = await Command(
            verb: .put,
            directObject: .item(key.proxy(engine)),
            indirectObject: .item(box.proxy(engine)),
            preposition: "in"
        )

        let score = await engine.scoreSyntaxRuleForCommand(syntaxRule: rule, command: command)

        #expect(score == 20)
    }

    @Test("scoreSyntaxRuleForCommand - wrong specific verb fails")
    func testScoreSyntaxRuleWrongSpecificVerbFails() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let rule = SyntaxRule.match(.specificVerb(.take), .directObject)
        let command = await Command(
            verb: .drop,  // Wrong verb
            directObject: .item(testItem.proxy(engine))
        )

        let score = await engine.scoreSyntaxRuleForCommand(syntaxRule: rule, command: command)

        // Should fail because specific verb doesn't match
        #expect(score == 0)
    }

    // MARK: - Handler Finding Tests

    @Test("findActionHandler - selects highest scoring handler")
    func testFindActionHandlerSelectsHighestScoring() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: testItem,
            customActionHandlers: [
                GenericVerbHandler(),
                SpecificVerbHandler(),
            ]
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = await Command(
            verb: .take,
            directObject: .item(testItem.proxy(engine))
        )

        let selectedHandler = await engine.findActionHandler(for: command)

        #expect(selectedHandler is SpecificVerbHandler)
    }

    @Test("findActionHandler - returns nil when no handlers match")
    func testFindActionHandlerReturnsNilWhenNoMatch() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = await Command(
            verb: "xyz123",  // No handler for .xyz123
            directObject: .item(testItem.proxy(engine))
        )

        let selectedHandler = await engine.findActionHandler(for: command)

        #expect(selectedHandler == nil)
    }

    // MARK: - Utility Function Tests

    @Test("couldHandlerMatchCommand - positive case")
    func testCouldHandlerMatchCommandPositive() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = GenericVerbHandler()
        let command = await Command(
            verb: .take,
            directObject: .item(testItem.proxy(engine))
        )

        let couldMatch = await engine.couldHandlerMatchCommand(handler, command)

        #expect(couldMatch == true)
    }

    @Test("couldHandlerMatchCommand - negative case")
    func testCouldHandlerMatchCommandNegative() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = GenericVerbHandler()
        let command = await Command(
            verb: .drop,  // Wrong verb
            directObject: .item(testItem.proxy(engine))
        )

        let couldMatch = await engine.couldHandlerMatchCommand(handler, command)

        #expect(couldMatch == false)
    }

    // MARK: - Real World Example Tests

    @Test("ClimbActionHandler vs ClimbOnActionHandler scoring")
    func testClimbHandlerScoring() async throws {
        let table = Item("table")
            .name("wooden table")
            .description("A sturdy wooden table.")
            .in(.startRoom)

        let game = MinimalGame(
            items: table
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let climbHandler = ClimbActionHandler()
        let climbOnHandler = ClimbOnActionHandler()

        // Test "climb on table" command with proper preposition
        let commandWithPreposition = await Command(
            verb: .climb,
            directObject: .item(table.proxy(engine)),
            preposition: "on"
        )

        let climbScore = await engine.scoreHandlerForCommand(
            handler: climbHandler, command: commandWithPreposition)
        let climbOnScore = await engine.scoreHandlerForCommand(
            handler: climbOnHandler, command: commandWithPreposition)

        #expect(climbOnScore == 17)
        #expect(climbScore == 10)
        #expect(climbOnScore > climbScore)

        // Test "climb table" command without preposition
        let commandWithoutPreposition = await Command(
            verb: .climb,
            directObject: .item(table.proxy(engine))
        )

        let climbScoreNoPrep = await engine.scoreHandlerForCommand(
            handler: climbHandler, command: commandWithoutPreposition)
        let climbOnScoreNoPrep = await engine.scoreHandlerForCommand(
            handler: climbOnHandler, command: commandWithoutPreposition)

        #expect(climbOnScoreNoPrep == 5)
        #expect(climbScoreNoPrep == 10)
        #expect(climbScoreNoPrep > climbOnScoreNoPrep)
    }

    // MARK: - Edge Cases

    @Test("scoreHandlerForCommand - handler with no verbs or syntax")
    func testHandlerWithNoVerbsOrSyntax() async throws {
        struct EmptyHandler: ActionHandler {
            let verbs: [Verb] = []
            let syntax: [SyntaxRule] = []
            let requiresLight: Bool = false

            func process(context: ActionContext) async throws -> ActionResult {
                ActionResult("Empty handler")
            }
        }

        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = EmptyHandler()
        let command = Command(verb: .take)

        let score = await engine.scoreHandlerForCommand(handler: handler, command: command)

        // Should fail because handler has no verbs AND no syntax rules
        #expect(score == 0)
    }

    @Test("scoreHandlerForCommand - case insensitive particle matching")
    func testCaseInsensitiveParticleMatching() async throws {
        let box = Item("box")
            .name("box")
            .isContainer
            .in(.startRoom)

        let key = Item("key")
            .name("key")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: box, key
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let handler = ParticleHandler()

        // Test with uppercase particle
        let commandUppercase = await Command(
            verb: .put,
            directObject: .item(key.proxy(engine)),
            indirectObject: .item(box.proxy(engine)),
            preposition: "IN"  // Uppercase
        )

        let scoreUppercase = await engine.scoreHandlerForCommand(
            handler: handler, command: commandUppercase)

        // Test with lowercase particle
        let commandLowercase = await Command(
            verb: .put,
            directObject: .item(key.proxy(engine)),
            indirectObject: .item(box.proxy(engine)),
            preposition: "in"  // Lowercase
        )

        let scoreLowercase = await engine.scoreHandlerForCommand(
            handler: handler, command: commandLowercase)

        #expect(scoreUppercase == 20)
        #expect(scoreLowercase == 20)
        #expect(scoreUppercase == scoreLowercase)
    }
}
