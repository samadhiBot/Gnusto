import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("JumpActionHandler Tests")
struct JumpActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("JUMP syntax works")
    func testJumpSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump")

        // Then
        await mockIO.expect(
            """
            > jump
            You spring upward with temporary defiance of gravity.
            """
        )
    }

    @Test("JUMP DIRECTOBJECT syntax works")
    func testJumpDirectObjectSyntax() async throws {
        // Given
        let log = Item("log")
            .name("fallen log")
            .description("A large fallen log.")
            .in(.startRoom)

        let game = MinimalGame(
            items: log
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump log")

        // Then
        await mockIO.expect(
            """
            > jump log
            You can't jump over the fallen log.
            """
        )

        let finalState = await engine.item("log")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("JUMP OVER DIRECTOBJECT syntax works")
    func testJumpOverDirectObjectSyntax() async throws {
        // Given
        let stream = Item("stream")
            .name("small stream")
            .description("A small babbling stream.")
            .in(.startRoom)

        let game = MinimalGame(
            items: stream
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump over stream")

        // Then
        await mockIO.expect(
            """
            > jump over stream
            You can't jump over the small stream.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot jump target not in scope")
    func testCannotJumpTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteObstacle = Item("remoteObstacle")
            .name("remote obstacle")
            .description("An obstacle in another room.")
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteObstacle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump obstacle")

        // Then
        await mockIO.expect(
            """
            > jump obstacle
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Does not require light to jump")
    func testDoesNotRequireLight() async throws {
        // Given: Dark room
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump")

        // Then
        await mockIO.expect(
            """
            > jump
            You spring upward with temporary defiance of gravity.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Jump with character gives special message")
    func testJumpWithCharacter() async throws {
        // Given
        let game = MinimalGame(
            items: Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump troll")

        // Then
        await mockIO.expect(
            """
            > jump troll
            Leaping upon the fierce troll would be an extraordinary breach
            of personal space.
            """
        )

        let finalState = await engine.item("troll")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Jump with regular object gives standard message")
    func testJumpWithObject() async throws {
        // Given
        let boulder = Item("boulder")
            .name("large boulder")
            .description("A massive boulder.")
            .in(.startRoom)

        let game = MinimalGame(
            items: boulder
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump boulder")

        // Then
        await mockIO.expect(
            """
            > jump boulder
            You can't jump over the large boulder.
            """
        )

        let finalState = await engine.item("boulder")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Jumping with object sets isTouched flag")
    func testJumpingSetsTouchedFlag() async throws {
        // Given
        let fence = Item("fence")
            .name("wooden fence")
            .description("A tall wooden fence.")
            .in(.startRoom)

        let game = MinimalGame(
            items: fence
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump fence")

        // Then
        let finalState = await engine.item("fence")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Jumping over object with OVER preposition")
    func testJumpOverWithPreposition() async throws {
        // Given
        let puddle = Item("puddle")
            .name("mud puddle")
            .description("A small mud puddle.")
            .in(.startRoom)

        let game = MinimalGame(
            items: puddle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump over puddle")

        // Then
        await mockIO.expect(
            """
            > jump over puddle
            You can't jump over the mud puddle.
            """
        )

        let finalState = await engine.item("puddle")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = JumpActionHandler()
        #expect(handler.synonyms.contains(.jump))
        #expect(handler.synonyms.contains(.leap))
        #expect(handler.synonyms.contains(.hop))
        #expect(handler.synonyms.count == 3)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = JumpActionHandler()
        #expect(handler.requiresLight == false)
    }
}
