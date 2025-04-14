import CustomDump
import Testing

@testable import Gnusto

@Suite("Wear/TakeOff Command Handler Tests")
struct WearTakeOffHandlerTests {
    @Test("Wear item")
    func testWearItem() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let hat = Object.item(
            id: "hat",
            name: "pointy hat",
            description: "A pointy hat, suitable for a wizard.",
            flags: .wearable, .takeable,
            location: "player"
        )
        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(hat, room)
        world.movePlayer(to: "room")
        // Move hat explicitly to player inventory
        world.move(hat.id, to: world.player.id)

        // Act
        let command = UserInput(verb: "wear", directObject: "hat", rawInput: "wear hat")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert
        expectNoDifference(effects, [.showText("You put on the pointy hat.")])

        // Verify item is worn
        guard let hat = world.find("hat") else {
            throw TestFailure("Hat not found")
        }
        #expect(hat.find(ObjectComponent.self)?.flags.contains(.worn) == true)
    }

    @Test("Wear item already worn")
    func testWearItemAlreadyWorn() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let hat = Object.item(
            id: "hat",
            name: "pointy hat",
            description: "A pointy hat.",
            flags: .wearable, .takeable, .worn,
            location: "player"
        )
        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(hat, room)
        world.movePlayer(to: "room")
        // Move hat explicitly to player inventory
        world.move(hat.id, to: world.player.id)

        // Act
        let command = UserInput(verb: "wear", directObject: "hat", rawInput: "wear hat")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert
        expectNoDifference(effects, [.showText("You're already wearing that.")])

        // Verify item is still worn
        guard let hat = world.find("hat") else {
            throw TestFailure("Hat not found")
        }
        #expect(hat.find(ObjectComponent.self)?.flags.contains(.worn) == true)
    }

    @Test("Wear non-wearable item")
    func testWearNonWearableItem() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let stone = Object.item(
            id: "stone",
            name: "smooth stone",
            description: "A smooth, grey stone.",
            flags: .takeable,
            location: "player"
        )
        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(stone, room)
        world.movePlayer(to: "room")
        // Move stone explicitly to player inventory
        world.move(stone.id, to: world.player.id)

        // Act
        let command = UserInput(verb: "wear", directObject: "stone", rawInput: "wear stone")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert
        expectNoDifference(effects, [.showText("You can't wear that.")])

        // Verify item is not worn
        guard let stone = world.find("stone") else {
            throw TestFailure("Stone not found")
        }
        #expect(stone.find(ObjectComponent.self)?.flags.contains(.worn) == false)
    }

    @Test("Take off item")
    func testTakeOffItem() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let hat = Object.item(
            id: "hat",
            name: "pointy hat",
            description: "A pointy hat.",
            flags: .wearable, .takeable, .worn,
            location: "player"
        )
        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(hat, room)
        world.movePlayer(to: "room")
        // Move hat explicitly to player inventory (even though worn)
        world.move(hat.id, to: world.player.id)

        // Act
        let command = UserInput(verb: "remove", directObject: "hat", rawInput: "remove hat")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert
        // Expect success message for taking off item
        expectNoDifference(effects, [.showText("You take off the pointy hat.")])

        // Verify item is no longer worn
        guard let hat = world.find("hat") else {
            throw TestFailure("Hat not found")
        }
        #expect(hat.find(ObjectComponent.self)?.flags.contains(.worn) == false)
    }

    @Test("Take off item not worn")
    func testTakeOffItemNotWorn() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let hat = Object.item(
            id: "hat",
            name: "pointy hat",
            description: "A pointy hat.",
            flags: .wearable, .takeable,
            location: "player"
        )
        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(hat, room)
        world.movePlayer(to: "room")
        // Move hat explicitly to player inventory
        world.move(hat.id, to: world.player.id)

        // Act
        let command = UserInput(verb: "remove", directObject: "hat", rawInput: "remove hat")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert
        // Expect "not wearing" message
        expectNoDifference(effects, [.showText("You aren't wearing that.")])

        // Verify item is still not worn
        guard let hat = world.find("hat") else {
            throw TestFailure("Hat not found")
        }
        #expect(hat.find(ObjectComponent.self)?.flags.contains(.worn) == false)
    }

    @Test("Take off non-wearable item (shouldn't happen, but test)")
    func testTakeOffNonWearable() throws {
         // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let stone = Object.item(
            id: "stone",
            name: "smooth stone",
            description: "A smooth, grey stone.",
            flags: .takeable,
            location: "player"
        )
        let room = Object.room(id: "room", name: "Room", description: "A room")

        // Add to world
        world.add(stone, room)
        world.movePlayer(to: "room")
        // Move stone explicitly to player inventory
        world.move(stone.id, to: world.player.id)

        // Act
        let command = UserInput(verb: "remove", directObject: "stone", rawInput: "remove stone")
        let effects = dispatcher.dispatch(.command(command), in: world)

        // Assert: Handler might give a generic "not wearing" message or specific non-wearable message
        // Expect "not wearing" message as it's not wearable, thus cannot be worn
        expectNoDifference(effects, [.showText("You aren't wearing that.")])

        // Verify item is still not worn (and was never worn)
        guard let stone = world.find("stone") else {
            throw TestFailure("Stone not found")
        }
        #expect(stone.find(ObjectComponent.self)?.flags.contains(.worn) == false)
    }
}
