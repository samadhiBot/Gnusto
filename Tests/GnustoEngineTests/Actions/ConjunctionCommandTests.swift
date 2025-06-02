import CustomDump
import Foundation
import Testing

@testable import GnustoEngine

/// Tests for commands with conjunctions like "DROP SWORD AND LANTERN"
@Suite("Conjunction Command Tests")
struct ConjunctionCommandTests {
    
    // MARK: - Test Helpers
    
    /// Creates a test engine with basic items for conjunction testing
    private func createTestEngine() async -> GameEngine {
        // Create items for testing
        let sword = Item(
            id: "sword",
            .name("sword"),
            .in(.player),
            .isTakable,
            .size(3)
        )
        
        let lantern = Item(
            id: "lantern",
            .name("lantern"),
            .in(.player),
            .isTakable,
            .size(2)
        )
        
        let book = Item(
            id: "book",
            .name("book"),
            .in(.player),
            .isTakable,
            .size(1)
        )
        
        let coin = Item(
            id: "coin",
            .name("coin"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(1)
        )
        
        let gem = Item(
            id: "gem",
            .name("gem"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(1)
        )
        
        let player = Player(in: .startRoom, carryingCapacity: 20)
        let game = MinimalGame(player: player, items: [sword, lantern, book, coin, gem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        return await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
    }
    
    // MARK: - DROP Conjunction Tests
    
    @Test("DROP SWORD AND LANTERN drops both items")
    func testDropSwordAndLantern() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler
        
        // Create the conjunction command manually for now
        let command = Command(
            verb: .drop,
            directObjects: [.item("sword"), .item("lantern")],
            isAllCommand: true, // Mark as multi-object command
            rawInput: "drop sword and lantern"
        )
        
        // Act: Execute the conjunction command
        await engine.execute(command: command)
        
        // Assert: Both items should be dropped
        let swordItem = try await engine.item("sword")
        let lanternItem = try await engine.item("lantern")
        
        #expect(swordItem.parent == .location(.startRoom))
        #expect(lanternItem.parent == .location(.startRoom))
        
        // Assert: Appropriate message
        let output = await mockIO.flush()
        expectNoDifference(output, "You drop the lantern and the sword.")
    }
    
    @Test("DROP SWORD, LANTERN AND BOOK drops all three items")
    func testDropThreeItemsWithCommaAndConjunction() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler
        
        // Create the conjunction command manually for now
        let command = Command(
            verb: .drop,
            directObjects: [.item("sword"), .item("lantern"), .item("book")],
            isAllCommand: true, // Mark as multi-object command
            rawInput: "drop sword, lantern and book"
        )
        
        // Act: Execute the conjunction command with comma
        await engine.execute(command: command)
        
        // Assert: All three items should be dropped
        let swordItem = try await engine.item("sword")
        let lanternItem = try await engine.item("lantern")
        let bookItem = try await engine.item("book")
        
        #expect(swordItem.parent == .location(.startRoom))
        #expect(lanternItem.parent == .location(.startRoom))
        #expect(bookItem.parent == .location(.startRoom))
        
        // Assert: Appropriate message
        let output = await mockIO.flush()
        expectNoDifference(output, "You drop the book, the lantern, and the sword.")

    }
    
    // MARK: - TAKE Conjunction Tests
    
    @Test("TAKE COIN AND GEM takes both items")
    func testTakeCoinAndGem() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler
        
        // Create the conjunction command manually for now
        let command = Command(
            verb: .take,
            directObjects: [.item("coin"), .item("gem")],
            isAllCommand: true, // Mark as multi-object command
            rawInput: "take coin and gem"
        )
        
        // Act: Execute the conjunction command
        await engine.execute(command: command)
        
        // Assert: Both items should be taken
        let coinItem = try await engine.item("coin")
        let gemItem = try await engine.item("gem")
        
        #expect(coinItem.parent == .player)
        #expect(gemItem.parent == .player)
        
        // Assert: Appropriate message
        let output = await mockIO.flush()
        expectNoDifference(output, "You take the coin and the gem.")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Conjunction with verb that doesn't support multiple objects fails")
    func testConjunctionWithUnsupportedVerb() async throws {
        // Create test setup directly
        let sword = Item(id: "sword", .name("sword"), .in(.player), .isTakable)
        let lantern = Item(id: "lantern", .name("lantern"), .in(.player), .isTakable)
        let player = Player(in: .startRoom)
        
        let vocabulary = Vocabulary.build(items: [sword, lantern])
        let gameState = GameState(
            locations: [Location(id: .startRoom, .name("Start Room"))],
            items: [sword, lantern],
            player: player
        )
        let parser = StandardParser()
        
        // Act: Try to parse "open sword and lantern" (OPEN doesn't support multiple objects)
        let result = parser.parse(
            input: "open sword and lantern",
            vocabulary: vocabulary,
            gameState: gameState
        )
        
        // Assert: Should get a parse error about multiple objects not being supported
        switch result {
        case .success:
            #expect(Bool(false), "Expected parsing to fail for unsupported multiple objects")
        case .failure(let error):
            let errorMessage = "\(error)"
            #expect(errorMessage.contains("doesn\\'t support multiple objects"))
        }
    }
    
    @Test("Conjunction with non-existent item handles gracefully")
    func testConjunctionWithNonExistentItem() async throws {
        // Create test setup directly
        let sword = Item(id: "sword", .name("sword"), .in(.player), .isTakable)
        let player = Player(in: .startRoom)
        
        let vocabulary = Vocabulary.build(items: [sword])
        let gameState = GameState(
            locations: [Location(id: .startRoom, .name("Start Room"))],
            items: [sword],
            player: player
        )
        let parser = StandardParser()
        
        // Act: Try to parse "drop sword and nonexistent" (nonexistent item should cause error)
        let result = parser.parse(
            input: "drop sword and nonexistent",
            vocabulary: vocabulary,
            gameState: gameState
        )
        
        // Assert: Should get a parse error about the non-existent item
        switch result {
        case .success:
            #expect(Bool(false), "Expected parsing to fail for non-existent item")
        case .failure(let error):
            let errorMessage = "\(error)"
            #expect(errorMessage.contains("can't see") || 
                    errorMessage.contains("don't see") ||
                    errorMessage.contains("not here") ||
                    errorMessage.contains("unknown") ||
                    errorMessage.contains("not in scope"))
        }
    }
    
    // MARK: - Mixed Conjunction Tests
    
    @Test("DROP with one held and one not held item")
    func testDropMixedHeldStatus() async throws {
        // Create items with one held and one not held
        let sword = Item(
            id: "sword",
            .name("sword"),
            .in(.player),
            .isTakable,
            .size(3)
        )
        
        let statue = Item(
            id: "statue",
            .name("statue"),
            .in(.location(.startRoom)),
            .size(10)
        )
        
        let player = Player(in: .startRoom, carryingCapacity: 20)
        let game = MinimalGame(player: player, items: [sword, statue])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Create a command with one held and one not held item
        let command = Command(
            verb: .drop,
            directObjects: [.item("sword"), .item("statue")],
            isAllCommand: true,
            rawInput: "drop sword and statue"
        )
        
        // Act: Try to drop a held item and a non-held item
        await engine.execute(command: command)
        
        // Assert: Should drop the sword but skip the statue
        let swordItem = try await engine.item("sword")
        let statueItem = try await engine.item("statue")
        
        #expect(swordItem.parent == .location(.startRoom))
        #expect(statueItem.parent == .location(.startRoom)) // Should remain in location
    }
    
    // MARK: - Parser Integration Tests
    
    @Test("Parser correctly parses DROP SWORD AND LANTERN")
    func testParserParsesDropSwordAndLantern() async throws {
        // Create test setup directly
        let sword = Item(id: "sword", .name("sword"), .in(.player), .isTakable)
        let lantern = Item(id: "lantern", .name("lantern"), .in(.player), .isTakable)
        let player = Player(in: .startRoom)
        
        let vocabulary = Vocabulary.build(items: [sword, lantern])
        let gameState = GameState(
            locations: [Location(id: .startRoom, .name("Start Room"))],
            items: [sword, lantern],
            player: player
        )
        let parser = StandardParser()
        
        // Act: Parse "drop sword and lantern"
        let result = parser.parse(
            input: "drop sword and lantern",
            vocabulary: vocabulary,
            gameState: gameState
        )
        
        // Assert: Should successfully parse with multiple objects
        switch result {
        case .success(let command):
            #expect(command.verb == .drop)
            #expect(command.directObjects.count == 2)
            #expect(command.directObjects.contains(.item("sword")))
            #expect(command.directObjects.contains(.item("lantern")))
            #expect(command.isAllCommand == true) // Multiple objects should set this flag
            #expect(command.rawInput == "drop sword and lantern")
        case .failure(let error):
            #expect(Bool(false), "Expected parsing to succeed, but got error: \(error)")
        }
    }
    
    @Test("Parser correctly parses TAKE COIN, GEM AND BOOK")
    func testParserParsesTakeWithCommaAndConjunction() async throws {
        // Create test setup directly
        let coin = Item(id: "coin", .name("coin"), .in(.location(.startRoom)), .isTakable)
        let gem = Item(id: "gem", .name("gem"), .in(.location(.startRoom)), .isTakable)
        let book = Item(id: "book", .name("book"), .in(.location(.startRoom)), .isTakable)
        let player = Player(in: .startRoom)
        
        let vocabulary = Vocabulary.build(items: [coin, gem, book])
        let gameState = GameState(
            locations: [Location(id: .startRoom, .name("Start Room"))],
            items: [coin, gem, book],
            player: player
        )
        let parser = StandardParser()
        
        // Act: Parse "take coin, gem and book"
        let result = parser.parse(
            input: "take coin, gem and book",
            vocabulary: vocabulary,
            gameState: gameState
        )
        
        // Assert: Should successfully parse with multiple objects
        switch result {
        case .success(let command):
            #expect(command.verb == .take)
            #expect(command.directObjects.count == 3)
            #expect(command.directObjects.contains(.item("coin")))
            #expect(command.directObjects.contains(.item("gem")))
            #expect(command.directObjects.contains(.item("book")))
            #expect(command.isAllCommand == true) // Multiple objects should set this flag
            #expect(command.rawInput == "take coin, gem and book")
        case .failure(let error):
            #expect(Bool(false), "Expected parsing to succeed, but got error: \(error)")
        }
    }
}
