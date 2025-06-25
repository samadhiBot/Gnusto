import CustomDump
import Testing

@testable import GnustoEngine

@Suite("PressActionHandler Tests")
struct PressActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("PRESS DIRECTOBJECT syntax works")
    func testPressDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let button = Item(
            id: "button",
            .name("red button"),
            .description("A large red button."),
            .isPressable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: button
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("press button")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > press button
            You press the red button.
            """)

        let finalState = try await engine.item("button")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("DEPRESS syntax works")
    func testDepressSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lightSwitch = Item(
            id: "lightSwitch",
            .name("light switch"),
            .description("A standard light switch."),
            .isPressable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lightSwitch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("depress switch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > depress switch
            You press the light switch.
            """)
    }

    @Test("PUSH syntax works for pressable items")
    func testPushSyntaxForPressableItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let doorbell = Item(
            id: "doorbell",
            .name("doorbell"),
            .description("A brass doorbell."),
            .isPressable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: doorbell
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push doorbell")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > push doorbell
            You press the doorbell.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot press without specifying object")
    func testCannotPressWithoutObject() async throws {
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
        try await engine.execute("press")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > press
            Press what?
            """)
    }

    @Test("Cannot press non-existent item")
    func testCannotPressNonExistentItem() async throws {
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
        try await engine.execute("press nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > press nonexistent
            You can't see any such thing.
            """)
    }

    @Test("Cannot press item not in scope")
    func testCannotPressItemNotInScope() async throws {
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

        let remoteButton = Item(
            id: "remoteButton",
            .name("remote button"),
            .description("A button in another room."),
            .isPressable,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteButton
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("press button")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > press button
            You can't see any such thing.
            """)
    }

    @Test("Cannot press location")
    func testCannotPressLocation() async throws {
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
        try await engine.execute("press testRoom")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > press testRoom
            That's not something you can press.
            """)
    }

    @Test("Cannot press player")
    func testCannotPressPlayer() async throws {
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
        try await engine.execute("press me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > press me
            That's not something you can press.
            """)
    }

    @Test("Requires light to press")
    func testRequiresLight() async throws {
        // Given: Dark room with pressable item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let button = Item(
            id: "button",
            .name("red button"),
            .description("A large red button."),
            .isPressable,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: button
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("press button")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > press button
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Press pressable item succeeds")
    func testPressPressableItemSucceeds() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let alarm = Item(
            id: "alarm",
            .name("fire alarm"),
            .description("A red fire alarm button."),
            .isPressable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: alarm
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("press alarm")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > press alarm
            You press the fire alarm.
            """)

        let finalState = try await engine.item("alarm")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Press non-pressable item fails")
    func testPressNonPressableItemFails() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("press rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > press rock
            You can't press the large rock.
            """)

        let finalState = try await engine.item("rock")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Press item sets touched flag")
    func testPressItemSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let keypad = Item(
            id: "keypad",
            .name("numeric keypad"),
            .description("A numeric keypad with buttons."),
            .isPressable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: keypad
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify keypad is not touched initially
        let initialState = try await engine.item("keypad")
        #expect(initialState.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("press keypad")

        // Then
        let finalState = try await engine.item("keypad")
        #expect(finalState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > press keypad
            You press the numeric keypad.
            """)
    }

    @Test("Press item updates pronouns")
    func testPressItemUpdatesPronouns() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let button = Item(
            id: "button",
            .name("emergency button"),
            .description("A big red emergency button."),
            .isPressable,
            .in(.location("testRoom"))
        )

        let lightSwitch = Item(
            id: "lightSwitch",
            .name("power switch"),
            .description("A main power switch."),
            .isPressable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: button, lightSwitch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // First examine the switch to set pronouns
        try await engine.execute("examine switch")
        _ = await mockIO.flush()

        // When - Press button should update pronouns to button
        try await engine.execute("press button")
        _ = await mockIO.flush()

        // Then - "examine it" should now refer to the button
        try await engine.execute("examine it")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine it
            A big red emergency button.
            """)
    }

    @Test("Press held item works")
    func testPressHeldItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let remote = Item(
            id: "remote",
            .name("TV remote"),
            .description("A television remote control."),
            .isPressable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: remote
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("press remote")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > press remote
            You press the TV remote.
            """)

        let finalState = try await engine.item("remote")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Press item in container")
    func testPressItemInContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("control box"),
            .description("A control box with buttons."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let button = Item(
            id: "button",
            .name("start button"),
            .description("A green start button."),
            .isPressable,
            .in(.item("box"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, button
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("press button")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > press button
            You press the start button.
            """)

        let finalState = try await engine.item("button")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Press different types of pressable items")
    func testPressDifferentTypesOfPressableItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lever = Item(
            id: "lever",
            .name("metal lever"),
            .description("A heavy metal lever."),
            .isPressable,
            .in(.location("testRoom"))
        )

        let panel = Item(
            id: "panel",
            .name("control panel"),
            .description("A complex control panel."),
            .isPressable,
            .in(.location("testRoom"))
        )

        let key = Item(
            id: "key",
            .name("piano key"),
            .description("A white piano key."),
            .isPressable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lever, panel, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Press lever
        try await engine.execute("press lever")

        let leverOutput = await mockIO.flush()
        expectNoDifference(
            leverOutput,
            """
            > press lever
            You press the metal lever.
            """)

        // When - Press panel
        try await engine.execute("press panel")

        let panelOutput = await mockIO.flush()
        expectNoDifference(
            panelOutput,
            """
            > press panel
            You press the control panel.
            """)

        // When - Press key
        try await engine.execute("press key")

        let keyOutput = await mockIO.flush()
        expectNoDifference(
            keyOutput,
            """
            > press key
            You press the piano key.
            """)
    }

    @Test("Press non-pressable different item types")
    func testPressNonPressableDifferentItemTypes() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("old book"),
            .description("An old leather book."),
            .in(.location("testRoom"))
        )

        let character = Item(
            id: "character",
            .name("old man"),
            .description("A wise old man."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let device = Item(
            id: "device",
            .name("strange device"),
            .description("A strange mechanical device."),
            .isDevice,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book, character, device
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Press book
        try await engine.execute("press book")

        let bookOutput = await mockIO.flush()
        expectNoDifference(
            bookOutput,
            """
            > press book
            You can't press the old book.
            """)

        // When - Press character
        try await engine.execute("press man")

        let characterOutput = await mockIO.flush()
        expectNoDifference(
            characterOutput,
            """
            > press man
            You can't press the old man.
            """)

        // When - Press device
        try await engine.execute("press device")

        let deviceOutput = await mockIO.flush()
        expectNoDifference(
            deviceOutput,
            """
            > press device
            You can't press the strange device.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = PressActionHandler()
        // PressActionHandler doesn't specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = PressActionHandler()
        #expect(handler.verbs.contains(.press))
        #expect(handler.verbs.contains(.depress))
        #expect(handler.verbs.contains(.push))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = PressActionHandler()
        #expect(handler.requiresLight == true)
    }

    @Test("Handler uses correct syntax")
    func testSyntaxRules() async throws {
        let handler = PressActionHandler()
        #expect(handler.syntax.count == 1)

        // Should have one syntax rule:
        // .match(.verb, .directObject)
    }
}
