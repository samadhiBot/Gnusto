import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("PushActionHandler Tests")
struct PushActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("PUSH DIRECTOBJECT syntax works")
    func testPushDirectObjectSyntax() async throws {
        // Given
        let button = Item(
            id: "button",
            .name("red button"),
            .description("A large red button."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: button
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push button")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > push button
            The red button meets your push with immovable resistance.
            """
        )

        let finalState = try await engine.item("button")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("PUSH CHARACTER syntax works")
    func testPushCharacterSyntax() async throws {
        // Given
        let towerGuard = Item(
            id: "guard",
            .name("surly guard"),
            .description("A surly tower guard."),
            .in(.startRoom),
            .characterSheet(.init())
        )

        let game = MinimalGame(
            items: towerGuard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push the guard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > push the guard
            Shoving the surly guard would cross lines better left
            uncrossed.
            """
        )

        let finalState = try await engine.item("guard")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("PUSH ENEMY syntax works")
    func testPushEnemySyntax() async throws {
        // Given
        let game = MinimalGame(
            items: Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push the troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > push the troll
            Shoving the fierce troll would cross lines better left
            uncrossed.
            """
        )

        let finalState = try await engine.item("troll")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("PRESS DIRECTOBJECT syntax works")
    func testPressDirectObjectSyntax() async throws {
        // Given
        let button = Item(
            id: "button",
            .name("red button"),
            .description("A large red button."),
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            The red button meets your push with immovable resistance.
            """
        )

        let finalState = try await engine.item("button")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("DEPRESS syntax works")
    func testDepressSyntax() async throws {
        // Given
        let lightSwitch = Item(
            id: "lightSwitch",
            .name("light switch"),
            .description("A standard light switch."),
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            The light switch meets your push with immovable resistance.
            """
        )
    }

    @Test("SHOVE syntax works")
    func testShoveSyntax() async throws {
        // Given
        let crate = Item(
            id: "crate",
            .name("wooden crate"),
            .description("A heavy wooden crate."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: crate
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shove crate")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shove crate
            The wooden crate meets your push with immovable resistance.
            """
        )
    }

    @Test("PUSH ALL syntax works")
    func testPushAllSyntax() async throws {
        // Given
        let button1 = Item(
            id: "button1",
            .name("first button"),
            .description("A red button."),
            .in(.startRoom)
        )

        let button2 = Item(
            id: "button2",
            .name("second button"),
            .description("A blue button."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: button1, button2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > push all
            The verb 'push' doesn't support multiple objects.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot push without specifying target")
    func testCannotPushWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > push
            Push what?
            """
        )
    }

    @Test("Cannot press non-existent item")
    func testCannotPressNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("press nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > press nonexistent
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot push target not in scope")
    func testCannotPushTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteButton = Item(
            id: "remoteButton",
            .name("remote button"),
            .description("A button in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteButton
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push button")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > push button
            Any such thing lurks beyond your reach.
            """
        )
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
            .in("darkRoom")
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
        expectNoDifference(
            output,
            """
            > push lever
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    @Test("Cannot press location")
    func testCannotPressLocation() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("press testRoom")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > press testRoom
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot press player")
    func testCannotPressPlayer() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("press me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > press me
            The logistics of pressing oneself prove insurmountable.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Push object in room")
    func testPushObjectInRoom() async throws {
        // Given
        let lightSwitch = Item(
            id: "lightSwitch",
            .name("light switch"),
            .description("A simple light switch."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: lightSwitch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push switch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > push switch
            The light switch meets your push with immovable resistance.
            """
        )

        let finalState = try await engine.item("lightSwitch")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Push held item")
    func testPushHeldItem() async throws {
        // Given
        let device = Item(
            id: "device",
            .name("electronic device"),
            .description("A small electronic device."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: device
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push device")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > push device
            The electronic device meets your push with immovable
            resistance.
            """
        )
    }

    @Test("Push multiple objects")
    func testPushMultipleObjects() async throws {
        // Given
        let button1 = Item(
            id: "button1",
            .name("red button"),
            .description("A red button."),
            .in(.startRoom)
        )

        let button2 = Item(
            id: "button2",
            .name("blue button"),
            .description("A blue button."),
            .in(.startRoom)
        )

        let button3 = Item(
            id: "button3",
            .name("green button"),
            .description("A green button."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: button1, button2, button3
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push red button and blue button")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > push red button and blue button
            The verb 'push' doesn't support multiple objects.
            """
        )
    }

    @Test("Pushing sets isTouched flag")
    func testPushingSetsTouchedFlag() async throws {
        // Given
        let doorbell = Item(
            id: "doorbell",
            .name("doorbell"),
            .description("A brass doorbell button."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: doorbell
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Verify initial state
        let initialState = try await engine.item("doorbell")
        #expect(await initialState.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("push doorbell")

        // Then
        let finalState = try await engine.item("doorbell")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Push object in open container")
    func testPushObjectInOpenContainer() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("control box"),
            .description("A control box with buttons."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.startRoom)
        )

        let button = Item(
            id: "button",
            .name("emergency button"),
            .description("A red emergency button."),
            .in(.item("box"))
        )

        let game = MinimalGame(
            items: box, button
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push button")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > push button
            The emergency button meets your push with immovable resistance.
            """
        )
    }

    @Test("Push all")
    func testPushAll() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("push all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > push all
            The verb 'push' doesn't support multiple objects.
            """
        )
    }

    @Test("Push sequence of different objects")
    func testPushSequenceOfDifferentObjects() async throws {
        // Given
        let lever = Item(
            id: "lever",
            .name("wooden lever"),
            .description("A wooden lever mechanism."),
            .in(.startRoom)
        )

        let dial = Item(
            id: "dial",
            .name("brass dial"),
            .description("A brass control dial."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: lever, dial
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "push lever",
            "shove dial"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > push lever
            The wooden lever meets your push with immovable resistance.

            > shove dial
            Pushing the brass dial proves an exercise in futility.
            """
        )

        let leverState = try await engine.item("lever")
        let dialState = try await engine.item("dial")
        #expect(await leverState.hasFlag(.isTouched) == true)
        #expect(await dialState.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = PushActionHandler()
        #expect(handler.synonyms == [.depress, .press, .push, .shove])
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = PushActionHandler()
        #expect(handler.requiresLight == true)
    }
}
