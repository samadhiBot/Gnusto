import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct TasteActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax rule accepts 'taste <item>'")
    func testSyntaxRule() async throws {
        let handler = TasteActionHandler()
        let syntax = try handler.syntax.primary.parse("taste apple")
        #expect(syntax.verb == .taste)
        #expect(syntax.directObject == .item(id: "apple"))
    }

    @Test("Syntax rule accepts synonym 'lick <item>'")
    func testLickSyntaxRule() async throws {
        let handler = TasteActionHandler()
        let syntax = try handler.syntax.synonyms.first!.parse("lick apple")
        #expect(syntax.verb == .taste)
        #expect(syntax.directObject == .item(id: "apple"))
    }

    // MARK: - Validation Testing

    @Test("Validation fails without a direct object")
    func testValidationFailsWithoutDirectObject() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        try await engine.execute("taste")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > taste
            Taste what?
            """)
    }

    @Test("Validation fails for unreachable item")
    func testValidationFailsForUnreachableItem() async throws {
        let apple = Item(id: "apple", .name("an apple"), .in(.location("anotherRoom")))
        let game = MinimalGame.lit(items: apple)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("taste apple")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > taste apple
            You can’t see any apple here.
            """)
    }

    // MARK: - Processing Testing

    @Test("Processing 'taste' returns a generic message")
    func testProcessTasteReturnsMessage() async throws {
        let apple = Item(id: "apple", .name("an apple"), .in(.location("testRoom")))
        let game = MinimalGame.lit(items: apple)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("taste apple")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > taste apple
            That tastes about average.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(TasteActionHandler().actionID == .taste)
    }
}
