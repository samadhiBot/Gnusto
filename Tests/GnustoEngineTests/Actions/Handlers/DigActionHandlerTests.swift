import CustomDump
import Testing

@testable import GnustoEngine

@Suite("DigActionHandler Tests")
struct DigActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("DIG syntax works")
    func testDigSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dig")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > dig
            Dig what?
            """)
    }

    @Test("DIG DIRECTOBJECT syntax works")
    func testDigDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let dirt = Item(
            id: "dirt",
            .name("pile of dirt"),
            .description("A pile of dirt."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: dirt
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dig dirt", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > dig dirt
            You apply your hands to the pile of dirt with results that
            suggest evolution skipped the ‘digging claws’ upgrade.

            > dig dirt
            You dig the pile of dirt with your hands, creating a depression
            that’s more symbolic than functional.

            > dig dirt
            Your fingers explore the pile of dirt with the sort of
            determination that makes proper tools weep.
            """)

        let finalState = try await engine.item("dirt")
        #expect(finalState.hasFlag(.isTouched) == false)
    }

    @Test("DIG DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testDigDirectObjectWithToolSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let ground = Item(
            id: "ground",
            .name("hard ground"),
            .description("Hard packed earth."),
            .in(.location("testRoom"))
        )

        let shovel = Item(
            id: "shovel",
            .name("rusty shovel"),
            .description("A rusty but functional shovel."),
            .isTool,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: ground, shovel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dig ground with shovel")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > dig ground with shovel
            You apply the rusty shovel to the ground with the confident
            determination of someone who believes in the power of
            persistence over physics.
            """)
    }

    @Test("DIG WITH INDIRECTOBJECT syntax works")
    func testDigWithToolSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let ground = Item(
            id: "ground",
            .name("hard ground"),
            .description("Hard packed earth."),
            .in(.location("testRoom"))
        )

        let shovel = Item(
            id: "shovel",
            .name("rusty shovel"),
            .description("A rusty but functional shovel."),
            .isTool,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: ground, shovel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dig with shovel")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > dig with shovel
            You apply the rusty shovel to the ground with the confident
            determination of someone who believes in the power of
            persistence over physics.
            """)
    }

    @Test("EXCAVATE syntax works")
    func testExcavateSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let mound = Item(
            id: "mound",
            .name("small mound"),
            .description("A small mound of earth."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: mound
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("excavate mound")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > excavate mound
            You apply your hands to the small mound with results that
            suggest evolution skipped the ‘digging claws’ upgrade.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot dig target not in scope")
    func testCannotDigTargetNotInScope() async throws {
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

        let remoteDirt = Item(
            id: "remoteDirt",
            .name("remote dirt"),
            .description("Dirt in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteDirt
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dig dirt")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > dig dirt
            You can’t see any such thing.
            """)
    }

    @Test("Cannot dig with tool not held")
    func testCannotDigWithToolNotHeld() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let dirt = Item(
            id: "dirt",
            .name("pile of dirt"),
            .description("A pile of dirt."),
            .in(.location("testRoom"))
        )

        let shovel = Item(
            id: "shovel",
            .name("steel shovel"),
            .description("A steel shovel."),
            .isTool,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: dirt, shovel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dig dirt with shovel")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > dig dirt with shovel
            You aren’t holding the steel shovel.
            """)
    }

    @Test("Requires light to dig")
    func testRequiresLight() async throws {
        // Given: Dark room
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let dirt = Item(
            id: "dirt",
            .name("pile of dirt"),
            .description("A pile of dirt."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: dirt
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dig dirt")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > dig dirt
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Dig takable item gives ineffective message")
    func testTakableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let statue = Item(
            id: "statue",
            .name("ebony statue"),
            .description("An elegant ebony statue."),
            .in(.location("testRoom")),
            .isTakable
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dig ebony statue")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > dig ebony statue
            You can’t dig that.
            """)
    }

    @Test("Dig with bare hands gives ineffective message")
    func testDigWithBareHands() async throws {
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
        try await engine.execute("dig the ground")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > dig the ground
            Digging with your bare hands is ineffective.
            """)
    }

    @Test("Dig with tool suggests using it")
    func testDigWithToolInInventory() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let spade = Item(
            id: "spade",
            .name("garden spade"),
            .description("A garden spade."),
            .isTool,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: spade
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dig the ground")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > dig
            You could try using a tool for digging.
            """)
    }

    @Test("Dig with appropriate tool but no target")
    func testDigWithAppropriateTool() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let shovel = Item(
            id: "shovel",
            .name("metal shovel"),
            .description("A metal shovel."),
            .isTool,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: shovel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dig with shovel")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > dig with shovel
            You dig with the metal shovel, but find nothing of interest.
            """)
    }

    @Test("Dig with inappropriate tool")
    func testDigWithInappropriateTool() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let fork = Item(
            id: "fork",
            .name("dinner fork"),
            .description("A dinner fork."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: fork
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dig with fork")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > dig with fork
            The dinner fork isn’t suitable for digging.
            """)
    }

    @Test("Dig specific object sets touched flag")
    func testDigSpecificObjectSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let sand = Item(
            id: "sand",
            .name("wet sand"),
            .description("Wet sand from the beach."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dig sand")

        // Then: Verify state changes
        let finalState = try await engine.item("sand")
        #expect(finalState.hasFlag(.isTouched) == true)

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > dig sand
            You can’t dig the wet sand.
            """)
    }

    @Test("Dig with tool on specific object")
    func testDigWithToolOnSpecificObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let hole = Item(
            id: "hole",
            .name("shallow hole"),
            .description("A shallow hole in the ground."),
            .in(.location("testRoom"))
        )

        let pickaxe = Item(
            id: "pickaxe",
            .name("heavy pickaxe"),
            .description("A heavy pickaxe."),
            .isTool,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: hole, pickaxe
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dig hole with pickaxe")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > dig hole with pickaxe
            You can’t dig the shallow hole.
            """)

        let finalState = try await engine.item("hole")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Multiple dig attempts with different tools")
    func testMultipleDigAttempts() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let shovel = Item(
            id: "shovel",
            .name("old shovel"),
            .description("An old shovel."),
            .isTool,
            .isTakable,
            .in(.player)
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
            items: shovel, spoon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Dig with appropriate tool
        try await engine.execute("dig with shovel")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > dig with shovel
            You dig with the old shovel, but find nothing of interest.
            """)

        // When: Dig with inappropriate tool
        try await engine.execute("dig with spoon")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > dig with spoon
            The wooden spoon isn’t suitable for digging.
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = DigActionHandler()
        // DigActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = DigActionHandler()
        #expect(handler.verbs.contains(.dig))
        #expect(handler.verbs.contains(.excavate))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = DigActionHandler()
        #expect(handler.requiresLight == true)
    }
}
