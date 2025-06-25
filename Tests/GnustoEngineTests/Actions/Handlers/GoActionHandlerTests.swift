import CustomDump
import Testing

@testable import GnustoEngine

@Suite("GoActionHandler Tests")
struct GoActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("GO DIRECTION syntax works")
    func testGoDirectionSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit,
            .exits([.north: .to("northRoom")])
        )

        let northRoom = Location(
            id: "northRoom",
            .name("North Room"),
            .description("A room to the north."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, northRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("go north")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go north
            — North Room —

            A room to the north.
            """)

        let playerLocation = await engine.playerLocationID
        #expect(playerLocation == "northRoom")
    }

    @Test("WALK DIRECTION syntax works")
    func testWalkDirectionSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit,
            .exits([.south: .to("southRoom")])
        )

        let southRoom = Location(
            id: "southRoom",
            .name("South Room"),
            .description("A room to the south."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, southRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("walk south")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > walk south
            — South Room —

            A room to the south.
            """)

        let playerLocation = await engine.playerLocationID
        #expect(playerLocation == "southRoom")
    }

    @Test("RUN DIRECTION syntax works")
    func testRunDirectionSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit,
            .exits([.east: .to("eastRoom")])
        )

        let eastRoom = Location(
            id: "eastRoom",
            .name("East Room"),
            .description("A room to the east."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, eastRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("run east")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > run east
            — East Room —

            A room to the east.
            """)

        let playerLocation = await engine.playerLocationID
        #expect(playerLocation == "eastRoom")
    }

    // MARK: - Directional Commands

    @Test("NORTH directional command works")
    func testNorthDirectionalCommand() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit,
            .exits([.north: .to("northRoom")])
        )

        let northRoom = Location(
            id: "northRoom",
            .name("North Room"),
            .description("A room to the north."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, northRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("north")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > north
            — North Room —

            A room to the north.
            """)

        let playerLocation = await engine.playerLocationID
        #expect(playerLocation == "northRoom")
    }

    @Test("N directional abbreviation works")
    func testNDirectionalAbbreviation() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit,
            .exits([.north: .to("northRoom")])
        )

        let northRoom = Location(
            id: "northRoom",
            .name("North Room"),
            .description("A room to the north."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, northRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("n")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > n
            — North Room —

            A room to the north.
            """)

        let playerLocation = await engine.playerLocationID
        #expect(playerLocation == "northRoom")
    }

    @Test("All cardinal directions work")
    func testAllCardinalDirections() async throws {
        // Given
        let centerRoom = Location(
            id: "centerRoom",
            .name("Center Room"),
            .description("A room in the center."),
            .inherentlyLit,
            .exits([
                .north: .to("northRoom"),
                .south: .to("southRoom"),
                .east: .to("eastRoom"),
                .west: .to("westRoom"),
            ]),
        )

        let northRoom = Location(
            id: "northRoom",
            .name("North Room"),
            .description("A room to the north."),
            .inherentlyLit,
            .exits([.south: .to("centerRoom")])
        )

        let southRoom = Location(
            id: "southRoom",
            .name("South Room"),
            .description("A room to the south."),
            .inherentlyLit,
            .exits([.north: .to("centerRoom")])
        )

        let eastRoom = Location(
            id: "eastRoom",
            .name("East Room"),
            .description("A room to the east."),
            .inherentlyLit,
            .exits([.west: .to("centerRoom")])
        )

        let westRoom = Location(
            id: "westRoom",
            .name("West Room"),
            .description("A room to the west."),
            .inherentlyLit,
            .exits([.east: .to("centerRoom")])
        )

        let game = MinimalGame(
            player: Player(in: "centerRoom"),
            locations: centerRoom, northRoom, southRoom, eastRoom, westRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Test each direction
        try await engine.execute("north")
        var playerLocation = await engine.playerLocationID
        #expect(playerLocation == "northRoom")

        try await engine.execute("south")
        playerLocation = await engine.playerLocationID
        #expect(playerLocation == "centerRoom")

        try await engine.execute("south")
        playerLocation = await engine.playerLocationID
        #expect(playerLocation == "southRoom")

        try await engine.execute("north")
        try await engine.execute("east")
        playerLocation = await engine.playerLocationID
        #expect(playerLocation == "eastRoom")

        try await engine.execute("west")
        try await engine.execute("west")
        playerLocation = await engine.playerLocationID
        #expect(playerLocation == "westRoom")

        // Clear output
        let output = await mockIO.flush()
        expectNoDifference(output, "")
    }

    // MARK: - Validation Testing

    @Test("Cannot go without specifying direction")
    func testCannotGoWithoutDirection() async throws {
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
        try await engine.execute("go")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go
            Go where?
            """)
    }

    @Test("Cannot go in direction with no exit")
    func testCannotGoInDirectionWithNoExit() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room with no exits."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("north")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > north
            You can’t go that way.
            """)
    }

    @Test("Cannot go through permanently blocked exit")
    func testCannotGoThroughPermanentlyBlockedExit() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit,
            .exits([
                .north: Exit(
                    destination: nil,
                    blockedMessage: "The way north is permanently blocked by rubble.")
            ])
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("north")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > north
            The way north is permanently blocked by rubble.
            """)
    }

    @Test("Cannot go through statically blocked exit")
    func testCannotGoThroughStaticallyBlockedExit() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit,
            .exits([
                .south: Exit(
                    destination: "southRoom",
                    blockedMessage: "A magical barrier blocks your way south.")
            ])
        )

        let southRoom = Location(
            id: "southRoom",
            .name("South Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, southRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("south")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > south
            A magical barrier blocks your way south.
            """)
    }

    @Test("Cannot go through closed door")
    func testCannotGoThroughClosedDoor() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit,
            .exits([.east: Exit(destination: "eastRoom", doorID: "door")])
        )

        let eastRoom = Location(
            id: "eastRoom",
            .name("East Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("wooden door"),
            .description("A sturdy wooden door."),
            .isDoor,
            // Note: Not open
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, eastRoom,
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("east")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > east
            The wooden door is closed.
            """)
    }

    @Test("Cannot go through locked door")
    func testCannotGoThroughLockedDoor() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit,
            .exits([.west: Exit(destination: "westRoom", doorID: "door")])
        )

        let westRoom = Location(
            id: "westRoom",
            .name("West Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("iron door"),
            .description("A heavy iron door."),
            .isDoor,
            .isOpen,
            .isLocked,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, westRoom,
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("west")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > west
            The iron door is locked.
            """)
    }

    @Test("Can go through open unlocked door")
    func testCanGoThroughOpenUnlockedDoor() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit,
            .exits([.north: Exit(destination: "northRoom", doorID: "door")])
        )

        let northRoom = Location(
            id: "northRoom",
            .name("North Room"),
            .description("A room beyond the door."),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("oak door"),
            .description("A polished oak door."),
            .isDoor,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, northRoom,
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("north")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > north
            — North Room —

            A room beyond the door.
            """)

        let playerLocation = await engine.playerLocationID
        #expect(playerLocation == "northRoom")
    }

    @Test("Can go through non-door exit object")
    func testCanGoThroughNonDoorExitObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit,
            .exits([.up: Exit(destination: "upperRoom", doorID: "stairs")])
        )

        let upperRoom = Location(
            id: "upperRoom",
            .name("Upper Room"),
            .description("A room upstairs."),
            .inherentlyLit
        )

        let stairs = Item(
            id: "stairs",
            .name("wooden stairs"),
            .description("A set of wooden stairs leading up."),
            // Note: Not a door, so doesn’t need to be open
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, upperRoom,
            items: stairs
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("up")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > up
            — Upper Room —

            A room upstairs.
            """)

        let playerLocation = await engine.playerLocationID
        #expect(playerLocation == "upperRoom")
    }

    // MARK: - Processing Testing

    @Test("Movement updates player location")
    func testMovementUpdatesPlayerLocation() async throws {
        // Given
        let startRoom = Location(
            id: "startRoom",
            .name("Start Room"),
            .inherentlyLit,
            .exits([.north: Exit(destination: "endRoom")])
        )

        let endRoom = Location(
            id: "endRoom",
            .name("End Room"),
            .description("The destination room."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "startRoom"),
            locations: startRoom, endRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify initial location
        var playerLocation = await engine.playerLocationID
        #expect(playerLocation == "startRoom")

        // When
        try await engine.execute("north")

        // Then
        playerLocation = await engine.playerLocationID
        #expect(playerLocation == "endRoom")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > north
            — End Room —

            The destination room.
            """)
    }

    @Test("Movement works in dark rooms")
    func testMovementWorksInDarkRooms() async throws {
        // Given: Dark starting room
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room."),
            .exits([.south: Exit(destination: "litRoom")])
            // Note: No .inherentlyLit property
        )

        let litRoom = Location(
            id: "litRoom",
            .name("Lit Room"),
            .description("A well-lit room."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom, litRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("south")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > south
            — Lit Room —

            A well-lit room.
            """)

        let playerLocation = await engine.playerLocationID
        #expect(playerLocation == "litRoom")
    }

    @Test("Movement from lit to dark room shows darkness")
    func testMovementFromLitToDarkRoomShowsDarkness() async throws {
        // Given
        let litRoom = Location(
            id: "litRoom",
            .name("Lit Room"),
            .description("A well-lit room."),
            .inherentlyLit,
            .exits([.north: Exit(destination: "darkRoom")])
        )

        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: litRoom, darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("north")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > north            It is pitch black. You can’t see a thing.
            """)

        let playerLocation = await engine.playerLocationID
        #expect(playerLocation == "darkRoom")
    }

    @Test("Movement with light source illuminates destination")
    func testMovementWithLightSourceIlluminatesDestination() async throws {
        // Given
        let litRoom = Location(
            id: "litRoom",
            .name("Lit Room"),
            .inherentlyLit,
            .exits([.north: Exit(destination: "darkRoom")])
        )

        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A room that needs artificial light.")
            // Note: No .inherentlyLit property
        )

        let torch = Item(
            id: "torch",
            .name("burning torch"),
            .description("A torch with a bright flame."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: litRoom, darkRoom,
            items: torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set torch to be on (providing light)
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("torch"))
        )

        // When
        try await engine.execute("north")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > north
            — Dark Room —

            A room that needs artificial light.
            """)

        let playerLocation = await engine.playerLocationID
        #expect(playerLocation == "darkRoom")
    }

    @Test("Roundtrip movement works")
    func testRoundtripMovementWorks() async throws {
        // Given
        let roomA = Location(
            id: "roomA",
            .name("Room A"),
            .description("The first room."),
            .inherentlyLit,
            .exits([.east: Exit(destination: "roomB")])
        )

        let roomB = Location(
            id: "roomB",
            .name("Room B"),
            .description("The second room."),
            .inherentlyLit,
            .exits([.west: Exit(destination: "roomA")])
        )

        let game = MinimalGame(
            player: Player(in: "roomA"),
            locations: roomA, roomB
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - go east then west
        try await engine.execute("east")
        var playerLocation = await engine.playerLocationID
        #expect(playerLocation == "roomB")

        try await engine.execute("west")
        playerLocation = await engine.playerLocationID
        #expect(playerLocation == "roomA")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > east
            — Room B —

            The second room.
            > west
            — Room A —

            The first room.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = GoActionHandler()
        // GoActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = GoActionHandler()
        #expect(handler.verbs.contains(.go))
        #expect(handler.verbs.contains(.walk))
        #expect(handler.verbs.contains(.run))
        #expect(handler.verbs.contains(.proceed))
        #expect(handler.verbs.contains(.stroll))
        #expect(handler.verbs.contains(.hike))
        #expect(handler.verbs.contains(.head))
        #expect(handler.verbs.contains(.move))
        #expect(handler.verbs.contains(.travel))
        #expect(handler.verbs.count == 9)
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
