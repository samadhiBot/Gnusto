import CustomDump
import Testing

@testable import GnustoEngine

@Suite("TurnOffActionHandler Tests")
struct TurnOffActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("TURN OFF DIRECTOBJECT syntax works")
    func testTurnOffDirectObjectSyntax() async throws {
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

        // Set the lamp to be on first
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("lamp"))
        )

        // When
        try await engine.execute("turn off lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lamp
            The brass lamp is now off.
            """)

        let finalState = try await engine.item("lamp")
        #expect(finalState.hasFlag(.isOn) == false)
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("SWITCH OFF DIRECTOBJECT syntax works")
    func testSwitchOffDirectObjectSyntax() async throws {
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

        // Set the flashlight to be on first
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("flashlight"))
        )

        // When
        try await engine.execute("switch off flashlight")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > switch off flashlight
            The silver flashlight is now off.
            """)

        let finalState = try await engine.item("flashlight")
        #expect(finalState.hasFlag(.isOn) == false)
    }

    @Test("BLOW OUT DIRECTOBJECT syntax works")
    func testBlowOutDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let candle = Item(
            id: "candle",
            .name("wax candle"),
            .description("A simple wax candle."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set the candle to be on first
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("candle"))
        )

        // When
        try await engine.execute("blow out candle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > blow out candle
            The wax candle is now off.
            """)

        let finalState = try await engine.item("candle")
        #expect(finalState.hasFlag(.isOn) == false)
    }

    @Test("EXTINGUISH syntax works")
    func testExtinguishSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let torch = Item(
            id: "torch",
            .name("wooden torch"),
            .description("A burning wooden torch."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set the torch to be on first
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("torch"))
        )

        // When
        try await engine.execute("extinguish torch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > extinguish torch
            The wooden torch is now off.
            """)

        let finalState = try await engine.item("torch")
        #expect(finalState.hasFlag(.isOn) == false)
    }

    @Test("DOUSE syntax works")
    func testDouseSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lantern = Item(
            id: "lantern",
            .name("oil lantern"),
            .description("An old oil lantern."),
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

        // Set the lantern to be on first
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("lantern"))
        )

        // When
        try await engine.execute("douse lantern")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > douse lantern
            The oil lantern is now off.
            """)

        let finalState = try await engine.item("lantern")
        #expect(finalState.hasFlag(.isOn) == false)
    }

    // MARK: - Validation Testing

    @Test("Cannot turn off without specifying what")
    func testCannotTurnOffWithoutWhat() async throws {
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
        try await engine.execute("turn off")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off
            Turn off what?
            """)
    }

    @Test("Cannot turn off non-existent item")
    func testCannotTurnOffNonExistentItem() async throws {
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
        try await engine.execute("turn off nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off nonexistent
            You can’t see any such thing.
            """)
    }

    @Test("Cannot turn off item not in scope")
    func testCannotTurnOffItemNotInScope() async throws {
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
        try await engine.execute("turn off lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lamp
            You can’t see any such thing.
            """)
    }

    @Test("Cannot turn off non-device item")
    func testCannotTurnOffNonDeviceItem() async throws {
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
        try await engine.execute("turn off rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off rock
            You can’t turn that off.
            """)
    }

    @Test("Cannot turn off already off device")
    func testCannotTurnOffAlreadyOffDevice() async throws {
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

        // Lamp is off by default, no need to set it

        // When
        try await engine.execute("turn off lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lamp
            It’s already off.
            """)
    }

    @Test("Requires light to turn off items")
    func testRequiresLight() async throws {
        // Given: Dark room with light source that’s on
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A brass lamp."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set the lamp to be on (providing light)
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("lamp"))
        )

        // Now try to turn it off - this should work since the lamp itself provides light
        // When
        try await engine.execute("turn off lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lamp
            The brass lamp is now off.
            You are plunged into darkness.
            """)
    }

    // MARK: - Processing Testing

    @Test("Turn off device clears isOn flag")
    func testTurnOffDeviceClearsIsOnFlag() async throws {
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

        // Set the radio to be on first
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("radio"))
        )

        // When
        try await engine.execute("turn off radio")

        // Then
        let finalState = try await engine.item("radio")
        #expect(finalState.hasFlag(.isOn) == false)
        #expect(finalState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off radio
            The portable radio is now off.
            """)
    }

    @Test("Turn off light source in dark room shows darkness message")
    func testTurnOffLightSourceInDarkRoomShowsDarknessMessage() async throws {
        // Given: Dark room with player holding only light source
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A room that becomes dark without a light source.")
            // Note: No .inherentlyLit property
        )

        let torch = Item(
            id: "torch",
            .name("wooden torch"),
            .description("A burning wooden torch."),
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

        // Set the torch to be on (providing light)
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("torch"))
        )

        // When
        try await engine.execute("turn off torch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off torch
            The wooden torch is now off.
            You are plunged into darkness.
            """)

        // Verify room is now dark
        let isLit = await engine.playerLocationIsLit()
        #expect(isLit == false)
    }

    @Test("Turn off light source with other light sources present doesn’t show darkness")
    func testTurnOffLightSourceWithOtherLightSourcesPresent() async throws {
        // Given: Dark room with two light sources
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A room with multiple light sources.")
            // Note: No .inherentlyLit property
        )

        let torch = Item(
            id: "torch",
            .name("wooden torch"),
            .description("A wooden torch."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A brass lamp."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: torch, lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set both light sources to be on
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("torch")),
            await engine.setFlag(.isOn, on: try await engine.item("lamp"))
        )

        // When - turn off one light source
        try await engine.execute("turn off torch")

        // Then - should not show darkness message since lamp is still on
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off torch
            The wooden torch is now off.
            """)

        // Verify room is still lit
        let isLit = await engine.playerLocationIsLit()
        #expect(isLit == true)
    }

    @Test("Turn off light source in inherently lit room doesn’t show darkness")
    func testTurnOffLightSourceInInherentlyLitRoom() async throws {
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

        // Set the lamp to be on first
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("lamp"))
        )

        // When
        try await engine.execute("turn off lamp")

        // Then - should not show darkness message since room is inherently lit
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lamp
            The desk lamp is now off.
            """)

        // Verify room is still lit
        let isLit = await engine.playerLocationIsLit()
        #expect(isLit == true)
    }

    @Test("Turn off non-light-source device")
    func testTurnOffNonLightSourceDevice() async throws {
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

        // Set the radio to be on first
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("radio"))
        )

        // When
        try await engine.execute("turn off radio")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off radio
            The portable radio is now off.
            """)

        let finalState = try await engine.item("radio")
        #expect(finalState.hasFlag(.isOn) == false)
    }

    @Test("Updates pronouns to refer to turned off item")
    func testUpdatesPronounsToTurnedOffItem() async throws {
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

        // Set the lamp to be on first
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("lamp"))
        )

        // When
        try await engine.execute("turn off lamp")
        try await engine.execute("examine it")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lamp
            The brass lamp is now off.
            > examine it
            A shiny brass lamp.
            """)
    }

    @Test("Turn off light source in location illuminates location items")
    func testTurnOffLightSourceInLocationIlluminatesLocationItems() async throws {
        // Given: Dark room with light source on floor and other items
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A dark room.")
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A brass lamp."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.location("darkRoom"))
        )

        let book = Item(
            id: "book",
            .name("old book"),
            .description("An old leather book."),
            .isTakable,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lamp, book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set the lamp to be on (providing light)
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("lamp"))
        )

        // When
        try await engine.execute("turn off lamp")

        // Then - should show darkness message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lamp
            The brass lamp is now off.
            You are plunged into darkness.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = TurnOffActionHandler()
        // TurnOffActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = TurnOffActionHandler()
        #expect(handler.verbs.contains(.extinguish))
        #expect(handler.verbs.contains(.douse))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = TurnOffActionHandler()
        #expect(handler.requiresLight == true)
    }

    @Test("Handler syntax rules are correct")
    func testSyntaxRules() async throws {
        let handler = TurnOffActionHandler()
        #expect(handler.syntax.count == 4)
        // The specific syntax patterns are tested through the command execution tests above
    }
}
