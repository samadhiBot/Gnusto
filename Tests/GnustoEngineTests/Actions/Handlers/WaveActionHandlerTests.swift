import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

struct WaveActionHandlerTests {
    // MARK: - Syntax Tests

    @Test("Wave with direct object but no preposition fails")
    func testWaveDirectObjectRequiresPreposition() async throws {
        let wand = Item(
            id: "wand",
            .name("magic wand"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: wand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave wand")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave wand
            The magic wand cuts through the air in your gesticulating
            grasp.
            """
        )
    }

    @Test("Wave at direct object syntax")
    func testWaveAtDirectObjectSyntax() async throws {
        let wand = Item(
            id: "wand",
            .name("magic wand"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: wand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave at wand")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave at wand
            Your wave passes by the magic wand without acknowledgment or
            effect.
            """
        )
    }

    @Test("Wave to direct object syntax")
    func testWaveToDirectObjectSyntax() async throws {
        let wand = Item(
            id: "wand",
            .name("magic wand"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: wand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave to wand")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave to wand
            Your wave passes by the magic wand without acknowledgment or
            effect.
            """
        )
    }

    @Test("Wave direct object at indirect object syntax")
    func testWaveDirectObjectAtIndirectObjectSyntax() async throws {
        let wand = Item(
            id: "wand",
            .name("magic wand"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: wand, Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave wand at troll")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave wand at troll
            The magic wand describes elaborate patterns as you wave it at
            the fierce troll.
            """
        )
    }

    @Test("Brandish synonym works")
    func testBrandishSyntax() async throws {
        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("brandish at sword")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > brandish at sword
            Your wave passes by the steel sword without acknowledgment or
            effect.
            """
        )
    }

    // MARK: - Error Condition Tests

    @Test("Cannot wave without any target")
    func testCannotWaveWithoutTarget() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave
            Your arms describe meaningless patterns in the air.
            """
        )
    }

    @Test("Cannot wave non-existent item")
    func testCannotWaveNonExistentItem() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave at wand")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave at wand
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Cannot wave item not in reach")
    func testCannotWaveItemNotInReach() async throws {
        let wand = Item(
            id: "wand",
            .name("magic wand"),
            .isTakable,
            .in("otherRoom")
        )

        let otherRoom = Location(
            id: "otherRoom",
            .name("Other Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            locations: otherRoom,
            items: wand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave at wand")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave at wand
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Requires light to wave")
    func testRequiresLight() async throws {
        let wand = Item(
            id: "wand",
            .name("magic wand"),
            .isTakable,
            .in(.player)
        )

        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room")
            // No .inherentlyLit - makes it dark
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: wand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave at wand")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave at wand
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Object Type Tests

    @Test("Wave at object gives object response")
    func testWaveAtObject() async throws {
        let box = Item(
            id: "box",
            .name("wooden box"),
            .isTakable,
            .in(.player)
        )

        let stone = Item(
            id: "stone",
            .name("stone"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: box, stone
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave box at stone")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave box at stone
            The wooden box describes elaborate patterns as you wave it at
            the stone.
            """
        )
    }

    @Test("Wave at character gives character response")
    func testWaveAtCharacter() async throws {
        let wand = Item(
            id: "wand",
            .name("magic wand"),
            .isTakable,
            .in(.player)
        )

        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wand, wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave wand at wizard")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave wand at wizard
            The magic wand describes elaborate patterns as you wave it at
            the old wizard.
            """
        )
    }

    @Test("Wave at enemy gives enemy response")
    func testWaveAtEnemy() async throws {
        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .isTakable,
            .in(.player)
        )

        let dragon = Item(
            id: "dragon",
            .name("red dragon"),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: sword, dragon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave sword at dragon")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave sword at dragon
            The steel sword describes elaborate patterns as you wave it at
            the red dragon.
            """
        )
    }

    @Test("Wave multiple items sequentially")
    func testWaveMultipleItemsSequentially() async throws {
        let wand = Item(
            id: "wand",
            .name("magic wand"),
            .isTakable,
            .in(.player)
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: wand, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute(
            "wave at wand",
            "wave at sword"
        )

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave at wand
            Your wave passes by the magic wand without acknowledgment or
            effect.

            > wave at sword
            The steel sword remains unimpressed by your enthusiastic
            gesticulation.
            """
        )
    }

    // MARK: - Handler Configuration Tests

    @Test("Verbs include wave and brandish")
    func testVerbs() async throws {
        let handler = WaveActionHandler()
        #expect(handler.synonyms.contains(.wave))
        #expect(handler.synonyms.contains(.brandish))
    }

    @Test("Requires light property is true")
    func testRequiresLightProperty() async throws {
        let handler = WaveActionHandler()
        #expect(handler.requiresLight == true)
    }
}
