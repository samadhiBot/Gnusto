import CustomDump
import Testing

@testable import GnustoEngine

@Suite("TurnOnActionHandler Tests")
struct TurnOnActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("LIGHT DIRECTOBJECT syntax works")
    func testLightDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lamp."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("light lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > light lamp
            The brass lamp is now on.
            """)

        let finalState = try await engine.item("lamp")
        #expect(finalState.hasFlag(.isOn) == true)
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("TURN ON DIRECTOBJECT syntax works")
    func testTurnOnDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let flashlight = Item(
            id: "flashlight",
            .name("silver flashlight"),
            .description("A modern silver flashlight."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: flashlight
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on flashlight")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn on flashlight
            The silver flashlight is now on.
            """)

        let finalState = try await engine.item("flashlight")
        #expect(finalState.hasFlag(.isOn) == true)
    }

    @Test("SWITCH ON DIRECTOBJECT syntax works")
    func testSwitchOnDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lantern = Item(
            id: "lantern",
            .name("camping lantern"),
            .description("A portable camping lantern."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lantern
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("switch on lantern")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > switch on lantern
            The camping lantern is now on.
            """)

        let finalState = try await engine.item("lantern")
        #expect(finalState.hasFlag(.isOn) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot turn on without specifying what")
    func testCannotTurnOnWithoutWhat() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn on
            Turn on what?
            """)
    }

    @Test("Cannot turn on non-existent item")
    func testCannotTurnOnNonExistentItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn on nonexistent
            You can’t see any such thing.
            """)
    }

    @Test("Cannot turn on item not in scope")
    func testCannotTurnOnItemNotInScope() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteLamp = Item(
            id: "remoteLamp",
            .name("remote lamp"),
            .description("A lamp in another room."),
            .isLightSource,
            .isDevice,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteLamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn on lamp
            You can’t see any such thing.
            """)
    }

    @Test("Cannot turn on non-device item")
    func testCannotTurnOnNonDeviceItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A heavy stone."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn on rock
            You can’t turn that on.
            """)
    }

    @Test("Cannot turn on already on device")
    func testCannotTurnOnAlreadyOnDevice() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lamp."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set the lamp to already be on
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("lamp"))
        )

        // When
        try await engine.execute("turn on lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn on lamp
            It’s already on.
            """)
    }

    @Test("Can turn on light source in dark room even if not normally reachable")
    func testCanTurnOnLightSourceInDarkRoom() async throws {
        // Given: Dark room with light source on floor
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A brass lamp sitting on the floor."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn on lamp
            The brass lamp is now on.
            You can see your surroundings now.

            — Dark Room —

            A pitch black room.

            There is a brass lamp here.
            """)

        let finalState = try await engine.item("lamp")
        #expect(finalState.hasFlag(.isOn) == true)
    }

    @Test("Requires light for non-light-source items")
    func testRequiresLightForNonLightSources() async throws {
        // Given: Dark room with non-light-source device
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let radio = Item(
            id: "radio",
            .name("portable radio"),
            .description("A small portable radio."),
            .isDevice,
            .isTakable,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: radio
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on radio")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn on radio
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Turn on device sets isOn flag")
    func testTurnOnDeviceSetsIsOnFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lamp."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on lamp")

        // Then
        let finalState = try await engine.item("lamp")
        #expect(finalState.hasFlag(.isOn) == true)
        #expect(finalState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn on lamp
            The brass lamp is now on.
            """)
    }

    @Test("Turn on light source illuminates dark room")
    func testTurnOnLightSourceIlluminatesDarkRoom() async throws {
        // Given: Dark room with player holding light source
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A room that is dark without a light source.")
            // Note: No .inherentlyLit property
        )

        let torch = Item(
            id: "torch",
            .name("wooden torch"),
            .description("A wooden torch with an unlit tip."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on torch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn on torch
            The wooden torch is now on.
            You can see your surroundings now.

            — Dark Room —

            A room that is dark without a light source.
            """)

        // Verify room is now lit
        let isLit = await engine.playerLocationIsLit()
        #expect(isLit == true)
    }

    @Test("Turn on non-light-source device")
    func testTurnOnNonLightSourceDevice() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let radio = Item(
            id: "radio",
            .name("portable radio"),
            .description("A small portable radio."),
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: radio
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on radio")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn on radio
            The portable radio is now on.
            """)

        let finalState = try await engine.item("radio")
        #expect(finalState.hasFlag(.isOn) == true)
    }

    @Test("Light flammable non-device item burns it")
    func testLightFlammableNonDeviceItemBurnsIt() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let paper = Item(
            id: "paper",
            .name("old paper"),
            .description("A yellowed piece of paper."),
            .isFlammable,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: paper
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("light paper")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > light paper
            The old paper burns to ashes.
            """)

        let finalState = try await engine.item("paper")
        #expect(finalState.parent == .nowhere)
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Device takes precedence over flammable for items that are both")
    func testDeviceTakesPrecedenceOverFlammable() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let torch = Item(
            id: "torch",
            .name("magical torch"),
            .description("A magical torch that can be turned on and off."),
            .isLightSource,
            .isDevice,
            .isFlammable,  // Both device and flammable
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("light torch")

        // Then - Should turn on, not burn
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > light torch
            The magical torch is now on.
            """)

        let finalState = try await engine.item("torch")
        #expect(finalState.hasFlag(.isOn) == true)
        #expect(finalState.parent == .player)  // Not burned
    }

    @Test("Updates pronouns to refer to turned on item")
    func testUpdatesPronounsToTurnedOnItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lamp."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on lamp")
        try await engine.execute("examine it")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn on lamp
            The brass lamp is now on.
            > examine it
            A shiny brass lamp.
            """)
    }

    @Test("Turn on inherently lit room light source doesn’t show illumination message")
    func testTurnOnInInherentlyLitRoom() async throws {
        // Given: Inherently lit room
        let litRoom = Location(
            id: "litRoom",
            .name("Bright Room"),
            .description("A naturally bright room."),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("desk lamp"),
            .description("A small desk lamp."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: litRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on lamp")

        // Then - Should not show "You can see your surroundings now" message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn on lamp
            The desk lamp is now on.
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = TurnOnActionHandler()
        #expect(handler.actions.contains(.lightSource))
        #expect(handler.actions.contains(.burn))
        #expect(handler.actions.count == 2)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = TurnOnActionHandler()
        // TurnOnActionHandler uses syntax rules, not verbs array
        #expect(handler.verbs.isEmpty)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = TurnOnActionHandler()
        #expect(handler.requiresLight == true)
    }

    @Test("Handler syntax rules are correct")
    func testSyntaxRules() async throws {
        let handler = TurnOnActionHandler()
        #expect(handler.syntax.count == 3)
        // The specific syntax patterns are tested through the command execution tests above
    }
}
