import Testing
import CustomDump

@testable import GnustoEngine

@Suite("RemoveActionHandler Tests")
struct RemoveActionHandlerTests {
    let handler = RemoveActionHandler()

    @Test("Remove worn item successfully")
    func testRemoveItemSuccess() async throws {
        let cloak = Item(
            id: "cloak",
            .in(.player),
            .isTakable,
            .isWearable,
            .isWorn
        )
        let game = MinimalGame(items: [cloak])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: StandardParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .remove,
            directObject: .item("cloak"),
            rawInput: "remove cloak"
        )

        // Initial state check
        #expect(try await engine.item("cloak").hasFlag(.isWorn) == true)
        let initialHistory = await engine.gameState.changeHistory
        #expect(initialHistory.isEmpty)

        // Act
        await engine.execute(command: command)

        // Assert State Change
        let finalCloakState = try await engine.item("cloak")
        #expect(finalCloakState.parent == .player)
        #expect(finalCloakState.hasFlag(.isWorn) == false, "Cloak should NOT have .isWorn flag")
        #expect(finalCloakState.hasFlag(.isTouched) == true, "Cloak should have .isTouched flag") // Ensure touched is added

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You take off the cloak.")

        // Assert Change History
        let expectedChanges = [
            StateChange(
                entityID: .item("cloak"),
                attribute: .itemAttribute(.isWorn),
                oldValue: true,
                newValue: false
            ),
            StateChange(
                entityID: .item("cloak"),
                attribute: .itemAttribute(.isTouched),
                newValue: true
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

    @Test("Remove fails if item not worn (but held)")
    func testRemoveItemNotWorn() async throws {
        let cloak = Item(
            id: "cloak",
            .in(.player),
            .isTakable,
            .isWearable
        )
        let game = MinimalGame(items: [cloak])
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verb: .remove,
            directObject: .item("cloak"),
            rawInput: "take off cloak"
        )

        // Act & Assert Error (on validate)
        await #expect(throws: ActionResponse.itemIsNotWorn("cloak")) {
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

    @Test("Remove fails if item not held")
    func testRemoveItemNotHeld() async throws {
        let game = MinimalGame() // Cloak doesn’t exist here
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verb: .remove,
            directObject: .item("cloak"),
            rawInput: "remove cloak"
        )

        // Act & Assert Error (on validate)
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

    @Test("Remove fails with no direct object")
    func testRemoveNoObject() async throws {
        let game = MinimalGame()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        // Command with nil directObject
        let command = Command(
            verb: .remove,
            rawInput: "remove"
        )

        // Act & Assert Error (on validate)
        await #expect(throws: ActionResponse.prerequisiteNotMet("Remove what?")) {
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

    @Test("Remove fails if item is fixed scenery (which can be worn)")
    func testRemoveFailsIfFixed() async throws {
        let amulet = Item(
            id: "amulet",
            .name("cursed amulet"),
            .in(.player),
            .isScenery,
            .isWearable,
            .isWorn
        )
        let game = MinimalGame(items: [amulet])
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verb: .remove,
            directObject: .item("amulet"),
            rawInput: "remove amulet"
        )

        // Act & Assert Error (on validate)
        await #expect(throws: ActionResponse.itemNotRemovable("amulet")) {
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

    @Test("REMOVE ALL works correctly")
    func testRemoveAll() async throws {
        let cloak = Item(id: "cloak", .name("cloak"), .in(.player), .isWearable, .isWorn)
        let boots = Item(id: "boots", .name("boots"), .in(.player), .isWearable, .isWorn)
        
        let game = MinimalGame(items: [cloak, boots])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "remove all"
        let command = Command(
            verb: .remove,
            directObjects: [.item("cloak"), .item("boots")],
            isAllCommand: true,
            rawInput: "remove all"
        )
        await engine.execute(command: command)
        
        // Assert: Should remove both items
        let output = await mockIO.flush()
        expectNoDifference(output, "You take off the boots and the cloak.")

        // Verify items are no longer worn
        let updatedCloak = try await engine.item("cloak")
        let updatedBoots = try await engine.item("boots")
        #expect(updatedCloak.hasFlag(.isWorn) == false)
        #expect(updatedBoots.hasFlag(.isWorn) == false)
        
        // Verify items are still held
        #expect(updatedCloak.parent == .player)
        #expect(updatedBoots.parent == .player)
    }
    
    @Test("REMOVE CLOAK AND BOOTS works correctly")
    func testRemoveCloakAndBoots() async throws {
        let cloak = Item(id: "cloak", .name("cloak"), .in(.player), .isWearable, .isWorn)
        let boots = Item(id: "boots", .name("boots"), .in(.player), .isWearable, .isWorn)
        
        let game = MinimalGame(items: [cloak, boots])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "remove cloak and boots"
        let command = Command(
            verb: .remove,
            directObjects: [.item("cloak"), .item("boots")],
            isAllCommand: false,
            rawInput: "remove cloak and boots"
        )
        await engine.execute(command: command)
        
        // Assert: Should remove both items
        let output = await mockIO.flush()
        expectNoDifference(output, "You take off the boots and the cloak.")

        // Verify items are no longer worn
        let updatedCloak = try await engine.item("cloak")
        let updatedBoots = try await engine.item("boots")
        #expect(updatedCloak.hasFlag(.isWorn) == false)
        #expect(updatedBoots.hasFlag(.isWorn) == false)
    }
    
    @Test("REMOVE ALL skips non-worn items")
    func testRemoveAllSkipsNonWorn() async throws {
        let cloak = Item(id: "cloak", .name("cloak"), .in(.player), .isWearable, .isWorn)
        let boots = Item(id: "boots", .name("boots"), .in(.player), .isWearable) // Not worn
        
        let game = MinimalGame(items: [cloak, boots])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "remove all"
        let command = Command(
            verb: .remove,
            directObjects: [.item("cloak"), .item("boots")],
            isAllCommand: true,
            rawInput: "remove all"
        )
        await engine.execute(command: command)
        
        // Assert: Should remove only the cloak
        let output = await mockIO.flush()
        expectNoDifference(output, "You take off the cloak.")

        // Verify only cloak is affected
        let updatedCloak = try await engine.item("cloak")
        let updatedBoots = try await engine.item("boots")
        #expect(updatedCloak.hasFlag(.isWorn) == false)
        #expect(updatedBoots.hasFlag(.isWorn) == false) // Was already false
    }
    
    @Test("REMOVE ALL with no worn items")
    func testRemoveAllWithNoWornItems() async throws {
        let boots = Item(id: "boots", .name("boots"), .in(.player), .isWearable) // Not worn
        
        let game = MinimalGame(items: [boots])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "remove all"
        let command = Command(
            verb: .remove,
            directObjects: [.item("boots")],
            isAllCommand: true,
            rawInput: "remove all"
        )
        await engine.execute(command: command)
        
        // Assert: Should get appropriate message
        let output = await mockIO.flush()
        expectNoDifference(output, "You aren’t wearing anything.")
    }
    
    @Test("REMOVE ALL skips scenery items")
    func testRemoveAllSkipsScenery() async throws {
        let cloak = Item(id: "cloak", .name("cloak"), .in(.player), .isWearable, .isWorn)
        let amulet = Item(id: "amulet", .name("cursed amulet"), .in(.player), .isWearable, .isWorn, .isScenery)
        
        let game = MinimalGame(items: [cloak, amulet])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "remove all"
        let command = Command(
            verb: .remove,
            directObjects: [.item("cloak"), .item("amulet")],
            isAllCommand: true,
            rawInput: "remove all"
        )
        await engine.execute(command: command)
        
        // Assert: Should remove only the cloak (skip cursed amulet)
        let output = await mockIO.flush()
        expectNoDifference(output, "You take off the cloak.")

        // Verify only cloak is affected
        let updatedCloak = try await engine.item("cloak")
        let updatedAmulet = try await engine.item("amulet")
        #expect(updatedCloak.hasFlag(.isWorn) == false)
        #expect(updatedAmulet.hasFlag(.isWorn) == true) // Still worn (cursed)
    }
}
