import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct ShakeActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax rule accepts 'shake <item>'")
    func testSyntaxRule() async throws {
        let handler = ShakeActionHandler()
        let syntax = try handler.syntax.primary.parse("shake box")
        #expect(syntax.verb == .shake)
        #expect(syntax.directObject == .item(id: "box"))
    }

    @Test("Syntax rule accepts synonym 'rattle <item>'")
    func testRattleSyntaxRule() async throws {
        let handler = ShakeActionHandler()
        let syntax = try handler.syntax.primary.parse("rattle box")
        #expect(syntax.verb == .shake)
        #expect(syntax.directObject == .item(id: "box"))
    }

    // MARK: - Validation Testing

    @Test("Validation fails without a direct object")
    func testValidationFailsWithoutDirectObject() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        try await engine.execute("shake")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake
            Shake what?
            """)
    }

    @Test("Validation fails for unreachable items")
    func testValidationFailsForUnreachableItem() async throws {
        let box = Item(id: "box", .name("a box"), .in(.location("anotherRoom")))
        let game = MinimalGame(items: box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("shake box")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake box
            You can’t see any box here.
            """)
    }

    @Test("Validation fails in the dark")
    func testValidationFailsInDark() async throws {
        let box = Item(id: "box", .name("a box"), .in(.location("testRoom")))
        let testRoom = Location(id: "testRoom", .name("Test Room"), .items(box))
        let game = MinimalGame(player: Player(in: "testRoom"), locations: testRoom)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("shake box")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake box
            It’s too dark to see.
            """)
    }

    // MARK: - Processing Testing

    @Test("Shaking a character")
    func testShakingCharacter() async throws {
        let troll = Item(id: "troll", .name("a troll"), .isCharacter, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: troll)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("shake troll")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake troll
            Shaking the troll is not a socially acceptable way to get its attention.
            """)
        let touched = try await engine.item("troll").hasFlag(.isTouched)
        #expect(touched)
    }

    @Test("Shaking a liquid container")
    func testShakingLiquidContainer() async throws {
        let bottle = Item(
            id: "bottle", .name("a bottle"), .isLiquidContainer, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: bottle)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("shake bottle")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake bottle
            You shake the bottle and hear liquid sloshing inside.
            """)
    }

    @Test("Shaking an open container")
    func testShakingOpenContainer() async throws {
        let box = Item(id: "box", .name("a box"), .isContainer, .isOpen, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("shake box")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake box
            You shake the box, but nothing happens.
            """)
    }

    @Test("Shaking a closed container")
    func testShakingClosedContainer() async throws {
        let box = Item(id: "box", .name("a box"), .isContainer, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("shake box")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake box
            You shake the box and hear something rattling inside.
            """)
    }

    @Test("Shaking a takable item")
    func testShakingTakableItem() async throws {
        let rock = Item(id: "rock", .name("a rock"), .isTakable, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("shake rock")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake rock
            You shake the rock vigorously, but nothing happens.
            """)
    }

    @Test("Shaking a fixed item")
    func testShakingFixedItem() async throws {
        let wall = Item(id: "wall", .name("a wall"), .in(.location("testRoom")))
        let game = MinimalGame.lit(items: wall)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("shake wall")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake wall
            You can’t shake the wall - it’s firmly in place.
            """)
    }

    // MARK: - ActionID Testing

}
