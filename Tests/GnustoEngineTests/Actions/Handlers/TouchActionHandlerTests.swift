import CustomDump
import Testing

@testable import GnustoEngine

@Suite("TouchActionHandler Tests")
struct TouchActionHandlerTests {
    let handler = TouchActionHandler()

    @Test("Touch item successfully in location")
    func testTouchItemSuccessfullyInLocation() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            .name("smooth rock"),
            .in(.player)
        )  // Not necessarily takable
        let game = MinimalGame(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("touch rock")

        // Assert
        let finalItemState = try await engine.item("rock")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Item should gain .touched property")
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > touch rock
            You feel nothing special.
            """)
    }

    @Test("Touch item successfully held")
    func testTouchItemSuccessfullyHeld() async throws {
        // Arrange
        let key = Item(
            id: "key",
            .name("brass key"),
            .in(.player),
            .isTakable
        )
        let game = MinimalGame(items: key)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("touch key")

        // Assert
        let finalItemState = try await engine.item("key")
        #expect(finalItemState.hasFlag(.isTouched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > touch key
            You feel nothing special.
            """)
    }

    @Test("Touch fails with no direct object")
    func testTouchFailsWithNoObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act & Assert
        try await engine.execute("touch")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > touch
            Touch what?
            """)
    }

    @Test("Touch fails item not accessible")
    func testTouchFailsItemNotAccessible() async throws {
        let figurine = Item(
            id: "figurine",
            .name("jade figurine"),
            .in(.nowhere)
        )
        let game = MinimalGame(items: figurine)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act & Assert
        try await engine.execute("touch figurine")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > touch figurine
            You can’t see any jade figurine here.
            """)
    }

    @Test("Touch item successfully in open container")
    func testTouchItemInOpenContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpen
        )
        let gem = Item(
            id: "gem",
            .name("ruby gem"),
            .in(.item("box"))
        )
        let game = MinimalGame(items: box, gem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("touch gem")

        // Assert
        let finalItemState = try await engine.item("gem")
        #expect(finalItemState.hasFlag(.isTouched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > touch gem
            You feel nothing special.
            """)
    }

    @Test("Touch item successfully on surface")
    func testTouchItemOnSurface() async throws {
        // Arrange
        let table = Item(
            id: "table",
            .name("wooden table"),
            .in(.location(.startRoom)),
            .isSurface
        )
        let book = Item(
            id: "book",
            .name("dusty book"),
            .in(.item("table"))
        )
        let game = MinimalGame(items: table, book)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("touch book")

        // Assert
        let finalItemState = try await engine.item("book")
        #expect(finalItemState.hasFlag(.isTouched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > touch book
            You feel nothing special.
            """)
    }

    @Test("Touch fails item in closed container")
    func testTouchFailsItemInClosedContainer() async throws {
        // Arrange
        let chest = Item(
            id: "chest",
            .name("locked chest"),
            .in(.location(.startRoom)),
            .isContainer  // Closed by default
        )
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.item("chest"))
        )
        let game = MinimalGame(items: chest, coin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        #expect(chest.attributes[.isOpen] == nil)  // Verify closed

        // Act & Assert
        try await engine.execute("touch coin")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > touch coin
            You can’t see any gold coin here.
            """)
    }
}
