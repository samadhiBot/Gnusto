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

        return GameEngine(
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
        let command = Command(verb: .empty, directObject: "box", rawInput: "empty box")
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
        let engine = await createTestEngine()

        // First empty the box by moving items out
        try await engine.apply(StateChange(
            entityID: .item("coin"),
            attribute: .parentEntity,
            oldValue: .parentEntity(.item("box")),
            newValue: .parentEntity(.location("testRoom"))
        ))

        try await engine.apply(StateChange(
            entityID: .item("gem"),
            attribute: .parentEntity,
            oldValue: .parentEntity(.item("box")),
            newValue: .parentEntity(.location("testRoom"))
        ))

        let handler = EmptyActionHandler()
        let command = Command(verb: .empty, directObject: "box", rawInput: "empty box")
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
        let engine = await createTestEngine()

        // Add a non-container item
        let coin = Item(
            id: "looseCoin",
            .name("loose coin"),
            .isTakable,
            .in(.location("testRoom"))
        )

        try await engine.apply(StateChange(
            entityID: .global,
            attribute: .addItem(coin),
            oldValue: nil,
            newValue: true
        ))

        let handler = EmptyActionHandler()
        let command = Command(verb: .empty, directObject: "looseCoin", rawInput: "empty loose coin")
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
        let engine = await createTestEngine()

        // Close the box
        try await engine.apply(StateChange(
            entityID: .item("box"),
            attribute: .clearFlag(.isOpen),
            oldValue: true,
            newValue: nil
        ))

        let handler = EmptyActionHandler()
        let command = Command(verb: .empty, directObject: "box", rawInput: "empty box")
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
        let engine = await createTestEngine()

        // Add a container in another location
        let distantBox = Item(
            id: "distantBox",
            .name("distant box"),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("anotherRoom"))
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .description("A distant room.")
        )

        try await engine.apply(StateChange(
            entityID: .global,
            attribute: .addLocation(anotherRoom),
            oldValue: nil,
            newValue: true
        ))

        try await engine.apply(StateChange(
            entityID: .global,
            attribute: .addItem(distantBox),
            oldValue: nil,
            newValue: true
        ))

        let handler = EmptyActionHandler()
        let command = Command(verb: .empty, directObject: "distantBox", rawInput: "empty distant box")
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
