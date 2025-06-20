import CustomDump
import Testing

@testable import GnustoEngine

@Suite("TakeActionHandler Tests")
struct TakeActionHandlerTests {
    let handler = TakeActionHandler()

    // Helper function to generate expected state changes for a successful 'take'
    private func expectedTakeChanges(
        itemID: ItemID,
        initialParent: ParentEntity,
        finalParent: ParentEntity = .player,  // Default final parent is player
        initialAttributes: [ItemAttributeID: StateValue],  // Use initial attributes map
        finalAttributes: [ItemAttributeID: StateValue]? = nil  // Optional final attributes map
    ) -> [StateChange] {
        var changes = [
            // Parent change
            StateChange(
                entityID: .item(itemID),
                attribute: .itemParent,
                oldValue: .parentEntity(initialParent),
                newValue: .parentEntity(finalParent)
            )
        ]

        // Determine final attributes, default to initial if not provided
        let effectiveFinalAttributes = finalAttributes ?? initialAttributes

        // Add attribute changes dynamically by comparing initial and final maps
        let allKeys = Set(initialAttributes.keys).union(effectiveFinalAttributes.keys)
        for key in allKeys {
            let oldValue = initialAttributes[key]

            guard let newValue = effectiveFinalAttributes[key] else {
                Issue.record("Expected attribute \(key) to exist in final attributes")
                continue
            }

            // Use nil-coalescing or direct comparison where appropriate
            if oldValue != newValue {
                changes.append(
                    StateChange(
                        entityID: .item(itemID),
                        attribute: .itemAttribute(key),
                        oldValue: oldValue,
                        newValue: newValue
                    )
                )
            }
        }

        // Ensure touched is set if not already true
        let initialIsTouched = initialAttributes[.isTouched]  // is Optional(StateValue)
        if initialIsTouched != true {  // Correctly compares Optional != Non-optional
            let touchedChange = StateChange(
                entityID: .item(itemID),
                attribute: .itemAttribute(.isTouched),
                oldValue: initialIsTouched,  // Keep original old value (nil or false)
                newValue: true,
            )

            // Avoid adding duplicate change if already handled by the general attribute comparison
            if let existingIndex = changes.firstIndex(where: {
                $0.attribute == .itemAttribute(.isTouched)
            }) {
                // If a change exists, make sure its newValue is true
                if changes[existingIndex].newValue != true {
                    changes[existingIndex] = touchedChange
                }
            } else {
                // If no change exists yet, add it
                changes.append(touchedChange)
            }
        }

        // Add pronoun change (assuming 'it' always refers to the taken item now)
        changes.append(
            StateChange(
                entityID: .global,
                attribute: .pronounReference(pronoun: "it"),
                oldValue: nil,  // Simplified assumption: previous 'it' is irrelevant
                newValue: .entityReferenceSet([.item(itemID)])
            )
        )

        return changes.sorted()  // Sort for consistent comparison
    }

    @Test("Take item successfully")
    func testTakeItemSuccessfully() async throws {
        // Arrange
        let testItem = Item(
            id: "key",
            .name("brass key"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(3)
        )
        let initialParent = testItem.parent
        let initialAttributes = testItem.attributes  // Capture initial attributes
        // Define player with capacity
        let player = Player(in: .startRoom, carryingCapacity: 10)

        let game = MinimalGame(player: player, items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initial state check
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute for full pipeline
        try await engine.execute("take key")

        // Assert Final State
        let finalItemState = try await engine.item("key")
        #expect(finalItemState.parent == .player)
        #expect(finalItemState.hasFlag(.isTouched) == true)  // Use convenience accessor
        #expect(await engine.getPronounReference(pronoun: "it") == [.item("key")])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take key
            Taken.
            """)

        // Assert Change History
        // Pass the initial attributes map to the helper
        let expectedChanges = expectedTakeChanges(
            itemID: "key",
            initialParent: initialParent,
            initialAttributes: initialAttributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory.sorted(), expectedChanges)
    }

    @Test("Take item fails when already held")
    func testTakeItemFailsWhenAlreadyHeld() async throws {
        // Arrange
        let testItem = Item(
            id: "key",
            .name("brass key"),
            .in(.player),  // Already held
            .isTakable
        )
        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initial state check
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute for full pipeline
        try await engine.execute("take key")

        // Assert Final State (Unchanged)
        let finalItemState = try await engine.item("key")
        #expect(finalItemState.parent == .player)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take key
            You already have that.
            """)

        // Assert Change History (Should be empty)
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Take item fails when not present in location")
    func testTakeItemFailsWhenNotPresent() async throws {
        // Arrange: Create item that *won't* be added to location
        let nonexistentItem = Item(
            id: "figurine",
            .name("jade figurine"),
            .in(.nowhere),  // Not in scope
            .isTakable
        )

        let game = MinimalGame(items: nonexistentItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("take figurine")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take figurine
            You can't see any such thing.
            """)

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Assert: Check that the player is still holding nothing
        #expect(await engine.items(in: .player).isEmpty)
    }

    @Test("Take item fails when not takable")
    func testTakeItemFailsWhenNotTakable() async throws {
        // Arrange: Create item *without* .isTakable attribute
        let testItem = Item(
            id: "rock",
            .name("heavy rock"),
            .in(.location(.startRoom))
            // No .isTakable: true
        )

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("take rock")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take rock
            You can't take the heavy rock.
            """)

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Assert: Check item parent DID NOT change
        let finalItemState = try await engine.item("rock")
        #expect(finalItemState.parent == .location(.startRoom), "Item should still be in the room")
    }

    @Test("Take fails with no direct object")
    func testTakeFailsWithNoObject() async throws {
        // Arrange
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("take")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take
            Take what?
            """)

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Take item successfully from open container in room")
    func testTakeItemSuccessfullyFromOpenContainerInRoom() async throws {
        // Arrange
        let container = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpen
        )
        let itemInContainer = Item(
            id: "gem",
            .name("ruby gem"),
            .in(.item("box")),
            .isTakable
        )
        let initialParent = itemInContainer.parent
        let initialAttributes = itemInContainer.attributes  // Capture initial

        let game = MinimalGame(items: container, itemInContainer)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initial state check
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute for full pipeline
        try await engine.execute("take gem")

        // Assert Final State
        let finalItemState = try await engine.item("gem")
        #expect(finalItemState.parent == .player)
        #expect(finalItemState.hasFlag(.isTouched) == true)
        let finalContainerState = try await engine.item("box")
        #expect(finalContainerState.parent == .location(.startRoom))
        #expect(finalContainerState.hasFlag(.isOpen) == true)  // Check flag
        #expect(await engine.getPronounReference(pronoun: "it") == [.item("gem")])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take gem
            Taken.
            """)

        // Assert Change History
        let expectedChanges = expectedTakeChanges(
            itemID: "gem",
            initialParent: initialParent,
            initialAttributes: initialAttributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory.sorted(), expectedChanges)
    }

    @Test("Take item successfully from open container held by player")
    func testTakeItemSuccessfullyFromOpenContainerHeld() async throws {
        // Arrange
        let container = Item(
            id: "pouch",
            .name("leather pouch"),
            .in(.player),
            .isContainer,
            .isOpen,  // Explicitly open
            .isTakable  // Player must be able to hold it
        )
        let itemInContainer = Item(
            id: "coin",
            .name("gold coin"),
            .in(.item("pouch")),
            .isTakable
        )
        let initialParent = itemInContainer.parent
        let initialAttributes = itemInContainer.attributes  // Capture initial

        let game = MinimalGame(items: container, itemInContainer)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initial state check
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute for full pipeline
        try await engine.execute("take coin")

        // Assert Final State
        let finalItemState = try await engine.item("coin")
        #expect(finalItemState.parent == .player)
        #expect(finalItemState.hasFlag(.isTouched) == true)
        let finalContainerState = try await engine.item("pouch")
        #expect(finalContainerState.parent == .player)
        #expect(finalContainerState.hasFlag(.isOpen) == true)  // Check flag
        #expect(await engine.getPronounReference(pronoun: "it") == [.item("coin")])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take coin
            Taken.
            """)

        // Assert Change History
        let expectedChanges = expectedTakeChanges(
            itemID: "coin",
            initialParent: initialParent,
            initialAttributes: initialAttributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory.sorted(), expectedChanges)
    }

    @Test("Take item fails from closed container")
    func testTakeItemFailsFromClosedContainer() async throws {
        // Arrange: Create a CLOSED container and item inside it
        let container = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer
        )
        let itemInContainer = Item(
            id: "gem",
            .name("ruby gem"),
            .in(.item("box")),
            .isTakable
        )

        let game = MinimalGame(items: container, itemInContainer)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        #expect(try await engine.item("box").hasFlag(.isOpen) == false)  // Verify closed

        // Act
        try await engine.execute("take gem")

        // Assert Output
        let output = await mockIO.flush()  // Define output before using it
        // ScopeResolver will prevent seeing it, standard message
        expectNoDifference(output, "> take gem\n\nYou can't see any such thing.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Assert: Check item parent DID NOT change
        let finalItemState = try await engine.item("gem")
        #expect(finalItemState.parent == .item("box"), "Item should still be in the box")
    }

    @Test("Take item fails from non-container item")
    func testTakeItemFailsFromNonContainer() async throws {
        // Arrange: Create a non-container and an item 'inside' it
        let nonContainer = Item(
            id: "statue",
            .name("stone statue"),
            .in(.location(.startRoom))
            // Not a container by default
        )
        let itemInside = Item(
            id: "chip",
            .name("stone chip"),
            .in(.item("statue")),
            .isTakable
        )

        let game = MinimalGame(items: nonContainer, itemInside)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        #expect(try await engine.item("statue").hasFlag(.isContainer) == false)  // Verify statue is not container

        // Act
        try await engine.execute("take chip from statue")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> take chip from statue\n\nYou can't take things out of the stone statue.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Assert: Check item parent DID NOT change
        let finalItemState = try await engine.item("chip")
        #expect(finalItemState.parent == .item("statue"), "Chip should still be parented to statue")
    }

    @Test("Take item fails when capacity exceeded")
    func testTakeItemFailsWhenCapacityExceeded() async throws {
        // Arrange
        let heavyItem = Item(
            id: "heavy",
            .name("heavy thing"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(101)  // Exceeds default capacity (100) if player has 0
        )
        // Player with capacity 0
        let player = Player(in: .startRoom, carryingCapacity: 0)
        let game = MinimalGame(player: player, items: heavyItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // We need to use the engine.execute to get the standard error message
        try await engine.execute("take heavy")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> take heavy\n\nYour hands are full.")  // Check standard message

        // Assert no state changes occurred
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Assert item is still in the room
        #expect(try await engine.item("heavy").parent == .location(.startRoom))
    }

    /// Tests that taking a wearable item successfully moves it to inventory but does not wear it.
    @Test("Take wearable item successfully (not worn)")
    func testTakeWearableItemSuccessfully() async throws {
        // Arrange
        let testItem = Item(
            id: "cloak",
            .name("dark cloak"),
            .in(.location(.startRoom)),
            .isTakable,
            .isWearable,
            .size(2)
        )
        let initialParent = testItem.parent
        let initialAttributes = testItem.attributes  // Capture initial
        // Define player with capacity
        let player = Player(in: .startRoom, carryingCapacity: 10)

        let game = MinimalGame(player: player, items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initial state check
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute for full pipeline
        try await engine.execute("take cloak")

        // Assert Final State
        let finalItemState = try await engine.item("cloak")
        #expect(finalItemState.parent == .player)
        #expect(finalItemState.hasFlag(.isTouched) == true)
        #expect(finalItemState.hasFlag(.isWorn) == false)  // Not worn
        #expect(await engine.getPronounReference(pronoun: "it") == [.item("cloak")])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> take cloak\n\nTaken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(
            itemID: "cloak",
            initialParent: initialParent,
            initialAttributes: initialAttributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory.sorted(), expectedChanges)
    }

    @Test("Take item successfully from surface in room")
    func testTakeItemSuccessfullyFromSurface() async throws {
        // Arrange
        let surfaceItem = Item(
            id: "table",
            .name("wooden table"),
            .in(.location(.startRoom)),
            .isSurface
        )
        let itemOnSurface = Item(
            id: "book",
            .name("old book"),
            .in(.item("table")),
            .isTakable,
            .isReadable
        )
        let initialParent = itemOnSurface.parent
        let initialAttributes = itemOnSurface.attributes  // Capture initial
        // Define player with capacity
        let player = Player(in: .startRoom, carryingCapacity: 10)

        let game = MinimalGame(player: player, items: surfaceItem, itemOnSurface)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initial state check
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute for full pipeline
        try await engine.execute("take book")

        // Assert Final State
        let finalItemState = try await engine.item(itemOnSurface.id)
        #expect(finalItemState.parent == .player)
        #expect(finalItemState.hasFlag(.isTouched) == true)
        let finalSurfaceState = try await engine.item(surfaceItem.id)
        #expect(finalSurfaceState.parent == .location(.startRoom))
        #expect(await engine.getPronounReference(pronoun: "it") == [.item(itemOnSurface.id)])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> take book\n\nTaken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(
            itemID: itemOnSurface.id,
            initialParent: initialParent,
            initialAttributes: initialAttributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory.sorted(), expectedChanges)
    }

    @Test("Take item that is already touched")
    func testTakeItemAlreadyTouched() async throws {
        // Arrange: Item is takable and already touched
        let testItem = Item(
            id: "key",
            .name("brass key"),
            .in(.location(.startRoom)),
            .isTakable,
            .isTouched,  // Start touched
            .size(3)
        )
        let initialParent = testItem.parent
        let initialAttributes = testItem.attributes  // Includes .isTouched: true
        // Define player with capacity
        let player = Player(in: .startRoom, carryingCapacity: 10)

        let game = MinimalGame(player: player, items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("take key")

        // Assert Final State
        let finalItemState = try await engine.item("key")
        #expect(finalItemState.parent == .player)
        #expect(finalItemState.hasFlag(.isTouched) == true)  // Still touched
        #expect(await engine.getPronounReference(pronoun: "it") == [.item("key")])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> take key\n\nTaken.")

        // Assert Change History
        // Helper should only generate parent and pronoun changes as attributes didn't change
        let expectedChanges = expectedTakeChanges(
            itemID: "key",
            initialParent: initialParent,
            initialAttributes: initialAttributes
        )
        // Since isTouched was already true, no change for it should be generated.
        // Only parent and pronoun changes are expected.
        #expect(expectedChanges.count == 2, "Expected only parent and pronoun changes")
        #expect(
            !expectedChanges.contains { $0.attribute == .itemAttribute(.isTouched) },
            "Should not contain isTouched change")
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory.sorted(), expectedChanges)
    }

    @Test("Take item at exact capacity")
    func testTakeItemAtExactCapacity() async throws {
        // Arrange: Player has capacity 10, holds item size 7, tries to take item size 3
        let heldItem = Item(
            id: "sword",
            .in(.player),
            .isTakable,
            .size(7)
        )
        let itemToTake = Item(
            id: "key",
            .name("brass key"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(3)
        )
        let initialParent = itemToTake.parent
        let initialAttributes = itemToTake.attributes  // Capture initial
        // Define player with capacity
        let player = Player(in: .startRoom, carryingCapacity: 10)

        let game = MinimalGame(player: player, items: heldItem, itemToTake)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("take key")

        // Assert Final State
        let finalItemState = try await engine.item("key")
        #expect(finalItemState.parent == .player)  // Should succeed
        #expect(finalItemState.hasFlag(.isTouched) == true)
        #expect(await engine.getPronounReference(pronoun: "it") == [.item("key")])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> take key\n\nTaken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(
            itemID: "key",
            initialParent: initialParent,
            initialAttributes: initialAttributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory.sorted(), expectedChanges)
    }

    @Test("Take item from transparent container")
    func testTakeItemFromTransparentContainer() async throws {
        // Arrange: Item is inside a *closed* but *transparent* container
        let container = Item(
            id: "jar",
            .name("glass jar"),
            .in(.location(.startRoom)),
            .isContainer,
            .isTransparent  // Closed by default, but transparent
        )
        let itemInContainer = Item(
            id: "fly",
            .name("dead fly"),
            .in(.item("jar")),
            .isTakable
        )

        // Define player with capacity
        let player = Player(in: .startRoom, carryingCapacity: 10)

        let game = MinimalGame(player: player, items: container, itemInContainer)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        #expect(await engine.gameState.changeHistory.isEmpty)
        #expect(try await engine.item("jar").hasFlag(.isOpen) == false)  // Verify closed
        #expect(try await engine.item("jar").hasFlag(.isTransparent) == true)  // Verify transparent

        // Act: ScopeResolver sees through transparent containers, but TakeActionHandler should still check if container is open
        try await engine.execute("take fly")

        // Assert Output - Should fail because container is closed
        let output = await mockIO.flush()
        expectNoDifference(output, "> take fly\n\nThe glass jar is closed.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Assert: Check item parent DID NOT change
        let finalItemState = try await engine.item("fly")
        #expect(finalItemState.parent == .item("jar"), "Fly should still be in the jar")
    }

    @Test("Take item fails due to player capacity")
    func testTakeItemFailsDueToCapacity() async throws {
        // Arrange: Player holds item, capacity is low, try to take another
        let itemHeld = Item(
            id: "sword",
            .in(.player),
            .isTakable,
            .size(8)
        )
        let itemToTake = Item(
            id: "shield",
            .name("shield"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(7)
        )
        // Define player with low capacity
        let player = Player(in: .startRoom, carryingCapacity: 10)

        let game = MinimalGame(player: player, items: itemHeld, itemToTake)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("take shield")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> take shield\n\nYour hands are full.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Assert: Check item parent DID NOT change
        let finalItemState = try await engine.item("shield")
        #expect(
            finalItemState.parent == .location(.startRoom), "Shield should still be in the room")
    }

    @Test("Take item from container using 'from' syntax")
    func testTakeItemFromContainerWithFromSyntax() async throws {
        // Arrange: Create a container with an item inside it
        let container = Item(
            id: "bag",
            .name("leather bag"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpen,
            .isTakable
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.item("bag")),
            .isTakable
        )

        let player = Player(in: .startRoom)
        let game = MinimalGame(player: player, items: container, coin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Parse and execute "take coin from bag"
        try await engine.execute("take coin from bag")

        // Assert: Coin should be taken from bag and moved to player
        let finalCoinState = try await engine.item("coin")
        #expect(finalCoinState.parent == .player)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take coin from bag
            Taken.
            """)
    }

    @Test("Take item from wrong container fails with appropriate message")
    func testTakeItemFromWrongContainerFails() async throws {
        // Arrange: Create a container with an item, and another empty container
        let bag = Item(
            id: "bag",
            .name("leather bag"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpen,
            .isTakable
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpen
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.item("bag")),
            .isTakable
        )

        let player = Player(in: .startRoom)
        let game = MinimalGame(player: player, items: bag, box, coin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Try to parse and execute "take coin from box" (coin is in bag, not box)
        try await engine.execute("take coin from box")

        // Assert: Should get error message
        let output = await mockIO.flush()
        expectNoDifference(output, "> take coin from box\n\nThe gold coin is not in the wooden box.")
    }

    @Test("Take item from container parses correctly")
    func testTakeFromContainerParsingStructure() async throws {
        // Arrange: Create a simple setup
        let bag = Item(
            id: "bag",
            .name("leather bag"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpen
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.item("bag")),
            .isTakable
        )

        let (engine, _) = await GameEngine.test(
            blueprint: MinimalGame(items: bag, coin)
        )

        // Act: Parse "take coin from bag"
        let result = await engine.parser.parse(
            input: "take coin from bag",
            vocabulary: engine.gameState.vocabulary,
            gameState: engine.gameState
        )

        // Assert: Should parse successfully with correct structure
        switch result {
        case .success(let command):
            #expect(command.verb == .take)
            #expect(command.directObject == .item("coin"))
            #expect(command.indirectObject == .item("bag"))
            #expect(command.preposition == "from")
            #expect(command.rawInput == "take coin from bag")
        case .failure(let error):
            Issue.record("Expected successful parsing but got error: \(error)")
        }
    }
}
