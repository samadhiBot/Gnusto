import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ThrowActionHandler Tests")
struct ThrowActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("THROW DIRECTOBJECT syntax works")
    func testThrowDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let ball = Item(
            id: "ball",
            .name("rubber ball"),
            .description("A bouncy rubber ball."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: ball
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw ball")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw ball
            You throw the rubber ball.
            """)

        let finalState = try await engine.item("ball")
        #expect(finalState.hasFlag(.isTouched) == true)
        #expect(finalState.parent == .location("testRoom"))
    }

    @Test("THROW DIRECTOBJECT AT INDIRECTOBJECT syntax works")
    func testThrowAtIndirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("small rock"),
            .description("A small throwing rock."),
            .isTakable,
            .in(.player)
        )

        let target = Item(
            id: "target",
            .name("wooden target"),
            .description("A wooden archery target."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock, target
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw rock at target")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw rock at target
            You throw the small rock at the wooden target.
            """)

        let finalRock = try await engine.item("rock")
        let finalTarget = try await engine.item("target")
        #expect(finalRock.hasFlag(.isTouched) == true)
        #expect(finalRock.parent == .location("testRoom"))
        #expect(finalTarget.hasFlag(.isTouched) == true)
    }

    @Test("THROW DIRECTOBJECT TO INDIRECTOBJECT syntax works")
    func testThrowToIndirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A shiny brass key."),
            .isTakable,
            .in(.player)
        )

        let castleGuard = Item(
            id: "guard",
            .name("castle guard"),
            .description("A stern castle guard."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: key, castleGuard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw key to guard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw key to guard
            The castle guard deftly catches the brass key.
            """)

        let finalKey = try await engine.item("key")
        let finalGuard = try await engine.item("guard")
        #expect(finalKey.hasFlag(.isTouched) == true)
        #expect(finalKey.parent == .location("testRoom"))
        #expect(finalGuard.hasFlag(.isTouched) == true)
    }

    @Test("HURL syntax works")
    func testHurlSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let spear = Item(
            id: "spear",
            .name("wooden spear"),
            .description("A sharp wooden spear."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: spear
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("hurl spear")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > hurl spear
            You throw the wooden spear.
            """)
    }

    @Test("TOSS syntax works")
    func testTossSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("toss coin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > toss coin
            You throw the gold coin.
            """)
    }

    @Test("CHUCK syntax works")
    func testChuckSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let stone = Item(
            id: "stone",
            .name("heavy stone"),
            .description("A heavy throwing stone."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: stone
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("chuck stone")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > chuck stone
            You throw the heavy stone.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot throw without specifying what")
    func testCannotThrowWithoutTarget() async throws {
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
        try await engine.execute("throw")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw
            Throw what?
            """)
    }

    @Test("Cannot throw item not held")
    func testCannotThrowItemNotHeld() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let ball = Item(
            id: "ball",
            .name("rubber ball"),
            .description("A bouncy rubber ball."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: ball
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw ball")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw ball
            You aren't holding the rubber ball.
            """)
    }

    @Test("Cannot throw non-existent item")
    func testCannotThrowNonExistentItem() async throws {
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
        try await engine.execute("throw nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw nonexistent
            You can't see any such thing.
            """)
    }

    @Test("Cannot throw at non-existent target")
    func testCannotThrowAtNonExistentTarget() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let ball = Item(
            id: "ball",
            .name("rubber ball"),
            .description("A bouncy rubber ball."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: ball
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw ball at nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw ball at nonexistent
            You can't see any such thing.
            """)
    }

    @Test("Cannot throw at target not in reach")
    func testCannotThrowAtTargetNotInReach() async throws {
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

        let ball = Item(
            id: "ball",
            .name("rubber ball"),
            .description("A bouncy rubber ball."),
            .isTakable,
            .in(.player)
        )

        let distantTarget = Item(
            id: "distantTarget",
            .name("distant target"),
            .description("A target in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: ball, distantTarget
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw ball at target")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw ball at target
            You can't see any such thing.
            """)
    }

    @Test("Cannot throw non-item")
    func testCannotThrowNonItem() async throws {
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
        try await engine.execute("throw me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw me
            You can't throw yourself.
            """)
    }

    @Test("Cannot throw at non-item")
    func testCannotThrowAtNonItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let ball = Item(
            id: "ball",
            .name("rubber ball"),
            .description("A bouncy rubber ball."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: ball
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw ball at me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw ball at me
            You can't throw at that.
            """)
    }

    @Test("Requires light to throw")
    func testRequiresLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let ball = Item(
            id: "ball",
            .name("rubber ball"),
            .description("A bouncy rubber ball."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: ball
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw ball")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw ball
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Throw item generally")
    func testThrowItemGenerally() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .description("A fragile glass bottle."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bottle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw bottle
            You throw the glass bottle.
            """)

        // Verify state changes
        let finalState = try await engine.item("bottle")
        #expect(finalState.hasFlag(.isTouched) == true)
        #expect(finalState.parent == .location("testRoom"))
    }

    @Test("Throw item at character")
    func testThrowItemAtCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A juicy red apple."),
            .isTakable,
            .in(.player)
        )

        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: apple, wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw apple at wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw apple at wizard
            The old wizard deftly catches the red apple.
            """)

        // Verify state changes
        let finalApple = try await engine.item("apple")
        let finalWizard = try await engine.item("wizard")
        #expect(finalApple.hasFlag(.isTouched) == true)
        #expect(finalApple.parent == .location("testRoom"))
        #expect(finalWizard.hasFlag(.isTouched) == true)
    }

    @Test("Throw item at object")
    func testThrowItemAtObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let dart = Item(
            id: "dart",
            .name("sharp dart"),
            .description("A sharp throwing dart."),
            .isTakable,
            .in(.player)
        )

        let board = Item(
            id: "board",
            .name("dartboard"),
            .description("A standard dartboard."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: dart, board
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw dart at board")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw dart at board
            You throw the sharp dart at the dartboard.
            """)

        // Verify state changes
        let finalDart = try await engine.item("dart")
        let finalBoard = try await engine.item("board")
        #expect(finalDart.hasFlag(.isTouched) == true)
        #expect(finalDart.parent == .location("testRoom"))
        #expect(finalBoard.hasFlag(.isTouched) == true)
    }

    @Test("Throw multiple items")
    func testThrowMultipleItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let ball1 = Item(
            id: "ball1",
            .name("red ball"),
            .description("A red rubber ball."),
            .isTakable,
            .in(.player)
        )

        let ball2 = Item(
            id: "ball2",
            .name("blue ball"),
            .description("A blue rubber ball."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: ball1, ball2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - throw first ball
        try await engine.execute("throw red ball")

        // Then - verify first ball was thrown
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > throw red ball
            You throw the red ball.
            """)

        let finalBall1 = try await engine.item("ball1")
        #expect(finalBall1.parent == .location("testRoom"))

        // When - throw second ball
        try await engine.execute("throw blue ball")

        // Then - verify second ball was thrown
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > throw blue ball
            You throw the blue ball.
            """)

        let finalBall2 = try await engine.item("ball2")
        #expect(finalBall2.parent == .location("testRoom"))
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = ThrowActionHandler()
        // ThrowActionHandler doesn't specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = ThrowActionHandler()
        #expect(handler.verbs.contains(.throw))
        #expect(handler.verbs.contains(.hurl))
        #expect(handler.verbs.contains(.toss))
        #expect(handler.verbs.contains(.chuck))
        #expect(handler.verbs.count == 4)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ThrowActionHandler()
        #expect(handler.requiresLight == true)
    }
}
