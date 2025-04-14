import CustomDump
import Testing

@testable import Gnusto

@Suite("Wear Command Handler Tests")
struct WearTests {
    @Test("Can wear a wearable item from inventory")
    func testWearWearableFromInventory() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let cloak = Object.item(
            id: "cloak",
            name: "velvet cloak",
            description: "A luxurious velvet cloak.",
            flags: .wearable, .takeable,
            location: "player" // Start in inventory
        )
        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(cloak, room)
        world.movePlayer(to: "room")
        // Move cloak explicitly to player inventory
        world.move(cloak.id, to: world.player.id)

        // Act
        let command = UserInput(verb: "wear", directObject: "cloak", rawInput: "wear cloak")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert
        let expectedEffects: [Effect] = [.showText("You put on the velvet cloak.")]
        expectNoDifference(effects, expectedEffects)

        // Verify flag
        guard let cloak = world.find("cloak") else {
            throw TestFailure("Could not find cloak object")
        }
        #expect(cloak.find(ObjectComponent.self)?.flags.contains(.worn) == true)
    }

    @Test("Cannot wear non-wearable item")
    func testWearNonWearable() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let book = Object.item(
            id: "book",
            name: "heavy book",
            description: "A large, heavy book.",
            flags: .takeable, // Not wearable
            location: "player"
        )
        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(book, room)
        world.movePlayer(to: "room")
        // Move book explicitly to player inventory
        world.move(book.id, to: world.player.id)

        // Act
        let command = UserInput(verb: "wear", directObject: "book", rawInput: "wear book")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert
        let expectedEffects: [Effect] = [.showText("You can't wear that.")]
        expectNoDifference(effects, expectedEffects)

        // Verify flag (should not be worn)
        guard let book = world.find("book") else {
            throw TestFailure("Could not find book object")
        }
        #expect(book.find(ObjectComponent.self)?.flags.contains(.worn) == false)
    }

    @Test("Cannot wear item not in inventory")
    func testWearItemNotInInventory() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let cloak = Object.item(
            id: "cloak",
            name: "velvet cloak",
            description: "A luxurious velvet cloak.",
            flags: .wearable, .takeable,
            location: "room" // In the room
        )
        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(cloak, room)
        world.movePlayer(to: "room")

        // Act
        let command = UserInput(verb: "wear", directObject: "cloak", rawInput: "wear cloak")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert
        let expectedEffects: [Effect] = [.showText("You aren't holding that.")]
        expectNoDifference(effects, expectedEffects)
    }

    @Test("Cannot wear item already worn")
    func testWearItemAlreadyWorn() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let cloak = Object.item(
            id: "cloak",
            name: "velvet cloak",
            description: "A luxurious velvet cloak.",
            flags: .wearable, .takeable, .worn, // Start as worn
            location: "player"
        )
        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(cloak, room)
        world.movePlayer(to: "room")
        // Move cloak explicitly to player inventory
        world.move(cloak.id, to: world.player.id)

        // Act
        let command = UserInput(verb: "wear", directObject: "cloak", rawInput: "wear cloak")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert
        let expectedEffects: [Effect] = [.showText("You're already wearing that.")]
        expectNoDifference(effects, expectedEffects)
    }

    @Test("Wear command requires direct object")
    func testWearRequiresObject() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create and add room
        let room = Object.room(id: "room", name: "Room", description: "A room")
        world.add(room)
        world.movePlayer(to: "room")

        // Act
        let command = UserInput(verb: "wear", rawInput: "wear") // No direct object
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert
        let expectedEffects: [Effect] = [.showText("What do you want to wear?")]
        expectNoDifference(effects, expectedEffects)
    }

    // Optional: Test that Inventory shows worn items correctly
    @Test("Inventory shows worn items")
    func testInventoryShowsWorn() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let cloak = Object.item(
            id: "cloak",
            name: "velvet cloak",
            description: "A worn cloak.",
            flags: .wearable, .takeable, .worn,
            location: "player"
        )
        let boots = Object.item(
            id: "boots",
            name: "leather boots",
            description: "Some boots.",
            flags: .wearable, .takeable,
            location: "player"
        )
        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(cloak, boots, room)
        world.movePlayer(to: "room")
        // Move items explicitly to player inventory
        world.move(cloak.id, to: world.player.id)
        world.move(boots.id, to: world.player.id)

        // Act
        // Use dispatcher to get inventory effects, simulating the command
        let command = UserInput(verb: "inventory", rawInput: "inventory")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert: Check combined output matches the new format
        let expectedOutput = """
        You are carrying:
          leather boots

        You are wearing:
          velvet cloak
        """
        // Compare the dispatcher effects with the expected text effect
        expectNoDifference(effects, [.showText(expectedOutput)])
    }
}
