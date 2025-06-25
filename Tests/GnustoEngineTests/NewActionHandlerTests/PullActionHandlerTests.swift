import Testing
import CustomDump
@testable import GnustoEngine

@Suite("PullActionHandler Tests")
struct PullActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("PULL DIRECTOBJECT syntax works")
    func testPullDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let rope = Item(
            id: "rope",
            .name("thick rope"),
            .description("A thick hemp rope."),
            .isPullable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > pull rope
            You pull the thick rope.
            """)

        let finalState = try await engine.item("rope")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot pull without specifying target")
    func testCannotPullWithoutTarget() async throws {
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
        try await engine.execute("pull")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > pull
            Pull what?
            """)
    }

    @Test("Cannot pull target not in scope")
    func testCannotPullTargetNotInScope() async throws {
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

        let remoteLever = Item(
            id: "remoteLever",
            .name("remote lever"),
            .description("A lever in another room."),
            .isPullable,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteLever
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull lever")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > pull lever
            You can’t see any such thing.
            """)
    }

    @Test("Requires light to pull")
    func testRequiresLight() async throws {
        // Given: Dark room with an object to pull
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let chain = Item(
            id: "chain",
            .name("metal chain"),
            .description("A heavy metal chain."),
            .isPullable,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: chain
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull chain")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > pull chain
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Pull pullable object succeeds")
    func testPullPullableObjectSucceeds() async throws {
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
            .isPullable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lever
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull lever")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > pull lever
            You pull the wooden lever.
            """)

        let finalState = try await engine.item("lever")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Pull non-pullable object fails")
    func testPullNonPullableObjectFails() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("heavy rock"),
            .description("A massive boulder."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > pull rock
            You can’t pull the heavy rock.
            """)

        let finalState = try await engine.item("rock")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Pull held pullable item")
    func testPullHeldPullableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let cord = Item(
            id: "cord",
            .name("silk cord"),
            .description("A fine silk cord."),
            .isPullable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: cord
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull cord")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > pull cord
            You pull the silk cord.
            """)
    }

    @Test("Pull handle mechanism")
    func testPullHandleMechanism() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let handle = Item(
            id: "handle",
            .name("door handle"),
            .description("A brass door handle."),
            .isPullable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: handle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull handle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > pull handle
            You pull the door handle.
            """)
    }

    @Test("Pulling sets isTouched flag")
    func testPullingSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bell = Item(
            id: "bell",
            .name("church bell"),
            .description("A large church bell with a rope."),
            .isPullable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bell
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify initial state
        let initialState = try await engine.item("bell")
        #expect(initialState.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("pull bell")

        // Then
        let finalState = try await engine.item("bell")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Pull sequence of different objects")
    func testPullSequenceOfDifferentObjects() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rope1 = Item(
            id: "rope1",
            .name("first rope"),
            .description("A thick rope."),
            .isPullable,
            .in(.location("testRoom"))
        )

        let rope2 = Item(
            id: "rope2",
            .name("second rope"),
            .description("A thin rope."),
            .isPullable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rope1, rope2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull first rope")
        try await engine.execute("pull second rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > pull first rope
            You pull the first rope.
            > pull second rope
            You pull the second rope.
            """)

        let rope1State = try await engine.item("rope1")
        let rope2State = try await engine.item("rope2")
        #expect(rope1State.hasFlag(.isTouched) == true)
        #expect(rope2State.hasFlag(.isTouched) == true)
    }

    @Test("Pull object in open container")
    func testPullObjectInOpenContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box with mechanisms."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let string = Item(
            id: "string",
            .name("pull string"),
            .description("A string for pulling."),
            .isPullable,
            .in(.item("box"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, string
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull string")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > pull string
            You pull the pull string.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = PullActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = PullActionHandler()
        #expect(handler.verbs.contains(.pull))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = PullActionHandler()
        #expect(handler.requiresLight == true)
    }
}
