import CustomDump
import Testing

@testable import GnustoEngine

@Suite("RemoveActionHandler Tests")
struct RemoveActionHandlerTests {
    @Test("Remove worn item successfully")
    func testRemoveItemSuccess() async throws {
        let cloak = Item(
            id: "cloak",
            .in(.player),
            .isTakable,
            .isWearable,
            .isWorn
        )
        let game = MinimalGame(items: cloak)
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game
        )

        // Initial state check
        #expect(try await engine.item("cloak").hasFlag(.isWorn) == true)
        let initialHistory = await engine.gameState.changeHistory
        #expect(initialHistory.isEmpty)

        // Act
        try await engine.execute("remove cloak")

        // Assert State Change
        let finalCloakState = try await engine.item("cloak")
        #expect(finalCloakState.parent == .player)
        #expect(finalCloakState.hasFlag(.isWorn) == false, "Cloak should NOT have .isWorn flag")
        #expect(finalCloakState.hasFlag(.isTouched) == true, "Cloak should have .isTouched flag")  // Ensure touched is added

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > remove cloak
            You take off the cloak.
            """)

        // Assert Change History
        let expectedChanges = [
            StateChange(
                entityID: .item("cloak"),
                attribute: .itemAttribute(.isWorn),
                oldValue: true,
                newValue: false
            ),
            StateChange(
                entityID: .item("cloak"),
                attribute: .itemAttribute(.isTouched),
                newValue: true
            ),
            StateChange(
                entityID: .global,
                attribute: .pronounReference(pronoun: "it"),
                newValue: .entityReferenceSet([.item("cloak")])
            ),
        ]
        let finalHistory = await engine.gameState.changeHistory
        expectNoDifference(finalHistory, expectedChanges)
    }

    @Test("Remove fails if item not worn (but held)")
    func testRemoveItemNotWorn() async throws {
        let cloak = Item(
            id: "cloak",
            .in(.player),
            .isTakable,
            .isWearable
        )
        let game = MinimalGame(items: cloak)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("take off cloak")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take off cloak
            You aren’t wearing the cloak.
            """)
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Remove fails if item not held")
    func testRemoveItemNotHeld() async throws {
        // Cloak doesn’t exist here
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("remove cloak")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > remove cloak
            You can’t see any such thing.
            """)
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Remove fails with no direct object")
    func testRemoveNoObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("remove")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > remove
            Remove what?
            """)
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Remove fails if item is fixed scenery (which can be worn)")
    func testRemoveFailsIfFixed() async throws {
        let amulet = Item(
            id: "amulet",
            .name("cursed amulet"),
            .in(.player),
            .omitDescription,
            .isWearable,
            .isWorn
        )
        let game = MinimalGame(items: amulet)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("remove amulet")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > remove amulet
            You can’t remove the cursed amulet.
            """)
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    // MARK: - Multiple Object Tests

    @Test("REMOVE ALL works correctly")
    func testRemoveAll() async throws {
        let cloak = Item(id: "cloak", .name("cloak"), .in(.player), .isWearable, .isWorn)
        let boots = Item(id: "boots", .name("boots"), .in(.player), .isWearable, .isWorn)

        let game = MinimalGame(items: cloak, boots)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Execute "remove all"
        try await engine.execute("remove all")

        // Assert: Should remove both items
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > remove all
            You take off the boots and the cloak.
            """)

        // Verify items are no longer worn
        let updatedCloak = try await engine.item("cloak")
        let updatedBoots = try await engine.item("boots")
        #expect(updatedCloak.hasFlag(.isWorn) == false)
        #expect(updatedBoots.hasFlag(.isWorn) == false)

        // Verify items are still held
        #expect(updatedCloak.parent == .player)
        #expect(updatedBoots.parent == .player)
    }

    @Test("REMOVE CLOAK AND BOOTS works correctly")
    func testRemoveCloakAndBoots() async throws {
        let cloak = Item(id: "cloak", .name("cloak"), .in(.player), .isWearable, .isWorn)
        let boots = Item(id: "boots", .name("boots"), .in(.player), .isWearable, .isWorn)

        let game = MinimalGame(items: cloak, boots)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Execute "remove cloak and boots"
        try await engine.execute("remove cloak and boots")

        // Assert: Should remove both items
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > remove cloak and boots
            You take off the boots and the cloak.
            """)

        // Verify items are no longer worn
        let updatedCloak = try await engine.item("cloak")
        let updatedBoots = try await engine.item("boots")
        #expect(updatedCloak.hasFlag(.isWorn) == false)
        #expect(updatedBoots.hasFlag(.isWorn) == false)
    }

    @Test("REMOVE ALL skips non-worn items")
    func testRemoveAllSkipsNonWorn() async throws {
        let cloak = Item(id: "cloak", .name("cloak"), .in(.player), .isWearable, .isWorn)
        let boots = Item(id: "boots", .name("boots"), .in(.player), .isWearable)  // Not worn

        let game = MinimalGame(items: cloak, boots)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Execute "remove all"
        try await engine.execute("remove all")

        // Assert: Should remove only the cloak
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > remove all
            You take off the cloak.
            """)

        // Verify only cloak is affected
        let updatedCloak = try await engine.item("cloak")
        let updatedBoots = try await engine.item("boots")
        #expect(updatedCloak.hasFlag(.isWorn) == false)
        #expect(updatedBoots.hasFlag(.isWorn) == false)  // Was already false
    }

    @Test("REMOVE ALL with no worn items")
    func testRemoveAllWithNoWornItems() async throws {
        let boots = Item(id: "boots", .name("boots"), .in(.player), .isWearable)  // Not worn

        let game = MinimalGame(items: boots)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Execute "remove all"
        try await engine.execute("remove all")

        // Assert: Should get appropriate message
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > remove all
            You aren’t wearing anything.
            """)
    }

    @Test("REMOVE ALL skips scenery items")
    func testRemoveAllSkipsScenery() async throws {
        let cloak = Item(id: "cloak", .name("cloak"), .in(.player), .isWearable, .isWorn)
        let amulet = Item(
            id: "amulet", .name("cursed amulet"), .in(.player), .isWearable, .isWorn,
            .omitDescription)

        let game = MinimalGame(items: cloak, amulet)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Execute "remove all"
        try await engine.execute("remove all")

        // Assert: Should remove only the cloak (skip cursed amulet)
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > remove all
            You take off the cloak.
            """)

        // Verify only cloak is affected
        let updatedCloak = try await engine.item("cloak")
        let updatedAmulet = try await engine.item("amulet")
        #expect(updatedCloak.hasFlag(.isWorn) == false)
        #expect(updatedAmulet.hasFlag(.isWorn) == true)  // Still worn (cursed)
    }
}
