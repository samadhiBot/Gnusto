import Testing
import CustomDump
@testable import GnustoEngine

@Suite("PushActionHandler Tests")
struct PushActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("PUSH DIRECTOBJECT syntax works")
    func testPushDirectObjectSyntax() async throws {
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
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: button
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push button")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > push button
            Nothing happens.
            """)

        let finalState = try await engine.item("button")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("SHOVE syntax works")
    func testShoveSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let crate = Item(
            id: "crate",
            .name("wooden crate"),
            .description("A heavy wooden crate."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: crate
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shove crate")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shove crate
            Nothing happens.
            """)
    }

    @Test("PUSH ALL syntax works")
    func testPushAllSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let button1 = Item(
            id: "button1",
            .name("first button"),
            .description("A red button."),
            .in(.location("testRoom"))
        )

        let button2 = Item(
            id: "button2",
            .name("second button"),
            .description("A blue button."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: button1, button2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > push all
            first button: Nothing happens.
            second button: Nothing happens.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot push without specifying target")
    func testCannotPushWithoutTarget() async throws {
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
        try await engine.execute("push")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > push
            Push what?
            """)
    }

    @Test("Cannot push target not in scope")
    func testCannotPushTargetNotInScope() async throws {
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
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteButton
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push button")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > push button
            You can't see any such thing.
            """)
    }

    @Test("Requires light to push")
    func testRequiresLight() async throws {
        // Given: Dark room with an object to push
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let lever = Item(
            id: "lever",
            .name("metal lever"),
            .description("A heavy metal lever."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lever
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push lever")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > push lever
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Push object in room")
    func testPushObjectInRoom() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lightSwitch = Item(
            id: "lightSwitch",
            .name("light switch"),
            .description("A simple light switch."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lightSwitch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push switch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > push switch
            Nothing happens.
            """)

        let finalState = try await engine.item("lightSwitch")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Push held item")
    func testPushHeldItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let device = Item(
            id: "device",
            .name("electronic device"),
            .description("A small electronic device."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: device
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push device")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > push device
            Nothing happens.
            """)
    }

    @Test("Push multiple objects")
    func testPushMultipleObjects() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let button1 = Item(
            id: "button1",
            .name("red button"),
            .description("A red button."),
            .in(.location("testRoom"))
        )

        let button2 = Item(
            id: "button2",
            .name("blue button"),
            .description("A blue button."),
            .in(.location("testRoom"))
        )

        let button3 = Item(
            id: "button3",
            .name("green button"),
            .description("A green button."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: button1, button2, button3
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push red button and blue button")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > push red button and blue button
            red button: Nothing happens.
            blue button: Nothing happens.
            """)

        let button1State = try await engine.item("button1")
        let button2State = try await engine.item("button2")
        #expect(button1State.hasFlag(.isTouched) == true)
        #expect(button2State.hasFlag(.isTouched) == true)
    }

    @Test("Pushing sets isTouched flag")
    func testPushingSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let doorbell = Item(
            id: "doorbell",
            .name("doorbell"),
            .description("A brass doorbell button."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: doorbell
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify initial state
        let initialState = try await engine.item("doorbell")
        #expect(initialState.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("push doorbell")

        // Then
        let finalState = try await engine.item("doorbell")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Push object in open container")
    func testPushObjectInOpenContainer() async throws {
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
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let button = Item(
            id: "button",
            .name("emergency button"),
            .description("A red emergency button."),
            .in(.item("box"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, button
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push button")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > push button
            Nothing happens.
            """)
    }

    @Test("Push all with no pushable items")
    func testPushAllWithNoPushableItems() async throws {
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
        try await engine.execute("push all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > push all
            There's nothing here to push.
            """)
    }

    @Test("Push all with mixed reachable and unreachable items")
    func testPushAllWithMixedItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let closedBox = Item(
            id: "closedBox",
            .name("closed box"),
            .description("A closed metal box."),
            .isContainer,
            .isOpenable,
            .in(.location("testRoom"))
        )

        let hiddenButton = Item(
            id: "hiddenButton",
            .name("hidden button"),
            .description("A button hidden inside the box."),
            .in(.item("closedBox"))
        )

        let visibleButton = Item(
            id: "visibleButton",
            .name("visible button"),
            .description("A button on the wall."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: closedBox, hiddenButton, visibleButton
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > push all
            closed box: Nothing happens.
            visible button: Nothing happens.
            """)
    }

    @Test("Push sequence of different objects")
    func testPushSequenceOfDifferentObjects() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lever = Item(
            id: "lever",
            .name("wooden lever"),
            .description("A wooden lever mechanism."),
            .in(.location("testRoom"))
        )

        let dial = Item(
            id: "dial",
            .name("brass dial"),
            .description("A brass control dial."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lever, dial
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push lever")
        try await engine.execute("shove dial")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > push lever
            Nothing happens.
            > shove dial
            Nothing happens.
            """)

        let leverState = try await engine.item("lever")
        let dialState = try await engine.item("dial")
        #expect(leverState.hasFlag(.isTouched) == true)
        #expect(dialState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = PushActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = PushActionHandler()
        #expect(handler.verbs.contains(.push))
        #expect(handler.verbs.contains(.shove))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = PushActionHandler()
        #expect(handler.requiresLight == true)
    }
}
