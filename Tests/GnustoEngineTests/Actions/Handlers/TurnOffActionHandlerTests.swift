import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("TurnOffActionHandler Tests")
struct TurnOffActionHandlerTests {

    // MARK: - Syntax Tests

    @Test("TURN OFF syntax works")
    func testTurnOffSyntax() async throws {
        // Given
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
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set the lamp to be on first
        try await engine.apply(
            lamp.proxy(engine).setFlag(.isOn)
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
            """
        )

        let finalState = await engine.item("lamp")
        #expect(await finalState.hasFlag(.isOn) == false)
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("SWITCH OFF syntax works")
    func testSwitchOffSyntax() async throws {
        // Given
        let flashlight = Item(
            id: "flashlight",
            .name("small flashlight"),
            .description("A compact flashlight."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: flashlight
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set the flashlight to be on first
        try await engine.apply(
            flashlight.proxy(engine).setFlag(.isOn)
        )

        // When
        try await engine.execute("switch off flashlight")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > switch off flashlight
            The small flashlight is now off.
            """
        )

        let finalState = await engine.item("flashlight")
        #expect(await finalState.hasFlag(.isOn) == false)
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Validation Tests

    @Test("Cannot turn off without specifying what")
    func testCannotTurnOffWithoutWhat() async throws {
        // Given
        let game = MinimalGame()
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
            """
        )
    }

    @Test("Cannot turn off non-existent item")
    func testCannotTurnOffNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn off lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lamp
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Cannot turn off item not in scope")
    func testCannotTurnOffItemNotInScope() async throws {
        // Given
        let otherRoom = Location(
            id: "otherRoom",
            .name("Other Room"),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lamp."),
            .isLightSource,
            .isDevice,
            .in("otherRoom")
        )

        let game = MinimalGame(
            locations: otherRoom,
            items: lamp
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
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Cannot turn off non-device item")
    func testCannotTurnOffNonDeviceItem() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A worn leather-bound book."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn off book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off book
            That refuses to acknowledge your attempts to silence it.
            """
        )
    }

    @Test("Cannot turn off already off device")
    func testCannotTurnOffAlreadyOffDevice() async throws {
        // Given
        let radio = Item(
            id: "radio",
            .name("portable radio"),
            .description("A small battery-powered radio."),
            .isDevice,
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: radio
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn off radio")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off radio
            It rests in darkness already.
            """
        )
    }

    // MARK: - Device Functionality Tests

    @Test("Turn off device clears isOn flag")
    func testTurnOffDeviceClearsIsOnFlag() async throws {
        // Given
        let computer = Item(
            id: "computer",
            .name("laptop computer"),
            .description("A sleek laptop computer."),
            .isDevice,
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: computer
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set the computer to be on first
        try await engine.apply(
            computer.proxy(engine).setFlag(.isOn)
        )

        // When
        try await engine.execute("turn off computer")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off computer
            The laptop computer is now off.
            """
        )

        let finalState = await engine.item("computer")
        #expect(await finalState.hasFlag(.isOn) == false)
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Turn off light source in dark room shows darkness message")
    func testTurnOffLightSourceInDarkRoomShowsDarknessMessage() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A room that is pitch black without light.")
        )

        let lantern = Item(
            id: "lantern",
            .name("electric lantern"),
            .description("A bright electric lantern."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lantern
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set the lantern to be on first (providing light)
        try await engine.apply(
            lantern.proxy(engine).setFlag(.isOn)
        )

        // When
        try await engine.execute("turn off lantern")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lantern
            The electric lantern is now off.

            The world vanishes into absolute blackness.

            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    @Test("Turn off light source with other light sources present")
    func testTurnOffLightSourceWithOtherLightSourcesPresent() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A room that is pitch black without light.")
        )

        let lantern = Item(
            id: "lantern",
            .name("electric lantern"),
            .description("A bright electric lantern."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let flashlight = Item(
            id: "flashlight",
            .name("small flashlight"),
            .description("A compact flashlight."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lantern, flashlight
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set both light sources to be on
        try await engine.apply(
            lantern.proxy(engine).setFlag(.isOn),
            flashlight.proxy(engine).setFlag(.isOn)
        )

        // When
        try await engine.execute("turn off lantern")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lantern
            The electric lantern is now off.
            """
        )

        // Room should still be lit due to flashlight
        let isLit = await engine.player.location.isLit
        #expect(isLit == true)
    }

    @Test("Turn off light source in inherently lit room")
    func testTurnOffLightSourceInInherentlyLitRoom() async throws {
        // Given
        let lamp = Item(
            id: "lamp",
            .name("desk lamp"),
            .description("A modern desk lamp."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set the lamp to be on first
        try await engine.apply(
            lamp.proxy(engine).setFlag(.isOn)
        )

        // When
        try await engine.execute("turn off lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lamp
            The desk lamp is now off.
            """
        )

        // Room should still be lit due to inherent lighting
        let isLit = await engine.player.location.isLit
        #expect(isLit == true)
    }

    @Test("Turn off non-light-source device")
    func testTurnOffNonLightSourceDevice() async throws {
        // Given
        let fan = Item(
            id: "fan",
            .name("electric fan"),
            .description("A small electric fan."),
            .isDevice,
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: fan
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set the fan to be on first
        try await engine.apply(
            fan.proxy(engine).setFlag(.isOn)
        )

        // When
        try await engine.execute("turn off fan")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off fan
            The electric fan is now off.
            """
        )

        let finalState = await engine.item("fan")
        #expect(await finalState.hasFlag(.isOn) == false)
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Touched flag always set on successful turn off")
    func testTouchedFlagAlwaysSet() async throws {
        // Given
        let device = Item(
            id: "device",
            .name("small device"),
            .description("A small electronic device."),
            .isDevice,
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: device
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Set device to be on and ensure it starts without touched flag
        try await engine.apply(
            device.proxy(engine).setFlag(.isOn),
            device.proxy(engine).clearFlag(.isTouched)
        )

        // Verify initial state
        let initialDevice = await engine.item("device")
        #expect(await initialDevice.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("turn off device")

        // Then
        let finalDevice = await engine.item("device")
        #expect(await finalDevice.hasFlag(.isTouched) == true)
    }

    // MARK: - Handler Property Tests

    @Test("Handler synonyms are correct")
    func testSynonyms() async throws {
        let handler = TurnOffActionHandler()
        #expect(handler.synonyms == [.switch, .turn])
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = TurnOffActionHandler()
        #expect(handler.requiresLight == false)
    }

    @Test("Handler syntax rules are correct")
    func testSyntaxRules() async throws {
        let handler = TurnOffActionHandler()
        let expectedSyntax: [SyntaxRule] = [
            .match(.verb, .off, .directObject)
        ]
        #expect(handler.syntax == expectedSyntax)
    }

    @Test("Handler registration in default handlers")
    func testHandlerRegistration() async throws {
        let defaultHandlers = GameEngine.defaultActionHandlers
        #expect(defaultHandlers.contains { $0 is TurnOffActionHandler })
    }

    @Test("All synonyms work")
    func testAllSynonyms() async throws {
        // Given
        let device = Item(
            id: "device",
            .name("test device"),
            .description("A device for testing."),
            .isDevice,
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: device
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Test each synonym
        for verb in ["turn", "switch"] {
            // Reset device state
            try await engine.apply(
                device.proxy(engine).setFlag(.isOn),
                device.proxy(engine).setFlag(.isTouched)
            )

            // When
            try await engine.execute("\(verb) off device")

            // Then
            let output = await mockIO.flush()
            expectNoDifference(
                output,
                """
                > \(verb) off device
                The test device is now off.
                """
            )

            let finalDevice = await engine.item("device")
            #expect(await finalDevice.hasFlag(.isOn) == false)
        }
    }
}
