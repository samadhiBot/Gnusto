import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

struct StandardParserTests {

    @Test("Parse Empty Input")
    func testParseEmpty() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)
        let parser = StandardParser()

        // When/Then - Empty string
        let result1 = try await parser.parse(
            input: "",
            vocabulary: engine.vocabulary,
            engine: engine
        )
        expectNoDifference(result1, .failure(.emptyInput))

        // When/Then - Whitespace only
        let result2 = try await parser.parse(
            input: "   \t ",
            vocabulary: engine.vocabulary,
            engine: engine
        )
        expectNoDifference(result2, .failure(.emptyInput))

        // When/Then - Noise words only
        let result3 = try await parser.parse(
            input: "the the the",
            vocabulary: engine.vocabulary,
            engine: engine
        )
        expectNoDifference(result3, .failure(.emptyInput))
    }

    @Test("Parse Unknown Verb")
    func testParseUnknownVerb() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)
        let parser = StandardParser()

        // When/Then - Unknown verb
        let result1 = try await parser.parse(
            input: "qwerty",
            vocabulary: engine.vocabulary,
            engine: engine
        )
        expectNoDifference(result1, .failure(.verbUnknown("qwerty")))

        // When/Then - Unknown verb with noise
        let result2 = try await parser.parse(
            input: "the qwerty the",
            vocabulary: engine.vocabulary,
            engine: engine
        )
        expectNoDifference(result2, .failure(.verbUnknown("qwerty")))
    }

    @Test("Parse Simple Verb - Known")
    func testParseSimpleVerbKnown() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)
        let parser = StandardParser()

        // When/Then - LOOK command
        let lookResult = try await parser.parse(
            input: "look",
            vocabulary: engine.vocabulary,
            engine: engine
        )
        let lookCommand = try lookResult.get()
        #expect(lookCommand.verb == .look)
        #expect(lookCommand.directObject == nil)
        #expect(lookCommand.indirectObject == nil)
        #expect(lookCommand.rawInput == "look")

        // When/Then - L command (abbreviation)
        let lResult = try await parser.parse(
            input: "l",
            vocabulary: engine.vocabulary,
            engine: engine
        )
        let lCommand = try lResult.get()
        #expect(lCommand.verb == .l)
        #expect(lCommand.directObject == nil)
        #expect(lCommand.indirectObject == nil)
        #expect(lCommand.rawInput == "l")
    }

    @Test("Parse Simple Verb - Synonym")
    func testParseSimpleVerbSynonym() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)
        let parser = StandardParser()

        // When/Then - "get" is a synonym for "take"
        let result = try await parser.parse(
            input: "get",
            vocabulary: engine.vocabulary,
            engine: engine
        )
        let command = try result.get()
        #expect(command.verb == .get)
        #expect(command.directObject == nil)
        #expect(command.indirectObject == nil)
        #expect(command.rawInput == "get")
    }

    @Test("Parse Verb + Direct Object")
    func testParseVerbDirectObject() async throws {
        // Given
        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .adjectives("brass"),
            .in(.startRoom),
            .isTakable
        )

        let game = MinimalGame(
            items: lamp
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let parser = StandardParser()

        // When/Then - Simple direct object
        let result = try await parser.parse(
            input: "take lamp",
            vocabulary: engine.vocabulary,
            engine: engine
        )
        let command = try result.get()
        let lampProxy = try await lamp.proxy(engine)
        #expect(command.verb == .take)
        #expect(command.directObject == .item(lampProxy))
        #expect(command.indirectObject == nil)
        #expect(command.rawInput == "take lamp")
    }

    @Test("Parse Verb + Direct Object + Modifiers")
    func testParseVerbDirectObjectMods() async throws {
        // Given
        let lamp1 = Item(
            id: "lamp1",
            .name("brass lamp"),
            .adjectives("brass"),
            .in(.startRoom),
            .isTakable
        )

        let lamp2 = Item(
            id: "lamp2",
            .name("silver lamp"),
            .adjectives("silver"),
            .in(.startRoom),
            .isTakable
        )

        let game = MinimalGame(
            items: lamp1, lamp2
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let parser = StandardParser()

        // When/Then - Specific lamp with modifier
        let result = try await parser.parse(
            input: "get the brass lamp",
            vocabulary: engine.vocabulary,
            engine: engine
        )
        let command = try result.get()
        let lamp1Proxy = try await lamp1.proxy(engine)

        expectNoDifference(
            command,
            Command(
                verb: .get,
                directObject: .item(lamp1Proxy),
                rawInput: "get the brass lamp"
            )
        )
    }

    @Test("Parse Verb + Direct + Preposition + Indirect")
    func testParseVerbDirectPrepIndirect() async throws {
        // Given
        let key = Item(
            id: "key",
            .name("small key"),
            .adjectives("small"),
            .in(.player),
            .isTakable
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .adjectives("wooden"),
            .in(.startRoom),
            .isContainer
        )

        let game = MinimalGame(
            items: key, box
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let parser = StandardParser()

        // When/Then - Put key in box
        let result = try await parser.parse(
            input: "put key in box",
            vocabulary: engine.vocabulary,
            engine: engine
        )
        let command = try result.get()
        let keyProxy = try await key.proxy(engine)
        let boxProxy = try await box.proxy(engine)
        #expect(command.verb == .put)
        #expect(command.directObject == .item(keyProxy))
        #expect(command.indirectObject == .item(boxProxy))
        #expect(command.preposition == .in)
        #expect(command.rawInput == "put key in box")
    }

    @Test("Parse Object Not In Scope")
    func testParseObjectNotInScope() async throws {
        // Given
        let hiddenItem = Item(
            id: "hidden",
            .name("hidden item"),
            .in(.nowhere),
            .isTakable
        )

        let game = MinimalGame(
            items: hiddenItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let parser = StandardParser()

        // When/Then - Try to take hidden item
        let result = try await parser.parse(
            input: "take hidden item",
            vocabulary: engine.vocabulary,
            engine: engine
        )

        // Should fail with item not in scope
        guard case .success = result else {
            Issue.record("Expected success")
            return
        }
    }

    @Test("Parse Ambiguous Object Reference")
    func testParseAmbiguousObjectReference() async throws {
        // Given
        let lamp1 = Item(
            id: "lamp1",
            .name("brass lamp"),
            .adjectives("brass"),
            .in(.startRoom),
            .isTakable
        )

        let lamp2 = Item(
            id: "lamp2",
            .name("silver lamp"),
            .adjectives("silver"),
            .in(.startRoom),
            .isTakable
        )

        let game = MinimalGame(
            items: lamp1, lamp2
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let parser = StandardParser()

        // When/Then - "lamp" is ambiguous
        let result = try await parser.parse(
            input: "take lamp",
            vocabulary: engine.vocabulary,
            engine: engine
        )

        // Should fail with ambiguity
        #expect(result.isFailure)
        if case .failure(let error) = result {
            #expect(error.isAmbiguityError)
        }
    }
}

// Add helper extensions for error checking
extension ParseError {
    var isAmbiguityError: Bool {
        switch self {
        case .ambiguity, .ambiguousObjectReference, .ambiguousReference:
            return true
        default:
            return false
        }
    }

    var isResolutionError: Bool {
        switch self {
        case .itemNotInScope, .modifierMismatch:
            return true
        default:
            return false
        }
    }
}

extension Result where Success == Command, Failure == ParseError {
    var isFailure: Bool {
        switch self {
        case .failure:
            return true
        case .success:
            return false
        }
    }
}
