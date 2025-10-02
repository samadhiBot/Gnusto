import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("TurnOnActionHandler Tests")
struct TurnOnActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("TURN ON DIRECTOBJECT syntax works")
    func testTurnOnDirectObjectSyntax() async throws {
        // Given
        let flashlight = Item("flashlight")
            .name("silver flashlight")
            .description("A modern silver flashlight.")
            .isLightSource
            .isDevice
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: flashlight
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on flashlight")

        // Then
        await mockIO.expectOutput(
            """
            > turn on flashlight
            You turn on the silver flashlight.
            """
        )

        let finalState = await engine.item("flashlight")
        #expect(await finalState.hasFlag(.isOn) == true)
    }

    @Test("SWITCH ON DIRECTOBJECT syntax works")
    func testSwitchOnDirectObjectSyntax() async throws {
        // Given
        let lantern = Item("lantern")
            .name("camping lantern")
            .description("A portable camping lantern.")
            .isLightSource
            .isDevice
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: lantern
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("switch on lantern")

        // Then
        await mockIO.expectOutput(
            """
            > switch on lantern
            You switch on the camping lantern.
            """
        )

        let finalState = await engine.item("lantern")
        #expect(await finalState.hasFlag(.isOn) == true)
    }

    @Test("TURN DIRECTOBJECT ON syntax works")
    func testTurnDirectObjectOnSyntax() async throws {
        // Given
        let flashlight = Item("flashlight")
            .name("silver flashlight")
            .description("A modern silver flashlight.")
            .isLightSource
            .isDevice
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: flashlight
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn flashlight on")

        // Then
        await mockIO.expectOutput(
            """
            > turn flashlight on
            You turn on the silver flashlight.
            """
        )

        let finalState = await engine.item("flashlight")
        #expect(await finalState.hasFlag(.isOn) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot turn on without specifying what")
    func testCannotTurnOnWithoutWhat() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on")

        // Then
        await mockIO.expectOutput(
            """
            > turn on
            Turn on what?
            """
        )
    }

    @Test("Cannot turn on non-existent item")
    func testCannotTurnOnNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on nonexistent")

        // Then
        await mockIO.expectOutput(
            """
            > turn on nonexistent
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot turn on item not in scope")
    func testCannotTurnOnItemNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteLamp = Item("remoteLamp")
            .name("remote lamp")
            .description("A lamp in another room.")
            .isLightSource
            .isDevice
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteLamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on lamp")

        // Then
        await mockIO.expectOutput(
            """
            > turn on lamp
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot turn on non-device item")
    func testCannotTurnOnNonDeviceItem() async throws {
        // Given
        let rock = Item("rock")
            .name("large rock")
            .description("A heavy stone.")
            .in(.startRoom)

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on rock")

        // Then
        await mockIO.expectOutput(
            """
            > turn on rock
            It remains stubbornly inert despite your ministrations.
            """
        )
    }

    @Test("Cannot turn on already on device")
    func testCannotTurnOnAlreadyOnDevice() async throws {
        // Given
        let lamp = Item("lamp")
            .name("brass lamp")
            .description("A shiny brass lamp.")
            .isLightSource
            .isDevice
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set the lamp to already be on
        try await engine.apply(
            lamp.proxy(engine).setFlag(.isOn)
        )

        // When
        try await engine.execute("turn on lamp")

        // Then
        await mockIO.expectOutput(
            """
            > turn on lamp
            It's already on.
            """
        )
    }

    @Test("Can turn on held light source in dark room")
    func testCanTurnOnHeldLightSourceInDarkRoom() async throws {
        // Given: Dark room with light source on floor
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let lamp = Item("lamp")
            .name("brass lamp")
            .description("A brass lamp sitting on the floor.")
            .isLightSource
            .isDevice
            .isTakable
            .in(.player)

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on lamp")

        // Then
        await mockIO.expectOutput(
            """
            > turn on lamp
            You turn on the brass lamp.

            --- Dark Room ---

            A pitch black room.
            """
        )

        let finalState = await engine.item("lamp")
        #expect(await finalState.hasFlag(.isOn) == true)
    }

    @Test("Cannot turn on not held light source in dark room")
    func testCannotTurnOnNotHeldLightSourceInDarkRoom() async throws {
        // Given: Dark room with light source on floor
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let lamp = Item("lamp")
            .name("brass lamp")
            .description("A brass lamp sitting on the floor.")
            .isLightSource
            .isDevice
            .isTakable
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on lamp")

        // Then
        await mockIO.expectOutput(
            """
            > turn on lamp
            Any such thing lurks beyond your reach.
            """
        )

        let finalState = await engine.item("lamp")
        #expect(await finalState.hasFlag(.isOn) == false)
    }

    @Test("Requires light for non-light-source items")
    func testRequiresLightForNonLightSources() async throws {
        // Given: Dark room with non-light-source device
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let radio = Item("radio")
            .name("portable radio")
            .description("A small portable radio.")
            .isDevice
            .isTakable
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: radio
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on radio")

        // Then
        await mockIO.expectOutput(
            """
            > turn on radio
            Any such thing lurks beyond your reach.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Turn on device sets isOn flag")
    func testTurnOnDeviceSetsIsOnFlag() async throws {
        // Given
        let lamp = Item("lamp")
            .name("brass lamp")
            .description("A shiny brass lamp.")
            .isLightSource
            .isDevice
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on lamp")

        // Then
        let finalState = await engine.item("lamp")
        #expect(await finalState.hasFlag(.isOn) == true)
        #expect(await finalState.hasFlag(.isTouched) == true)

        await mockIO.expectOutput(
            """
            > turn on lamp
            You turn on the brass lamp.
            """
        )
    }

    @Test("Turn on light source illuminates dark room")
    func testTurnOnLightSourceIlluminatesDarkRoom() async throws {
        // Given: Dark room with player holding light source
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A room that is dark without a light source.")
            // Note: No .inherentlyLit property

        let torch = Item("torch")
            .name("silver torch")
            .description("A silver torch with an unlit tip.")
            .isLightSource
            .isDevice
            .isTakable
            .in(.player)

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "turn on torch",
            "turn off torch",
        )

        // Then
        await mockIO.expectOutput(
            """
            > turn on torch
            You turn on the silver torch.

            --- Dark Room ---

            A room that is dark without a light source.

            > turn off torch
            The silver torch is now off.

            You are swallowed by impenetrable shadow.

            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )

        // Verify room is now lit
        let isLit = await engine.player.location.isLit
        #expect(isLit == false)
    }

    @Test("Turn on non-light-source device")
    func testTurnOnNonLightSourceDevice() async throws {
        // Given
        let radio = Item("radio")
            .name("portable radio")
            .description("A small portable radio.")
            .isDevice
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: radio
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on radio")

        // Then
        await mockIO.expectOutput(
            """
            > turn on radio
            You turn on the portable radio.
            """
        )

        let finalState = await engine.item("radio")
        #expect(await finalState.hasFlag(.isOn) == true)
    }

    @Test("Updates pronouns to refer to turned on item")
    func testUpdatesPronounsToTurnedOnItem() async throws {
        // Given
        let lamp = Item("lamp")
            .name("brass lamp")
            .description("A shiny brass lamp.")
            .isLightSource
            .isDevice
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "turn on lamp",
            "examine it"
        )

        // Then
        await mockIO.expectOutput(
            """
            > turn on lamp
            You turn on the brass lamp.

            > examine it
            A shiny brass lamp.
            """
        )
    }

    @Test("Turn on inherently lit room light source doesn't show illumination message")
    func testTurnOnInInherentlyLitRoom() async throws {
        // Given: Inherently lit room
        let litRoom = Location("litRoom")
            .name("Bright Room")
            .description("A naturally bright room.")
            .inherentlyLit

        let lamp = Item("lamp")
            .name("desk lamp")
            .description("A small desk lamp.")
            .isLightSource
            .isDevice
            .isTakable
            .in(.player)

        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: litRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on lamp")

        // Then - Should not show "You can see your surroundings now" message
        await mockIO.expectOutput(
            """
            > turn on lamp
            You turn on the desk lamp.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = TurnOnActionHandler()
        // TurnOnActionHandler uses syntax rules, not verbs array
        expectNoDifference(handler.synonyms, [.switch, .turn])
    }

    @Test("Handler does not require light in some cases")
    func testRequiresLightProperty() async throws {
        let handler = TurnOnActionHandler()
        #expect(handler.requiresLight == false)
    }

    @Test("Handler syntax rules are correct")
    func testSyntaxRules() async throws {
        let handler = TurnOnActionHandler()
        expectNoDifference(
            handler.syntax,
            [
                .match(.verb, .directObject, .on),
                .match(.verb, .on, .directObject),
            ]
        )
    }
}
