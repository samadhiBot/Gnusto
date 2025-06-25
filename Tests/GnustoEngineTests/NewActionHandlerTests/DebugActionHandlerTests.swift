import Testing
import CustomDump
@testable import GnustoEngine

@Suite("DebugActionHandler Tests")
struct DebugActionHandlerTests {

    // MARK: - teleport

    @Test("DEBUG TELEPORT moves player to a new location")
    func testDebugTeleport() async throws {
        // Given
        let room1 = Location(id: "room1", .name("Room 1"), .inherentlyLit)
        let room2 = Location(id: "room2", .name("Room 2"), .inherentlyLit)

        let game = MinimalGame(
            player: Player(in: "room1"),
            locations: room1, room2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug teleport room2")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > debug teleport room2
            Player teleported to room2.
            """)

        let playerLocation = try await engine.playerLocation()
        #expect(playerLocation == room2)
    }

    // MARK: - setflag

    @Test("DEBUG SETFLAG sets a flag on an item")
    func testDebugSetFlag() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let box = Item(id: "box", .name("box"), .in(.location("testRoom")))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug setflag box isOpen")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > debug setflag box isOpen
            Flag 'isOpen' set on item 'box'.
            """)

        let itemState = try await engine.item("box")
        #expect(itemState.hasFlag(.isOpen))
    }

    // MARK: - clearflag

    @Test("DEBUG CLEARFLAG clears a flag from an item")
    func testDebugClearFlag() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let box = Item(id: "box", .name("box"), .isOpen, .in(.location("testRoom")))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug clearflag box isOpen")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > debug clearflag box isOpen
            Flag 'isOpen' cleared from item 'box'.
            """)

        let itemState = try await engine.item("box")
        #expect(!itemState.hasFlag(.isOpen))
    }

    // MARK: - relocate

    @Test("DEBUG RELOCATE moves an item to a new location")
    func testDebugRelocate() async throws {
        // Given
        let room1 = Location(id: "room1", .name("Room 1"), .inherentlyLit)
        let room2 = Location(id: "room2", .name("Room 2"), .inherentlyLit)
        let ball = Item(id: "ball", .name("ball"), .in(.location("room1")))

        let game = MinimalGame(
            player: Player(in: "room1"),
            locations: room1, room2,
            items: ball
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug relocate ball room2")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > debug relocate ball room2
            Item 'ball' relocated to 'room2'.
            """)

        let itemState = try await engine.item("ball")
        #expect(itemState.parent == .location("room2"))
    }

    @Test("DEBUG RELOCATE moves an item to the player")
    func testDebugRelocateToPlayer() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let key = Item(id: "key", .name("key"), .in(.location("testRoom")))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: key
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug relocate key player")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > debug relocate key player
            Item 'key' relocated to 'player'.
            """)

        let itemState = try await engine.item("key")
        #expect(itemState.parent == .player)
    }

    // MARK: - showstate

    @Test("DEBUG SHOWSTATE shows the state of an item")
    func testDebugShowState() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let box = Item(id: "box", .name("box"), .isContainer, .isOpen, .in(.location("testRoom")))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug showstate box")

        // Then
        let output = await mockIO.flush()
        let expected = """
        > debug showstate box
        - parent: location("testRoom")
        - flags:
          - isContainer
          - isOpen

        """
        expectNoDifference(output.replacingOccurrences(of: "\n-", with: "\n -"), expected)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = DebugActionHandler()
        #expect(handler.verbs.contains(.debug))
        #expect(handler.verbs.count == 1)
    }
}
