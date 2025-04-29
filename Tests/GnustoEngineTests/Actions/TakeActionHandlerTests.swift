import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("TakeActionHandler Tests")
struct TakeActionHandlerTests {
    let handler = TakeActionHandler()

    // Helper to create the expected StateChange array for successful take
    private func expectedTakeChanges(
        itemID: ItemID,
        oldParent: ParentEntity,
        oldProperties: Set<ItemProperty>,
        oldPronounIt: Set<ItemID>?
    ) -> [StateChange] {
        var finalProperties = oldProperties
        finalProperties.insert(.touched)

        var changes: [StateChange] = [
            StateChange(
                entityId: .item(itemID),
                propertyKey: .itemParent,
                oldValue: .parentEntity(oldParent),
                newValue: .parentEntity(.player)
            )
        ]

        if oldProperties != finalProperties {
            changes.append(StateChange(
                entityId: .item(itemID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldProperties),
                newValue: .itemProperties(finalProperties)
            ))
        }

        changes.append(StateChange(
            entityId: .global,
            propertyKey: .pronounReference(pronoun: "it"),
            oldValue: oldPronounIt != nil ? .itemIDSet(oldPronounIt!) : nil,
            newValue: .itemIDSet([itemID])
        ))

        return changes
    }

    @Test("Take item successfully")
    func testTakeItemSuccessfully() async throws {
        // Arrange
        let testItem = Item(
            id: "key",
            name: "brass key",
            properties: .takable,
            size: 3,
            parent: .location("startRoom")
        )
        let initialParent = testItem.parent
        let initialProperties = testItem.properties
        // Define player with capacity
        let player = Player(in: "startRoom", carryingCapacity: 10)

        let game = MinimalGame(player: player, items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialPronounIt = engine.getPronounReference(pronoun: "it") // Capture initial state

        let command = Command(verbID: "take", directObject: "key", rawInput: "take key")

        // Initial state check
        #expect(engine.gameState.changeHistory.isEmpty == true)

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasProperty(.touched) == true)
        #expect(engine.getPronounReference(pronoun: "it") == ["key"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(itemID: "key", oldParent: initialParent, oldProperties: initialProperties, oldPronounIt: initialPronounIt)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Take item fails when already held")
    func testTakeItemFailsWhenAlreadyHeld() async throws {
        // Arrange
        let testItem = Item(id: "key", name: "brass key", properties: .takable, parent: .player)
        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        let command = Command(verbID: "take", directObject: "key", rawInput: "take key")

        // Initial state check
        #expect(engine.gameState.changeHistory.isEmpty == true)

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State (Unchanged)
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.parent == .player)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You already have that.")

        // Assert Change History (Should be empty)
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Take item fails when not present in location")
    func testTakeItemFailsWhenNotPresent() async throws {
        // Arrange: Create item that *won't* be added to location
        let nonexistentItem = Item(
            id: "ghost",
            name: "ghostly apparition",
            properties: .takable,
            parent: .nowhere
        )

        let game = MinimalGame(items: [nonexistentItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "take", directObject: "ghost", rawInput: "take ghost")

        // Act & Assert: Expect ActionError.itemNotAccessible
        await #expect(throws: ActionError.itemNotAccessible("ghost")) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Check that the player is still holding nothing
        #expect(engine.itemSnapshots(withParent: .player).isEmpty == true)

        // Assert: Check NO message was printed by the handler
        let output = await mockIO.flush()
        #expect(output.isEmpty == true)
    }

    @Test("Take item fails when not takable")
    func testTakeItemFailsWhenNotTakable() async throws {
        // Arrange: Create item *without* .takable property
        let testItem = Item(
            id: "rock",
            name: "heavy rock",
            parent: .location("startRoom")
        ) // No .takable

        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "take", directObject: "rock", rawInput: "take rock")

        // Act & Assert: Expect specific ActionError
        await #expect(throws: ActionError.itemNotTakable("rock")) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Check item parent DID NOT change
        let finalItemState = engine.itemSnapshot(with: "rock")
        #expect(finalItemState?.parent == .location("startRoom"), "Item should still be in the room")

        // Assert: Check NO message was printed by the handler (error is caught by engine)
        let output = await mockIO.flush()
        #expect(output.isEmpty == true, "No output should be printed by handler on error")
    }

    @Test("Take fails with no direct object")
    func testTakeFailsWithNoObject() async throws {
        // Arrange
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        let command = Command(verbID: "take", rawInput: "take")

        // Act & Assert: Expect error from validate()
        await #expect(throws: ActionError.prerequisiteNotMet("Take what?")) {
             try await handler.perform(command: command, engine: engine)
        }
        #expect(await mockIO.recordedOutput.isEmpty == true)
    }

    @Test("Take item successfully from open container in room")
    func testTakeItemSuccessfullyFromOpenContainerInRoom() async throws {
        // Arrange
        let container = Item(id: "box", name: "wooden box", properties: .container, .open, parent: .location("startRoom"))
        let itemInContainer = Item(id: "gem", name: "ruby gem", properties: .takable, parent: .item("box"))
        let initialParent = itemInContainer.parent
        let initialProperties = itemInContainer.properties

        let game = MinimalGame(items: [container, itemInContainer])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        let initialPronounIt = engine.getPronounReference(pronoun: "it")

        let command = Command(verbID: "take", directObject: "gem", rawInput: "take gem")

        // Initial state check
        #expect(engine.gameState.changeHistory.isEmpty == true)

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = engine.itemSnapshot(with: "gem")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasProperty(.touched) == true)
        let finalContainerState = engine.itemSnapshot(with: "box")
        #expect(finalContainerState?.parent == .location("startRoom"))
        #expect(finalContainerState?.hasProperty(.open) == true)
        #expect(engine.getPronounReference(pronoun: "it") == ["gem"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(itemID: "gem", oldParent: initialParent, oldProperties: initialProperties, oldPronounIt: initialPronounIt)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Take item successfully from open container held by player")
    func testTakeItemSuccessfullyFromOpenContainerHeld() async throws {
        // Arrange
        let container = Item(id: "pouch", name: "leather pouch", properties: .container, .open, .takable, parent: .player)
        let itemInContainer = Item(id: "coin", name: "gold coin", properties: .takable, parent: .item("pouch"))
        let initialParent = itemInContainer.parent
        let initialProperties = itemInContainer.properties

        let game = MinimalGame(items: [container, itemInContainer])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        let initialPronounIt = engine.getPronounReference(pronoun: "it")

        let command = Command(verbID: "take", directObject: "coin", rawInput: "take coin")

        // Initial state check
        #expect(engine.gameState.changeHistory.isEmpty == true)

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = engine.itemSnapshot(with: "coin")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasProperty(.touched) == true)
        let finalContainerState = engine.itemSnapshot(with: "pouch")
        #expect(finalContainerState?.parent == .player)
        #expect(finalContainerState?.hasProperty(.open) == true)
        #expect(engine.getPronounReference(pronoun: "it") == ["coin"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(itemID: "coin", oldParent: initialParent, oldProperties: initialProperties, oldPronounIt: initialPronounIt)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Take item fails from closed container")
    func testTakeItemFailsFromClosedContainer() async throws {
        // Arrange: Create a CLOSED container and item inside it
        let container = Item(
            id: "box",
            name: "wooden box",
            properties: .container, // Closed by default
            parent: .location("startRoom")
        )
        let itemInContainer = Item(
            id: "gem",
            name: "ruby gem",
            properties: .takable,
            parent: .item("box")
        )

        let game = MinimalGame(items: [container, itemInContainer])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        #expect(container.hasProperty(.open) == false) // Verify container is closed

        let command = Command(verbID: "take", directObject: "gem", rawInput: "take gem")

        // Act & Assert: Expect specific ActionError
        await #expect(throws: ActionError.containerIsClosed("box")) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Check item parent DID NOT change
        let finalItemState = engine.itemSnapshot(with: "gem")
        #expect(finalItemState?.parent == .item("box"), "Item should still be in the box")

        // Assert: Check NO message was printed by the handler
        let output = await mockIO.flush()
        #expect(output.isEmpty == true, "No output should be printed by handler on error")
    }

    @Test("Take item fails from non-container item")
    func testTakeItemFailsFromNonContainer() async throws {
        // Arrange: Create a non-container and an item 'inside' it (logically impossible but test setup)
        let nonContainer = Item(
            id: "statue",
            name: "stone statue",
            properties: .takable, // Not a container
            parent: .location("startRoom")
        )
        let itemInside = Item(
            id: "chip",
            name: "stone chip",
            properties: .takable,
            parent: .item("statue")
        )

        let game = MinimalGame(items: [nonContainer, itemInside])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        #expect(nonContainer.hasProperty(.container) == false) // Verify statue is not container

        let command = Command(verbID: "take", directObject: "chip", rawInput: "take chip from statue") // Target the chip

        // Act & Assert: Expect ActionError.prerequisiteNotMet
        await #expect(throws: ActionError.prerequisiteNotMet("You can't take things out of the stone statue.")) {
             try await handler.perform(command: command, engine: engine)
        }

        // Assert: Check item parent DID NOT change
        let finalItemState = engine.itemSnapshot(with: "chip")
        #expect(finalItemState?.parent == .item("statue"), "Chip should still be parented to statue")

        // Assert: Check NO message was printed by the handler
        let output = await mockIO.flush()
        #expect(output.isEmpty == true)
    }

    @Test("Take item fails when capacity exceeded")
    func testTakeItemFailsWhenCapacityExceeded() async throws {
        // Arrange
        let heavyItem = Item(
            id: "heavy",
            name: "heavy thing",
            properties: .takable,
            size: 101, // Exceeds default capacity (100)
            parent: .location("startRoom")
        )
        let game = MinimalGame(items: [heavyItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(verbID: "take", directObject: "heavy", rawInput: "take heavy")

        // Act & Assert: Expect validate to throw playerCannotCarryMore
        await #expect(throws: ActionError.playerCannotCarryMore) {
            try await handler.validate(command: command, engine: engine)
        }

        // Assert no output was printed by the handler itself during validation
        let output = await mockIO.flush()
        #expect(output.isEmpty, "No output should be printed by handler on error")
    }

    /// Tests that taking a wearable item successfully moves it to inventory but does not wear it.
    @Test("Take wearable item successfully (not worn)")
    func testTakeWearableItemSuccessfully() async throws {
        // Arrange
        let testItem = Item(id: "cloak", name: "dark cloak", properties: .takable, .wearable, size: 2, parent: .location("startRoom"))
        let initialParent = testItem.parent
        let initialProperties = testItem.properties
        // Define player with capacity
        let player = Player(in: "startRoom", carryingCapacity: 10)

        let game = MinimalGame(player: player, items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        let initialPronounIt = engine.getPronounReference(pronoun: "it")

        let command = Command(verbID: "take", directObject: "cloak", rawInput: "take cloak")

        // Initial state check
        #expect(engine.gameState.changeHistory.isEmpty == true)

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = engine.itemSnapshot(with: "cloak")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasProperty(.touched) == true)
        #expect(finalItemState?.hasProperty(.worn) == false)
        #expect(engine.getPronounReference(pronoun: "it") == ["cloak"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(itemID: "cloak", oldParent: initialParent, oldProperties: initialProperties, oldPronounIt: initialPronounIt)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Take item successfully from surface in room")
    func testTakeItemSuccessfullyFromSurface() async throws {
        // Arrange
        let surfaceItem = Item(id: "table", name: "wooden table", properties: .surface, parent: .location("startRoom"))
        let itemOnSurface = Item(id: "book", name: "old book", properties: .takable, .read, parent: .item(surfaceItem.id))
        let initialParent = itemOnSurface.parent
        let initialProperties = itemOnSurface.properties
        // Define player with capacity
        let player = Player(in: "startRoom", carryingCapacity: 10)

        let game = MinimalGame(player: player, items: [surfaceItem, itemOnSurface])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        let initialPronounIt = engine.getPronounReference(pronoun: "it")

        let command = Command(verbID: "take", directObject: itemOnSurface.id, rawInput: "take book")

        // Initial state check
        #expect(engine.gameState.changeHistory.isEmpty == true)

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = engine.itemSnapshot(with: itemOnSurface.id)
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasProperty(.touched) == true)
        let finalSurfaceState = engine.itemSnapshot(with: surfaceItem.id)
        #expect(finalSurfaceState?.parent == .location("startRoom"))
        #expect(engine.getPronounReference(pronoun: "it") == [itemOnSurface.id])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(itemID: itemOnSurface.id, oldParent: initialParent, oldProperties: initialProperties, oldPronounIt: initialPronounIt)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Take item that is already touched")
    func testTakeItemAlreadyTouched() async throws {
        // Arrange: Item is takable and already touched
        let testItem = Item(
            id: "key",
            name: "brass key",
            properties: .takable, .touched, // Start with .touched
            size: 3,
            parent: .location("startRoom")
        )
        let initialParent = testItem.parent
        let initialProperties = testItem.properties // Includes .touched
        // Define player with capacity
        let player = Player(in: "startRoom", carryingCapacity: 10)

        let game = MinimalGame(player: player, items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialPronounIt = engine.getPronounReference(pronoun: "it")

        let command = Command(verbID: "take", directObject: "key", rawInput: "take key")

        #expect(engine.gameState.changeHistory.isEmpty == true)

        // Act
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasProperty(.touched) == true) // Still touched
        #expect(engine.getPronounReference(pronoun: "it") == ["key"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

        // Assert Change History
        // Properties shouldn't change, so helper should only generate parent and pronoun changes
        let expectedChanges = expectedTakeChanges(itemID: "key", oldParent: initialParent, oldProperties: initialProperties, oldPronounIt: initialPronounIt)
        #expect(expectedChanges.count == 2, "Expected only parent and pronoun changes")
        #expect(!expectedChanges.contains { $0.propertyKey == .itemProperties }, "Should not contain property change")
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Take item at exact capacity")
    func testTakeItemAtExactCapacity() async throws {
        // Arrange: Player has capacity 10, holds item size 7, tries to take item size 3
        let heldItem = Item(id: "sword", name: "sword", properties: .takable, size: 7, parent: .player)
        let itemToTake = Item(
            id: "key",
            name: "brass key",
            properties: .takable,
            size: 3,
            parent: .location("startRoom")
        )
        let initialParent = itemToTake.parent
        let initialProperties = itemToTake.properties
        // Define player with capacity
        let player = Player(in: "startRoom", carryingCapacity: 10)

        let game = MinimalGame(player: player, items: [heldItem, itemToTake])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialPronounIt = engine.getPronounReference(pronoun: "it")

        let command = Command(verbID: "take", directObject: "key", rawInput: "take key")

        #expect(engine.gameState.changeHistory.isEmpty == true)

        // Act
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.parent == .player) // Should succeed
        #expect(finalItemState?.hasProperty(.touched) == true)
        #expect(engine.getPronounReference(pronoun: "it") == ["key"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(itemID: "key", oldParent: initialParent, oldProperties: initialProperties, oldPronounIt: initialPronounIt)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Take item from transparent container")
    func testTakeItemFromTransparentContainer() async throws {
        // Arrange: Item is inside a *closed* but *transparent* container
        let container = Item(
            id: "jar",
            name: "glass jar",
            properties: .container, .transparent, // Closed by default, but transparent
            parent: .location("startRoom")
        )
        let itemInContainer = Item(
            id: "fly",
            name: "dead fly",
            properties: .takable,
            parent: .item("jar")
        )
        let initialParent = itemInContainer.parent
        let initialProperties = itemInContainer.properties
        // Define player with capacity
        let player = Player(in: "startRoom", carryingCapacity: 10)

        let game = MinimalGame(player: player, items: [container, itemInContainer])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialPronounIt = engine.getPronounReference(pronoun: "it")

        let command = Command(verbID: "take", directObject: "fly", rawInput: "take fly")

        #expect(engine.gameState.changeHistory.isEmpty == true)

        // Act: Should succeed because ScopeResolver sees through transparent containers
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = engine.itemSnapshot(with: "fly")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasProperty(.touched) == true)
        #expect(engine.getPronounReference(pronoun: "it") == ["fly"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(itemID: "fly", oldParent: initialParent, oldProperties: initialProperties, oldPronounIt: initialPronounIt)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Take item fails due to player capacity")
    func testTakeItemFailsDueToCapacity() async throws {
        // Arrange: Player holds item, capacity is low, try to take another
        let itemHeld = Item(
            id: "sword",
            name: "sword",
            properties: .takable,
            size: 8,
            parent: .player
        )
        let itemToTake = Item(
            id: "shield",
            name: "shield",
            properties: .takable,
            size: 7,
            parent: .location("startRoom")
        )
        // Define player with low capacity
        let player = Player(in: "startRoom", carryingCapacity: 10)

        let game = MinimalGame(player: player, items: [itemHeld, itemToTake])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(game: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verbID: "take", directObject: "shield", rawInput: "take shield")

        // Act & Assert: Expect specific ActionError
        await #expect(throws: ActionError.playerCannotCarryMore) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Check item parent DID NOT change
        let finalItemState = engine.itemSnapshot(with: "shield")
        #expect(finalItemState?.parent == .location("startRoom"), "Shield should still be in the room")

        // Assert: Check NO message was printed by the handler
        let output = await mockIO.flush()
        #expect(output.isEmpty == true, "No output should be printed by handler on error")
    }
}
