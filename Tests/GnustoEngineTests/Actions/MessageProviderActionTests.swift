import Testing

@testable import GnustoEngine

/// Tests to verify that ActionHandlers properly use the MessageProvider system
/// instead of hardcoded strings.
@MainActor
struct MessageProviderActionTests {

    // MARK: - Test Setup

    private func createTestGame() -> MinimalGame {
        let sword = Item(
            id: "sword",
            .name("sword"),
            .isWeapon,
            .isTakable,
            .in(.player)
        )
        let box = Item(
            id: "box",
            .name("box"),
            .isContainer,
            .isOpenable,
            .isTakable
        )
        let rope = Item(
            id: "rope",
            .name("rope"),
            .isClimbable,
            .isTakable
        )
        let food = Item(
            id: "food",
            .name("bread"),
            .isEdible,
            .isTakable,
            .omitArticle
        )
        let character = Item(
            id: "guard",
            .name("guard"),
            .isCharacter
        )

        return MinimalGame(
            items: [sword, box, rope, food, character]
        )
    }

    private func createEngine() async -> GameEngine {
        let game = createTestGame()
        let mockIO = MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )
        return engine
    }

    // MARK: - Atmospheric Commands Tests

    @Test("BREATHE command uses MessageProvider for responses")
    func testBreatheUsesMessageProvider() async throws {
        let engine = await createEngine()
        let handler = BreatheActionHandler()
        let command = Command(
            verb: .breathe,
            rawInput: "breathe"
        )
        let context = ActionContext(command: command, engine: engine)

        let result = try await handler.process(context: context)

        // Should have a message
        #expect(result.message != nil)

        // Message should be one of the expected breathe responses
        let expectedResponses = [
            "You breathe in deeply, feeling refreshed.",
            "You take a slow, calming breath.",
            "The air fills your lungs. You're glad that you can breathe.",
            "You inhale deeply, then exhale slowly.",
            "You breathe in the love... and blow out the jive.",
        ]

        #expect(expectedResponses.contains(result.message!))
    }

    @Test("CRY command uses MessageProvider for responses")
    func testCryUsesMessageProvider() async throws {
        let engine = await createEngine()
        let handler = CryActionHandler()
        let command = Command(
            verb: .cry,
            rawInput: "cry"
        )
        let context = ActionContext(command: command, engine: engine)

        let result = try await handler.process(context: context)

        // Should have a message
        #expect(result.message != nil)

        // Message should be one of the expected cry responses
        let expectedResponses = [
            "You shed a tear for the futility of it all.",
            "You weep quietly to yourself.",
            "You sob dramatically, and feel a little better.",
            "You cry a bit. There, there now.",
            "You bawl your eyes out, which is somewhat cathartic.",
            "You weep with the passion of a thousand sorrows.",
            "You cry like a baby. How embarrassing.",
            "You shed crocodile tears. Very convincing.",
            "You weep bitter tears.",
            "You break down and cry. After a bit the world seems a little brighter.",
        ]

        #expect(expectedResponses.contains(result.message!))
    }

    @Test("DANCE command uses MessageProvider for responses")
    func testDanceUsesMessageProvider() async throws {
        let engine = await createEngine()
        let handler = DanceActionHandler()
        let command = Command(
            verb: .dance,
            rawInput: "dance"
        )
        let context = ActionContext(command: command, engine: engine)

        let result = try await handler.process(context: context)

        // Should have a message
        #expect(result.message != nil)

        // Message should be one of the expected dance responses
        let expectedResponses = [
            "Dancing is forbidden.",
            "You dance an adorable little jig.",
            "You boogie down with surprising grace.",
            "You perform a modern interpretive dance.",
            "You dance like nobody's watching (which they aren't).",
            "You cut a rug with style and panache.",
            "You dance the dance of your people.",
            "You waltz around the area with imaginary partners.",
            "You break into spontaneous choreography.",
            "You dance with wild abandon. Bravo!",
            "Let all the children boogie.",
        ]

        #expect(expectedResponses.contains(result.message!))
    }

    // MARK: - Validation Error Tests

    @Test("BREATHE with object uses MessageProvider for error")
    func testBreatheWithObjectError() async throws {
        let engine = await createEngine()
        let handler = BreatheActionHandler()
        let command = Command(
            verb: .breathe,
            directObject: .item("sword"),
            rawInput: "breathe"
        )
        let context = ActionContext(command: command, engine: engine)

        await #expect(throws: ActionResponse.self) {
            try await handler.validate(context: context)
        }

        // The error should use a MessageProvider message
        do {
            try await handler.validate(context: context)
        } catch let error as ActionResponse {
            if case .prerequisiteNotMet(let message) = error {
                #expect(message == "You can't breathe that.")
            } else {
                Issue.record("Expected prerequisiteNotMet error")
            }
        }
    }

    @Test("ATTACK without object uses MessageProvider for error")
    func testAttackWithoutObjectError() async throws {
        let engine = await createEngine()
        let handler = AttackActionHandler()
        let command = Command(
            verb: .attack,
            rawInput: "attack"
        )
        let context = ActionContext(command: command, engine: engine)

        await #expect(throws: ActionResponse.self) {
            try await handler.validate(context: context)
        }

        // The error should use the MessageProvider message
        do {
            try await handler.validate(context: context)
        } catch let error as ActionResponse {
            if case .prerequisiteNotMet(let message) = error {
                #expect(message == "Attack what?")
            } else {
                Issue.record("Expected prerequisiteNotMet error")
            }
        }
    }

    // MARK: - Complex Action Tests

    @Test("CHOMP without object uses MessageProvider for random response")
    func testChompWithoutObject() async throws {
        let engine = await createEngine()
        let handler = ChompActionHandler()
        let command = Command(
            verb: .chomp,
            rawInput: "chomp"
        )
        let context = ActionContext(command: command, engine: engine)

        let result = try await handler.process(context: context)

        // Should have a message
        #expect(result.message != nil)

        // Message should be one of the expected chomp responses
        let expectedResponses = [
            "You chomp your teeth together menacingly.",
            "You clench your fists and gnash your teeth.",
            "You chomp at the air for everyone to see.",
            "Sounds of your chomping echo around you.",
            "You practice your chomping technique.",
            "It feels good to get some chomping done.",
        ]

        #expect(expectedResponses.contains(result.message!))
    }

    @Test("CHOMP on edible item uses MessageProvider")
    func testChompOnEdibleItem() async throws {
        let engine = await createEngine()
        let handler = ChompActionHandler()
        let command = Command(
            verb: .chomp,
            directObject: .item("food"),
            rawInput: "chomp"
        )
        let context = ActionContext(command: command, engine: engine)

        let result = try await handler.process(context: context)

        // Should have a message about eating
        #expect(result.message != nil)
        #expect(result.message == "You take a bite. It tastes like bread.")
    }

    @Test("ATTACK non-character uses MessageProvider response")
    func testAttackNonCharacter() async throws {
        let engine = await createEngine()
        let handler = AttackActionHandler()
        let command = Command(
            verb: .attack,
            directObject: .item(
                "box"
            ),
            rawInput: "attack"
        )
        let context = ActionContext(command: command, engine: engine)

        let result = try await handler.process(context: context)

        // Should use the MessageProvider response for attacking non-character
        #expect(result.message == "I've known strange people, but fighting a box?")
    }

    @Test("ATTACK character with bare hands uses MessageProvider response")
    func testAttackCharacterBareHands() async throws {
        let engine = await createEngine()
        let handler = AttackActionHandler()
        let command = Command(
            verb: .attack,
            directObject: .item(
                "guard"
            ),
            rawInput: "attack"
        )
        let context = ActionContext(command: command, engine: engine)

        let result = try await handler.process(context: context)

        // Should use the MessageProvider response for bare hands attack
        #expect(result.message == "Trying to attack a guard with your bare hands is suicidal.")
    }

    // MARK: - Burning Tests

    @Test("BURN without object uses MessageProvider for error")
    func testBurnWithoutObject() async throws {
        let engine = await createEngine()
        let handler = BurnActionHandler()
        let command = Command(
            verb: .burn,
            rawInput: "burn"
        )
        let context = ActionContext(command: command, engine: engine)

        await #expect(throws: ActionResponse.self) {
            try await handler.validate(context: context)
        }

        do {
            try await handler.validate(context: context)
        } catch let error as ActionResponse {
            if case .prerequisiteNotMet(let message) = error {
                #expect(message == "Burn what?")
            } else {
                Issue.record("Expected prerequisiteNotMet error")
            }
        }
    }

    // MARK: - Cutting Tests

    @Test("CUT without object uses MessageProvider for error")
    func testCutWithoutObject() async throws {
        let engine = await createEngine()
        let handler = CutActionHandler()
        let command = Command(
            verb: .cut,
            rawInput: "cut"
        )
        let context = ActionContext(command: command, engine: engine)

        await #expect(throws: ActionResponse.self) {
            try await handler.validate(context: context)
        }

        do {
            try await handler.validate(context: context)
        } catch let error as ActionResponse {
            if case .prerequisiteNotMet(let message) = error {
                #expect(message == "Cut what?")
            } else {
                Issue.record("Expected prerequisiteNotMet error")
            }
        }
    }

    // MARK: - Climbing Tests

    @Test("CLIMB without object uses MessageProvider for error")
    func testClimbWithoutObject() async throws {
        let engine = await createEngine()
        let handler = ClimbActionHandler()
        let command = Command(
            verb: .climb,
            rawInput: "climb"
        )
        let context = ActionContext(command: command, engine: engine)

        let result = try await handler.process(context: context)

        // Should return the MessageProvider message for "Climb what?"
        #expect(result.message == "Climb what?")
    }

    @Test("CLIMB climbable item uses MessageProvider for success")
    func testClimbClimbableItem() async throws {
        let engine = await createEngine()
        let handler = ClimbActionHandler()
        let command = Command(
            verb: .climb,
            directObject: .item(
                "rope"
            ),
            rawInput: "climb"
        )
        let context = ActionContext(command: command, engine: engine)

        let result = try await handler.process(context: context)

        // Should use MessageProvider for success message
        #expect(result.message == "You climb the rope.")
    }

    @Test("CLIMB non-climbable item uses MessageProvider for failure")
    func testClimbNonClimbableItem() async throws {
        let engine = await createEngine()
        let handler = ClimbActionHandler()
        let command = Command(
            verb: .climb,
            directObject: .item(
                "sword"
            ),
            rawInput: "climb"
        )
        let context = ActionContext(command: command, engine: engine)

        let result = try await handler.process(context: context)

        // Should use MessageProvider for failure message
        #expect(result.message == "You can't climb the sword.")
    }

    // MARK: - Curse Tests

    @Test("CURSE without object uses MessageProvider for random response")
    func testCurseWithoutObject() async throws {
        let engine = await createEngine()
        let handler = CurseActionHandler()
        let command = Command(
            verb: .curse,
            rawInput: "curse"
        )
        let context = ActionContext(command: command, engine: engine)

        let result = try await handler.process(context: context)

        // Should have a message
        #expect(result.message != nil)

        // Message should be one of the expected curse responses
        let expectedResponses = [
            "You curse under your breath.",
            "You let out a string of colorful expletives.",
            "You swear like a sailor. Very cathartic.",
            "You curse the fates that brought you here.",
            "You damn everything in sight. You feel better now.",
            "You use language that would make your mother wash your mouth out with soap.",
            "You curse fluently in several languages.",
            "You swear with the passion of a thousand frustrated adventurers.",
        ]

        #expect(expectedResponses.contains(result.message!))
    }

    @Test("CURSE with object uses MessageProvider for targeted response")
    func testCurseWithObject() async throws {
        let engine = await createEngine()
        let handler = CurseActionHandler()
        let command = Command(
            verb: .curse,
            directObject: .item(
                "sword"
            ),
            rawInput: "curse"
        )
        let context = ActionContext(command: command, engine: engine)

        let result = try await handler.process(context: context)

        // Should have a message that contains the item name
        #expect(result.message != nil)
        #expect(result.message!.contains("sword"))

        // Should be one of the expected targeted responses
        let expectedPatterns = [
            "You curse sword roundly. You feel a bit better.",
            "You let loose a string of expletives at sword.",
            "You damn sword to the seven hells.",
            "You swear colorfully at sword. How therapeutic!",
            "You curse sword with words that would make a sailor blush.",
        ]

        #expect(expectedPatterns.contains(result.message!))
    }

    // MARK: - MessageProvider Context Tests

    @Test("ActionContext.message() works correctly")
    func testActionContextMessage() async throws {
        let engine = await createEngine()
        let command = Command(
            verb: .take,
            directObject: .item(
                "sword"
            ),
            rawInput: "take"
        )
        let context = ActionContext(command: command, engine: engine)

        let message = context.message.taken()
        #expect(message == "Taken.")

        let customMessage = context.message.attackWhat()
        #expect(customMessage == "Attack what?")
    }

    // MARK: - Integration Tests

    @Test("Multiple atmospheric commands maintain variety")
    func testMultipleAtmosphericCommandsVariety() async throws {
        let engine = await createEngine()
        let handler = DanceActionHandler()
        let command = Command(
            verb: .dance,
            rawInput: "dance"
        )
        let context = ActionContext(command: command, engine: engine)

        var responses = Set<String>()

        // Execute dance command multiple times
        for _ in 0..<20 {
            let result = try await handler.process(context: context)
            if let message = result.message {
                responses.insert(message)
            }
        }

        // Should get variety in responses (not always the same one)
        #expect(responses.count > 1, "Should get variety in dance responses")
    }
}
