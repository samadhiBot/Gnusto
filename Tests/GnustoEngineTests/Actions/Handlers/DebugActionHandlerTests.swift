import CustomDump
import Testing
@testable import GnustoEngine

@Suite("DebugActionHandler Tests")
struct DebugActionHandlerTests {
    let handler = DebugActionHandler()

    // MARK: - Setup Helper
    
    private func createTestEngine() async -> GameEngine {
        let testItem = Item(
            id: "test_item",
            .name("test item"),
            .description("A test item for debugging."),
            .isTakable,
            .in(.player)
        )
        
        let testLocation = Location(
            id: "test_location",
            .name("Test Location"),
            .description("A test location for debugging."),
            .exits([
                .north: .to("other_location")
            ])
        )
        
        let game = MinimalGame(
            locations: [testLocation],
            items: [testItem]
        )
        
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        
        return await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
    }
    
    // MARK: - Validation Tests
    
    @Test("DEBUG fails with no direct object")
    func testValidationFailsWithNoDirectObject() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .debug,
            rawInput: "debug"
        )

        // Act & Assert Error
        await #expect(throws: ActionResponse.prerequisiteNotMet("DEBUG requires a direct object to examine.")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: await engine.gameState
                )
            )
        }
    }
    
    @Test("DEBUG validates player successfully")
    func testValidationSucceedsForPlayer() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .debug,
            directObject: .player,
            rawInput: "debug self"
        )

        // Should not throw
        try await handler.validate(
            context: ActionContext(
                command: command,
                engine: engine,
                stateSnapshot: await engine.gameState
            )
        )
    }
    
    @Test("DEBUG validates existing item successfully")
    func testValidationSucceedsForExistingItem() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .debug,
            directObject: .item("test_item"),
            rawInput: "debug test_item"
        )

        // Should not throw
        try await handler.validate(
            context: ActionContext(
                command: command,
                engine: engine,
                stateSnapshot: await engine.gameState
            )
        )
    }
    
    @Test("DEBUG validates existing location successfully")
    func testValidationSucceedsForExistingLocation() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .debug,
            directObject: .location("test_location"),
            rawInput: "debug test_location"
        )

        // Should not throw
        try await handler.validate(
            context: ActionContext(
                command: command,
                engine: engine,
                stateSnapshot: await engine.gameState
            )
        )
    }
    
    @Test("DEBUG fails for non-existent item")
    func testValidationFailsForNonExistentItem() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .debug,
            directObject: .item("nonexistent_item"),
            rawInput: "debug nonexistent_item"
        )

        // Act & Assert Error
        await #expect(throws: ActionResponse.unknownEntity(.item("nonexistent_item"))) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: await engine.gameState
                )
            )
        }
    }
    
    @Test("DEBUG fails for non-existent location")
    func testValidationFailsForNonExistentLocation() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .debug,
            directObject: .location("nonexistent_location"),
            rawInput: "debug nonexistent_location"
        )

        // Act & Assert Error
        await #expect(throws: ActionResponse.unknownEntity(.location("nonexistent_location"))) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: await engine.gameState
                )
            )
        }
    }
    
    // MARK: - Processing Tests
    
    @Test("DEBUG player produces formatted output")
    func testProcessPlayerDebug() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        let command = Command(
            verb: .debug,
            directObject: .player,
            rawInput: "debug self"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        
        // Should contain markdown code block and player data
        #expect(output.contains("```"))
        #expect(output.contains("Player") || output.contains("player"))
    }
    
    @Test("DEBUG item produces formatted output")
    func testProcessItemDebug() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        let command = Command(
            verb: .debug,
            directObject: .item("test_item"),
            rawInput: "debug test_item"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        
        // Should contain markdown code block and item data
        #expect(output.contains("```"))
        #expect(output.contains("test_item") || output.contains("Item"))
    }
    
    @Test("DEBUG location produces formatted output")
    func testProcessLocationDebug() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        let command = Command(
            verb: .debug,
            directObject: .location("test_location"),
            rawInput: "debug test_location"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        
        // Should contain markdown code block and location data
        #expect(output.contains("```"))
        #expect(output.contains("test_location") || output.contains("Location"))
    }
    
    @Test("DEBUG process fails with no direct object")
    func testProcessFailsWithNoDirectObject() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .debug,
            rawInput: "debug"
        )

        // Act & Assert Error
        await #expect(throws: ActionResponse.prerequisiteNotMet("DEBUG requires a direct object.")) {
            try await handler.process(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: await engine.gameState
                )
            )
        }
    }
    
    @Test("DEBUG process fails for non-existent item in snapshot")
    func testProcessFailsForNonExistentItemInSnapshot() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .debug,
            directObject: .item("nonexistent_item"),
            rawInput: "debug nonexistent_item"
        )

        // Act & Assert Error
        await #expect(throws: ActionResponse.unknownEntity(.item("nonexistent_item"))) {
            try await handler.process(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: await engine.gameState
                )
            )
        }
    }
    
    @Test("DEBUG process fails for non-existent location in snapshot")
    func testProcessFailsForNonExistentLocationInSnapshot() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .debug,
            directObject: .location("nonexistent_location"),
            rawInput: "debug nonexistent_location"
        )

        // Act & Assert Error
        await #expect(throws: ActionResponse.unknownEntity(.location("nonexistent_location"))) {
            try await handler.process(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: await engine.gameState
                )
            )
        }
    }
    
    // MARK: - Integration Tests
    
    @Test("DEBUG command full workflow for player")
    func testFullWorkflowForPlayer() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .debug,
            directObject: .player,
            rawInput: "debug self"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )
        
        // Validate
        try await handler.validate(context: context)
        
        // Process
        let result = try await handler.process(context: context)
        
        // Verify result
        #expect(result.message?.contains("```") == true)
        #expect(result.stateChanges.isEmpty) // DEBUG should not modify state
        #expect(result.sideEffects.isEmpty) // DEBUG should not have side effects
    }
    
    @Test("DEBUG command full workflow for item")
    func testFullWorkflowForItem() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .debug,
            directObject: .item("test_item"),
            rawInput: "debug test_item"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )
        
        // Validate
        try await handler.validate(context: context)
        
        // Process
        let result = try await handler.process(context: context)
        
        // Verify result
        #expect(result.message?.contains("```") == true)
        #expect(result.stateChanges.isEmpty) // DEBUG should not modify state
        #expect(result.sideEffects.isEmpty) // DEBUG should not have side effects
    }
    
    @Test("DEBUG command full workflow for location")
    func testFullWorkflowForLocation() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .debug,
            directObject: .location("test_location"),
            rawInput: "debug test_location"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )
        
        // Validate
        try await handler.validate(context: context)
        
        // Process
        let result = try await handler.process(context: context)
        
        // Verify result
        #expect(result.message?.contains("```") == true)
        #expect(result.stateChanges.isEmpty) // DEBUG should not modify state
        #expect(result.sideEffects.isEmpty) // DEBUG should not have side effects
    }
    
    // MARK: - Output Format Tests
    
    @Test("DEBUG output is properly formatted with code blocks")
    func testOutputFormatting() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .debug,
            directObject: .player,
            rawInput: "debug self"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )

        let result = try await handler.process(context: context)

        // Should start and end with code block markers
        #expect(result.message?.hasPrefix("```") == true)
        #expect(result.message?.hasSuffix("```") == true)
        
        // Should have content between the markers
        let content = result.message?.dropFirst(3).dropLast(3)
        #expect(content?.isEmpty == false)
    }
    
    @Test("DEBUG output contains meaningful entity data")
    func testOutputContainsMeaningfulData() async throws {
        let engine = await createTestEngine()

        // Test item debug
        let itemCommand = Command(
            verb: .debug,
            directObject: .item("test_item"),
            rawInput: "debug test_item"
        )
        let itemContext = ActionContext(
            command: itemCommand,
            engine: engine,
            stateSnapshot: await engine.gameState
        )
        let itemResult = try await handler.process(context: itemContext)
        
        // Should contain item-specific data
        #expect(itemResult.message?.contains("test_item") == true || itemResult.message?.contains("id") == true)
        
        // Test location debug
        let locationCommand = Command(
            verb: .debug,
            directObject: .location("test_location"),
            rawInput: "debug test_location"
        )
        let locationContext = ActionContext(
            command: locationCommand,
            engine: engine,
            stateSnapshot: await engine.gameState
        )
        let locationResult = try await handler.process(context: locationContext)
        
        // Should contain location-specific data
        #expect(locationResult.message?.contains("test_location") == true || locationResult.message?.contains("id") == true)
    }
    
    // MARK: - Edge Cases
    
    @Test("DEBUG works with item that has complex properties")
    func testDebugComplexItem() async throws {
        let complexItem = Item(
            id: "complex_item",
            .name("complex item"),
            .description("A complex item with many properties."),
            .isTakable,
            .isWearable,
            .isOpenable,
            .isContainer,
            .size(10),
            .capacity(5),
            .in(.location("test_location"))
        )
        
        let game = MinimalGame(items: [complexItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        
        let command = Command(
            verb: .debug,
            directObject: .item("complex_item"),
            rawInput: "debug complex_item"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()

        // Should contain complex item data
        #expect(output.contains("```"))
        #expect(output.contains("complex_item"))
    }
    
    @Test("DEBUG works with location that has complex exits")
    func testDebugComplexLocation() async throws {
        let complexLocation = Location(
            id: "complex_location",
            .name("Complex Location"),
            .description("A location with multiple exits and properties."),
            .exits([
                .north: .to("north_room"),
                .south: .to("south_room"),
                .east: .to("east_room"),
                .west: .to("west_room")
            ]),
            .inherentlyLit
        )
        
        let game = MinimalGame(locations: [complexLocation])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        
        let command = Command(
            verb: .debug,
            directObject: .location("complex_location"),
            rawInput: "debug complex_location"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()

        // Should contain complex location data
        #expect(output.contains("```"))
        #expect(output.contains("complex_location"))
    }
    
    @Test("DEBUG works with player that has modified state")
    func testDebugModifiedPlayer() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        // Modify player state
        let scoreChange = StateChange(
            entityID: .player,
            attribute: .playerScore,
            newValue: 100
        )
        try await engine.apply(scoreChange)
        
        let movesChange = StateChange(
            entityID: .player,
            attribute: .playerMoves,
            newValue: 50
        )
        try await engine.apply(movesChange)
        
        let command = Command(
            verb: .debug,
            directObject: .player,
            rawInput: "debug self"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        
        // Should contain player data
        #expect(output.contains("```"))
        #expect(output.contains("Player") || output.contains("player"))
    }
    
    // MARK: - Error Consistency Tests
    
    @Test("DEBUG validation and process errors are consistent")
    func testValidationAndProcessErrorConsistency() async throws {
        let engine = await createTestEngine()

        // Test with non-existent item
        let command = Command(
            verb: .debug,
            directObject: .item("nonexistent"),
            rawInput: "debug nonexistent"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )
        
        var validationError: ActionResponse?
        var processError: ActionResponse?
        
        // Capture validation error
        do {
            try await handler.validate(context: context)
        } catch let error as ActionResponse {
            validationError = error
        }
        
        // Capture process error
        do {
            let _ = try await handler.process(context: context)
        } catch let error as ActionResponse {
            processError = error
        }
        
        // Both should fail with the same error type
        #expect(validationError == .unknownEntity(.item("nonexistent")))
        #expect(processError == .unknownEntity(.item("nonexistent")))
    }
} 
