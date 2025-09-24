import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("RemoveActionHandler Tests")
struct RemoveActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("REMOVE DIRECTOBJECT syntax works")
    func testRemoveDirectObjectSyntax() async throws {
        // Given
        let hat = Item(
            id: "hat",
            .name("blue hat"),
            .description("A stylish blue hat."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let game = MinimalGame(
            items: hat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: Hat must be worn first
        try await engine.apply(
            hat.proxy(engine).setFlag(.isWorn)
        )

        // When
        try await engine.execute("remove hat")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove hat
            You remove the blue hat.
            """
        )

        let finalState = await engine.item("hat")
        #expect(await finalState.hasFlag(.isWorn) == false)
        #expect(await finalState.hasFlag(.isTouched) == true)
        #expect(await finalState.playerIsHolding)
    }

    @Test("DOFF syntax works")
    func testDoffSyntax() async throws {
        // Given
        let cloak = Item(
            id: "cloak",
            .name("woolen cloak"),
            .description("A warm woolen cloak."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let game = MinimalGame(
            items: cloak
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: Cloak must be worn first
        try await engine.apply(
            cloak.proxy(engine).setFlag(.isWorn)
        )

        // When
        try await engine.execute("doff cloak")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > doff cloak
            You doff the woolen cloak.
            """
        )

        let finalState = await engine.item("cloak")
        #expect(await finalState.hasFlag(.isWorn) == false)
    }

    @Test("TAKE OFF syntax works")
    func testTakeOffSyntax() async throws {
        // Given
        let shoes = Item(
            id: "shoes",
            .name("leather shoes"),
            .description("Comfortable leather shoes."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let game = MinimalGame(
            items: shoes
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: Shoes must be worn first
        try await engine.apply(
            shoes.proxy(engine).setFlag(.isWorn)
        )

        // When
        try await engine.execute("take off shoes")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take off shoes
            You take off the leather shoes.
            """
        )

        let finalState = await engine.item("shoes")
        #expect(await finalState.hasFlag(.isWorn) == false)
    }

    @Test("REMOVE ALL syntax works")
    func testRemoveAllSyntax() async throws {
        // Given
        let hat = Item(
            id: "hat",
            .name("red hat"),
            .description("A bright red hat."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let gloves = Item(
            id: "gloves",
            .name("silk gloves"),
            .description("Elegant silk gloves."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let game = MinimalGame(
            items: hat, gloves
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: Both items must be worn first
        try await engine.apply(
            hat.proxy(engine).setFlag(.isWorn),
            gloves.proxy(engine).setFlag(.isWorn)
        )

        // When
        try await engine.execute("remove all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove all
            You remove the silk gloves and the red hat.
            """
        )

        let finalHat = await engine.item("hat")
        let finalGloves = await engine.item("gloves")
        #expect(await finalHat.hasFlag(.isWorn) == false)
        #expect(await finalGloves.hasFlag(.isWorn) == false)
    }

    // MARK: - Validation Testing

    @Test("Cannot remove without specifying what")
    func testCannotRemoveWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("remove")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove
            Remove what?
            """
        )
    }

    @Test("Cannot remove item not worn")
    func testCannotRemoveItemNotWorn() async throws {
        // Given
        let hat = Item(
            id: "hat",
            .name("blue hat"),
            .description("A stylish blue hat."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let game = MinimalGame(
            items: hat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When (hat is not worn)
        try await engine.execute("remove hat")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove hat
            You aren't wearing the blue hat.
            """
        )
    }

    @Test("Cannot remove non-existent item")
    func testCannotRemoveNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("remove nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove nonexistent
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Cannot remove fixed scenery")
    func testCannotRemoveFixedScenery() async throws {
        // Given
        let fixedItem = Item(
            id: "fixedItem",
            .name("ceremonial robe"),
            .description("A ceremonial robe that cannot be removed."),
            .isWearable,
            .omitDescription,
            .in(.player)
        )

        let game = MinimalGame(
            items: fixedItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: Item must be worn first
        try await engine.apply(
            fixedItem.proxy(engine).setFlag(.isWorn)
        )

        // When
        try await engine.execute("remove robe")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove robe
            The universe denies your request to remove the ceremonial robe.
            """
        )
    }

    @Test("Cannot remove non-item")
    func testCannotRemoveNonItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("remove me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove me
            That's not something you can remove.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Remove single worn item")
    func testRemoveSingleWornItem() async throws {
        // Given
        let jacket = Item(
            id: "jacket",
            .name("leather jacket"),
            .description("A tough leather jacket."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let game = MinimalGame(
            items: jacket
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: Jacket must be worn first
        try await engine.apply(
            jacket.proxy(engine).setFlag(.isWorn)
        )

        // When
        try await engine.execute("remove jacket")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove jacket
            You remove the leather jacket.
            """
        )

        // Verify state changes
        let finalState = await engine.item("jacket")
        #expect(await finalState.hasFlag(.isWorn) == false)
        #expect(await finalState.hasFlag(.isTouched) == true)
        #expect(await finalState.playerIsHolding)
    }

    @Test("Remove multiple worn items")
    func testRemoveMultipleWornItems() async throws {
        // Given
        let coat = Item(
            id: "coat",
            .name("winter coat"),
            .description("A warm winter coat."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let scarf = Item(
            id: "scarf",
            .name("woolen scarf"),
            .description("A cozy woolen scarf."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let mittens = Item(
            id: "mittens",
            .name("thick mittens"),
            .description("Thick winter mittens."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let game = MinimalGame(
            items: coat, scarf, mittens
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: All items must be worn first
        try await engine.apply(
            coat.proxy(engine).setFlag(.isWorn),
            scarf.proxy(engine).setFlag(.isWorn),
            mittens.proxy(engine).setFlag(.isWorn)
        )

        // When
        try await engine.execute("remove coat and scarf and mittens")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove coat and scarf and mittens
            You remove the winter coat, the thick mittens, and the woolen
            scarf.
            """
        )

        // Verify all items are no longer worn
        let finalCoat = await engine.item("coat")
        let finalScarf = await engine.item("scarf")
        let finalMittens = await engine.item("mittens")

        #expect(await finalCoat.hasFlag(.isWorn) == false)
        #expect(await finalScarf.hasFlag(.isWorn) == false)
        #expect(await finalMittens.hasFlag(.isWorn) == false)

        #expect(await finalCoat.hasFlag(.isTouched) == true)
        #expect(await finalScarf.hasFlag(.isTouched) == true)
        #expect(await finalMittens.hasFlag(.isTouched) == true)
    }

    @Test("Remove all when wearing multiple items")
    func testRemoveAllWithMultipleWornItems() async throws {
        // Given
        let shirt = Item(
            id: "shirt",
            .name("cotton shirt"),
            .description("A comfortable cotton shirt."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let pants = Item(
            id: "pants",
            .name("blue pants"),
            .description("Comfortable blue pants."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let watch = Item(
            id: "watch",
            .name("gold watch"),
            .description("An expensive gold watch."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let game = MinimalGame(
            items: shirt, pants, watch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: All items must be worn first
        try await engine.apply(
            shirt.proxy(engine).setFlag(.isWorn),
            pants.proxy(engine).setFlag(.isWorn),
            watch.proxy(engine).setFlag(.isWorn)
        )

        // When
        try await engine.execute("remove all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove all
            You remove the blue pants, the cotton shirt, and the gold
            watch.
            """
        )

        // Verify all items are no longer worn
        let finalShirt = await engine.item("shirt")
        let finalPants = await engine.item("pants")
        let finalWatch = await engine.item("watch")

        #expect(await finalShirt.hasFlag(.isWorn) == false)
        #expect(await finalPants.hasFlag(.isWorn) == false)
        #expect(await finalWatch.hasFlag(.isWorn) == false)
    }

    @Test("Remove all when not wearing anything")
    func testRemoveAllWhenNotWearingAnything() async throws {
        // Given
        let hat = Item(
            id: "hat",
            .name("straw hat"),
            .description("A light straw hat."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let game = MinimalGame(
            items: hat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When (hat is not worn)
        try await engine.execute("remove all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove all
            You remove everything you're wearing.
            """
        )
    }

    @Test("Remove all skips non-removable items")
    func testRemoveAllSkipsNonRemovableItems() async throws {
        // Given
        let removableHat = Item(
            id: "removableHat",
            .name("baseball cap"),
            .description("A casual baseball cap."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let fixedRing = Item(
            id: "fixedRing",
            .name("cursed ring"),
            .description("A ring that cannot be removed."),
            .isWearable,
            .omitDescription,
            .in(.player)
        )

        let game = MinimalGame(
            items: removableHat, fixedRing
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: Both items must be worn first
        try await engine.apply(
            removableHat.proxy(engine).setFlag(.isWorn),
            fixedRing.proxy(engine).setFlag(.isWorn)
        )

        // When
        try await engine.execute("remove all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove all
            You remove the baseball cap.
            """
        )

        // Verify only removable item was removed
        let finalHat = await engine.item("removableHat")
        let finalRing = await engine.item("fixedRing")

        #expect(await finalHat.hasFlag(.isWorn) == false)
        #expect(await finalRing.hasFlag(.isWorn) == true)  // Still worn
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = RemoveActionHandler()
        #expect(handler.synonyms.contains(.remove))
        #expect(handler.synonyms.contains(.doff))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = RemoveActionHandler()
        #expect(handler.requiresLight == false)
    }
}
