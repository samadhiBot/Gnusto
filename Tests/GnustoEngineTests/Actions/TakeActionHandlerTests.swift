import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("TakeActionHandler Tests")
struct TakeActionHandlerTests {
    let handler = TakeActionHandler()

    @Test("Take item successfully")
    func testTakeItemSuccessfully() async throws {
        // Arrange: Create data
        let testItem = Item(
            id: "key",
            name: "brass key",
            properties: .takable,
            size: 3, // Give size
            parent: .location("startRoom")
        )

        var game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        game.state.player.carryingCapacity = 10 // Set capacity

        let command = Command(verbID: "take", directObject: "key", rawInput: "take key")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check item parent changed
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.parent == .player, "Item should be held by player")

        // Check item has .touched property
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should have .touched property")

        // Check output message
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.", "Expected 'Taken.' message")
    }

    @Test("Take item fails when already held")
    func testTakeItemFailsWhenAlreadyHeld() async throws {
        // Arrange: Create data
        let testItem = Item(
            id: "key",
            name: "brass key",
            properties: .takable,
            parent: .player
        )

        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "take", directObject: "key", rawInput: "take key")

        // Act
        // Perform the action directly; expect it not to throw.
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check item parent DID NOT change
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.parent == .player, "Item should still be held by player")

        // Check output message
        let output = await mockIO.flush()
        expectNoDifference(output, "You already have that.")
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
        // Arrange: Minimal setup, no specific items needed
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Command with nil directObject
        let command = Command(verbID: "take", rawInput: "take")
        #expect(command.directObject == nil) // Verify command setup

        // Act
        // Expect no throw, just a message
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check output message
        let output = await mockIO.flush()
        expectNoDifference(output, "Take what?")
    }

    @Test("Take item successfully from open container in room")
    func testTakeItemSuccessfullyFromOpenContainerInRoom() async throws {
        // Arrange: Create container and item inside it
        let container = Item(
            id: "box",
            name: "wooden box",
            properties: .container, .open, // Open container
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

        let command = Command(verbID: "take", directObject: "gem", rawInput: "take gem") // Target the item inside

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check item parent changed to player
        let finalItemState = engine.itemSnapshot(with: "gem")
        #expect(finalItemState?.parent == .player, "Item should be held by player")

        // Check item has .touched property
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should have .touched property")

        // Check container state didn't change (still open, in room)
        let finalContainerState = engine.itemSnapshot(with: "box")
        #expect(finalContainerState?.parent == .location("startRoom"))
        #expect(finalContainerState?.hasProperty(.open) == true)

        // Check output message
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")
    }

    @Test("Take item successfully from open container held by player")
    func testTakeItemSuccessfullyFromOpenContainerHeld() async throws {
        // Arrange: Create container and item inside it
        let container = Item(
            id: "pouch",
            name: "leather pouch",
            properties: .container, .open, .takable,
            parent: .player
        ) // Open & Takable
        let itemInContainer = Item(
            id: "coin",
            name: "gold coin",
            properties: .takable,
            parent: .item("pouch")
        )

        let game = MinimalGame(items: [container, itemInContainer])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "take", directObject: "coin", rawInput: "take coin") // Target the item inside

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check item parent changed to player
        let finalItemState = engine.itemSnapshot(with: "coin")
        #expect(finalItemState?.parent == .player, "Item should be held by player")

        // Check item has .touched property
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should have .touched property")

        // Check container state didn't change (still open, held by player)
        let finalContainerState = engine.itemSnapshot(with: "pouch")
        #expect(finalContainerState?.parent == .player)
        #expect(finalContainerState?.hasProperty(.open) == true)

        // Check output message
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")
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
        // Arrange: Items with specific sizes
        let itemHeld = Item(
            id: "sword",
            name: "heavy sword",
            properties: .takable,
            size: 8,
            parent: .player
        )
        let itemToTake = Item(
            id: "shield",
            name: "large shield",
            properties: .takable,
            size: 7,
            parent: .location("startRoom")
        )

        var game = MinimalGame(items: [itemHeld, itemToTake])
        game.state.player.carryingCapacity = 10 // Capacity lower than combined size

        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Verify initial weight calculation is correct (optional but good)
        let initialWeight = engine.gameState.player.currentInventoryWeight(allItems: engine.gameState.items)
        #expect(initialWeight == 8)

        let command = Command(verbID: "take", directObject: "shield", rawInput: "take shield") // Try to take shield

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

    /// Tests that taking a wearable item successfully moves it to inventory but does not wear it.
    @Test("Take wearable item successfully (not worn)")
    func testTakeWearableItemSuccessfully() async throws {
        // Arrange: Create a wearable item
        let testItem = Item(
            id: "cloak",
            name: "dark cloak",
            properties: .takable,
            .wearable,
            size: 2,
            parent: .location("startRoom")
        )

        var game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        game.state.player.carryingCapacity = 10

        let command = Command(verbID: "take", directObject: "cloak", rawInput: "take cloak")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check item parent changed
        let finalItemState = engine.itemSnapshot(with: "cloak")
        #expect(finalItemState?.parent == .player, "Item should be held by player")

        // Check item has .touched property but NOT .worn
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should have .touched property")
        #expect(finalItemState?.hasProperty(.worn) == false, "Item should NOT have .worn property after just taking")

        // Check output message
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")
    }

    @Test("Take updates 'it' pronoun")
    func testTakeUpdatesPronoun() async throws {
        // Arrange
        let testItem = Item(
            id: "widget",
            name: "shiny widget",
            properties: .takable,
            parent: .location("startRoom")
        )

        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "take", directObject: testItem.id, rawInput: "take widget")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalPronounIt = engine.gameState.pronouns["it"]
        #expect(finalPronounIt == [testItem.id], "'it' pronoun should refer to the taken item")
        let output = await mockIO.flush()
        #expect(output == "Taken.")
    }

    @Test("Take item successfully from surface in room")
    func testTakeItemSuccessfullyFromSurface() async throws {
        // Arrange: Create surface and item on it
        let surfaceItem = Item(
            id: "table",
            name: "wooden table",
            properties: .surface,
            parent: .location("startRoom")
        )
        let itemOnSurface = Item(
            id: "book",
            name: "old book",
            properties: .takable, .read,
            parent: .item(surfaceItem.id)
        )

        var game = MinimalGame(items: [surfaceItem, itemOnSurface])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        game.state.player.carryingCapacity = 10

        let command = Command(verbID: "take", directObject: itemOnSurface.id, rawInput: "take book")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: itemOnSurface.id)
        #expect(finalItemState?.parent == .player, "Item should be held by player")
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should have .touched property")

        let finalSurfaceState = engine.itemSnapshot(with: surfaceItem.id)
        #expect(finalSurfaceState?.parent == .location("startRoom"))

        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")
    }
}
