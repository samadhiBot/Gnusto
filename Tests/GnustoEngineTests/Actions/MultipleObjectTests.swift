import CustomDump
import Testing

@testable import GnustoEngine

/// Tests for verbs that support multiple objects (ALL and AND keywords).
struct MultipleObjectTests {
    
    // MARK: - EXAMINE Multiple Objects Tests
    
    @Test("EXAMINE ALL works correctly")
    func testExamineAll() async throws {
        let sword = Item(
            id: "sword",
            .name("sword"),
            .in(.location(.startRoom)),
            .description("A sharp blade.")
        )
        let lantern = Item(
            id: "lantern",
            .name("lantern"),
            .in(.location(.startRoom)),
            .description("A bright light.")
        )
        
        let game = MinimalGame(items: [sword, lantern])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "examine all"
        let command = Command(
            verb: .examine,
            directObjects: [.item("sword"), .item("lantern")],
            isAllCommand: true,
            rawInput: "examine all"
        )
        await engine.execute(command: command)
        
        // Assert: Should examine both items
        let output = await mockIO.flush()
        expectNoDifference(output, """
            - Sword: A sharp blade.
            - Lantern: A bright light.
            """)
    }
    
    @Test("EXAMINE SWORD AND LANTERN works correctly")
    func testExamineSwordAndLantern() async throws {
        let sword = Item(
            id: "sword",
            .name("sword"),
            .in(.location(.startRoom)),
            .description("A sharp blade.")
        )
        let lantern = Item(
            id: "lantern",
            .name("lantern"),
            .in(.location(.startRoom)),
            .description("A bright light.")
        )
        
        let game = MinimalGame(items: [sword, lantern])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "examine sword and lantern"
        let command = Command(
            verb: .examine,
            directObjects: [.item("sword"), .item("lantern")],
            isAllCommand: false,
            rawInput: "examine sword and lantern"
        )
        await engine.execute(command: command)
        
        // Assert: Should examine both items
        let output = await mockIO.flush()
        expectNoDifference(output, """
            - Sword: A sharp blade.
            - Lantern: A bright light.
            """)
    }
    
    // MARK: - GIVE Multiple Objects Tests
    
    @Test("GIVE ALL TO MERCHANT works correctly")
    func testGiveAllToMerchant() async throws {
        let coin = Item(
            id: "coin",
            .name("coin"),
            .in(.player)
        )
        let gem = Item(
            id: "gem",
            .name("gem"),
            .in(.player)
        )
        let merchant = Item(
            id: "merchant",
            .name("merchant"),
            .in(.location(.startRoom)),
            .isCharacter
        )
        
        let game = MinimalGame(items: [coin, gem, merchant])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "give all to merchant"
        let command = Command(
            verb: .give,
            directObjects: [.item("coin"), .item("gem")],
            indirectObjects: [.item("merchant")],
            isAllCommand: true,
            rawInput: "give all to merchant"
        )
        await engine.execute(command: command)
        
        // Assert: Should give both items
        let output = await mockIO.flush()
        expectNoDifference(output, "You give the coin and the gem to the merchant.")

        // Verify items moved to merchant
        let updatedCoin = try await engine.item("coin")
        let updatedGem = try await engine.item("gem")
        #expect(updatedCoin.parent == ParentEntity.item("merchant"))
        #expect(updatedGem.parent == ParentEntity.item("merchant"))
    }
    
    @Test("GIVE COIN AND GEM TO MERCHANT works correctly")
    func testGiveCoinAndGemToMerchant() async throws {
        let coin = Item(
            id: "coin",
            .name("coin"),
            .in(.player)
        )
        let gem = Item(
            id: "gem",
            .name("gem"),
            .in(.player)
        )
        let merchant = Item(
            id: "merchant",
            .name("merchant"),
            .in(.location(.startRoom)),
            .isCharacter
        )
        
        let game = MinimalGame(items: [coin, gem, merchant])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "give coin and gem to merchant"
        let command = Command(
            verb: .give,
            directObjects: [.item("coin"), .item("gem")],
            indirectObjects: [.item("merchant")],
            isAllCommand: false,
            rawInput: "give coin and gem to merchant"
        )
        await engine.execute(command: command)
        
        // Assert: Should give both items
        let output = await mockIO.flush()
        expectNoDifference(output, "You give the coin and the gem to the merchant.")

        // Verify items moved to merchant
        let updatedCoin = try await engine.item("coin")
        let updatedGem = try await engine.item("gem")
        #expect(updatedCoin.parent == ParentEntity.item("merchant"))
        #expect(updatedGem.parent == ParentEntity.item("merchant"))
    }
    
    // MARK: - PUT Multiple Objects Tests
    
    @Test("PUT ALL IN BOX works correctly")
    func testPutAllInBox() async throws {
        let coin = Item(
            id: "coin",
            .name("coin"),
            .in(.player)
        )
        let gem = Item(
            id: "gem",
            .name("gem"),
            .in(.player)
        )
        let box = Item(
            id: "box",
            .name("box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpen
        )
        
        let game = MinimalGame(items: [coin, gem, box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "put all in box"
        let command = Command(
            verb: .insert,
            directObjects: [.item("coin"), .item("gem")],
            indirectObjects: [.item("box")],
            isAllCommand: true,
            rawInput: "put all in box"
        )
        await engine.execute(command: command)
        
        // Assert: Should put both items in box
        let output = await mockIO.flush()
        expectNoDifference(output, "You put the coin and the gem in the box.")
        
        // Verify items moved to box
        let updatedCoin = try await engine.item("coin")
        let updatedGem = try await engine.item("gem")
        #expect(updatedCoin.parent == ParentEntity.item("box"))
        #expect(updatedGem.parent == ParentEntity.item("box"))
    }
    
    @Test("PUT COIN AND GEM IN BOX works correctly")
    func testPutCoinAndGemInBox() async throws {
        let coin = Item(
            id: "coin",
            .name("coin"),
            .in(.player)
        )
        let gem = Item(
            id: "gem",
            .name("gem"),
            .in(.player)
        )
        let box = Item(
            id: "box",
            .name("box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpen
        )
        
        let game = MinimalGame(items: [coin, gem, box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "put coin and gem in box"
        let command = Command(
            verb: .insert,
            directObjects: [.item("coin"), .item("gem")],
            indirectObjects: [.item("box")],
            isAllCommand: false,
            rawInput: "put coin and gem in box"
        )
        await engine.execute(command: command)
        
        // Assert: Should put both items in box
        let output = await mockIO.flush()
        expectNoDifference(output, "You put the coin and the gem in the box.")

        // Verify items moved to box
        let updatedCoin = try await engine.item("coin")
        let updatedGem = try await engine.item("gem")
        #expect(updatedCoin.parent == ParentEntity.item("box"))
        #expect(updatedGem.parent == ParentEntity.item("box"))
    }
    
    // MARK: - PUSH Multiple Objects Tests
    
    @Test("PUSH ALL works correctly")
    func testPushAll() async throws {
        let button = Item(
            id: "button",
            .name("button"),
            .in(.location(.startRoom))
        )
        let lever = Item(
            id: "lever",
            .name("lever"),
            .in(.location(.startRoom))
        )
        
        let game = MinimalGame(items: [button, lever])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "push all"
        let command = Command(
            verb: .push,
            directObjects: [.item("button"), .item("lever")],
            isAllCommand: true,
            rawInput: "push all"
        )
        await engine.execute(command: command)
        
        // Assert: Should push both items
        let output = await mockIO.flush()
        expectNoDifference(output, "You push the button and the lever. Nothing happens.")
    }
    
    @Test("PUSH BUTTON AND LEVER works correctly")
    func testPushButtonAndLever() async throws {
        let button = Item(
            id: "button",
            .name("button"),
            .in(.location(.startRoom))
        )
        let lever = Item(
            id: "lever",
            .name("lever"),
            .in(.location(.startRoom))
        )
        
        let game = MinimalGame(items: [button, lever])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "push button and lever"
        let command = Command(
            verb: .push,
            directObjects: [.item("button"), .item("lever")],
            isAllCommand: false,
            rawInput: "push button and lever"
        )
        await engine.execute(command: command)
        
        // Assert: Should push both items
        let output = await mockIO.flush()
        expectNoDifference(output, "You push the button and the lever. Nothing happens.")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Multiple objects with unsupported verb fails gracefully")
    func testMultipleObjectsWithUnsupportedVerb() async throws {
        let sword = Item(
            id: "sword",
            .name("sword"),
            .in(.location(.startRoom))
        )
        let lantern = Item(
            id: "lantern",
            .name("lantern"),
            .in(.location(.startRoom))
        )
        
        let game = MinimalGame(items: [sword, lantern])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Try "open sword and lantern" (OPEN doesn't support multiple objects)
        let command = Command(
            verb: .open,
            directObjects: [.item("sword"), .item("lantern")],
            isAllCommand: false,
            rawInput: "open sword and lantern"
        )
        await engine.execute(command: command)
        
        // Assert: Should get an error about multiple objects not being supported
        let output = await mockIO.flush()
        expectNoDifference(output, "The OPEN command doesn’t support multiple objects.")
    }
    
    @Test("ALL with no applicable items handles gracefully")
    func testAllWithNoApplicableItems() async throws {
        let game = MinimalGame(items: [])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)
        
        // Act: Execute "take all" when there's nothing to take
        let command = Command(
            verb: .take,
            directObjects: [],
            isAllCommand: true,
            rawInput: "take all"
        )
        await engine.execute(command: command)
        
        // Assert: Should get appropriate message
        let output = await mockIO.flush()
        expectNoDifference(output, "There is nothing here to take.")
    }
} 
