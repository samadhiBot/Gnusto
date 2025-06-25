import Testing
import CustomDump
@testable import GnustoEngine

@Suite("CutActionHandler Tests")
struct CutActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CUT DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testCutWithToolSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rope = Item(
            id: "rope",
            .name("length of rope"),
            .in(.location("testRoom"))
        )

        let knife = Item(
            id: "knife",
            .name("sharp knife"),
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rope, knife
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut rope with knife")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cut rope with knife
            You can't cut the length of rope with the sharp knife.
            """)
    }

    @Test("SLICE DIRECTOBJECT syntax works")
    func testSliceSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bread = Item(
            id: "bread",
            .name("loaf of bread"),
            .in(.location("testRoom"))
        )

        let knife = Item(
            id: "knife",
            .name("sharp knife"),
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bread, knife
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("slice bread")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > slice bread
            You need a tool to do that.
            """)
    }

    @Test("PRUNE DIRECTOBJECT syntax works")
    func testPruneSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bushes = Item(
            id: "bushes",
            .name("some bushes"),
            .in(.location("testRoom"))
        )

        let shears = Item(
            id: "shears",
            .name("some shears"),
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bushes, shears
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("prune bushes with shears")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > prune bushes with shears
            You can't cut the some bushes with the some shears.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot cut without specifying target")
    func testCannotCutWithoutTarget() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cut
            What do you want to cut?
            """)
    }

    @Test("Cannot cut item not in scope")
    func testCannotCutItemNotInScope() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteRope = Item(
            id: "remoteRope",
            .name("remote rope"),
            .in(.location("anotherRoom"))
        )

        let knife = Item(
            id: "knife",
            .name("sharp knife"),
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteRope, knife
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut rope with knife")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cut rope with knife
            You can't see any such thing.
            """)
    }

    @Test("Cannot cut with tool not held")
    func testCannotCutWithToolNotHeld() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rope = Item(
            id: "rope",
            .name("length of rope"),
            .in(.location("testRoom"))
        )

        let knife = Item(
            id: "knife",
            .name("sharp knife"),
            .in(.location("testRoom")) // Note: not held by player
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rope, knife
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut rope with knife")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cut rope with knife
            You need to be holding the sharp knife to use it.
            """)
    }

    @Test("Requires light to cut items")
    func testRequiresLight() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let rope = Item(
            id: "rope",
            .name("length of rope"),
            .in(.location("darkRoom"))
        )

        let knife = Item(
            id: "knife",
            .name("sharp knife"),
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: rope, knife
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut rope with knife")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cut rope with knife
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = CutActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = CutActionHandler()
        #expect(handler.verbs.contains(.cut))
        #expect(handler.verbs.contains(.slice))
        #expect(handler.verbs.contains(.prune))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = CutActionHandler()
        #expect(handler.requiresLight == true)
    }
}
