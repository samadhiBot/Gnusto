import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("TakeActionHandler Tests")
struct TakeActionHandlerTests {
    let handler = TakeActionHandler()

    // Helper function to generate expected state changes for a successful 'take'
    private func expectedTakeChanges(
        itemID: ItemID,
        initialParent: ParentEntity,
        finalParent: ParentEntity = .player, // Default final parent is player
        initialTouched: Bool,
        finalTouched: Bool = true, // Default is true after taking
        initialLight: Bool? = nil, // Optional initial light state
        finalLight: Bool? = nil    // Optional final light state
    ) -> [StateChange] {
        var changes = [
            // Parent change
            StateChange(
                entityId: .item(id: itemID),
                propertyKey: .itemParent,
                oldValue: .parent(initialParent),
                newValue: .parent(finalParent)
            ),
        ]

        // Add touched change only if it actually changes
        if initialTouched != finalTouched {
            changes.append(StateChange(
                entityId: .item(id: itemID),
                propertyKey: .itemDynamicValue(key: .itemTouched),
                oldValue: .bool(initialTouched),
                newValue: .bool(finalTouched)
            ))
        }

        // Add light change only if it actually changes
        if initialLight != finalLight,
           let finalLightValue = finalLight // Ensure finalLight is not nil if different
        {
            changes.append(StateChange(
                entityId: .item(id: itemID),
                propertyKey: .itemDynamicValue(key: .itemLight), // Assuming .itemLight is the correct ID
                oldValue: initialLight.map { .bool($0) }, // Map optional Bool to optional StateValue
                newValue: .bool(finalLightValue)
            ))
        }

        // Add pronoun change (assuming 'it' always refers to the taken item now)
        changes.append(StateChange(
            entityId: .global,
            propertyKey: .pronounReference(pronoun: "it"),
            oldValue: nil, // Simplified assumption: previous 'it' is irrelevant
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
        let finalItemState = engine.item(with: "key")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasProperty(.touched) == true)
        #expect(engine.getPronounReference(pronoun: "it") == ["key"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(
            itemID: "key",
            initialParent: initialParent,
            initialTouched: false // Key starts untouched
        )
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Take item fails when already held")
    func testTakeItemFailsWhenAlreadyHeld() async throws {
        // Arrange
        let testItem = Item(
            id: "key",
            name: "brass key",
            properties: .takable,
            parent: .player
        )
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
        let finalItemState = engine.item(with: "key")
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
            id: "figurine",
            name: "jade figurine",
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

        let command = Command(verbID: "take", directObject: "figurine", rawInput: "take figurine")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't see any such thing.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)

        // Assert: Check that the player is still holding nothing
        #expect(engine.items(withParent: .player).isEmpty == true)
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

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't take the heavy rock.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)

        // Assert: Check item parent DID NOT change
        let finalItemState = engine.item(with: "rock")
        #expect(finalItemState?.parent == .location("startRoom"), "Item should still be in the room")
    }

    @Test("Take fails with no direct object")
    func testTakeFailsWithNoObject() async throws {
        // Arrange
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        let command = Command(verbID: "take", rawInput: "take")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Take what?")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Take item successfully from open container in room")
    func testTakeItemSuccessfullyFromOpenContainerInRoom() async throws {
        // Arrange
        let container = Item(
            id: "box",
            name: "wooden box",
            properties: .container,
            dynamicValues: [.isOpen: true],
            parent: .location("startRoom")
        )
        let itemInContainer = Item(
            id: "gem",
            name: "ruby gem",
            properties: .takable,
            parent: .item("box")
        )
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
        let finalItemState = engine.item(with: "gem")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasProperty(.touched) == true)
        let finalContainerState = engine.item(with: "box")
        #expect(finalContainerState?.parent == .location("startRoom"))
        #expect(finalContainerState?.dynamicValues["isOpen"]?.toBool == true)
        #expect(engine.getPronounReference(pronoun: "it") == ["gem"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(
            itemID: "gem",
            initialParent: initialParent,
            initialTouched: false
        )
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Take item successfully from open container held by player")
    func testTakeItemSuccessfullyFromOpenContainerHeld() async throws {
        // Arrange
        let container = Item(
            id: "pouch",
            name: "leather pouch",
            properties: .container, .takable,
            dynamicValues: [.isOpen: true],
            parent: .player
        )
        let itemInContainer = Item(
            id: "coin",
            name: "gold coin",
            properties: .takable,
            parent: .item("pouch")
        )
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
        let finalItemState = engine.item(with: "coin")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasProperty(.touched) == true)
        let finalContainerState = engine.item(with: "pouch")
        #expect(finalContainerState?.parent == .player)
        #expect(finalContainerState?.dynamicValues["isOpen"]?.toBool == true)
        #expect(engine.getPronounReference(pronoun: "it") == ["coin"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(
            itemID: "coin",
            initialParent: initialParent,
            initialTouched: false
        )
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

        #expect(container.dynamicValues["isOpen"] == nil)

        let command = Command(verbID: "take", directObject: "gem", rawInput: "take gem")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't see any such thing.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)

        // Assert: Check item parent DID NOT change
        let finalItemState = engine.item(with: "gem")
        #expect(finalItemState?.parent == .item("box"), "Item should still be in the box")
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

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't take things out of the stone statue.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)

        // Assert: Check item parent DID NOT change
        let finalItemState = engine.item(with: "chip")
        #expect(finalItemState?.parent == .item("statue"), "Chip should still be parented to statue")
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
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }

        // Assert no output was printed by the handler itself during validation
        let output = await mockIO.flush()
        #expect(output.isEmpty, "No output should be printed by handler on error")
    }

    /// Tests that taking a wearable item successfully moves it to inventory but does not wear it.
    @Test("Take wearable item successfully (not worn)")
    func testTakeWearableItemSuccessfully() async throws {
        // Arrange
        let testItem = Item(
            id: "cloak",
            name: "dark cloak",
            properties: .takable,
            .wearable,
            size: 2,
            parent: .location("startRoom")
        )
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
        let finalItemState = engine.item(with: "cloak")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasProperty(.touched) == true)
        #expect(finalItemState?.hasProperty(.worn) == false)
        #expect(engine.getPronounReference(pronoun: "it") == ["cloak"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(
            itemID: "cloak",
            initialParent: initialParent,
            initialTouched: false
        )
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Take item successfully from surface in room")
    func testTakeItemSuccessfullyFromSurface() async throws {
        // Arrange
        let surfaceItem = Item(
            id: "table",
            name: "wooden table",
            properties: .surface,
            parent: .location("startRoom")
        )
        let itemOnSurface = Item(
            id: "book",
            name: "old book",
            properties: .takable,
            .read,
            parent: .item(surfaceItem.id)
        )
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
        let finalItemState = engine.item(with: itemOnSurface.id)
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasProperty(.touched) == true)
        let finalSurfaceState = engine.item(with: surfaceItem.id)
        #expect(finalSurfaceState?.parent == .location("startRoom"))
        #expect(engine.getPronounReference(pronoun: "it") == [itemOnSurface.id])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(
            itemID: itemOnSurface.id,
            initialParent: initialParent,
            initialTouched: false
        )
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
        let finalItemState = engine.item(with: "key")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasProperty(.touched) == true) // Still touched
        #expect(engine.getPronounReference(pronoun: "it") == ["key"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

        // Assert Change History
        // Properties shouldn't change, so helper should only generate parent and pronoun changes
        let expectedChanges = expectedTakeChanges(
            itemID: "key",
            initialParent: initialParent,
            initialTouched: true
        )
        #expect(expectedChanges.count == 2, "Expected only parent and pronoun changes")
        #expect(!expectedChanges.contains { $0.propertyKey == .itemProperties }, "Should not contain property change")
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Take item at exact capacity")
    func testTakeItemAtExactCapacity() async throws {
        // Arrange: Player has capacity 10, holds item size 7, tries to take item size 3
        let heldItem = Item(
            id: "sword",
            name: "sword",
            properties: .takable,
            size: 7,
            parent: .player
        )
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
        let finalItemState = engine.item(with: "key")
        #expect(finalItemState?.parent == .player) // Should succeed
        #expect(finalItemState?.hasProperty(.touched) == true)
        #expect(engine.getPronounReference(pronoun: "it") == ["key"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(
            itemID: "key",
            initialParent: initialParent,
            initialTouched: false
        )
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
        let finalItemState = engine.item(with: "fly")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasProperty(.touched) == true)
        #expect(engine.getPronounReference(pronoun: "it") == ["fly"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

        // Assert Change History
        let expectedChanges = expectedTakeChanges(
            itemID: "fly",
            initialParent: initialParent,
            initialTouched: false
        )
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

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Your hands are full.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)

        // Assert: Check item parent DID NOT change
        let finalItemState = engine.item(with: "shield")
        #expect(finalItemState?.parent == .location("startRoom"), "Shield should still be in the room")
    }
}
