import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

struct WaveActionHandlerTests {
    // MARK: - Syntax Tests

    @Test("Wave with direct object but no preposition fails")
    func testWaveDirectObjectRequiresPreposition() async throws {
        let wand = Item("wand")
            .name("magic wand")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: wand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave wand")

        await mockIO.expect(
            """
            > wave wand
            You brandish the magic wand with theatrical enthusiasm.
            """
        )
    }

    @Test("Wave at direct object syntax")
    func testWaveAtDirectObjectSyntax() async throws {
        let wand = Item("wand")
            .name("magic wand")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: wand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave at wand")

        await mockIO.expect(
            """
            > wave at wand
            The magic wand remains unimpressed by your enthusiastic
            gesticulation.
            """
        )
    }

    @Test("Wave to direct object syntax")
    func testWaveToDirectObjectSyntax() async throws {
        let wand = Item("wand")
            .name("magic wand")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: wand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave to wand")

        await mockIO.expect(
            """
            > wave to wand
            The magic wand remains unimpressed by your enthusiastic
            gesticulation.
            """
        )
    }

    @Test("Wave direct object at indirect object syntax")
    func testWaveDirectObjectAtIndirectObjectSyntax() async throws {
        let wand = Item("wand")
            .name("magic wand")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: wand, Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave wand at troll")

        await mockIO.expect(
            """
            > wave wand at troll
            You flourish the magic wand in the general direction of the
            fierce troll.
            """
        )
    }

    @Test("Brandish synonym works")
    func testBrandishSyntax() async throws {
        let sword = Item("sword")
            .name("steel sword")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("brandish at sword")

        await mockIO.expect(
            """
            > brandish at sword
            The steel sword remains unimpressed by your enthusiastic
            gesticulation.
            """
        )
    }

    // MARK: - Error Condition Tests

    @Test("Cannot wave without any target")
    func testCannotWaveWithoutTarget() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave")

        await mockIO.expect(
            """
            > wave
            You wave your hands with theatrical flourish.
            """
        )
    }

    @Test("Cannot wave non-existent item")
    func testCannotWaveNonExistentItem() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave at wand")

        await mockIO.expect(
            """
            > wave at wand
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot wave item not in reach")
    func testCannotWaveItemNotInReach() async throws {
        let wand = Item("wand")
            .name("magic wand")
            .isTakable
            .in("otherRoom")

        let otherRoom = Location("otherRoom")
            .name("Other Room")
            .inherentlyLit

        let game = MinimalGame(
            locations: otherRoom,
            items: wand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave at wand")

        await mockIO.expect(
            """
            > wave at wand
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Requires light to wave")
    func testRequiresLight() async throws {
        let wand = Item("wand")
            .name("magic wand")
            .isTakable
            .in(.player)

        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            // No .inherentlyLit - makes it dark

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: wand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave at wand")

        await mockIO.expect(
            """
            > wave at wand
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Object Type Tests

    @Test("Wave at object gives object response")
    func testWaveAtObject() async throws {
        let box = Item("box")
            .name("wooden box")
            .isTakable
            .in(.player)

        let stone = Item("stone")
            .name("stone")
            .in(.startRoom)

        let game = MinimalGame(
            items: box, stone
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave box at stone")

        await mockIO.expect(
            """
            > wave box at stone
            You flourish the wooden box in the general direction of the
            stone.
            """
        )
    }

    @Test("Wave at character gives character response")
    func testWaveAtCharacter() async throws {
        let wand = Item("wand")
            .name("magic wand")
            .isTakable
            .in(.player)

        let wizard = Item("wizard")
            .name("old wizard")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: wand, wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave wand at wizard")

        await mockIO.expect(
            """
            > wave wand at wizard
            You flourish the magic wand in the general direction of the old
            wizard.
            """
        )
    }

    @Test("Wave at enemy gives enemy response")
    func testWaveAtEnemy() async throws {
        let sword = Item("sword")
            .name("steel sword")
            .isTakable
            .in(.player)

        let dragon = Item("dragon")
            .name("red dragon")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: sword, dragon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave sword at dragon")

        await mockIO.expect(
            """
            > wave sword at dragon
            You flourish the steel sword in the general direction of the
            red dragon.
            """
        )
    }

    @Test("Wave multiple items sequentially")
    func testWaveMultipleItemsSequentially() async throws {
        let wand = Item("wand")
            .name("magic wand")
            .isTakable
            .in(.player)

        let sword = Item("sword")
            .name("steel sword")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: wand, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute(
            "wave at wand",
            "wave at sword"
        )

        await mockIO.expect(
            """
            > wave at wand
            The magic wand remains unimpressed by your enthusiastic
            gesticulation.

            > wave at sword
            You wave at the steel sword, which maintains its steadfast
            inanimacy.
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
