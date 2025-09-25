import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ItemProxy Movement Tests")
struct ItemProxyMovementTests {
    @Test("availableExits returns all exits for .any movement behavior")
    func testAvailableExitsAnyBehavior() async throws {
        // Given: A location with various types of exits
        let hallway = Location(
            id: "hallway",
            .name("Hallway"),
            .inherentlyLit,
            .exits(
                .north("library"),  // Normal open exit
                .south("kitchen", via: "kitchenDoor"),  // Exit with door
                .east(blocked: "The wall is too thick"),  // Permanently blocked
                .west("garden")  // Another normal exit
            )
        )

        let library = Location(
            id: "library",
            .name("Library"),
            .inherentlyLit
        )

        let kitchen = Location(
            id: "kitchen",
            .name("Kitchen"),
            .inherentlyLit
        )

        let garden = Location(
            id: "garden",
            .name("Garden"),
            .inherentlyLit
        )

        let kitchenDoor = Item(
            id: "kitchenDoor",
            .name("kitchen door"),
            .isLocked,
            .in("hallway")
        )

        let npc = Item(
            id: "guard",
            .name("guard"),
            .in("hallway")
        )

        let game = MinimalGame(
            player: Player(in: "library"),
            locations: hallway, library, kitchen, garden,
            items: kitchenDoor, npc
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting available exits with .any behavior
        let guardProxy = await engine.item("guard")
        let availableExits = await guardProxy.availableExits(behavior: .any)

        // Then: All exits should be available regardless of doors or blocked messages
        expectNoDifference(availableExits, [
            .north("library"),
            .east(blocked: "The wall is too thick"),
            .south("kitchen", via: "kitchenDoor"),
            .west("garden"),
        ])
    }

    @Test("availableExits filters properly for .normal movement behavior")
    func testAvailableExitsNormalBehavior() async throws {
        // Given: A location with doors in various states
        let hallway = Location(
            id: "hallway",
            .name("Hallway"),
            .inherentlyLit,
            .exits(
                .north("library"),  // Normal open exit
                .south("kitchen", via: "kitchenDoor"),  // Closed door
                .east("study", via: "studyDoor"),  // Open door
                .west(blocked: "The wall blocks your way")  // Blocked exit
            )
        )

        let library = Location(id: "library", .name("Library"), .inherentlyLit)
        let kitchen = Location(id: "kitchen", .name("Kitchen"), .inherentlyLit)
        let study = Location(id: "study", .name("Study"), .inherentlyLit)

        let kitchenDoor = Item(
            id: "kitchenDoor",
            .name("kitchen door"),
            .in("hallway")
        )

        let studyDoor = Item(
            id: "studyDoor",
            .name("study door"),
            .isOpen,
            .in("hallway")
        )

        let npc = Item(
            id: "merchant",
            .name("merchant"),
            .in("hallway")
        )

        let game = MinimalGame(
            player: Player(in: "library"),
            locations: hallway, library, kitchen, study,
            items: kitchenDoor, studyDoor, npc
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting available exits with normal behavior
        let merchantProxy = await engine.item("merchant")
        let availableExits = await merchantProxy.availableExits(behavior: .normal)

        // Then: Only open exits and open doors should be available
        expectNoDifference(availableExits, [
            .north("library"),
            .east("study", via: "studyDoor"),
        ])
    }

    @Test("availableExits handles .closedDoors movement behavior")
    func testAvailableExitsClosedDoorsBehavior() async throws {
        // Given: Doors in various locked/unlocked states
        let room = Location(
            id: "room",
            .name("Room"),
            .inherentlyLit,
            .exits(
                .north("hall1", via: "door1"),  // Closed, unlocked
                .south("hall2", via: "door2"),  // Closed, locked
                .east("hall3", via: "door3")  // Open
            )
        )

        let hall1 = Location(id: "hall1", .name("Hall 1"), .inherentlyLit)
        let hall2 = Location(id: "hall2", .name("Hall 2"), .inherentlyLit)
        let hall3 = Location(id: "hall3", .name("Hall 3"), .inherentlyLit)

        let door1 = Item(
            id: "door1",
            .name("door 1"),
            .in("room")
        )

        let door2 = Item(
            id: "door2",
            .name("door 2"),
            .isLocked,  // Closed and locked
            .in("room")
        )

        let door3 = Item(
            id: "door3",
            .name("door 3"),
            .isOpen,  // Open
            .in("room")
        )

        let npc = Item(
            id: "thief",
            .name("thief"),
            .in("room")
        )

        let game = MinimalGame(
            player: Player(in: "hall1"),
            locations: room, hall1, hall2, hall3,
            items: door1, door2, door3, npc
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting available exits with .closedDoors behavior
        let thiefProxy = await engine.item("thief")
        let availableExits = await thiefProxy.availableExits(behavior: .closedDoors)

        // Then: Should be able to pass through open doors and closed unlocked doors
        expectNoDifference(availableExits, [
            .north("hall1", via: "door1"),
            .east("hall3", via: "door3"),
        ])
    }

    @Test("availableExits handles .lockedDoorsUnlockedByKeys movement behavior")
    func testAvailableExitsWithKeys() async throws {
        // Given: Locked doors with specific keys
        let room = Location(
            id: "room",
            .name("Room"),
            .inherentlyLit,
            .exits(
                .north("vault", via: "vaultDoor"),
                .south("safe", via: "safeDoor")
            )
        )

        let vault = Location(id: "vault", .name("Vault"), .inherentlyLit)
        let safe = Location(id: "safe", .name("Safe"), .inherentlyLit)

        let vaultDoor = Item(
            id: "vaultDoor",
            .name("vault door"),
            .isLocked,
            .lockKey("vaultKey"),
            .in("room")
        )

        let safeDoor = Item(
            id: "safeDoor",
            .name("safe door"),
            .isLocked,
            .lockKey("safeKey"),
            .in("room")
        )

        let npc = Item(
            id: "burglar",
            .name("burglar"),
            .in("room")
        )

        let game = MinimalGame(
            player: Player(in: "vault"),
            locations: room, vault, safe,
            items: vaultDoor, safeDoor, npc
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting available exits with specific keys
        let burglarProxy = await engine.item("burglar")
        let availableExitsWithVaultKey = await burglarProxy.availableExits(
            behavior: .lockedDoorsUnlockedByKeys(["vaultKey"])
        )

        // Then: Should only be able to pass through vault door
        expectNoDifference(availableExitsWithVaultKey, [
            .north("vault", via: "vaultDoor"),
        ])

        // When: Getting available exits with both keys
        let availableExitsWithBothKeys = await burglarProxy.availableExits(
            behavior: .lockedDoorsUnlockedByKeys(["vaultKey", "safeKey"])
        )

        // Then: Should be able to pass through all doors
        expectNoDifference(availableExitsWithBothKeys, [
            .north("vault", via: "vaultDoor"),
            .south("safe", via: "safeDoor"),
        ])
    }

    @Test("availableExits returns empty array for NPC with no location")
    func testAvailableExitsWithNoLocation() async throws {
        // Given: An NPC not in any location
        let room = Location(
            id: "room",
            .name("Room"),
            .inherentlyLit
        )

        let npc = Item(
            id: "ghost",
            .name("ghost"),
            .in(.nowhere)  // Not in any location
        )

        let game = MinimalGame(
            player: Player(in: "room"),
            locations: room,
            items: npc
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting available exits
        let ghostProxy = await engine.item("ghost")
        let availableExits = await ghostProxy.availableExits()

        // Then: Should return empty array
        #expect(availableExits.isEmpty)
    }

    @Test("availableExits returns empty array for location with no exits")
    func testAvailableExitsWithNoExits() async throws {
        // Given: A location with no exits
        let trap = Location(
            id: "trap",
            .name("Trap Room"),
            .inherentlyLit
            // No exits defined
        )

        let npc = Item(
            id: "prisoner",
            .name("prisoner"),
            .in("trap")
        )

        let game = MinimalGame(
            player: Player(in: "trap"),
            locations: trap,
            items: npc
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting available exits
        let prisonerProxy = await engine.item("prisoner")
        let availableExits = await prisonerProxy.availableExits()

        // Then: Should return empty array
        #expect(availableExits.isEmpty)
    }
}
