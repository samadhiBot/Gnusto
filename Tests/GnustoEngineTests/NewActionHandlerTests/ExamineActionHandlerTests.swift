import Testing
import CustomDump
@testable import GnustoEngine

@Suite("ExamineActionHandler Tests")
struct ExamineActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("EXAMINE syntax works")
    func testExamineSyntax() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let pebble = Item(
            id: "pebble",
            .name("small pebble"),
            .description("A smooth, grey pebble."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: pebble
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine pebble")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > examine pebble
            A smooth, grey pebble.
            """)

        let finalState = try await engine.item("pebble")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("X as a synonym for EXAMINE works")
    func testXSyntax() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let pebble = Item(
            id: "pebble",
            .name("small pebble"),
            .description("A smooth, grey pebble."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: pebble
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("x pebble")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > x pebble
            A smooth, grey pebble.
            """)
    }

    @Test("INSPECT as a synonym for EXAMINE works")
    func testInspectSyntax() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let pebble = Item(
            id: "pebble",
            .name("small pebble"),
            .description("A smooth, grey pebble."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: pebble
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inspect pebble")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > inspect pebble
            A smooth, grey pebble.
            """)
    }

    @Test("LOOK AT as a syntax for EXAMINE works")
    func testLookAtSyntax() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let pebble = Item(
            id: "pebble",
            .name("small pebble"),
            .description("A smooth, grey pebble."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: pebble
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look at pebble")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > look at pebble
            A smooth, grey pebble.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot examine without specifying target")
    func testCannotExamineWithoutTarget() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let game = MinimalGame(player: Player(in: "testRoom"), locations: testRoom)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > examine
            What do you want to examine?
            """)
    }

    @Test("Cannot examine item not in scope")
    func testCannotExamineItemNotInScope() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let anotherRoom = Location(id: "anotherRoom", .name("Another Room"), .inherentlyLit)
        let remotePebble = Item(id: "remotePebble", .name("remote pebble"), .in(.location("anotherRoom")))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remotePebble
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine pebble")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > examine pebble
            You can't see any such thing.
            """)
    }

    @Test("Requires light to examine items")
    func testRequiresLight() async throws {
        // Given
        let darkRoom = Location(id: "darkRoom", .name("Dark Room"))
        let pebble = Item(id: "pebble", .name("pebble"), .in(.location("darkRoom")))

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: pebble
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine pebble")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > examine pebble
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Examine item with no description gives default message")
    func testExamineItemWithNoDescription() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let rock = Item(
            id: "rock",
            .name("a rock"),
            // No .description
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > examine rock
            You see nothing special about a rock.
            """)
    }

    @Test("Examine self gives a special message")
    func testExamineSelf() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let game = MinimalGame(player: Player(in: "testRoom"), locations: testRoom)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine self")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > examine self
            You are your usual charming self.
            """)
    }

    @Test("Examine readable item shows its text")
    func testExamineReadableItem() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let note = Item(
            id: "note",
            .name("folded note"),
            .description("A hastily folded note."),
            .isReadable,
            .readText("The password is 'xyzzy'."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: note
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine note")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > examine note
            The password is 'xyzzy'.
            """)
    }

    @Test("Examine container shows its state and contents")
    func testExamineContainer() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A plain wooden box."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let key = Item(
            id: "key",
            .name("small key"),
            .in(.item("box"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, key
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > examine box
            A plain wooden box. The wooden box contains a small key.
            """)
    }

    @Test("Examine closed container shows it's closed")
    func testExamineClosedContainer() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A plain wooden box."),
            .isContainer,
            // Not .isOpen
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > examine box
            A plain wooden box. The wooden box is closed.
            """)
    }

    @Test("Examine surface shows items on it")
    func testExamineSurface() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)

        let table = Item(
            id: "table",
            .name("sturdy table"),
            .description("A sturdy wooden table."),
            .isSurface,
            .in(.location("testRoom"))
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .in(.item("table"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: table, lamp
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine table")

        // Then
        let output = await mockIO.flush()
        // The regex helps match "On the sturdy table is a brass lamp."
        let expectedPattern = #"> examine table\s+A sturdy wooden table\.\s+On the sturdy table is a brass lamp\."#
        #expect(output.matches(of: Regex(expectedPattern)).count == 1)
    }

    @Test("EXAMINE IN delegates to LookInsideActionHandler")
    func testExamineInDelegates() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let box = Item(
            id: "box",
            .name("wooden box"),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )
        let key = Item(id: "key", .name("tiny key"), .in(.item("box")))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, key
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine in box")

        // Then
        let output = await mockIO.flush()
        // This is the output from LookInsideActionHandler
        expectNoDifference(output, """
            > examine in box
            In the wooden box you see a tiny key.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = ExamineActionHandler()
        #expect(handler.verbs.contains(.examine))
        #expect(handler.verbs.contains("x"))
        #expect(handler.verbs.contains(.inspect))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ExamineActionHandler()
        #expect(handler.requiresLight == true)
    }
}
