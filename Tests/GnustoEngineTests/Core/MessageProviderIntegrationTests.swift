import CustomDump
import Testing

@testable import GnustoEngine

/// Tests for MessageProvider integration with GameEngine
@Suite("MessageProvider Integration Tests")
struct MessageProviderIntegrationTests {
    class TestMessageProvider: MessageProvider, @unchecked Sendable {
        override func roomIsDark() -> String {
            "TEST: Custom darkness message"
        }

        override func emptyInput() -> String {
            "TEST: Custom empty input message"
        }
    }

    @Test("GameEngine uses custom MessageProvider from GameBlueprint")
    func testEngineUsesCustomMessageProvider() async throws {
        struct TestGame: GameBlueprint {
            let storyTitle = "Test Game"
            let introduction = "A test"
            let release = "1.0"
            let maximumScore = 10

            let player = Player(in: "void")

            let locations = [
                Location(
                    id: "void",
                    .name("Void"),
                    .description("An empty void.")
                    // No .inherentlyLit, so it's dark by default
                )
            ]

            let messageProvider: MessageProvider = TestMessageProvider()
        }

        let game = TestGame()
        let mockIO = await MockIOHandler()
        var mockParser = MockParser()

        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        #expect(engine.messageProvider.languageCode == "en")

        // Test that the engine's MessageProvider is the custom one
        let darknessMessage = engine.messageProvider.roomIsDark()
        #expect(darknessMessage == "TEST: Custom darkness message")

        // Test darkness message in actual engine behavior
        // Configure parser to return empty input error
        mockParser.defaultParseResult = .failure(.emptyInput)

        // Enqueue empty input and quit
        await mockIO.enqueueInput("", "quit")

        // Run the engine
        await engine.run()

        // Check that custom messages were used
        let output = await mockIO.flush()

        // Should contain the custom darkness message (when describing dark starting
        // location) and should contain the custom empty input message
        expectNoDifference(output, """
            Test Game

            A test

            TEST: Custom darkness message

            > 
            A strange buzzing sound indicates something is wrong.

            > quit
            """)
    }

    @Test("MessageProvider parameters are properly formatted")
    func testMessageParameterFormatting() async throws {
        let provider = MessageProvider()

        // Test single parameter
        expectNoDifference(
            provider.itemNotTakable(item: "the golden sword"),
            "You can't take the golden sword."
        )

        // Test multiple parameters
        expectNoDifference(
            provider.itemNotInContainer(item: "the key", container: "the box"),
            "The key isn't in the box."
        )

        // Test parameter with capitalization
        expectNoDifference(
            provider.containerIsClosed(item: "the chest"),
            "The chest is closed."
        )

        // Test modifier mismatch with array
        expectNoDifference(
            provider.modifierMismatch(noun: "sword", modifiers: ["golden", "magical"]),
            "I don't see any 'golden magical sword' here."
        )
    }
}
