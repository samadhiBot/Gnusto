import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("GoActionHandler Tests")
struct GoActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("GO DIRECTION syntax works")
    func testGoDirectionSyntax() async throws {
        // Given
        let roundRoom = Location("roundRoom")
            .name("Round Room")
            .description("A room for testing.")
            .inherentlyLit
            .north("northRoom")

        let northRoom = Location("northRoom")
            .name("North Room")
            .description("A room to the north.")
            .inherentlyLit

        let game = MinimalGame(
            player: Player(in: "roundRoom"),
            locations: roundRoom, northRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("go north")

        // Then
        await mockIO.expect(
            """
            > go north
            --- North Room ---

            A room to the north.
            """
        )

        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "northRoom")
    }

    @Test("WALK DIRECTION syntax works")
    func testWalkDirectionSyntax() async throws {
        // Given
        let roundRoom = Location("roundRoom")
            .name("Round Room")
            .inherentlyLit
            .south("southRoom")

        let southRoom = Location("southRoom")
            .name("South Room")
            .description("A room to the south.")
            .inherentlyLit

        let game = MinimalGame(
            player: Player(in: "roundRoom"),
            locations: roundRoom, southRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("walk south")

        // Then
        await mockIO.expect(
            """
            > walk south
            --- South Room ---

            A room to the south.
            """
        )

        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "southRoom")
    }

    @Test("RUN DIRECTION syntax works")
    func testRunDirectionSyntax() async throws {
        // Given
        let roundRoom = Location("roundRoom")
            .name("Round Room")
            .inherentlyLit
            .east("eastRoom")

        let eastRoom = Location("eastRoom")
            .name("East Room")
            .description("A room to the east.")
            .inherentlyLit

        let game = MinimalGame(
            player: Player(in: "roundRoom"),
            locations: roundRoom, eastRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("run east")

        // Then
        await mockIO.expect(
            """
            > run east
            --- East Room ---

            A room to the east.
            """
        )

        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "eastRoom")
    }

    // MARK: - Directional Commands

    @Test("NORTH directional command works")
    func testNorthDirectionalCommand() async throws {
        // Given
        let roundRoom = Location("roundRoom")
            .name("Round Room")
            .inherentlyLit
            .north("northRoom")

        let northRoom = Location("northRoom")
            .name("North Room")
            .description("A room to the north.")
            .inherentlyLit

        let game = MinimalGame(
            player: Player(in: "roundRoom"),
            locations: roundRoom, northRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("north")

        // Then
        await mockIO.expect(
            """
            > north
            --- North Room ---

            A room to the north.
            """
        )

        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "northRoom")
    }

    @Test("N directional abbreviation works")
    func testNDirectionalAbbreviation() async throws {
        // Given
        let roundRoom = Location("roundRoom")
            .name("Round Room")
            .inherentlyLit
            .north("northRoom")

        let northRoom = Location("northRoom")
            .name("North Room")
            .description("A room to the north.")
            .inherentlyLit

        let game = MinimalGame(
            player: Player(in: "roundRoom"),
            locations: roundRoom, northRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("n")

        // Then
        await mockIO.expect(
            """
            > n
            --- North Room ---

            A room to the north.
            """
        )

        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "northRoom")
    }

    @Test("All cardinal directions work")
    func testAllCardinalDirections() async throws {
        // Given
        let centerRoom = Location("centerRoom")
            .name("Center Room")
            .description("A room in the center.")
            .inherentlyLit
            .north("northRoom")
            .south("southRoom")
            .east("eastRoom")
            .west("westRoom")

        let northRoom = Location("northRoom")
            .name("North Room")
            .description("A room to the north.")
            .inherentlyLit
            .south("centerRoom")

        let southRoom = Location("southRoom")
            .name("South Room")
            .description("A room to the south.")
            .inherentlyLit
            .north("centerRoom")

        let eastRoom = Location("eastRoom")
            .name("East Room")
            .description("A room to the east.")
            .inherentlyLit
            .west("centerRoom")

        let westRoom = Location("westRoom")
            .name("West Room")
            .description("A room to the west.")
            .inherentlyLit
            .east("centerRoom")

        let game = MinimalGame(
            player: Player(in: "centerRoom"),
            locations: centerRoom, northRoom, southRoom, eastRoom, westRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Test each direction
        try await engine.execute("north")
        var playerLocation = await engine.player.location.id
        #expect(playerLocation == "northRoom")

        try await engine.execute("south")
        playerLocation = await engine.player.location.id
        #expect(playerLocation == "centerRoom")

        try await engine.execute("south")
        playerLocation = await engine.player.location.id
        #expect(playerLocation == "southRoom")

        try await engine.execute("north")
        try await engine.execute("east")
        playerLocation = await engine.player.location.id
        #expect(playerLocation == "eastRoom")

        try await engine.execute("west")
        try await engine.execute("west")
        playerLocation = await engine.player.location.id
        #expect(playerLocation == "westRoom")

        // Clear output
        await mockIO.expect(
            """
            > north
            --- North Room ---

            A room to the north.

            > south
            --- Center Room ---

            A room in the center.

            > south
            --- South Room ---

            A room to the south.

            > north
            --- Center Room ---

            > east
            --- East Room ---

            A room to the east.

            > west
            --- Center Room ---

            > west
            --- West Room ---

            A room to the west.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot go without specifying direction")
    func testCannotGoWithoutDirection() async throws {
        // Given
        let roundRoom = Location("roundRoom")
            .name("Round Room")
            .inherentlyLit

        let game = MinimalGame(
            player: Player(in: "roundRoom"),
            locations: roundRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("go")

        // Then
        await mockIO.expect(
            """
            > go
            The compass awaits your decision.
            """
        )
    }

    @Test("Cannot go in direction with no exit")
    func testCannotGoInDirectionWithNoExit() async throws {
        // Given
        let roundRoom = Location("roundRoom")
            .name("Round Room")
            .description("A room with no exits.")
            .inherentlyLit

        let game = MinimalGame(
            player: Player(in: "roundRoom"),
            locations: roundRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("north")

        // Then
        await mockIO.expect(
            """
            > north
            That way lies only disappointment.
            """
        )
    }

    @Test("Cannot go through permanently blocked exit")
    func testCannotGoThroughPermanentlyBlockedExit() async throws {
        // Given
        let roundRoom = Location("roundRoom")
            .name("Round Room")
            .inherentlyLit
            .north(blocked: "The way north is permanently blocked by rubble.")

        let game = MinimalGame(
            player: Player(in: "roundRoom"),
            locations: roundRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("north")

        // Then
        await mockIO.expect(
            """
            > north
            The way north is permanently blocked by rubble.
            """
        )
    }

    @Test("Cannot go through statically blocked exit")
    func testCannotGoThroughStaticallyBlockedExit() async throws {
        // Given
        let roundRoom = Location("roundRoom")
            .name("Round Room")
            .inherentlyLit
            .south(blocked: "A magical barrier blocks your way south.")

        let southRoom = Location("southRoom")
            .name("South Room")
            .inherentlyLit

        let game = MinimalGame(
            player: Player(in: "roundRoom"),
            locations: roundRoom, southRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("south")

        // Then
        await mockIO.expect(
            """
            > south
            A magical barrier blocks your way south.
            """
        )
    }

    @Test("Cannot go through closed door")
    func testCannotGoThroughClosedDoor() async throws {
        // Given
        let roundRoom = Location("roundRoom")
            .name("Round Room")
            .inherentlyLit
            .east("eastRoom", via: "door")

        let eastRoom = Location("eastRoom")
            .name("East Room")
            .inherentlyLit

        let door = Item("door")
            .name("wooden door")
            .description("A sturdy wooden door.")
            .isOpenable
            // Note: Not open
            .in("roundRoom")

        let game = MinimalGame(
            player: Player(in: "roundRoom"),
            locations: roundRoom, eastRoom,
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("east")

        // Then
        await mockIO.expect(
            """
            > east
            The wooden door is closed.
            """
        )
    }

    @Test("Cannot go through locked door")
    func testCannotGoThroughLockedDoor() async throws {
        // Given
        let roundRoom = Location("roundRoom")
            .name("Round Room")
            .inherentlyLit
            .west("westRoom", via: "door")

        let westRoom = Location("westRoom")
            .name("West Room")
            .inherentlyLit

        let door = Item("door")
            .name("iron door")
            .description("A heavy iron door.")
            .isOpenable
            .isLockable
            .isOpen
            .isLocked
            .in("roundRoom")

        let game = MinimalGame(
            player: Player(in: "roundRoom"),
            locations: roundRoom, westRoom,
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("west")

        // Then
        await mockIO.expect(
            """
            > west
            The iron door is locked.
            """
        )
    }

    @Test("Can go through open unlocked door")
    func testCanGoThroughOpenUnlockedDoor() async throws {
        // Given
        let roundRoom = Location("roundRoom")
            .name("Round Room")
            .inherentlyLit
            .north("northRoom", via: "door")

        let northRoom = Location("northRoom")
            .name("North Room")
            .description("A room beyond the door.")
            .inherentlyLit

        let door = Item("door")
            .name("oak door")
            .description("A polished oak door.")
            .isOpenable
            .isOpen
            .in("roundRoom")

        let game = MinimalGame(
            player: Player(in: "roundRoom"),
            locations: roundRoom, northRoom,
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("north")

        // Then
        await mockIO.expect(
            """
            > north
            --- North Room ---

            A room beyond the door.
            """
        )

        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "northRoom")
    }

    @Test("Can go through non-door exit object")
    func testCanGoThroughNonDoorExitObject() async throws {
        // Given
        let roundRoom = Location("roundRoom")
            .name("Round Room")
            .inherentlyLit
            .up("upperRoom", via: "stairs")

        let upperRoom = Location("upperRoom")
            .name("Upper Room")
            .description("A room upstairs.")
            .inherentlyLit

        let stairs = Item("stairs")
            .name("wooden stairs")
            .description("A set of wooden stairs leading up.")
            // Note: Not a door, so doesn't need to be open
            .in("roundRoom")

        let game = MinimalGame(
            player: Player(in: "roundRoom"),
            locations: roundRoom, upperRoom,
            items: stairs
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("up")

        // Then
        await mockIO.expect(
            """
            > up
            --- Upper Room ---

            A room upstairs.
            """
        )

        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "upperRoom")
    }

    // MARK: - Processing Testing

    @Test("Movement updates player location")
    func testMovementUpdatesPlayerLocation() async throws {
        // Given
        let startRoom = Location("startRoom")
            .name("Start Room")
            .inherentlyLit
            .north("endRoom")

        let endRoom = Location("endRoom")
            .name("End Room")
            .description("The destination room.")
            .inherentlyLit

        let game = MinimalGame(
            player: Player(in: "startRoom"),
            locations: startRoom, endRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify initial location
        var playerLocation = await engine.player.location.id
        #expect(playerLocation == "startRoom")

        // When
        try await engine.execute("north")

        // Then
        playerLocation = await engine.player.location.id
        #expect(playerLocation == "endRoom")

        await mockIO.expect(
            """
            > north
            --- End Room ---

            The destination room.
            """
        )
    }

    @Test("Movement works in dark rooms")
    func testMovementWorksInDarkRooms() async throws {
        // Given: Dark starting room
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            .south("litRoom")
        // Note: No .inherentlyLit property

        let litRoom = Location("litRoom")
            .name("Lit Room")
            .description("A well-lit room.")
            .inherentlyLit

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom, litRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("south")

        // Then
        await mockIO.expect(
            """
            > south
            --- Lit Room ---

            A well-lit room.
            """
        )

        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "litRoom")
    }

    @Test("Movement from lit to dark room shows darkness")
    func testMovementFromLitToDarkRoomShowsDarkness() async throws {
        // Given
        let litRoom = Location("litRoom")
            .name("Lit Room")
            .description("A well-lit room.")
            .inherentlyLit
            .north("darkRoom")

        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
        // Note: No .inherentlyLit property

        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: litRoom, darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("north")

        // Then
        await mockIO.expect(
            """
            > north
            Darkness rushes in like a living thing.

            This is the kind of dark that swallows shapes and edges,
            leaving only breath and heartbeat to prove you exist.
            """
        )

        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "darkRoom")
    }

    @Test("Movement with light source illuminates destination")
    func testMovementWithLightSourceIlluminatesDestination() async throws {
        // Given
        let litRoom = Location("litRoom")
            .name("Lit Room")
            .inherentlyLit
            .north("darkRoom")

        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A room that needs artificial light.")
        // Note: No .inherentlyLit property

        let torch = Item("torch")
            .name("burning torch")
            .description("A torch with a bright flame.")
            .isLightSource
            .isDevice
            .isTakable
            .in(.player)

        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: litRoom, darkRoom,
            items: torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set torch to be on (providing light)
        try await engine.apply(
            torch.proxy(engine).setFlag(.isOn)
        )

        // When
        try await engine.execute("north")

        // Then
        await mockIO.expect(
            """
            > north
            --- Dark Room ---

            A room that needs artificial light.
            """
        )

        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "darkRoom")
    }

    @Test("Roundtrip movement works")
    func testRoundtripMovementWorks() async throws {
        // Given
        let roomA = Location("roomA")
            .name("Room A")
            .description("The first room.")
            .inherentlyLit
            .east("roomB")

        let roomB = Location("roomB")
            .name("Room B")
            .description("The second room.")
            .inherentlyLit
            .west("roomA")

        let game = MinimalGame(
            player: Player(in: "roomA"),
            locations: roomA, roomB
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - go east then west
        try await engine.execute("east")
        var playerLocation = await engine.player.location.id
        #expect(playerLocation == "roomB")

        try await engine.execute("west")
        playerLocation = await engine.player.location.id
        #expect(playerLocation == "roomA")

        await mockIO.expect(
            """
            > east
            --- Room B ---

            The second room.

            > west
            --- Room A ---

            The first room.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = GoActionHandler()
        #expect(handler.synonyms.contains(.go))
        #expect(handler.synonyms.contains(.walk))
        #expect(handler.synonyms.contains(.run))
        #expect(handler.synonyms.contains(.proceed))
        #expect(handler.synonyms.contains(.stroll))
        #expect(handler.synonyms.contains(.hike))
        #expect(handler.synonyms.contains(.head))
        #expect(handler.synonyms.contains(.move))
        #expect(handler.synonyms.contains(.travel))
        #expect(handler.synonyms.count == 9)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = GoActionHandler()
        #expect(handler.requiresLight == false)
    }

    @Test("Handler syntax rules are correct")
    func testSyntaxRules() async throws {
        let handler = GoActionHandler()
        #expect(handler.syntax.count == 1)
        // The specific syntax pattern requires verb + direction
    }
}
