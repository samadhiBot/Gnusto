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
        let rock = Item("rock")
            .name("large rock")
            .description("A big granite boulder.")
            .in(.startRoom)

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick rock")

        // Then
        await mockIO.expectOutput(
            """
            > kick rock
            Your foot meets the large rock in an unequal contest. Your foot
            loses.
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
        await mockIO.expectOutput(
            """
            > kick
            Kick what?
            """
        )
    }

    @Test("Cannot kick target not in scope")
    func testCannotKickTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteRock = Item("remoteRock")
            .name("remote rock")
            .description("A rock in another room.")
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteRock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick rock")

        // Then
        await mockIO.expectOutput(
            """
            > kick rock
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Requires light to kick")
    func testRequiresLight() async throws {
        // Given: Dark room with an object to kick
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")

        let rock = Item("rock")
            .name("large rock")
            .description("A big granite boulder.")
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick rock")

        // Then
        await mockIO.expectOutput(
            """
            > kick rock
            The darkness here is absolute, consuming all light and hope of
            sight.
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
        await mockIO.expectOutput(
            """
            > kick troll
            Kicking the fierce troll would irreparably damage your
            relationship, among other things.
            """
        )

        let finalState = await engine.item("troll")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Kick regular object gives standard message")
    func testKickRegularObject() async throws {
        // Given
        let box = Item("box")
            .name("wooden box")
            .description("A sturdy wooden box.")
            .in(.startRoom)

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick box")

        // Then
        await mockIO.expectOutput(
            """
            > kick box
            Your foot meets the wooden box in an unequal contest. Your foot
            loses.
            """
        )

        let finalState = await engine.item("box")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Kick small object")
    func testKickSmallObject() async throws {
        // Given
        let pebble = Item("pebble")
            .name("small pebble")
            .description("A tiny pebble.")
            .in(.startRoom)
            .isTakable

        let game = MinimalGame(
            items: pebble
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick pebble")

        // Then
        await mockIO.expectOutput(
            """
            > kick pebble
            You nudge the small pebble with your foot. The universe yawns.
            """
        )
    }

    @Test("Kicking sets isTouched flag")
    func testKickingSetsTouchedFlag() async throws {
        // Given
        let door = Item("door")
            .name("wooden door")
            .description("A heavy wooden door.")
            .in(.startRoom)

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
        let table = Item("table")
            .name("oak table")
            .description("A solid oak table.")
            .in(.startRoom)

        let chair = Item("chair")
            .name("wooden chair")
            .description("A simple wooden chair.")
            .in(.startRoom)

        let game = MinimalGame(
            items: table, chair
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick table", "kick chair")

        // Then
        await mockIO.expectOutput(
            """
            > kick table
            Your foot meets the oak table in an unequal contest. Your foot
            loses.

            > kick chair
            The wooden chair absorbs your kick with monumental
            indifference.
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
