import CustomDump
import Testing

@testable import GnustoEngine

@Suite("RemoveActionHandler Tests")
struct RemoveActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("REMOVE DIRECTOBJECT syntax works")
    func testRemoveDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let hat = Item(
            id: "hat",
            .name("blue hat"),
            .description("A stylish blue hat."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: hat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: Hat must be worn first
        try await engine.apply(
            engine.setFlag(.isWorn, on: "hat")
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
            """)

        let finalState = try await engine.item("hat")
        #expect(finalState.hasFlag(.isWorn) == false)
        #expect(finalState.hasFlag(.isTouched) == true)
        #expect(finalState.parent == .player)
    }

    @Test("DOFF syntax works")
    func testDoffSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let cloak = Item(
            id: "cloak",
            .name("woolen cloak"),
            .description("A warm woolen cloak."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: cloak
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: Cloak must be worn first
        try await engine.apply(
            engine.setFlag(.isWorn, on: "cloak")
        )

        // When
        try await engine.execute("doff cloak")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > doff cloak
            You remove the woolen cloak.
            """)

        let finalState = try await engine.item("cloak")
        #expect(finalState.hasFlag(.isWorn) == false)
    }

    @Test("TAKE OFF syntax works")
    func testTakeOffSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let shoes = Item(
            id: "shoes",
            .name("leather shoes"),
            .description("Comfortable leather shoes."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: shoes
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: Shoes must be worn first
        try await engine.apply(
            engine.setFlag(.isWorn, on: "shoes")
        )

        // When
        try await engine.execute("take off shoes")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take off shoes
            You remove the leather shoes.
            """)

        let finalState = try await engine.item("shoes")
        #expect(finalState.hasFlag(.isWorn) == false)
    }

    @Test("REMOVE ALL syntax works")
    func testRemoveAllSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

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
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: hat, gloves
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: Both items must be worn first
        try await engine.apply(
            engine.setFlag(.isWorn, on: "hat"),
            engine.setFlag(.isWorn, on: "gloves")
        )

        // When
        try await engine.execute("remove all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove all
            You remove the red hat and the silk gloves.
            """)

        let finalHat = try await engine.item("hat")
        let finalGloves = try await engine.item("gloves")
        #expect(finalHat.hasFlag(.isWorn) == false)
        #expect(finalGloves.hasFlag(.isWorn) == false)
    }

    // MARK: - Validation Testing

    @Test("Cannot remove without specifying what")
    func testCannotRemoveWithoutTarget() async throws {
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
        try await engine.execute("remove")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove
            Remove what?
            """)
    }

    @Test("Cannot remove item not worn")
    func testCannotRemoveItemNotWorn() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let hat = Item(
            id: "hat",
            .name("blue hat"),
            .description("A stylish blue hat."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You aren’t wearing the blue hat.
            """)
    }

    @Test("Cannot remove non-existent item")
    func testCannotRemoveNonExistentItem() async throws {
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
        try await engine.execute("remove nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove nonexistent
            You can’t see any such thing.
            """)
    }

    @Test("Cannot remove fixed scenery")
    func testCannotRemoveFixedScenery() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let fixedItem = Item(
            id: "fixedItem",
            .name("ceremonial robe"),
            .description("A ceremonial robe that cannot be removed."),
            .isWearable,
            .omitDescription,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: fixedItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: Item must be worn first
        try await engine.apply(
            engine.setFlag(.isWorn, on: "fixedItem")
        )

        // When
        try await engine.execute("remove robe")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove robe
            You can’t remove the ceremonial robe.
            """)
    }

    @Test("Cannot remove non-item")
    func testCannotRemoveNonItem() async throws {
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
        try await engine.execute("remove me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove me
            That's not something you can remove.
            """)
    }

    // MARK: - Processing Testing

    @Test("Remove single worn item")
    func testRemoveSingleWornItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let jacket = Item(
            id: "jacket",
            .name("leather jacket"),
            .description("A tough leather jacket."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: jacket
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: Jacket must be worn first
        try await engine.apply(
            engine.setFlag(.isWorn, on: "jacket")
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
            """)

        // Verify state changes
        let finalState = try await engine.item("jacket")
        #expect(finalState.hasFlag(.isWorn) == false)
        #expect(finalState.hasFlag(.isTouched) == true)
        #expect(finalState.parent == .player)
    }

    @Test("Remove multiple worn items")
    func testRemoveMultipleWornItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

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
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: coat, scarf, mittens
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: All items must be worn first
        try await engine.apply(
            engine.setFlag(.isWorn, on: "coat"),
            engine.setFlag(.isWorn, on: "scarf"),
            engine.setFlag(.isWorn, on: "mittens")
        )

        // When
        try await engine.execute("remove coat and scarf and mittens")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove coat and scarf and mittens
            You remove the winter coat, the woolen scarf, and the thick mittens.
            """)

        // Verify all items are no longer worn
        let finalCoat = try await engine.item("coat")
        let finalScarf = try await engine.item("scarf")
        let finalMittens = try await engine.item("mittens")

        #expect(finalCoat.hasFlag(.isWorn) == false)
        #expect(finalScarf.hasFlag(.isWorn) == false)
        #expect(finalMittens.hasFlag(.isWorn) == false)

        #expect(finalCoat.hasFlag(.isTouched) == true)
        #expect(finalScarf.hasFlag(.isTouched) == true)
        #expect(finalMittens.hasFlag(.isTouched) == true)
    }

    @Test("Remove all when wearing multiple items")
    func testRemoveAllWithMultipleWornItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

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
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: shirt, pants, watch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: All items must be worn first
        try await engine.apply(
            engine.setFlag(.isWorn, on: "shirt"),
            engine.setFlag(.isWorn, on: "pants"),
            engine.setFlag(.isWorn, on: "watch")
        )

        // When
        try await engine.execute("remove all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove all
            You remove the cotton shirt, the blue pants, and the gold watch.
            """)

        // Verify all items are no longer worn
        let finalShirt = try await engine.item("shirt")
        let finalPants = try await engine.item("pants")
        let finalWatch = try await engine.item("watch")

        #expect(finalShirt.hasFlag(.isWorn) == false)
        #expect(finalPants.hasFlag(.isWorn) == false)
        #expect(finalWatch.hasFlag(.isWorn) == false)
    }

    @Test("Remove all when not wearing anything")
    func testRemoveAllWhenNotWearingAnything() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let hat = Item(
            id: "hat",
            .name("straw hat"),
            .description("A light straw hat."),
            .isTakable,
            .isWearable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You aren’t wearing anything.
            """)
    }

    @Test("Remove all skips non-removable items")
    func testRemoveAllSkipsNonRemovableItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

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
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: removableHat, fixedRing
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: Both items must be worn first
        try await engine.apply(
            engine.setFlag(.isWorn, on: "removableHat"),
            engine.setFlag(.isWorn, on: "fixedRing")
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
            """)

        // Verify only removable item was removed
        let finalHat = try await engine.item("removableHat")
        let finalRing = try await engine.item("fixedRing")

        #expect(finalHat.hasFlag(.isWorn) == false)
        #expect(finalRing.hasFlag(.isWorn) == true)  // Still worn
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = RemoveActionHandler()
        // RemoveActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = RemoveActionHandler()
        #expect(handler.verbs.contains(.remove))
        #expect(handler.verbs.contains(.doff))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = RemoveActionHandler()
        #expect(handler.requiresLight == false)
    }
}
