import CustomDump
import Foundation
import GnustoEngine
import Testing

@Suite("EmptyActionHandler")
struct EmptyActionHandlerTests {
    // MARK: - Test Helpers

    private func createTestEngine() async -> GameEngine {
        let box = Item(
            id: "box",
            .name("box"),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let coin = Item(
            id: "coin",
            .name("coin"),
            .isTakable,
            .in(.item("box"))
        )

        let gem = Item(
            id: "gem",
            .name("gem"),
            .isTakable,
            .in(.item("box"))
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing empty commands.")
        )

        let game = MinimalGame(
            locations: [testRoom],
            items: [box, coin, gem]
        )

        let mockIO = await MockIOHandler()
        let mockParser = MockParser()

        return await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
    }

    private func createTestEngineWithEmptyBox() async -> GameEngine {
        let box = Item(
            id: "box",
            .name("box"),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let coin = Item(
            id: "coin",
            .name("coin"),
            .isTakable,
            .in(.location("testRoom"))
        )

        let gem = Item(
            id: "gem",
            .name("gem"),
            .isTakable,
            .in(.location("testRoom"))
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing empty commands.")
        )

        let game = MinimalGame(
            locations: [testRoom],
            items: [box, coin, gem]
        )

        let mockIO = await MockIOHandler()
        let mockParser = MockParser()

        return await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
    }

    private func createTestEngineWithNonContainer() async -> GameEngine {
        let box = Item(
            id: "box",
            .name("box"),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let looseCoin = Item(
            id: "looseCoin",
            .name("loose coin"),
            .isTakable,
            .in(.location("testRoom"))
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing empty commands.")
        )

        let game = MinimalGame(
            locations: [testRoom],
            items: [box, looseCoin]
        )

        let mockIO = await MockIOHandler()
        let mockParser = MockParser()

        return await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
    }

    private func createTestEngineWithClosedBox() async -> GameEngine {
        let box = Item(
            id: "box",
            .name("box"),
            .isContainer,
            .isTakable,
            .in(.location("testRoom"))
        )

        let coin = Item(
            id: "coin",
            .name("coin"),
            .isTakable,
            .in(.item("box"))
        )

        let gem = Item(
            id: "gem",
            .name("gem"),
            .isTakable,
            .in(.item("box"))
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing empty commands.")
        )

        let game = MinimalGame(
            locations: [testRoom],
            items: [box, coin, gem]
        )

        let mockIO = await MockIOHandler()
        let mockParser = MockParser()

        return await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
    }

    private func createTestEngineWithDistantBox() async -> GameEngine {
        let box = Item(
            id: "box",
            .name("box"),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let distantBox = Item(
            id: "distantBox",
            .name("distant box"),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("anotherRoom"))
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing empty commands.")
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .description("A distant room.")
        )

        let game = MinimalGame(
            locations: [testRoom, anotherRoom],
            items: [box, distantBox]
        )

        let mockIO = await MockIOHandler()
        let mockParser = MockParser()

        return await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
    }

    // MARK: - Tests

    @Test("EMPTY command on container with contents")
    func testEmptyCommand() async throws {
        let engine = await createTestEngine()
        let handler = EmptyActionHandler()
        let command = Command(verb: .empty, directObject: .item("box"), rawInput: "empty box")
        let context = ActionContext(command: command, engine: engine)

        // Should validate successfully
        try await handler.validate(context: context)

        // Should empty the box
        let result = try await handler.process(context: context)
        #expect(result.message?.contains("You empty the box") == true)

        // Verify items are now in the test room
        let coinAfter = try await engine.item("coin")
        let gemAfter = try await engine.item("gem")
        #expect(coinAfter.parent == .location("testRoom"))
        #expect(gemAfter.parent == .location("testRoom"))

        // Verify box is marked as touched
        let boxAfter = try await engine.item("box")
        #expect(boxAfter.hasFlag(.isTouched))
    }

    @Test("EMPTY command on empty container")
    func testEmptyEmptyContainer() async throws {
        let engine = await createTestEngineWithEmptyBox()
        let handler = EmptyActionHandler()
        let command = Command(verb: .empty, directObject: .item("box"), rawInput: "empty box")
        let context = ActionContext(command: command, engine: engine)

        // Should validate successfully
        try await handler.validate(context: context)

        // Should provide "already empty" message
        let result = try await handler.process(context: context)
        #expect(result.message == "The box is already empty.")
    }

    @Test("EMPTY command without direct object")
    func testEmptyWithoutObject() async throws {
        let engine = await createTestEngine()
        let handler = EmptyActionHandler()
        let command = Command(verb: .empty, rawInput: "empty")
        let context = ActionContext(command: command, engine: engine)

        // Should fail validation
        do {
            try await handler.validate(context: context)
            Issue.record("Expected validation to fail for empty without object")
        } catch let response as ActionResponse {
            if case .prerequisiteNotMet(let message) = response {
                #expect(message == "Empty what?")
            } else {
                Issue.record("Expected prerequisiteNotMet error, got: \(response)")
            }
        }
    }

    @Test("EMPTY command on non-container")
    func testEmptyNonContainer() async throws {
        let engine = await createTestEngineWithNonContainer()
        let handler = EmptyActionHandler()
        let command = Command(verb: .empty, directObject: .item("looseCoin"), rawInput: "empty loose coin")
        let context = ActionContext(command: command, engine: engine)

        // Should fail validation
        do {
            try await handler.validate(context: context)
            Issue.record("Expected validation to fail for non-container")
        } catch let response as ActionResponse {
            if case .targetIsNotAContainer(let itemID) = response {
                #expect(itemID.rawValue == "looseCoin")
            } else {
                Issue.record("Expected targetIsNotAContainer error, got: \(response)")
            }
        }
    }

    @Test("EMPTY command on closed container")
    func testEmptyClosedContainer() async throws {
        let engine = await createTestEngineWithClosedBox()
        let handler = EmptyActionHandler()
        let command = Command(verb: .empty, directObject: .item("box"), rawInput: "empty box")
        let context = ActionContext(command: command, engine: engine)

        // Should fail validation
        do {
            try await handler.validate(context: context)
            Issue.record("Expected validation to fail for closed container")
        } catch let response as ActionResponse {
            if case .containerIsClosed(let itemID) = response {
                #expect(itemID.rawValue == "box")
            } else {
                Issue.record("Expected containerIsClosed error, got: \(response)")
            }
        }
    }

    @Test("EMPTY command on inaccessible container")
    func testEmptyInaccessibleContainer() async throws {
        let engine = await createTestEngineWithDistantBox()
        let handler = EmptyActionHandler()
        let command = Command(verb: .empty, directObject: .item("distantBox"), rawInput: "empty distant box")
        let context = ActionContext(command: command, engine: engine)

        // Should fail validation due to item not being accessible
        do {
            try await handler.validate(context: context)
            Issue.record("Expected validation to fail for inaccessible item")
        } catch let response as ActionResponse {
            if case .itemNotAccessible(let itemID) = response {
                #expect(itemID.rawValue == "distantBox")
            } else {
                Issue.record("Expected itemNotAccessible error, got: \(response)")
            }
        }
    }
}
