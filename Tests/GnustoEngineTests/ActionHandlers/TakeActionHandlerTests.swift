import Testing
@testable import GnustoEngine

@Suite
struct TakeActionHandlerTests {
    private var engine: GnustoEngine!
    private var player: Actor!
    private var room: Location!
    private var lamp: Item!
    private var table: Item! // Added for surface test
    private var box: Item! // Added for container test
    private var stone: Item! // Added for non-container test


    init() async throws {
        engine = GnustoEngine()
        player = await engine.player
        room = await engine.currentLocation
        lamp = Item(id: "brass-lamp", name: "brass lamp", description: "A tarnished brass lamp.", isTakable: true)
        table = Item(id: "table", name: "table", description: "A sturdy wooden table.", isTakable: false) // Table is not takable
        table.contents = .surface(.init(capacity: 5)) // Make table a surface
        box = Item(id: "box", name: "box", description: "A small wooden box.", isTakable: true)
        box.contents = .container(.init(capacity: 3, isOpen: true)) // Make box a container
        stone = Item(id: "stone", name: "stone", description: "A smooth grey stone.", isTakable: true) // Stone is takable, but not a container

        await engine.add(item: lamp, to: room)
        await engine.add(item: table, to: room) // Add table to room
        await engine.add(item: box, to: room) // Add box to room
        await engine.add(item: stone, to: room) // Add stone to room
    }

    // MARK: - Success Cases

    @Test func testTakeItemSuccessfully() async throws {
        let result = try await TakeActionHandler().handleAction(context: .init(engine: engine, directObject: lamp))
        #expect(result.output == "Taken.")
        let playerInventory = await player.inventory
        #expect(playerInventory.contains(lamp.id))
        let roomContents = await room.items
        #expect(!roomContents.contains(lamp.id))
    }

    /// Tests that taking an item successfully updates the "it" pronoun.
    @Test func testTakeUpdatesPronoun() async throws {
        _ = try await TakeActionHandler().handleAction(context: .init(engine: engine, directObject: lamp))
        let itPronoun = await engine.gameState.pronouns["it"]
        #expect(itPronoun == .object(lamp.id))
    }

    /// Tests taking an item successfully from a surface.
    @Test func testTakeItemSuccessfullyFromSurface() async throws {
        // Put the lamp on the table first
        await engine.add(item: lamp, to: table)

        let result = try await TakeActionHandler().handleAction(context: .init(engine: engine, directObject: lamp))
        #expect(result.output == "Taken.")

        let playerInventory = await player.inventory
        #expect(playerInventory.contains(lamp.id))

        let tableSurface = await table.contents.asSurface
        #expect(tableSurface?.items.contains(lamp.id) == false)
    }

    /// Tests taking an item successfully from an open container.
    @Test func testTakeItemSuccessfullyFromContainer() async throws {
        // Put the lamp in the box first
        await engine.add(item: lamp, to: box)

        let result = try await TakeActionHandler().handleAction(context: .init(engine: engine, directObject: lamp))
        #expect(result.output == "Taken.")

        let playerInventory = await player.inventory
        #expect(playerInventory.contains(lamp.id))

        let boxContainer = await box.contents.asContainer
        #expect(boxContainer?.items.contains(lamp.id) == false)
    }


    // MARK: - Failure Cases

    @Test func testTakeItemFailsWhenNotTakable() async throws {
        let untakableItem = Item(id: "statue", name: "stone statue", description: "A heavy stone statue.", isTakable: false)
        await engine.add(item: untakableItem, to: room)
        await #expect(throws: ActionError.itemNotTakable(untakableItem.id)) {
            _ = try await TakeActionHandler().handleAction(context: .init(engine: engine, directObject: untakableItem))
        }
    }

    @Test func testTakeItemFailsWhenAlreadyHeld() async throws {
        await engine.add(item: lamp, to: player) // Put lamp in player's inventory
        await #expect(throws: ActionError.itemNotHeld(lamp.id)) { // Should fail as if not present in room
            _ = try await TakeActionHandler().handleAction(context: .init(engine: engine, directObject: lamp))
        }
    }

    @Test func testTakeItemFailsWhenNotInReach() async throws {
        // Item exists but is not in the current location or player inventory
        let distantItem = Item(id: "distant-coin", name: "distant coin", description: "A coin far away.", isTakable: true)
        // Do not add distantItem to the engine's current location or player

        await #expect(throws: ActionError.itemNotHeld(distantItem.id)) {
            _ = try await TakeActionHandler().handleAction(context: .init(engine: engine, directObject: distantItem))
        }
    }

    @Test func testTakeItemFailsFromClosedContainer() async throws {
        let closedBox = Item(id: "closed-box", name: "closed box", description: "A sealed wooden box.", isTakable: true)
        closedBox.contents = .container(.init(capacity: 3, isOpen: false)) // Closed container
        await engine.add(item: closedBox, to: room)
        let key = Item(id: "key", name: "key", description: "A small key.", isTakable: true)
        await engine.add(item: key, to: closedBox) // Put key inside

        await #expect(throws: ActionError.itemNotHeld(key.id)) { // Should fail as if not present
            _ = try await TakeActionHandler().handleAction(context: .init(engine: engine, directObject: key))
        }
    }

    @Test func testTakeItemFailsFromNonContainer() async throws {
        // Try to take the lamp *from* the stone (which is not a container or surface)
        // Place lamp near stone for context, but the 'from' is the key part
        await engine.add(item: lamp, to: room)
        await engine.add(item: stone, to: room)

        await #expect(throws: ActionError.prerequisiteNotMet) { // Expecting generic prerequisite failure
            _ = try await TakeActionHandler().handleAction(context: .init(engine: engine, directObject: lamp, indirectObject: stone))
        }
        // Verify lamp is still in the room
        let roomItems = await room.items
        #expect(roomItems.contains(lamp.id))
    }

    @Test func testTakeItemFailsWhenNotPresent() async throws {
        let nonExistentItem = Item(id: "ghost", name: "ghost", description: "A non-existent ghost.", isTakable: true)
        // Do not add nonExistentItem anywhere

        await #expect(throws: ActionError.itemNotHeld(nonExistentItem.id)) {
             _ = try await TakeActionHandler().handleAction(context: .init(engine: engine, directObject: nonExistentItem))
        }
    }

    @Test func testTakeItemFailsWhenPlayerInventoryFull() async throws {
        player.maxCarryCapacity = 1 // Set player capacity to 1
        let firstItem = Item(id: "item1", name: "item 1", description: "First item.", isTakable: true)
        await engine.add(item: firstItem, to: player) // Player already holding one item

        let secondItem = Item(id: "item2", name: "item 2", description: "Second item.", isTakable: true)
        await engine.add(item: secondItem, to: room) // Second item is in the room

        await #expect(throws: ActionError.playerCannotCarryMore) {
            _ = try await TakeActionHandler().handleAction(context: .init(engine: engine, directObject: secondItem))
        }
        // Verify second item is still in the room
        let roomItems = await room.items
        #expect(roomItems.contains(secondItem.id))
    }
}

extension ActionError: @retroactive Swift.LocalizedError {
    public var errorDescription: String? {
        // Provide user-friendly descriptions for errors if needed
        // This is primarily for debugging or testing, not game output
        switch self {
        case .prerequisiteNotMet(let reason): return "Prerequisite not met: \\(reason)"
        case .internalEngineError(let reason): return "Internal engine error: \\(reason)"
        case .invalidDirection: return "Invalid direction."
        case .directionIsBlocked(let reason): return "Direction is blocked" + (reason.map { ": \\($0)" } ?? ".")
        case .itemNotTakable(let itemID): return "Item '\\(itemID)' cannot be taken."
        case .itemNotDroppable(let itemID): return "Item '\\(itemID)' cannot be dropped."
        case .itemNotOpenable(let itemID): return "Item '\\(itemID)' cannot be opened."
        case .itemNotCloseable(let itemID): return "Item '\\(itemID)' cannot be closed."
        case .itemNotLockable(let itemID): return "Item '\\(itemID)' cannot be locked."
        case .itemNotUnlockable(let itemID): return "Item '\\(itemID)' cannot be unlocked."
        case .itemNotEdible(let itemID): return "Item '\\(itemID)' cannot be eaten."
        case .itemNotReadable(let itemID): return "Item '\\(itemID)' cannot be read."
        case .itemNotWearable(let itemID): return "Item '\\(itemID)' cannot be worn."
        case .itemNotRemovable(let itemID): return "Item '\\(itemID)' cannot be removed."
        case .itemAlreadyOpen(let itemID): return "Item '\\(itemID)' is already open."
        case .itemAlreadyClosed(let itemID): return "Item '\\(itemID)' is already closed."
        case .itemIsLocked(let itemID): return "Item '\\(itemID)' is locked."
        case .itemIsUnlocked(let itemID): return "Item '\\(itemID)' is unlocked."
        case .wrongKey(let keyID, let lockID): return "Key '\\(keyID)' does not fit the lock on '\\(lockID)'."
        case .targetIsNotAContainer(let itemID): return "'\\(itemID)' is not a container."
        case .targetIsNotASurface(let itemID): return "'\\(itemID)' is not a surface."
        case .containerIsClosed(let itemID): return "Container '\\(itemID)' is closed."
        case .containerIsOpen(let itemID): return "Container '\\(itemID)' is already open."
        case .containerIsFull(let itemID): return "Container '\\(itemID)' is full."
        case .itemNotInContainer(let item, let container): return "Item '\\(item)' is not in container '\\(container)'."
        case .itemNotOnSurface(let item, let surface): return "Item '\\(item)' is not on surface '\\(surface)'."
        case .playerCannotCarryMore: return "Player cannot carry any more."
        case .itemNotHeld(let itemID): return "Item '\\(itemID)' is not held by the player or accessible." // Updated description
        }
    }
}

// Helper to get Surface component, useful in tests
extension ComponentContainer {
    var asSurface: SurfaceComponent? {
        get async {
            if case .surface(let surface) = self { return surface }
            return nil
        }
    }
    var asContainer: ContainerComponent? {
        get async {
            if case .container(let container) = self { return container }
            return nil
        }
    }
}
