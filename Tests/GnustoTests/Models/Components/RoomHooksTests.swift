import CustomDump
import Foundation
import Testing

@testable import Gnusto

@Suite("Room Hooks Tests")
struct RoomHooksTests {
    @Test("onEnter hook should execute when player enters room")
    func testOnEnterHook() throws {
        let renderer = TestRenderer()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create our test world
        let world = World()

        world.add(
            .room(
                id: "startRoom",
                name: "Starting Room",
                description: "A plain room.",
                exits: [
                    .east: .direct("magicRoom"),
                ]
            ),

            .room(
                id: "magicRoom",
                name: "Magic Room",
                description: "A mysterious room with shimmering walls.",
                RoomHooksComponent(
                    onEnter: { @Sendable _ in
                        [.showText("As you enter, the walls begin to glow brighter!")]
                    }
                )
            )
        )

        world.movePlayer(to: "startRoom")

        // Act - move player to the magic room
        let moveInput = UserInput(
            verb: "go",
            directObject: "east",
            rawInput: "go east"
        )

        let effects = dispatcher.dispatch(.command(moveInput), in: world)

        expectNoDifference(
            renderer.process(effects),
            """
            As you enter, the walls begin to glow brighter!
            MAGIC ROOM
            A mysterious room with shimmering walls.
            """
        )

        // Verify player is now in the magic room
        #expect(world.playerLocation?.id == "magicRoom")
    }

    @Test("beforeAction hook should intercept action when returning effects")
    func testBeforeActionHookInterception() throws {
        // Create our test world
        let world = World()
        let renderer = TestRenderer()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        world.add(
            .item(
                id: "magicCrystal",
                name: "magic crystal",
                description: "A glowing crystal that floats slightly above the surface.",
                flags: .takeable,
                location: "enchantedRoom"
            ),

            .room(
                id: "enchantedRoom",
                name: "Enchanted Room",
                description: "A room filled with magical energy.",
                RoomHooksComponent(
                    beforeAction: { @Sendable action, _ in
                        if case .command(let command) = action,
                           command.verb == "take",
                           command.directObject == "magicCrystal" {
                            return [.showText("The crystal floats away from your grasp!")]
                        }
                        return nil
                    }
                )
            )
        )

        world.movePlayer(to: "enchantedRoom")

        // Act - Try to take the crystal
        let takeInput = UserInput(
            verb: "take",
            directObject: "magicCrystal",
            rawInput: "take crystal"
        )

        let effects = dispatcher.dispatch(.command(takeInput), in: world)

        expectNoDifference(
            renderer.process(effects),
            "The crystal floats away from your grasp!"
        )

        // Verify crystal is still in the room (not in inventory)
        guard
            let crystal = world.find("magicCrystal"),
            let location = crystal.location
        else {
            throw TestFailure("Crystal not found or missing location component")
        }
        #expect(location == "enchantedRoom")
    }

    @Test("beforeAction hook should allow action to proceed when returning nil")
    func testBeforeActionHookPassthrough() throws {
        // Create our test world
        let world = World()
        let renderer = TestRenderer()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        world.add(
            .item(
                id: "book",
                name: "leather-bound book",
                description: "An old book with a leather binding.",
                flags: .takeable,
                adjectives: "leather-bound",
                location: "libraryRoom"
            ),

            .room(
                id: "libraryRoom",
                name: "Library",
                description: "A quiet library with bookshelves.",
                RoomHooksComponent(
                    beforeAction: { @Sendable action, _ in
                        if case .command(let command) = action,
                           command.verb == "take",
                           command.directObject == "restrictedBook" {
                            return [.showText("That book is chained to the shelf.")]
                        }
                        return nil
                    }
                )
            )
        )

        world.movePlayer(to: "libraryRoom")

        // Act - Try to take the normal book
        let takeInput = UserInput(
            verb: "take",
            directObject: "book",
            rawInput: "take book"
        )

        let effects = dispatcher.dispatch(.command(takeInput), in: world)

        expectNoDifference(
            renderer.process(effects),
            "You take the leather-bound book."
        )

        // Verify book is now in inventory
        guard
            let takenBook = world.find("book"),
            let location = takenBook.find(LocationComponent.self)
        else {
            throw TestFailure("Book not found or player missing")
        }
        #expect(location.parentID == world.player.id)
    }

    @Test("afterAction hook should add effects after command processing")
    func testAfterActionHook() throws {
        // Create our test world
        let world = World()
        let renderer = TestRenderer()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        world.add(
            .room(
                id: "echoRoom",
                name: "Echo Chamber",
                description: "A large chamber where sounds echo.",
                RoomHooksComponent(
                    afterAction: { @Sendable action, _ in
                        if case .command(let command) = action,
                           command.verb == "look" {
                            return [.showText("Your gaze seems to bounce around the chamber...")]
                        }
                        return []
                    }
                )
            )
        )

        world.movePlayer(to: "echoRoom")

        // Act - Look around
        let lookInput = UserInput(verb: "look", rawInput: "look")
        let effects = dispatcher.dispatch(.command(lookInput), in: world)

        expectNoDifference(
            renderer.process(effects),
            """
            A large chamber where sounds echo.
            Your gaze seems to bounce around the chamber...
            """
        )
    }

    @Test("multiple hooks should work together in sequence")
    func testMultipleHooks() throws {
        // Create our test world
        let world = World()
        let renderer = TestRenderer()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        world.add(
            .room(
                id: "startRoom",
                name: "Starting Room",
                description: "A plain starting room.",
                exits: [
                    .north: .direct("complexRoom")
                ]
            ),

            .item(
                id: "ancientRelic",
                name: "ancient relic",
                description: "A mysterious ancient relic.",
                flags: .takeable,
                adjectives: "ancient",
                location: "complexRoom"
            ),

            .room(
                id: "complexRoom",
                name: "Complex Room",
                description: "A room with multiple magical properties.",
                RoomHooksComponent(
                    onEnter: { @Sendable _ in
                        [.showText("The room acknowledges your presence with a soft hum.")]
                    },
                    beforeAction: { @Sendable action, _ in
                        if case .command(let command) = action,
                           command.verb == "take",
                           command.directObject == "ancientRelic" {
                            return [.showText("A magical barrier prevents you from touching the relic.")]
                        }
                        return nil
                    },
                    afterAction: { @Sendable action, _ in
                        if case .command(let command) = action,
                           command.verb == "look" {
                            return [.showText("The ceiling shimmers in response to your attention.")]
                        }
                        return []
                    }
                )
            )
        )

        world.movePlayer(to: "startRoom")

        // Test 1: onEnter hook
        let moveInput = UserInput(verb: "go", directObject: "north", rawInput: "go north")
        let moveEffects = dispatcher.dispatch(.command(moveInput), in: world)

        expectNoDifference(
            renderer.process(moveEffects),
            "The room acknowledges your presence with a soft hum." // onEnter message only
        )
        #expect(world.playerLocation?.id == "complexRoom") // Verify player moved

        // Test 2: beforeAction hook (blocked action)
        let takeInput = UserInput(verb: "take", directObject: "ancientRelic", rawInput: "take relic")
        let takeEffects = dispatcher.dispatch(.command(takeInput), in: world)

        expectNoDifference(
            renderer.process(takeEffects),
            "A magical barrier prevents you from touching the relic."
        )
        #expect(world.find("ancientRelic")?.find(LocationComponent.self)?.parentID == "complexRoom") // Verify relic wasn't taken

        // Test 3: afterAction hook (look command)
        let lookInput = UserInput(verb: "look", rawInput: "look")
        let lookEffects = dispatcher.dispatch(.command(lookInput), in: world)

        expectNoDifference(
            renderer.process(lookEffects),
            """
            A room with multiple magical properties.
            You can see: ancient relic
            The ceiling shimmers in response to your attention.
            """
        )
    }
}
