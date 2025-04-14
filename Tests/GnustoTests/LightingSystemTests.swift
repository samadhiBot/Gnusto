import CustomDump
import Foundation
import Testing

@testable import Gnusto

@Suite("Lighting System Tests")
struct LightingSystemTests {
    @Test("Dark rooms should have limited visibility without light sources")
    func testDarkRoomWithoutLight() throws {
        // Arrange
        let world = World()
        let renderer = TestRenderer()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let darkCave = Object.room(
            id: "darkCave",
            name: "Dark Cave",
            description: "A spacious cave with ancient drawings on the walls.",
            isLit: false,
            darkDescription: "It's pitch black in here. You can't see a thing."
        )

        let treasure = Object.item(
            id: "treasure",
            name: "treasure chest",
            description: "An ornate treasure chest with gold inlays.",
            location: "darkCave"
        )

        // Add to world
        world.add(darkCave, treasure)
        // Player added by default, move them
        world.movePlayer(to: "darkCave")

        // Act - Try to look around
        let lookInput = UserInput(verb: "look", rawInput: "look")
        let lookEffects = dispatcher.dispatch(.command(lookInput), in: world)
        expectNoDifference(
            renderer.process(lookEffects),
            "It's pitch black in here. You can't see a thing."
        )

        // Try to examine the treasure
        let examineInput = UserInput(
            verb: "examine",
            directObject: "treasure",
            rawInput: "examine treasure"
        )
        let examineEffects = dispatcher.dispatch(.command(examineInput), in: world)

        // Should not be able to examine objects in the dark
        // The message comes from ActionDispatcher's darkness check
        expectNoDifference(
            renderer.process(examineEffects),
            "It's too dark to see that!"
        )
    }

    @Test("Carrying a lit light source should illuminate a dark room")
    func testDarkRoomWithCarriedLight() throws {
        // Arrange
        let world = World()
        let renderer = TestRenderer()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let darkCave = Object.room(
            id: "darkCave",
            name: "Dark Cave",
            description: "A spacious cave with ancient drawings on the walls.",
            darkDescription: "It's pitch black in here. You can't see a thing."
        )

        let treasure = Object.item(
            id: "treasure",
            name: "treasure chest",
            description: "An ornate treasure chest with gold inlays.",
            location: "darkCave"
        )

        let lantern = Object.item(
            id: "lantern",
            name: "brass lantern",
            description: "A sturdy brass lantern that gives off a warm light.",
            flags: .takeable,
            location: "darkCave",
            LightSourceComponent(isOn: true)
        )

        // Add to world
        world.add(darkCave, treasure, lantern)
        // Move player and lantern
        world.movePlayer(to: "darkCave")
        world.move("lantern", to: "player")

        // Act - Look around
        let lookInput = UserInput(verb: "look", rawInput: "look")
        let lookEffects = dispatcher.dispatch(.command(lookInput), in: world)

        // Assert - Should see the lit room description
        expectNoDifference(lookEffects, [
            .showText("DARK CAVE"),
            .showText("A spacious cave with ancient drawings on the walls."),
            .showText("You can see: treasure chest."),
        ])

        // Should be able to examine objects in the lit room
        let examineInput = UserInput(verb: "examine", directObject: "treasure", rawInput: "examine treasure")
        let examineEffects = dispatcher.dispatch(.command(examineInput), in: world)
        // Examine output should just be the description now.
        expectNoDifference(
            renderer.process(examineEffects),
            "An ornate treasure chest with gold inlays."
        )
    }

    @Test("A light source in the room should illuminate a dark room")
    func testDarkRoomWithRoomLight() throws {
        // Arrange
        let world = World()
        let renderer = TestRenderer()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let darkCave = Object.room(
            id: "darkCave",
            name: "Dark Cave",
            description: "A spacious cave with ancient drawings on the walls.",
            darkDescription: "It's pitch black in here. You can't see a thing."
        )

        let torch = Object.item(
            id: "torch",
            name: "wall torch",
            description: "A burning torch mounted on the wall.",
            location: "darkCave",
            LightSourceComponent(isOn: true)
        )

        // Add to world
        world.add(darkCave, torch)
        // Move player
        world.movePlayer(to: "darkCave")

        // Act - Look around
        let lookInput = UserInput(verb: "look", rawInput: "look")
        let lookEffects = dispatcher.dispatch(.command(lookInput), in: world)

        // Assert - Should see the lit room description
        let expectedLookOutput = """
            Dark Cave
            A spacious cave with ancient drawings on the walls.
            You can see: wall torch
            """
        expectNoDifference(lookEffects, [.showText(expectedLookOutput)])
    }

    @Test("Should be able to turn on a light source in a dark room")
    func testTurningOnLightInDarkRoom() throws {
        // Arrange
        let world = World()
        let renderer = TestRenderer()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let darkCave = Object.room(
            id: "darkCave",
            name: "Dark Cave",
            description: "A spacious cave with ancient drawings on the walls.",
            isLit: false,
            darkDescription: "It's pitch black in here. You can't see a thing."
        )

        let lantern = Object.item(
            id: "lantern",
            name: "brass lantern",
            description: "A sturdy brass lantern that's currently off.",
            flags: .device, .takeable,
            location: "darkCave",
            LightSourceComponent(isOn: false)
        )

        // Add to world
        world.add(darkCave, lantern)
        // Move player and lantern
        world.movePlayer(to: "darkCave")
        world.move("lantern", to: "player")

        // Act - Turn on the lantern
        let turnOnInput = UserInput(
            verb: "turn",
            directObject: "lantern",
            prepositions: ["on"],
            rawInput: "turn on lantern"
        )
        let turnOnEffects = dispatcher.dispatch(.command(turnOnInput), in: world)

        // Assert 1: Check the effect of turning on the lantern
        expectNoDifference(turnOnEffects, [.showText("You turn on the brass lantern.")])

        // Assert 2: Verify the lantern is on and room is now illuminated
        guard let updatedLantern = world.find("lantern"), let lightSource = updatedLantern.find(LightSourceComponent.self) else {
            throw TestFailure("Failed to get lantern or light source component after turning on")
        }
        #expect(lightSource.isOn)
        #expect(world.isIlluminated(darkCave.id))

        // Act 2: Look around now that the light is on
        let lookInput = UserInput(verb: "look", rawInput: "look")
        let lookEffects = dispatcher.dispatch(.command(lookInput), in: world)

        // Assert 3: Check the description of the now-lit room
        let expectedLookOutput = """
        Dark Cave
        A spacious cave with ancient drawings on the walls.
        You can see: brass lantern
        """
        expectNoDifference(lookEffects, [.showText(expectedLookOutput)])
    }

    @Test("Moving between lit and dark rooms should give appropriate descriptions")
    func testMovingBetweenLitAndDarkRooms() throws {
        // Arrange
        let world = World()
        let renderer = TestRenderer()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let entrance = Object.room(
            id: "entrance",
            name: "Cave Entrance",
            description: "A bright entrance to a cave system. Sunlight streams in from above.",
            exits: [.north: .direct("darkTunnel")] // Exit to dark tunnel
        )

        let darkTunnel = Object.room(
            id: "darkTunnel",
            name: "Dark Tunnel",
            description: "A narrow tunnel extending into darkness.", // Normal description
            isLit: false,
            darkDescription: "It is completely dark here.", // Dark description
            exits: [.south: .direct("entrance")] // Exit back to entrance
        )

        // Add to world
        world.add(entrance, darkTunnel)
        // Move player
        world.movePlayer(to: "entrance")

        // Act 1 - Move to the dark tunnel without a light
        let moveNorthInput = UserInput(verb: "go", directObject: "north", rawInput: "go north")
        let moveEffects = dispatcher.dispatch(.command(moveNorthInput), in: world)

        // Assert 1 - Should see the dark description of the new room
        // Corrected expected message to use room's darkDescription
        expectNoDifference(
            renderer.process(moveEffects),
            "It is completely dark here." // The darkDescription from RoomComponent
        )
        #expect(world.playerLocation?.id == "darkTunnel")

        // Act 2 - Move back to the entrance
        let moveSouthInput = UserInput(verb: "go", directObject: "south", rawInput: "go south")
        let moveSouthEffects = dispatcher.dispatch(.command(moveSouthInput), in: world)

        // Assert 2 - Should see the lit description of the entrance
        expectNoDifference(
            renderer.process(moveSouthEffects),
            "Cave Entrance\nA bright entrance to a cave system. Sunlight streams in from above."
        )
        #expect(world.playerLocation?.id == "entrance")

        // Act 3 - Move back to the dark tunnel
        let moveNorthAgainInput = UserInput(verb: "go", directObject: "north", rawInput: "go north")
        let moveNorthAgainEffects = dispatcher.dispatch(.command(moveNorthAgainInput), in: world)

        // Assert 3: Check the result of moving into the dark room again
        // Corrected expected message
        expectNoDifference(renderer.process(moveNorthAgainEffects), "It is completely dark here.")
        #expect(world.playerLocation?.id == "darkTunnel") // Verify player moved

        // Act 4: Explicitly look in the dark tunnel
        let lookDarkInput = UserInput(verb: "look", rawInput: "look")
        let lookDarkEffects = dispatcher.dispatch(.command(lookDarkInput), in: world)

        // Assert 4: Should get the dark description again
        // Corrected expected message
        expectNoDifference(renderer.process(lookDarkEffects), "It is completely dark here.")
    }

    @Test("Light sources only affect their immediate location")
    func testLightSourceLocality() throws {
        // Arrange
        let world = World()
        let renderer = TestRenderer()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let darkRoom = Object.room(
            id: "darkRoom",
            name: "Dark Room",
            description: "A standard dark room.",
            isLit: false,
            darkDescription: "Pitch black.",
            exits: [.north: .direct("anotherDarkRoom")]
        )

        let anotherDarkRoom = Object.room(
            id: "anotherDarkRoom",
            name: "Another Dark Room",
            description: "Yet another dark room.",
            isLit: false,
            darkDescription: "Still dark.",
            exits: [.south: .direct("darkRoom")]
        )

        let torch = Object.item(
            id: "torch",
            name: "wall torch",
            description: "A burning torch mounted on the wall.",
            location: "darkRoom",
            LightSourceComponent(isOn: true)
        )

        // Add to world
        world.add(darkRoom, anotherDarkRoom, torch)
        // Move player
        world.movePlayer(to: "darkRoom")

        // Act 1 - Look in the lit room
        let lookLitInput = UserInput(verb: "look", rawInput: "look")
        let lookLitEffects = dispatcher.dispatch(.command(lookLitInput), in: world)
        #expect(renderer.process(lookLitEffects).contains("standard dark room")) // Should see normal description

        // Act 2 - Move to the second dark room (without the torch)
        let moveInput = UserInput(verb: "go", directObject: "north", rawInput: "go north")
        let moveEffects = dispatcher.dispatch(.command(moveInput), in: world)

        // Assert 2 - Should see the dark description of the second room
        expectNoDifference(
            renderer.process(moveEffects),
            "Still dark." // The darkDescription of anotherDarkRoom
        )
        #expect(world.playerLocation?.id == "anotherDarkRoom")
    }

    @Test("Verbs allowed in darkness")
    func testAllowedVerbsInDarkness() throws {
        // Arrange
        let world = World()
        let renderer = TestRenderer()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Create objects first
        let pitchBlack = Object.room(
            id: "pitchBlack",
            name: "Pitch Black Void",
            description: "Should not see this.",
            isLit: false,
            darkDescription: "It is utterly dark."
        )
        let widget = Object.item(
            id: "widget",
            name: "widget",
            description: "A small, nondescript widget.",
            location: "player" // Will be moved later
        )

        // Add to world
        world.add(pitchBlack, widget)
        // Move player and widget
        world.movePlayer(to: "pitchBlack")
        world.move(widget.id, to: world.player.id)

        // Define allowed commands and expected (non-darkness) responses
        let allowedCommands: [(UserInput, String)] = [
            (UserInput(verb: "look", rawInput: "look"), "It is pitch black. You are likely to be eaten by a grue."),
            (UserInput(verb: "inventory", rawInput: "i"), "You are carrying:\n  widget"),
            (UserInput(verb: "save", rawInput: "save"), "Game saved."),
            (UserInput(verb: "quit", rawInput: "q"), "Are you sure you want to quit? (y/n)"),
            (UserInput(verb: "help", rawInput: "help"), "Available commands:"),
            (UserInput(verb: "wait", rawInput: "wait"), "Time passes..."),
            (UserInput(verb: "score", rawInput: "score"), "Score: 0/100 (Not implemented)"),
            (UserInput(verb: "version", rawInput: "version"), "Gnusto Engine v0.1 (Test Game)"),
            (UserInput(verb: "turn", rawInput: "turn"), "Turn on what?"),
            (UserInput(verb: "light", rawInput: "light"), "Turn on what?"),
            (UserInput(verb: "feel", rawInput: "feel"), "You feel around in the darkness, but find nothing interesting."),
            (UserInput(verb: "touch", rawInput: "touch"), "You feel around in the darkness, but find nothing interesting.")
        ]

        for (command, expectedResponse) in allowedCommands {
            let effects = dispatcher.dispatch(.command(command), in: world)
            let renderedOutput = renderer.process(effects)
            // Use contains for multi-line or prefix checks
            if command.verb == .inventory {
                #expect(renderedOutput == "You are carrying:\n  widget", "Command 'inventory' should work")
            } else if expectedResponse.contains("\n") || command.verb == .help {
                #expect(renderedOutput.contains(expectedResponse), "Command '\(command.verb?.rawValue ?? "<unknown>")' should work: \nExpected containing:\n\(expectedResponse)\nActual:\n\(renderedOutput)")
            } else {
                expectNoDifference(renderedOutput, expectedResponse, "Command '\(command.verb?.rawValue ?? "<unknown>")' should work")
            }
        }

        // Define restricted commands
        let restrictedCommands: [UserInput] = [
            UserInput(verb: "go", directObject: "north", rawInput: "go north"),
            UserInput(verb: "take", directObject: "widget", rawInput: "take widget"),
            UserInput(verb: "drop", directObject: "widget", rawInput: "drop widget")
        ]

        for command in restrictedCommands {
            let effects = dispatcher.dispatch(.command(command), in: world)
            let renderedOutput = renderer.process(effects)

            // Check if it produced *some* failure message rather than succeeding silently.
            // Or check for the specific darkness message if appropriate.
            if command.verb == .go {
                expectNoDifference(renderedOutput, "It's too dark to see! You might need a light source.", "Command '\(command.rawInput)' should be restricted")
            } else {
                #expect(!renderedOutput.isEmpty, "Command '\(command.rawInput)' should produce some output, not be empty")
                // We might need more specific checks here depending on *why* it's restricted
            }
        }

        // Test examining the held widget specifically
        let examineWidgetInput = UserInput(verb: "examine", directObject: "widget", rawInput: "examine widget")
        let examineWidgetEffects = dispatcher.dispatch(.command(examineWidgetInput), in: world)
        // Since widget is held, examination should work and give its description
        expectNoDifference(examineWidgetEffects, [.showText("A small, nondescript widget.")], "Command 'examine widget' should work when held in dark")
    }
}
