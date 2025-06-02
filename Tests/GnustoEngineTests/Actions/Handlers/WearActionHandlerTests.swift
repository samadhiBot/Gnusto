import Testing
import CustomDump

@testable import GnustoEngine

@Suite("WearActionHandler Tests")
struct WearActionHandlerTests {
    // Keep handler instance for direct validation testing
    let handler = WearActionHandler()

    @Test("Wear held, wearable item successfully")
    func testWearItemSuccess() async throws {
        let cloak = Item(
            id: "cloak",
            .name("velvet cloak"),
            .in(.player),
            .isWearable,
            .isTakable
        )
        let game = MinimalGame(items: [cloak])
        let mockIO = await MockIOHandler()
        var mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .wear,
            directObject: .item("cloak"),
            rawInput: "wear cloak"
        )
        mockParser.parseHandler = { _, _, _ in .success(command) }

        let initialItem = try await engine.item("cloak")
        #expect(initialItem.hasFlag(.isWorn) == false)
        #expect(await engine.gameState.changeHistory.isEmpty)

        await engine.execute(command: command)

        let finalCloakState = try await engine.item("cloak")
        #expect(finalCloakState.parent == .player)
        #expect(finalCloakState.hasFlag(.isWorn) == true, "Cloak should have .worn property")
        #expect(finalCloakState.hasFlag(.isTouched) == true, "Cloak should have .touched property")

        let output = await mockIO.flush()
        expectNoDifference(output, "You put on the velvet cloak.")

        let expectedChanges = [
            StateChange(
                entityID: .item("cloak"),
                attribute: .itemAttribute(.isWorn),
                newValue: true,
            ),
            StateChange(
                entityID: .item("cloak"),
                attribute: .itemAttribute(.isTouched),
                newValue: true,
            ),
            StateChange(
                entityID: .global,
                attribute: .pronounReference(pronoun: "it"),
                newValue: .entityReferenceSet([.item("cloak")])
            )
        ]
        let finalHistory = await engine.gameState.changeHistory
        expectNoDifference(finalHistory, expectedChanges)
    }

    @Test("Wear fails if item not held")
    func testWearItemNotHeld() async throws {
        let game = MinimalGame()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verb: .wear,
            directObject: .item("cloak"),
            rawInput: "wear cloak"
        )

        await #expect(throws: ActionResponse.itemNotAccessible("cloak")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Wear fails if item not wearable")
    func testWearItemNotWearable() async throws {
        let rock = Item(
            id: "rock",
            .name("heavy rock"),
            .in(.player),
            .isTakable
        )
        let game = MinimalGame(items: [rock])
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verb: .wear,
            directObject: .item("rock"),
            rawInput: "wear rock"
        )

        await #expect(throws: ActionResponse.itemNotWearable("rock")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Wear fails if item already worn")
    func testWearItemAlreadyWorn() async throws {
        let cloak = Item(
            id: "cloak",
            .name("velvet cloak"),
            .in(.player),
            .isWearable,
            .isTakable,
            .isWorn
        )
        let game = MinimalGame(items: [cloak])
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verb: .wear,
            directObject: .item("cloak"),
            rawInput: "wear cloak"
        )

        await #expect(throws: ActionResponse.itemIsAlreadyWorn("cloak")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Wear fails with no direct object")
    func testWearNoObject() async throws {
        let game = MinimalGame()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verb: .wear,
            rawInput: "wear"
        )

        await #expect(throws: ActionResponse.prerequisiteNotMet("Wear what?")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    // MARK: - Multiple Object Tests

    @Test("WEAR ALL works correctly")
    func testWearAll() async throws {
        let cloak = Item(id: "cloak", .name("cloak"), .in(.player), .isWearable)
        let boots = Item(id: "boots", .name("boots"), .in(.player), .isWearable)
        
        let game = MinimalGame(items: [cloak, boots])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "wear all"
        let command = Command(
            verb: .wear,
            directObjects: [.item("cloak"), .item("boots")],
            isAllCommand: true,
            rawInput: "wear all"
        )
        await engine.execute(command: command)
        
        // Assert: Should wear both items
        let output = await mockIO.flush()
        expectNoDifference(output, "You put on the boots and the cloak.")

        // Verify items are worn
        let updatedCloak = try await engine.item("cloak")
        let updatedBoots = try await engine.item("boots")
        #expect(updatedCloak.hasFlag(.isWorn) == true)
        #expect(updatedBoots.hasFlag(.isWorn) == true)
    }
    
    @Test("WEAR CLOAK AND BOOTS works correctly")
    func testWearCloakAndBoots() async throws {
        let cloak = Item(id: "cloak", .name("cloak"), .in(.player), .isWearable)
        let boots = Item(id: "boots", .name("boots"), .in(.player), .isWearable)
        
        let game = MinimalGame(items: [cloak, boots])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "wear cloak and boots"
        let command = Command(
            verb: .wear,
            directObjects: [.item("cloak"), .item("boots")],
            isAllCommand: false,
            rawInput: "wear cloak and boots"
        )
        await engine.execute(command: command)
        
        // Assert: Should wear both items
        let output = await mockIO.flush()
        expectNoDifference(output, "You put on the boots and the cloak.")
        
        // Verify items are worn
        let updatedCloak = try await engine.item("cloak")
        let updatedBoots = try await engine.item("boots")
        #expect(updatedCloak.hasFlag(.isWorn) == true)
        #expect(updatedBoots.hasFlag(.isWorn) == true)
    }
    
    @Test("WEAR ALL skips non-wearable items")
    func testWearAllSkipsNonWearable() async throws {
        let cloak = Item(id: "cloak", .name("cloak"), .in(.player), .isWearable)
        let rock = Item(id: "rock", .name("rock"), .in(.player)) // Not wearable
        
        let game = MinimalGame(items: [cloak, rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "wear all"
        let command = Command(
            verb: .wear,
            directObjects: [.item("cloak"), .item("rock")],
            isAllCommand: true,
            rawInput: "wear all"
        )
        await engine.execute(command: command)
        
        // Assert: Should wear only the cloak
        let output = await mockIO.flush()
        expectNoDifference(output, "You put on the cloak.")
        
        // Verify only cloak is worn
        let updatedCloak = try await engine.item("cloak")
        let updatedRock = try await engine.item("rock")
        #expect(updatedCloak.hasFlag(.isWorn) == true)
        #expect(updatedRock.hasFlag(.isWorn) == false)
    }
    
    @Test("WEAR ALL with no wearable items")
    func testWearAllWithNoWearableItems() async throws {
        let rock = Item(id: "rock", .name("rock"), .in(.player)) // Not wearable
        
        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "wear all"
        let command = Command(
            verb: .wear,
            directObjects: [.item("rock")],
            isAllCommand: true,
            rawInput: "wear all"
        )
        await engine.execute(command: command)
        
        // Assert: Should get appropriate message
        let output = await mockIO.flush()
        expectNoDifference(output, "You have nothing to wear.")
    }
    
    @Test("WEAR ALL skips already worn items")
    func testWearAllSkipsAlreadyWorn() async throws {
        let cloak = Item(id: "cloak", .name("cloak"), .in(.player), .isWearable, .isWorn)
        let boots = Item(id: "boots", .name("boots"), .in(.player), .isWearable)
        
        let game = MinimalGame(items: [cloak, boots])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "wear all"
        let command = Command(
            verb: .wear,
            directObjects: [.item("cloak"), .item("boots")],
            isAllCommand: true,
            rawInput: "wear all"
        )
        await engine.execute(command: command)
        
        // Assert: Should wear only the boots
        let output = await mockIO.flush()
        expectNoDifference(output, "You put on the boots.")
        
        // Verify states
        let updatedCloak = try await engine.item("cloak")
        let updatedBoots = try await engine.item("boots")
        #expect(updatedCloak.hasFlag(.isWorn) == true) // Already worn
        #expect(updatedBoots.hasFlag(.isWorn) == true) // Newly worn
    }
}
