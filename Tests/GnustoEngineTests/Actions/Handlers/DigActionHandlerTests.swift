import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("DigActionHandler Tests")
struct DigActionHandlerTests {

    // MARK: - Syntax Testing

    @Test("DIG syntax works")
    func testDigSyntax() async throws {
        let shovel = Item(
            id: "shovel",
            .name("shovel"),
            .description("A sturdy shovel."),
            .isTakable,
            .isTool,
            .in(.player)
        )

        let game = MinimalGame(
            items: shovel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("dig")

        await mockIO.expectOutput(
            """
            > dig
            The ground here resists your archaeological ambitions.
            """
        )
    }

    @Test("DIG OBJECT syntax works")
    func testDigObjectSyntax() async throws {
        let mound = Item(
            id: "mound",
            .name("dirt mound"),
            .description("A small mound of dirt."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: mound
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("dig mound")

        await mockIO.expectOutput(
            """
            > dig mound
            The ground here resists your archaeological ambitions.
            """
        )
    }

    @Test("DIG IN OBJECT syntax works")
    func testDigInObjectSyntax() async throws {
        let sand = Item(
            id: "sand",
            .name("sand pile"),
            .description("A small pile of sand."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: sand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("dig in the sand")

        await mockIO.expectOutput(
            """
            > dig in the sand
            The ground here resists your archaeological ambitions.
            """
        )
    }

    @Test("DIG OBJECT WITH TOOL syntax works")
    func testDigObjectWithToolSyntax() async throws {
        let mound = Item(
            id: "mound",
            .name("dirt mound"),
            .description("A small mound of dirt."),
            .in(.startRoom)
        )

        let shovel = Item(
            id: "shovel",
            .name("shovel"),
            .description("A sturdy shovel."),
            .isTakable,
            .isTool,
            .in(.player)
        )

        let game = MinimalGame(
            items: mound, shovel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("dig mound with shovel")

        await mockIO.expectOutput(
            """
            > dig mound with shovel
            The ground here resists your archaeological ambitions.
            """
        )
    }

    @Test("DIG WITH TOOL syntax works")
    func testDigWithToolSyntax() async throws {
        let shovel = Item(
            id: "shovel",
            .name("shovel"),
            .description("A sturdy shovel."),
            .isTakable,
            .isTool,
            .in(.player)
        )

        let game = MinimalGame(
            items: shovel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("dig with shovel")

        await mockIO.expectOutput(
            """
            > dig with shovel
            The ground here resists your archaeological ambitions.
            """
        )
    }

    @Test("EXCAVATE syntax works")
    func testExcavateSyntax() async throws {
        let shovel = Item(
            id: "shovel",
            .name("shovel"),
            .description("A sturdy shovel."),
            .isTakable,
            .isTool,
            .in(.player)
        )

        let game = MinimalGame(
            items: shovel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("excavate with shovel")

        await mockIO.expectOutput(
            """
            > excavate with shovel
            The ground here resists your archaeological ambitions.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Requires light to dig")
    func testRequiresLight() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("dig")

        await mockIO.expectOutput(
            """
            > dig
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    @Test("Cannot dig item not in scope")
    func testCannotDigItemNotInScope() async throws {
        let otherRoom = Location(
            id: "otherRoom",
            .name("Other Room"),
            .inherentlyLit
        )

        let mound = Item(
            id: "mound",
            .name("dirt mound"),
            .description("A small mound of dirt."),
            .in("otherRoom")
        )

        let game = MinimalGame(
            locations: otherRoom,
            items: mound
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("dig mound")

        await mockIO.expectOutput(
            """
            > dig mound
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot dig with tool not held")
    func testCannotDigWithToolNotHeld() async throws {
        let mound = Item(
            id: "mound",
            .name("dirt mound"),
            .description("A small mound of dirt."),
            .in(.startRoom)
        )

        let shovel = Item(
            id: "shovel",
            .name("shovel"),
            .description("A sturdy shovel."),
            .isTakable,
            .isTool,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: mound, shovel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("dig mound with shovel")

        await mockIO.expectOutput(
            """
            > dig mound with shovel
            You aren't holding the shovel.
            """
        )
    }

    @Test("Cannot dig takable items")
    func testCannotDigTakableItems() async throws {
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("dig coin")

        await mockIO.expectOutput(
            """
            > dig coin
            The ground here resists your archaeological ambitions.
            """
        )
    }

    // MARK: - Item Digging Testing

    @Test("Dig item with no tool and no tools in inventory")
    func testDigItemWithNoToolAndNoTools() async throws {
        let mound = Item(
            id: "mound",
            .name("dirt mound"),
            .description("A small mound of dirt."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: mound
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("dig mound")

        await mockIO.expectOutput(
            """
            > dig mound
            The ground here resists your archaeological ambitions.
            """
        )

        // Verify .isTouched flag was set
        let finalMound = await engine.item("mound")
        #expect(await finalMound.hasFlag(.isTouched) == true)
    }

    @Test("Dig item with no tool but tools in inventory")
    func testDigItemWithNoToolButToolsInInventory() async throws {
        let mound = Item(
            id: "mound",
            .name("dirt mound"),
            .description("A small mound of dirt."),
            .in(.startRoom)
        )

        let shovel = Item(
            id: "shovel",
            .name("shovel"),
            .description("A sturdy shovel."),
            .isTakable,
            .isTool,
            .in(.player)
        )

        let game = MinimalGame(
            items: mound, shovel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("dig mound")

        await mockIO.expectOutput(
            """
            > dig mound
            The ground here resists your archaeological ambitions.
            """
        )

        // Verify .isTouched flag was set
        let finalMound = await engine.item("mound")
        #expect(await finalMound.hasFlag(.isTouched) == true)
    }

    @Test("Dig item with tool")
    func testDigItemWithTool() async throws {
        let mound = Item(
            id: "mound",
            .name("dirt mound"),
            .description("A small mound of dirt."),
            .in(.startRoom)
        )

        let shovel = Item(
            id: "shovel",
            .name("shovel"),
            .description("A sturdy shovel."),
            .isTakable,
            .isTool,
            .in(.player)
        )

        let game = MinimalGame(
            items: mound, shovel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("dig mound with shovel")

        await mockIO.expectOutput(
            """
            > dig mound with shovel
            The ground here resists your archaeological ambitions.
            """
        )

        // Verify .isTouched flag was set
        let finalMound = await engine.item("mound")
        #expect(await finalMound.hasFlag(.isTouched) == true)
    }

    // MARK: - Universal Object Digging Testing

    @Test("Dig universal object that's diggable")
    func testDigUniversal() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("dig ground")

        await mockIO.expectOutput(
            """
            > dig ground
            The ground here resists your archaeological ambitions.
            """
        )
    }

    @Test("Cannot dig with universal object as tool")
    func testCannotDigWithUniversalAsTool() async throws {
        let mound = Item(
            id: "mound",
            .name("dirt mound"),
            .description("A small mound of dirt."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: mound
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("dig mound with ground")

        await mockIO.expectOutput(
            """
            > dig mound with ground
            You can't dig the dirt mound with that.
            """
        )
    }

    @Test("Cannot dig unsupported universal object")
    func testCannotDigUnsupportedUniversal() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("dig ceiling")

        await mockIO.expectOutput(
            """
            > dig ceiling
            That defies the fundamental laws of digging.
            """
        )
    }

    // MARK: - State Change Testing

    @Test("Digging item sets touched flag and updates pronouns")
    func testDiggingItemSetsStateChanges() async throws {
        let mound = Item(
            id: "mound",
            .name("dirt mound"),
            .description("A small mound of dirt."),
            .in(.startRoom)
        )

        let shovel = Item(
            id: "shovel",
            .name("shovel"),
            .description("A sturdy shovel."),
            .isTakable,
            .isTool,
            .in(.player)
        )

        let game = MinimalGame(
            items: mound, shovel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify pronouns were updated by trying to reference "it"
        try await engine.execute(
            "dig mound with shovel",
            "examine it"
        )

        await mockIO.expectOutput(
            """
            > dig mound with shovel
            The ground here resists your archaeological ambitions.

            > examine it
            A small mound of dirt.
            """
        )

        // Verify .isTouched flag was set
        let finalMound = await engine.item("mound")
        #expect(await finalMound.hasFlag(.isTouched) == true)
    }

    // MARK: - Error Handling Testing

    @Test("Dig with no argument and no tool throws error")
    func testDigWithNoArgumentAndNoTool() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("dig")

        await mockIO.expectOutput(
            """
            > dig
            The ground here resists your archaeological ambitions.
            """
        )
    }

    // MARK: - Handler Properties Testing

    @Test("Handler exposes correct verbs")
    func testVerbs() async throws {
        let handler = DigActionHandler()
        #expect(handler.synonyms.contains(.dig))
        #expect(handler.synonyms.contains(.excavate))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = DigActionHandler()
        #expect(handler.requiresLight == true)
    }

    @Test("Handler supports diggable universals")
    func testHandlesUniversal() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // When
        try await engine.execute("dig the ground")

        // Then
        await mockIO.expectOutput(
            """
            > dig the ground
            The ground here resists your archaeological ambitions.
            """
        )
    }

    @Test("Handler syntax rules are correct")
    func testSyntaxRules() async throws {
        let handler = DigActionHandler()
        #expect(handler.syntax.count == 5)
        #expect(handler.syntax.contains(.match(.verb)))
        #expect(handler.syntax.contains(.match(.verb, .directObject)))
        #expect(handler.syntax.contains(.match(.verb, .in, .directObject)))
        #expect(handler.syntax.contains(.match(.verb, .directObject, .with, .indirectObject)))
        #expect(handler.syntax.contains(.match(.verb, .with, .indirectObject)))
    }
}
