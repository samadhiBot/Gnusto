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
        initialAttributes: [AttributeID: StateValue], // Use initial attributes map
        finalAttributes: [AttributeID: StateValue]? = nil // Optional final attributes map
    ) -> [StateChange] {
        var changes = [
            // Parent change
            StateChange(
                entityID: .item(itemID),
                attributeKey: .itemParent,
                oldValue: .parentEntity(initialParent),
                newValue: .parentEntity(finalParent)
            ),
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
                changes.append(StateChange(
                    entityID: .item(itemID),
                    attributeKey: .itemAttribute(key),
                    oldValue: oldValue,
                    newValue: newValue
                ))
            }
        }

        // Add pronoun change (assuming 'it' always refers to the taken item now)
        changes.append(StateChange(
            entityID: .global,
            attributeKey: .pronounReference(pronoun: "it"),
            oldValue: nil, // Simplified assumption: previous 'it' is irrelevant
            newValue: .itemIDSet([itemID])
        ))

        // Ensure touched is set if not already true
        let initialIsTouched = initialAttributes[.isTouched] // is Optional(StateValue)
        if initialIsTouched != true { // Correctly compares Optional != Non-optional
            let touchedChange = StateChange(
                entityID: .item(itemID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: initialIsTouched, // Keep original old value (nil or false)
                newValue: true,
            )

            // Avoid adding duplicate change if already handled by the general attribute comparison
            if let existingIndex = changes.firstIndex(where: { $0.attributeKey == .itemAttribute(.isTouched) }) {
                // If a change exists, make sure its newValue is true
                if changes[existingIndex].newValue != true {
                    changes[existingIndex] = touchedChange
                }
            } else {
                // If no change exists yet, add it
                changes.append(touchedChange)
            }
        }

        return changes.sorted() // Sort for consistent comparison
    }

    @Test("Take item successfully")
    func testTakeItemSuccessfully() async throws {
        // Arrange
        let testItem = Item(
            id: "key",
            name: "brass key",
            parent: .location("startRoom"),
            attributes: [
                .isTakable: true,
                .size: 3
            ]
        )
        let initialParent = testItem.parent
        let initialAttributes = testItem.attributes // Capture initial attributes
        // Define player with capacity
        let player = Player(in: "startRoom", carryingCapacity: 10)

        let game = MinimalGame(player: player, items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialPronounIt = await engine.getPronounReference(pronoun: "it") // Capture initial state

        let command = Command(verbID: "take", directObject: "key", rawInput: "take key")

        // Initial state check
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = await engine.item("key")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasFlag(.isTouched) == true) // Use convenience accessor
        #expect(await engine.getPronounReference(pronoun: "it") == ["key"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

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
            name: "brass key",
            parent: .player, // Already held
            attributes: [.isTakable: true]
        )
        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        let command = Command(verbID: "take", directObject: "key", rawInput: "take key")

        // Initial state check
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State (Unchanged)
        let finalItemState = await engine.item("key")
        #expect(finalItemState?.parent == .player)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You already have that.")

        // Assert Change History (Should be empty)
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Take item fails when not present in location")
    func testTakeItemFailsWhenNotPresent() async throws {
        // Arrange: Create item that *won't* be added to location
        let nonexistentItem = Item(
            id: "figurine",
            name: "jade figurine",
            parent: .nowhere, // Not in scope
            attributes: [.isTakable: true]
        )

        let game = MinimalGame(items: [nonexistentItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
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
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Assert: Check that the player is still holding nothing
        #expect(await engine.items(in: .player).isEmpty == true)
    }

    @Test("Take item fails when not takable")
    func testTakeItemFailsWhenNotTakable() async throws {
        // Arrange: Create item *without* .isTakable attribute
        let testItem = Item(
            id: "rock",
            name: "heavy rock",
            parent: .location("startRoom")
            // No .isTakable: true
        )

        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
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
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Assert: Check item parent DID NOT change
        let finalItemState = await engine.item("rock")
        #expect(finalItemState?.parent == .location("startRoom"), "Item should still be in the room")
    }

    @Test("Take fails with no direct object")
    func testTakeFailsWithNoObject() async throws {
        // Arrange
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        let command = Command(verbID: "take", rawInput: "take")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Take what?")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Take item successfully from open container in room")
    func testTakeItemSuccessfullyFromOpenContainerInRoom() async throws {
        // Arrange
        let container = Item(
            id: "box",
            name: "wooden box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpen: true // Explicitly open
            ]
        )
        let itemInContainer = Item(
            id: "gem",
            name: "ruby gem",
            parent: .item("box"),
            attributes: [.isTakable: true]
        )
        let initialParent = itemInContainer.parent
        let initialAttributes = itemInContainer.attributes // Capture initial

        let game = MinimalGame(items: [container, itemInContainer])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        let initialPronounIt = await engine.getPronounReference(pronoun: "it")

        let command = Command(verbID: "take", directObject: "gem", rawInput: "take gem")

        // Initial state check
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = await engine.item("gem")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasFlag(.isTouched) == true)
        let finalContainerState = await engine.item("box")
        #expect(finalContainerState?.parent == .location("startRoom"))
        #expect(finalContainerState?.hasFlag(.isOpen) == true) // Check flag
        #expect(await engine.getPronounReference(pronoun: "it") == ["gem"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

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
            name: "leather pouch",
            parent: .player,
            attributes: [
                .isContainer: true,
                .isOpen: true, // Explicitly open
                .isTakable: true // Player must be able to hold it
            ]
        )
        let itemInContainer = Item(
            id: "coin",
            name: "gold coin",
            parent: .item("pouch"),
            attributes: [.isTakable: true]
        )
        let initialParent = itemInContainer.parent
        let initialAttributes = itemInContainer.attributes // Capture initial

        let game = MinimalGame(items: [container, itemInContainer])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        let initialPronounIt = await engine.getPronounReference(pronoun: "it")

        let command = Command(verbID: "take", directObject: "coin", rawInput: "take coin")

        // Initial state check
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = await engine.item("coin")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasFlag(.isTouched) == true)
        let finalContainerState = await engine.item("pouch")
        #expect(finalContainerState?.parent == .player)
        #expect(finalContainerState?.hasFlag(.isOpen) == true) // Check flag
        #expect(await engine.getPronounReference(pronoun: "it") == ["coin"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

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
            name: "wooden box",
            parent: .location("startRoom"),
            attributes: [.isContainer: true] // Closed by default (no .isOpen)
        )
        let itemInContainer = Item(
            id: "gem",
            name: "ruby gem",
            parent: .item("box"),
            attributes: [.isTakable: true]
        )

        let game = MinimalGame(items: [container, itemInContainer])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        #expect(await engine.item("box")?.hasFlag(.isOpen) == false) // Verify closed

        let command = Command(verbID: "take", directObject: "gem", rawInput: "take gem")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush() // Define output before using it
        // ScopeResolver will prevent seeing it, standard message
        expectNoDifference(output, "You can't see any such thing.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Assert: Check item parent DID NOT change
        let finalItemState = await engine.item("gem")
        #expect(finalItemState?.parent == .item("box"), "Item should still be in the box")
    }

    @Test("Take item fails from non-container item")
    func testTakeItemFailsFromNonContainer() async throws {
        // Arrange: Create a non-container and an item 'inside' it
        let nonContainer = Item(
            id: "statue",
            name: "stone statue",
            parent: .location("startRoom")
            // Not a container by default
        )
        let itemInside = Item(
            id: "chip",
            name: "stone chip",
            parent: .item("statue"),
            attributes: [.isTakable: true]
        )

        let game = MinimalGame(items: [nonContainer, itemInside])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        #expect(await engine.item("statue")?.hasFlag(.isContainer) == false) // Verify statue is not container

        // Command targets the chip, but context is "from statue"
        let command = Command(
            verbID: "take",
            directObject: "chip",
            indirectObject: "statue", // Specify source
            rawInput: "take chip from statue"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't take things out of the stone statue.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Assert: Check item parent DID NOT change
        let finalItemState = await engine.item("chip")
        #expect(finalItemState?.parent == .item("statue"), "Chip should still be parented to statue")
    }

    @Test("Take item fails when capacity exceeded")
    func testTakeItemFailsWhenCapacityExceeded() async throws {
        // Arrange
        let heavyItem = Item(
            id: "heavy",
            name: "heavy thing",
            parent: .location("startRoom"),
            attributes: [
                .isTakable: true,
                .size: 101 // Exceeds default capacity (100) if player has 0
            ]
        )
        // Player with capacity 0
        let player = Player(in: "startRoom", carryingCapacity: 0)
        let game = MinimalGame(player: player, items: [heavyItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(verbID: "take", directObject: "heavy", rawInput: "take heavy")

        // We need to use the engine.execute to get the standard error message
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Your hands are full.") // Check standard message

        // Assert no state changes occurred
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Assert item is still in the room
        #expect(await engine.item("heavy")?.parent == .location("startRoom"))
    }

    /// Tests that taking a wearable item successfully moves it to inventory but does not wear it.
    @Test("Take wearable item successfully (not worn)")
    func testTakeWearableItemSuccessfully() async throws {
        // Arrange
        let testItem = Item(
            id: "cloak",
            name: "dark cloak",
            parent: .location("startRoom"),
            attributes: [
                .isTakable: true,
                .isWearable: true,
                .size: 2
            ]
        )
        let initialParent = testItem.parent
        let initialAttributes = testItem.attributes // Capture initial
        // Define player with capacity
        let player = Player(in: "startRoom", carryingCapacity: 10)

        let game = MinimalGame(player: player, items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        let initialPronounIt = await engine.getPronounReference(pronoun: "it")

        let command = Command(verbID: "take", directObject: "cloak", rawInput: "take cloak")

        // Initial state check
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = await engine.item("cloak")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasFlag(.isTouched) == true)
        #expect(finalItemState?.hasFlag(.isWorn) == false) // Not worn
        #expect(await engine.getPronounReference(pronoun: "it") == ["cloak"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

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
            name: "wooden table",
            parent: .location("startRoom"),
            attributes: [.isSurface: true]
        )
        let itemOnSurface = Item(
            id: "book",
            name: "old book",
            parent: .item(surfaceItem.id),
            attributes: [
                .isTakable: true,
                .isReadable: true
            ]
        )
        let initialParent = itemOnSurface.parent
        let initialAttributes = itemOnSurface.attributes // Capture initial
        // Define player with capacity
        let player = Player(in: "startRoom", carryingCapacity: 10)

        let game = MinimalGame(player: player, items: [surfaceItem, itemOnSurface])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        let initialPronounIt = await engine.getPronounReference(pronoun: "it")

        let command = Command(verbID: "take", directObject: itemOnSurface.id, rawInput: "take book")

        // Initial state check
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = await engine.item(itemOnSurface.id)
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasFlag(.isTouched) == true)
        let finalSurfaceState = await engine.item(surfaceItem.id)
        #expect(finalSurfaceState?.parent == .location("startRoom"))
        #expect(await engine.getPronounReference(pronoun: "it") == [itemOnSurface.id])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

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
            name: "brass key",
            parent: .location("startRoom"),
            attributes: [
                .isTakable: true,
                .isTouched: true, // Start touched
                .size: 3
            ]
        )
        let initialParent = testItem.parent
        let initialAttributes = testItem.attributes // Includes .isTouched: true
        // Define player with capacity
        let player = Player(in: "startRoom", carryingCapacity: 10)

        let game = MinimalGame(player: player, items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialPronounIt = await engine.getPronounReference(pronoun: "it")

        let command = Command(verbID: "take", directObject: "key", rawInput: "take key")

        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Act
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = await engine.item("key")
        #expect(finalItemState?.parent == .player)
        #expect(finalItemState?.hasFlag(.isTouched) == true) // Still touched
        #expect(await engine.getPronounReference(pronoun: "it") == ["key"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

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
        #expect(!expectedChanges.contains { $0.attributeKey == .itemAttribute(.isTouched) }, "Should not contain isTouched change")
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory.sorted(), expectedChanges)
    }


    @Test("Take item at exact capacity")
    func testTakeItemAtExactCapacity() async throws {
        // Arrange: Player has capacity 10, holds item size 7, tries to take item size 3
        let heldItem = Item(
            id: "sword",
            name: "sword",
            parent: .player,
            attributes: [
                .isTakable: true,
                .size: 7
            ]
        )
        let itemToTake = Item(
            id: "key",
            name: "brass key",
            parent: .location("startRoom"),
            attributes: [
                .isTakable: true,
                .size: 3
            ]
        )
        let initialParent = itemToTake.parent
        let initialAttributes = itemToTake.attributes // Capture initial
        // Define player with capacity
        let player = Player(in: "startRoom", carryingCapacity: 10)

        let game = MinimalGame(player: player, items: [heldItem, itemToTake])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialPronounIt = await engine.getPronounReference(pronoun: "it")

        let command = Command(verbID: "take", directObject: "key", rawInput: "take key")

        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Act
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = await engine.item("key")
        #expect(finalItemState?.parent == .player) // Should succeed
        #expect(finalItemState?.hasFlag(.isTouched) == true)
        #expect(await engine.getPronounReference(pronoun: "it") == ["key"])

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Taken.")

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
            name: "glass jar",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isTransparent: true // Closed by default, but transparent
            ]
        )
        let itemInContainer = Item(
            id: "fly",
            name: "dead fly",
            parent: .item("jar"),
            attributes: [.isTakable: true]
        )
        let initialParent = itemInContainer.parent
        let initialAttributes = itemInContainer.attributes // Capture initial
        // Define player with capacity
        let player = Player(in: "startRoom", carryingCapacity: 10)

        let game = MinimalGame(player: player, items: [container, itemInContainer])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialPronounIt = await engine.getPronounReference(pronoun: "it")

        let command = Command(verbID: "take", directObject: "fly", rawInput: "take fly")

        #expect(await engine.gameState.changeHistory.isEmpty == true)
        #expect(await engine.item("jar")?.hasFlag(.isOpen) == false) // Verify closed
        #expect(await engine.item("jar")?.hasFlag(.isTransparent) == true) // Verify transparent

        // Act: ScopeResolver sees through transparent containers, but TakeActionHandler should still check if container is open
        await engine.execute(command: command)

        // Assert Output - Should fail because container is closed
        let output = await mockIO.flush()
        expectNoDifference(output, "You have to open the glass jar first.") // Updated expected message

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Assert: Check item parent DID NOT change
        let finalItemState = await engine.item("fly")
        #expect(finalItemState?.parent == .item("jar"), "Fly should still be in the jar")
    }

    @Test("Take item fails due to player capacity")
    func testTakeItemFailsDueToCapacity() async throws {
        // Arrange: Player holds item, capacity is low, try to take another
        let itemHeld = Item(
            id: "sword",
            name: "sword",
            parent: .player,
            attributes: [
                .isTakable: true,
                .size: 8
            ]
        )
        let itemToTake = Item(
            id: "shield",
            name: "shield",
            parent: .location("startRoom"),
            attributes: [
                .isTakable: true,
                .size: 7
            ]
        )
        // Define player with low capacity
        let player = Player(in: "startRoom", carryingCapacity: 10)

        let game = MinimalGame(player: player, items: [itemHeld, itemToTake])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verbID: "take", directObject: "shield", rawInput: "take shield")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Your hands are full.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Assert: Check item parent DID NOT change
        let finalItemState = await engine.item("shield")
        #expect(finalItemState?.parent == .location("startRoom"), "Shield should still be in the room")
    }
}

// Helper to sort StateChange arrays for comparison
extension Array where Element == StateChange {
    func sorted() -> [StateChange] {
        sorted(by: { $0 < $1 })
    }
}
