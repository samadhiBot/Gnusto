import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("KickActionHandler Tests")
struct KickActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("KICK DIRECTOBJECT syntax works")
    func testKickDirectObjectSyntax() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A big granite boulder."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kick rock
            Kicking the large rock would injure your pride and possibly
            your toes.
            """
        )

        let finalState = await engine.item("rock")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot kick without specifying target")
    func testCannotKickWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kick
            Kick what?
            """
        )
    }

    @Test("Cannot kick target not in scope")
    func testCannotKickTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteRock = Item(
            id: "remoteRock",
            .name("remote rock"),
            .description("A rock in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteRock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kick rock
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Requires light to kick")
    func testRequiresLight() async throws {
        // Given: Dark room with an object to kick
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A big granite boulder."),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kick rock
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Kick character gives special message")
    func testKickCharacter() async throws {
        // Given
        let game = MinimalGame(
            items: Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kick troll
            The fierce troll has done nothing to deserve such unprovoked
            violence.
            """
        )

        let finalState = await engine.item("troll")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Kick regular object gives standard message")
    func testKickRegularObject() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A sturdy wooden box."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kick box
            Kicking the wooden box would injure your pride and possibly
            your toes.
            """
        )

        let finalState = await engine.item("box")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Kick small object")
    func testKickSmallObject() async throws {
        // Given
        let pebble = Item(
            id: "pebble",
            .name("small pebble"),
            .description("A tiny pebble."),
            .in(.startRoom),
            .isTakable
        )

        let game = MinimalGame(
            items: pebble
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick pebble")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kick pebble
            The small pebble shifts slightly under your half-hearted kick.
            """
        )
    }

    @Test("Kicking sets isTouched flag")
    func testKickingSetsTouchedFlag() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("wooden door"),
            .description("A heavy wooden door."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: door
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick door")

        // Then
        let finalState = await engine.item("door")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Kick multiple objects in sequence")
    func testKickMultipleObjects() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("oak table"),
            .description("A solid oak table."),
            .in(.startRoom)
        )

        let chair = Item(
            id: "chair",
            .name("wooden chair"),
            .description("A simple wooden chair."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: table, chair
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick table", "kick chair")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kick table
            Kicking the oak table would injure your pride and possibly your
            toes.

            > kick chair
            Your foot meets the wooden chair in an unequal contest. Your
            foot loses.
            """
        )

        let tableState = await engine.item("table")
        let chairState = await engine.item("chair")
        #expect(await tableState.hasFlag(.isTouched) == true)
        #expect(await chairState.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = KickActionHandler()
        #expect(handler.synonyms.contains(.kick))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = KickActionHandler()
        #expect(handler.requiresLight == true)
    }
}
