import Testing
import CustomDump
@testable import GnustoEngine

@Suite("CutActionHandler Tests")
struct CutActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CUT DIRECTOBJECT syntax works")
    func testCutDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let rope = Item(
            id: "rope",
            .name("thick rope"),
            .description("A thick rope."),
            .in(.location("testRoom"))
        )

        let knife = Item(
            id: "knife",
            .name("sharp knife"),
            .description("A sharp kitchen knife."),
            .isWeapon,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rope, knife
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cut rope
            You cut the thick rope with the sharp knife.
            """)

        let finalState = try await engine.item("rope")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("CUT DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testCutWithToolSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let paper = Item(
            id: "paper",
            .name("piece of paper"),
            .description("A piece of paper."),
            .in(.location("testRoom"))
        )

        let scissors = Item(
            id: "scissors",
            .name("sharp scissors"),
            .description("A pair of sharp scissors."),
            .isTool,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: paper, scissors
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut paper with scissors")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cut paper with scissors
            You cut the piece of paper with the sharp scissors.
            """)
    }

    @Test("SLICE syntax works")
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
            .description("A fresh loaf of bread."),
            .in(.location("testRoom"))
        )

        let knife = Item(
            id: "knife",
            .name("bread knife"),
            .description("A serrated bread knife."),
            .isWeapon,
            .isTakable,
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
            You cut the loaf of bread with the bread knife.
            """)
    }

    @Test("CHOP syntax works")
    func testChopSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let wood = Item(
            id: "wood",
            .name("piece of wood"),
            .description("A piece of wood."),
            .in(.location("testRoom"))
        )

        let axe = Item(
            id: "axe",
            .name("sharp axe"),
            .description("A sharp woodcutting axe."),
            .isTool,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: wood, axe
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("chop wood")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chop wood
            You cut the piece of wood with the sharp axe.
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
            Cut what?
            """)
    }

    @Test("Cannot cut target not in scope")
    func testCannotCutTargetNotInScope() async throws {
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
            .description("A rope in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteRope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cut rope
            You can’t see any such thing.
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
            .name("thick rope"),
            .description("A thick rope."),
            .in(.location("testRoom"))
        )

        let knife = Item(
            id: "knife",
            .name("sharp knife"),
            .description("A sharp knife."),
            .isWeapon,
            .isTakable,
            .in(.location("testRoom"))
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
            You aren’t holding the sharp knife.
            """)
    }

    @Test("Requires light to cut")
    func testRequiresLight() async throws {
        // Given: Dark room with an item to cut
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let rope = Item(
            id: "rope",
            .name("thick rope"),
            .description("A thick rope."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cut rope
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Cut with appropriate weapon")
    func testCutWithAppropriateWeapon() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let fabric = Item(
            id: "fabric",
            .name("piece of fabric"),
            .description("A piece of fabric."),
            .in(.location("testRoom"))
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A sharp steel sword."),
            .isWeapon,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: fabric, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut fabric with sword")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cut fabric with sword
            You cut the piece of fabric with the steel sword.
            """)

        let finalState = try await engine.item("fabric")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Cut with inappropriate tool")
    func testCutWithInappropriateTool() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rope = Item(
            id: "rope",
            .name("thick rope"),
            .description("A thick rope."),
            .in(.location("testRoom"))
        )

        let spoon = Item(
            id: "spoon",
            .name("wooden spoon"),
            .description("A wooden spoon."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rope, spoon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut rope with spoon")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cut rope with spoon
            The wooden spoon is not sharp enough to cut with.
            """)
    }

    @Test("Cut without tool when no cutting implements available")
    func testCutWithoutToolNoCuttingImplements() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rope = Item(
            id: "rope",
            .name("thick rope"),
            .description("A thick rope."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cut rope
            You have no suitable cutting tool.
            """)
    }

    @Test("Cut without tool but with cutting implements in inventory")
    func testCutWithoutToolButWithCuttingImplements() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rope = Item(
            id: "rope",
            .name("thick rope"),
            .description("A thick rope."),
            .in(.location("testRoom"))
        )

        let knife = Item(
            id: "knife",
            .name("sharp knife"),
            .description("A sharp knife."),
            .isWeapon,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rope, knife
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cut rope
            You cut the thick rope with the sharp knife.
            """)
    }

    @Test("Cutting sets isTouched flag")
    func testCuttingSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let string = Item(
            id: "string",
            .name("piece of string"),
            .description("A piece of string."),
            .in(.location("testRoom"))
        )

        let knife = Item(
            id: "knife",
            .name("utility knife"),
            .description("A sharp utility knife."),
            .isWeapon,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: string, knife
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut string")

        // Then
        let finalState = try await engine.item("string")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = CutActionHandler()
        // CutActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = CutActionHandler()
        #expect(handler.verbs.contains(.cut))
        #expect(handler.verbs.contains(.slice))
        #expect(handler.verbs.contains(.chop))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = CutActionHandler()
        #expect(handler.requiresLight == true)
    }
}
