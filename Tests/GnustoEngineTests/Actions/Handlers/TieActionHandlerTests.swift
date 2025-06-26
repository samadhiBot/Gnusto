import Testing
import CustomDump
@testable import GnustoEngine

@Suite("TieActionHandler Tests")
struct TieActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("TIE DIRECTOBJECT syntax works")
    func testTieDirectObjectSyntax() async throws {
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
            .description("A thick climbing rope."),
            .isRope,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tie rope
            You tie a knot in the thick rope.
            """)

        let finalState = try await engine.item("rope")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("TIE DIRECTOBJECT TO INDIRECTOBJECT syntax works")
    func testTieToSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rope = Item(
            id: "rope",
            .name("long rope"),
            .description("A long rope."),
            .isRope,
            .isTakable,
            .in(.location("testRoom"))
        )

        let post = Item(
            id: "post",
            .name("wooden post"),
            .description("A sturdy wooden post."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rope, post
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope to post")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tie rope to post
            You need something to tie with.
            """)

        let finalRope = try await engine.item("rope")
        let finalPost = try await engine.item("post")
        #expect(finalRope.hasFlag(.isTouched) == true)
        #expect(finalPost.hasFlag(.isTouched) == true)
    }

    @Test("TIE DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testTieWithSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("cardboard box"),
            .description("A simple cardboard box."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let string = Item(
            id: "string",
            .name("ball of string"),
            .description("A ball of string."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, string
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie box with string")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tie box with string
            You need something to tie with.
            """)
    }

    @Test("FASTEN syntax works")
    func testFastenSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let belt = Item(
            id: "belt",
            .name("leather belt"),
            .description("A leather belt."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: belt
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fasten belt")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > fasten belt
            You need something to tie the leather belt with.
            """)
    }

    @Test("BIND syntax works")
    func testBindSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let package = Item(
            id: "package",
            .name("small package"),
            .description("A small package."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: package
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("bind package")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > bind package
            You need something to tie the small package with.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot tie without specifying what")
    func testCannotTieWithoutWhat() async throws {
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
        try await engine.execute("tie")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tie
            Tie what?
            """)
    }

    @Test("Cannot tie item not in scope")
    func testCannotTieItemNotInScope() async throws {
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

        let remoteRope = Item(
            id: "remoteRope",
            .name("remote rope"),
            .description("A rope in another room."),
            .isRope,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteRope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tie rope
            You can’t see any such thing.
            """)
    }

    @Test("Cannot tie to item not in scope")
    func testCannotTieToItemNotInScope() async throws {
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

        let rope = Item(
            id: "rope",
            .name("long rope"),
            .description("A long rope."),
            .isRope,
            .in(.location("testRoom"))
        )

        let remotePost = Item(
            id: "remotePost",
            .name("remote post"),
            .description("A post in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: rope, remotePost
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope to post")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tie rope to post
            You can’t see any such thing.
            """)
    }

    @Test("Requires light to tie")
    func testRequiresLight() async throws {
        // Given: Dark room with rope
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let rope = Item(
            id: "rope",
            .name("thick rope"),
            .description("A thick rope."),
            .isRope,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tie rope
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Tie rope creates knot")
    func testTieRopeCreatesKnot() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rope = Item(
            id: "rope",
            .name("climbing rope"),
            .description("A sturdy climbing rope."),
            .isRope,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tie rope
            You tie a knot in the climbing rope.
            """)

        let finalState = try await engine.item("rope")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Tie non-rope item needs something to tie with")
    func testTieNonRopeNeedsTool() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tie box
            You need something to tie the wooden box with.
            """)

        let finalState = try await engine.item("box")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Tie character needs something to tie with")
    func testTieCharacterNeedsTool() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let prisoner = Item(
            id: "prisoner",
            .name("captured prisoner"),
            .description("A captured prisoner."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: prisoner
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie prisoner")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tie prisoner
            You need something to tie the captured prisoner with.
            """)
    }

    @Test("Cannot tie item to itself")
    func testCannotTieToSelf() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rope = Item(
            id: "rope",
            .name("long rope"),
            .description("A long rope."),
            .isRope,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope to rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tie rope to rope
            You can’t tie long rope to itself.
            """)
    }

    @Test("Cannot tie living beings together")
    func testCannotTieLivingBeings() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let castleGuard = Item(
            id: "castleGuard",
            .name("castle guard"),
            .description("A castle guard."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let prisoner = Item(
            id: "prisoner",
            .name("captured prisoner"),
            .description("A captured prisoner."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: castleGuard, prisoner
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie guard to prisoner")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tie guard to prisoner
            You can’t tie living beings together.
            """)
    }

    @Test("Tie two objects together needs tool")
    func testTieTwoObjectsNeedsTool() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let chair = Item(
            id: "chair",
            .name("wooden chair"),
            .description("A wooden chair."),
            .in(.location("testRoom"))
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A wooden table."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: chair, table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie chair to table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tie chair to table
            You need something to tie with.
            """)

        let finalChair = try await engine.item("chair")
        let finalTable = try await engine.item("table")
        #expect(finalChair.hasFlag(.isTouched) == true)
        #expect(finalTable.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = TieActionHandler()
        // TieActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = TieActionHandler()
        #expect(handler.verbs.contains(.tie))
        #expect(handler.verbs.contains(.fasten))
        #expect(handler.verbs.contains(.bind))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = TieActionHandler()
        #expect(handler.requiresLight == true)
    }
}
