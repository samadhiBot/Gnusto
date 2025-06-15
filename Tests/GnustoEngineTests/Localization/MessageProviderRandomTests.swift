import Testing

@testable import GnustoEngine

/// Tests for the MessageProvider random message selection functionality.
@MainActor
struct MessageProviderRandomTests {

    // MARK: - Test Data

    private let multilineMessage = """
        First response option
        Second response option
        Third response option
        Fourth response option
        """

    private let singleLineMessage = "Single response"

    private let emptyMessage = ""

    private let messageWithEmptyLines = """
        First option

        Second option


        Third option
        """

    // MARK: - Random Selection Tests

    @Test("Random selection from multiline message returns valid option")
    func testRandomSelectionFromMultilineMessage() async throws {
        let provider = StandardMessageProvider()
        var rng = SystemRandomNumberGenerator()

        let possibleResponses = [
            "First response option",
            "Second response option",
            "Third response option",
            "Fourth response option",
        ]

        // Test multiple selections to ensure randomness works
        var selectedMessages = Set<String>()
        for _ in 0..<20 {
            let selected = provider.selectRandomLine(from: multilineMessage, using: &rng)
            selectedMessages.insert(selected)
            #expect(possibleResponses.contains(selected))
        }

        // With 20 iterations, we should get some variety (not always the same message)
        #expect(selectedMessages.count > 1)
    }

    @Test("Random selection from single line returns that line")
    func testRandomSelectionFromSingleLine() async throws {
        let provider = StandardMessageProvider()
        var rng = SystemRandomNumberGenerator()

        let selected = provider.selectRandomLine(from: singleLineMessage, using: &rng)
        #expect(selected == "Single response")
    }

    @Test("Random selection from empty message returns empty string")
    func testRandomSelectionFromEmptyMessage() async throws {
        let provider = StandardMessageProvider()
        var rng = SystemRandomNumberGenerator()

        let selected = provider.selectRandomLine(from: emptyMessage, using: &rng)
        #expect(selected.isEmpty)
    }

    @Test("Random selection filters out empty lines")
    func testRandomSelectionFiltersEmptyLines() async throws {
        let provider = StandardMessageProvider()
        var rng = SystemRandomNumberGenerator()

        let possibleResponses = [
            "First option",
            "Second option",
            "Third option",
        ]

        // Test multiple selections
        for _ in 0..<10 {
            let selected = provider.selectRandomLine(from: messageWithEmptyLines, using: &rng)
            #expect(possibleResponses.contains(selected))
            #expect(!selected.isEmpty)
        }
    }

    // MARK: - GameEngine Integration Tests

    @Test("GameEngine randomMessage handles single-line messages")
    func testGameEngineRandomMessageSingleLine() async throws {
        let game = MinimalGame()
        let mockIO = MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let message = await taken)
        #expect(message == "Taken.")
    }

    @Test("GameEngine randomMessage handles multi-line messages")
    func testGameEngineRandomMessageMultiLine() async throws {
        let game = MinimalGame()
        let mockIO = MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let possibleResponses = [
            "You breathe in deeply, feeling refreshed.",
            "You take a slow, calming breath.",
            "The air fills your lungs. You're glad that you can breathe.",
            "You inhale deeply, then exhale slowly.",
            "You breathe in the love... and blow out the jive.",
        ]

        // Test multiple calls to ensure we get valid responses
        var selectedMessages = Set<String>()
        for _ in 0..<20 {
            let message = await breatheResponses)
            selectedMessages.insert(message)
            #expect(possibleResponses.contains(message))
        }

        // Should get some variety
        #expect(selectedMessages.count > 1)
    }

    @Test("GameEngine randomMessage handles curse responses with parameters")
    func testGameEngineRandomMessageWithParameters() async throws {
        let game = MinimalGame()
        let mockIO = MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let itemName = "the rusty sword"
        let message = await curseTargetResponses(item: itemName))

        // Should contain the item name
        #expect(message.contains(itemName))

        // Should be one of the expected patterns
        let expectedPatterns = [
            "You curse \(itemName) roundly. You feel a bit better.",
            "You let loose a string of expletives at \(itemName).",
            "You damn \(itemName) to the seven hells.",
            "You swear colorfully at \(itemName). How therapeutic!",
            "You curse \(itemName) with words that would make a sailor blush.",
        ]

        #expect(expectedPatterns.contains(message))
    }

    // MARK: - Message Consistency Tests

    @Test("All atmospheric response messages are properly formatted")
    func testAtmosphericMessageFormatting() async throws {
        let provider = StandardMessageProvider()

        let atmosphericKeys: [MessageKey] = [
            .breatheResponses,
            .cryResponses,
            .danceResponses,
            .chompResponses,
            .curseResponses,
        ]

        for key in atmosphericKeys {
            let message = provider.message(for: key)
            let lines = message.split(separator: "\n", omittingEmptySubsequences: true)

            // Should have multiple options
            #expect(lines.count > 1, "Key \(key) should have multiple response options")

            // Each line should be non-empty when trimmed
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                #expect(!trimmed.isEmpty, "All response options should be non-empty")
            }
        }
    }

    @Test("Parameterized atmospheric messages work correctly")
    func testParameterizedAtmosphericMessages() async throws {
        let provider = StandardMessageProvider()
        let testItem = "the magical orb"

        let message = provider.message(for: .chompTargetResponses(item: testItem))
        let lines = message.split(separator: "\n", omittingEmptySubsequences: true)

        #expect(lines.count > 1)

        // Each line should contain the item name
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            #expect(
                trimmed.contains(testItem),
                "Response '\(trimmed)' should contain item name '\(testItem)'")
        }
    }

    // MARK: - Deterministic Behavior Tests

    @Test("Same seed produces same random selection")
    func testDeterministicRandomSelection() async throws {
        let provider = StandardMessageProvider()

        // Use a seeded generator for deterministic results
        struct SeededRNG: RandomNumberGenerator {
            var state: UInt64

            init(seed: UInt64) {
                self.state = seed
            }

            mutating func next() -> UInt64 {
                state = state &* 1_103_515_245 &+ 12345
                return state
            }
        }

        var rng1 = SeededRNG(seed: 12345)
        var rng2 = SeededRNG(seed: 12345)

        let selection1 = provider.selectRandomLine(from: multilineMessage, using: &rng1)
        let selection2 = provider.selectRandomLine(from: multilineMessage, using: &rng2)

        #expect(selection1 == selection2, "Same seed should produce same selection")
    }
}
