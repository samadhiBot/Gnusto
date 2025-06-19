import CustomDump
import Testing

@testable import GnustoEngine

@Suite("LookUnderActionHandler Tests")
struct LookUnderActionHandlerTests {
    let handler = LookUnderActionHandler()

    @Test("Look under item gives default response")
    func testLookUnderItemGivesDefaultResponse() async throws {
        let table = Item(
            id: "table",
            .name("wooden table"),
            .in(.location(.startRoom)),
            .isSurface
        )
        let game = MinimalGame(items: table)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .lookUnder,
            indirectObject: .item("table"),
            rawInput: "look under table"
        )

        // Initial state check
        let initialTable = try await engine.item("table")
        #expect(initialTable.attributes[.isTouched] == nil)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        await engine.execute(command: command)

        // Assert State Change
        let finalTable = try await engine.item("table")
        #expect(finalTable.attributes[.isTouched] == true)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You find nothing of interest under the wooden table.")

        // Assert Change History
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(
            changeHistory,
            [
                StateChange(
                    entityID: .item(table.id),
                    attribute: .itemAttribute(.isTouched),
                    newValue: true
                ),
                StateChange(
                    entityID: .global,
                    attribute: .pronounReference(pronoun: "it"),
                    newValue: .entityReferenceSet([.item(table.id)])
                ),
            ])
    }

    @Test("Look under fails if item not accessible")
    func testLookUnderFailsIfNotAccessible() async throws {
        let table = Item(
            id: "table",
            .name("wooden table"),
            .in(.nowhere),
            .isSurface
        )
        let game = MinimalGame(items: table)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .lookUnder,
            indirectObject: .item("table"),
            rawInput: "look under table"
        )

        // Act & Assert Error
        await #expect(throws: Error.self) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine
                )
            )
        }
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Look under fails with no indirect object")
    func testLookUnderFailsWithNoObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        let command = Command(
            verb: .lookUnder,
            rawInput: "look under"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Look under what?")

        // Assert Error Message
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Look under fails with non-item target")
    func testLookUnderFailsWithNonItemTarget() async throws {
        let (engine, mockIO) = await GameEngine.test()

        let command = Command(
            verb: .lookUnder,
            indirectObject: .location(.startRoom),
            rawInput: "look under room"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t look under that.")

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Look under fails if item not reachable")
    func testLookUnderFailsIfNotReachable() async throws {
        let box = Item(
            id: "box",
            .name("locked box"),
            .in(.location(.startRoom)),
            .isContainer
            // Not open, so contents not reachable
        )
        let carpet = Item(
            id: "carpet",
            .name("small carpet"),
            .in(.item("box")),
            .isTakable
        )
        let game = MinimalGame(items: box, carpet)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .lookUnder,
            indirectObject: .item("carpet"),
            rawInput: "look under carpet"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Look under works on player inventory items")
    func testLookUnderWorksOnInventoryItems() async throws {
        let mat = Item(
            id: "mat",
            .name("welcome mat"),
            .in(.player),
            .isTakable
        )
        let game = MinimalGame(items: mat)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .lookUnder,
            indirectObject: .item("mat"),
            rawInput: "look under mat"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You find nothing of interest under the welcome mat.")

        // Assert State Change
        let finalMat = try await engine.item("mat")
        #expect(finalMat.attributes[.isTouched] == true)
    }

    @Test("Look under works on items on surfaces")
    func testLookUnderWorksOnItemsOnSurfaces() async throws {
        let table = Item(
            id: "table",
            .name("wooden table"),
            .in(.location(.startRoom)),
            .isSurface,
            .isOpen
        )
        let book = Item(
            id: "book",
            .name("old book"),
            .in(.item("table")),
            .isTakable
        )
        let game = MinimalGame(items: table, book)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .lookUnder,
            indirectObject: .item("book"),
            rawInput: "look under book"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You find nothing of interest under the old book.")

        // Assert State Change
        let finalBook = try await engine.item("book")
        #expect(finalBook.attributes[.isTouched] == true)
    }
}
