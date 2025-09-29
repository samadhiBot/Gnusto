import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("CutActionHandler Tests")
struct CutActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CUT DIRECTOBJECT syntax works")
    func testCutDirectObjectSyntax() async throws {
        // Given
        let rope = Item(
            id: "rope",
            .name("thick rope"),
            .description("A thick rope."),
            .in(.startRoom)
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
            items: rope, knife
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut rope")

        // Then
        await mockIO.expectOutput(
            """
            > cut rope
            The thick rope resists division with stubborn integrity.
            """
        )

        let finalState = await engine.item("rope")
        #expect(await finalState.hasFlag(.isTouched) == false)
    }

    @Test("CUT DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testCutWithToolSyntax() async throws {
        // Given
        let paper = Item(
            id: "paper",
            .name("piece of paper"),
            .description("A piece of paper."),
            .in(.startRoom)
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
            items: paper, scissors
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut paper with scissors")

        // Then
        await mockIO.expectOutput(
            """
            > cut paper with scissors
            The piece of paper resists division with stubborn integrity.
            """
        )
    }

    @Test("SLICE syntax works")
    func testSliceSyntax() async throws {
        // Given
        let bread = Item(
            id: "bread",
            .name("loaf of bread"),
            .description("A fresh loaf of bread."),
            .in(.startRoom)
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
            items: bread, knife
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("slice bread")

        // Then
        await mockIO.expectOutput(
            """
            > slice bread
            The loaf of bread resists division with stubborn integrity.
            """
        )
    }

    @Test("CHOP syntax works")
    func testChopSyntax() async throws {
        // Given
        let wood = Item(
            id: "wood",
            .name("piece of wood"),
            .description("A piece of wood."),
            .in(.startRoom)
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
            items: wood, axe
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("chop wood")

        // Then
        await mockIO.expectOutput(
            """
            > chop wood
            The piece of wood resists division with stubborn integrity.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot cut without specifying target")
    func testCannotCutWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut")

        // Then
        await mockIO.expectOutput(
            """
            > cut
            Cut what?
            """
        )
    }

    @Test("Cannot cut target not in scope")
    func testCannotCutTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteRope = Item(
            id: "remoteRope",
            .name("remote rope"),
            .description("A rope in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteRope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut rope")

        // Then
        await mockIO.expectOutput(
            """
            > cut rope
            Any such thing lurks beyond your reach.
            """
        )
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
            .in("darkRoom")
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
        await mockIO.expectOutput(
            """
            > cut rope
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Cutting avoided with variations")
    func testCuttingAvoided() async throws {
        // Given
        let fabric = Item(
            id: "fabric",
            .name("piece of fabric"),
            .description("A piece of fabric."),
            .in(.startRoom)
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
            items: fabric, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut the fabric with the sword")

        // Then
        await mockIO.expectOutput(
            """
            > cut the fabric with the sword
            The piece of fabric resists division with stubborn integrity.
            """
        )

        let finalState = await engine.item("fabric")
        #expect(await finalState.hasFlag(.isTouched) == false)
    }

    @Test("Cut myself denied")
    func testCutMyselfDenied() async throws {
        // Given
        let rope = Item(
            id: "rope",
            .name("thick rope"),
            .description("A thick rope."),
            .in(.startRoom)
        )

        let spoon = Item(
            id: "spoon",
            .name("wooden spoon"),
            .description("A wooden spoon."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: rope, spoon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cut myself")

        // Then
        await mockIO.expectOutput(
            """
            > cut myself
            Self-harm is not the solution to your problems.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = CutActionHandler()
        #expect(handler.synonyms.contains(.cut))
        #expect(handler.synonyms.contains(.slice))
        #expect(handler.synonyms.contains(.chop))
        #expect(handler.synonyms.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = CutActionHandler()
        #expect(handler.requiresLight == true)
    }
}
