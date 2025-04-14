import CustomDump
import Testing

@testable import Gnusto

@Suite("PutIn Command Handler Tests")
struct PutInTests {
    @Test("Put item into open container")
    func testPutInOpenContainer() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let chest = Object.item(
            id: "chest",
            name: "wooden chest",
            description: "A sturdy wooden chest.",
            flags: .container, .openable,
            location: "room",
            ContainerComponent(isOpen: true, capacity: 10)
        )

        let coin = Object.item(
            id: "coin",
            name: "gold coin",
            description: "A shiny gold coin.",
            flags: .takeable,
            location: "player"
        )

        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(chest, coin, room)
        world.movePlayer(to: "room")
        // Move coin explicitly to player inventory *after* adding player/coin
        world.move(coin.id, to: world.player.id)

        // Act
        let command = UserInput(verb: "put", directObject: "coin", prepositions: ["in"], indirectObject: "chest", rawInput: "put coin in chest")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert
        let expectedEffects: [Effect] = [.showText("You put the gold coin in the wooden chest.")]
        expectNoDifference(effects, expectedEffects)

        // Verify item location
        guard let coin = world.find("coin"),
              let location = coin.find(LocationComponent.self) else {
            throw TestFailure("Coin not found or missing location")
        }
        #expect(location.parentID == "chest")
    }

    @Test("Cannot put item into non-container")
    func testPutInNonContainer() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let table = Object.item(
            id: "table",
            name: "wooden table",
            description: "A plain wooden table.",
            location: "room"
        )

        let coin = Object.item(
            id: "coin",
            name: "gold coin",
            description: "A shiny gold coin.",
            flags: .takeable,
            location: "player"
        )

        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(table, coin, room)
        world.movePlayer(to: "room")
        // Move coin explicitly to player inventory
        world.move(coin.id, to: world.player.id)

        // Act
        let command = UserInput(verb: "put", directObject: "coin", prepositions: ["in"], indirectObject: "table", rawInput: "put coin in table")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert
        let expectedEffects: [Effect] = [.showText("You can't put anything in the wooden table.")]
        expectNoDifference(effects, expectedEffects)

        // Verify item location (should still be player)
        guard let coin = world.find("coin"),
              let location = coin.find(LocationComponent.self) else {
            throw TestFailure("Coin not found or missing location")
        }
        #expect(location.parentID == "player")
    }

    @Test("Cannot put item into closed container")
    func testPutInClosedContainer() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let chest = Object.item(
            id: "chest",
            name: "wooden chest",
            description: "A sturdy wooden chest.",
            flags: .container, .openable,
            location: "room",
            ContainerComponent(isOpen: false, capacity: 10) // Starts closed
        )

        let coin = Object.item(
            id: "coin",
            name: "gold coin",
            description: "A shiny gold coin.",
            flags: .takeable,
            location: "player"
        )

        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(chest, coin, room)
        world.movePlayer(to: "room")
        // Move coin explicitly to player inventory
        world.move(coin.id, to: world.player.id)

        // Act
        let command = UserInput(verb: "put", directObject: "coin", prepositions: ["in"], indirectObject: "chest", rawInput: "put coin in chest")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert
        let expectedEffects: [Effect] = [.showText("The wooden chest is closed.")]
        expectNoDifference(effects, expectedEffects)

        // Verify item location (should still be player)
        guard let coin = world.find("coin"),
              let location = coin.find(LocationComponent.self) else {
            throw TestFailure("Coin not found or missing location")
        }
        #expect(location.parentID == "player")
    }

    @Test("Cannot put item not held")
    func testPutItemNotHeld() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let chest = Object.item(
            id: "chest",
            name: "wooden chest",
            description: "A sturdy wooden chest.",
            flags: .container, .openable,
            location: "room",
            ContainerComponent(isOpen: true, capacity: 10)
        )

        let coin = Object.item(
            id: "coin",
            name: "gold coin",
            description: "A shiny gold coin.",
            flags: .takeable,
            location: "room" // Location ID only - starts in room
        )

        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(chest, coin, room)
        world.movePlayer(to: "room")

        // Act
        let command = UserInput(verb: "put", directObject: "coin", prepositions: ["in"], indirectObject: "chest", rawInput: "put coin in chest")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert
        let expectedEffects: [Effect] = [.showText("You aren't holding that.")]
        expectNoDifference(effects, expectedEffects)
    }

    @Test("Cannot put container into itself")
    func testPutContainerInSelf() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let bag = Object.item(
            id: "bag",
            name: "leather bag",
            description: "A simple leather bag.",
            flags: .container, .openable, .takeable,
            location: "player",
            ContainerComponent(isOpen: true, capacity: 5)
        )

        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(bag, room)
        world.movePlayer(to: "room")
        // Move bag explicitly to player inventory
        world.move(bag.id, to: world.player.id)

        // Act: Try to put the bag into itself
        let command = UserInput(verb: "put", directObject: "bag", prepositions: ["in"], indirectObject: "bag", rawInput: "put bag in bag")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert
        let expectedEffects: [Effect] = [.showText("You can't put something in itself.")]
        expectNoDifference(effects, expectedEffects)
    }

    // Removed testPutInPerson as .person flag was removed

    // Test putting item ON a surface (uses PutInHandler but checks surface flag)
    @Test("Put item on surface")
    func testPutOnSurface() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let table = Object.item(
            id: "table",
            name: "wooden table",
            description: "A sturdy wooden table.",
            flags: .surface, .container,
            location: "room",
            ContainerComponent(isOpen: true, capacity: 10)
        )

        let cup = Object.item(
            id: "cup",
            name: "tin cup",
            description: "A simple tin cup.",
            flags: .takeable,
            location: "player"
        )

        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(table, cup, room)
        world.movePlayer(to: "room")
        // Move cup explicitly to player inventory
        world.move(cup.id, to: world.player.id)

        // Act
        let command = UserInput(verb: "put", directObject: "cup", prepositions: ["on"], indirectObject: "table", rawInput: "put cup on table")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert: Handler should adapt message for surfaces
        let expectedEffects: [Effect] = [.showText("You put the tin cup on the wooden table.")]
        expectNoDifference(effects, expectedEffects)

        // Verify item location
        guard let cup = world.find("cup"),
              let location = cup.find(LocationComponent.self) else {
            throw TestFailure("Cup not found or missing location")
        }
        #expect(location.parentID == "table")
    }

    @Test("Cannot put item on non-surface")
    func testPutOnNonSurface() throws {
         // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let chest = Object.item(
            id: "chest",
            name: "wooden chest",
            description: "A sturdy wooden chest.",
            flags: .container, .openable,
            location: "room",
            ContainerComponent(isOpen: true, capacity: 10)
        )

        let cup = Object.item(
            id: "cup",
            name: "tin cup",
            description: "A simple tin cup.",
            flags: .takeable,
            location: "player"
        )

        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(chest, cup, room)
        world.movePlayer(to: "room")
        // Move cup explicitly to player inventory
        world.move(cup.id, to: world.player.id)

        // Act
        let command = UserInput(verb: "put", directObject: "cup", prepositions: ["on"], indirectObject: "chest", rawInput: "put cup on chest")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert: Should get a message indicating it's not a surface
        let expectedEffects: [Effect] = [.showText("You can't put things on the wooden chest.")]
        expectNoDifference(effects, expectedEffects)
    }

    // Add more tests: container full, putting item inside nested container, etc.
}
