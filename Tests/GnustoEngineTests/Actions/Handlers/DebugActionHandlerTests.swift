import Foundation
import Testing
@testable import GnustoEngine

@MainActor
struct DebugActionHandlerTests {
    
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
            ]),
        )
        
        let game = MinimalGame(
            locations: [testLocation],
            items: [testItem]
        )
        
        let mockIO = MockIOHandler()
        let mockParser = MockParser()
        
        return await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
    }
    
    // MARK: - Initialization Tests
    
    @Test("DebugActionHandler initialization works correctly")
    func testInitialization() {
        let handler = DebugActionHandler()
        
        // Should initialize without issues
        #expect(handler is ActionHandler)
    }
    
    // MARK: - Validation Tests
    
    @Test("DEBUG fails with no direct object")
    func testValidationFailsWithNoDirectObject() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        let command = Command(
            verb: "debug",
            rawInput: "debug"
        )
        let context = ActionContext(command: command, engine: engine)
        
        do {
            try await handler.validate(context: context)
            Issue.record("Expected validation to throw an error, but it succeeded.")
        } catch let error as ActionResponse {
            #expect(error == .prerequisiteNotMet("DEBUG requires a direct object to examine."))
        } catch {
            Issue.record("Thrown error was not an ActionResponse: \(error)")
        }
    }
    
    @Test("DEBUG validates player successfully")
    func testValidationSucceedsForPlayer() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        let command = Command(
            verb: "debug",
            directObject: .player,
            rawInput: "debug self"
        )
        let context = ActionContext(command: command, engine: engine)
        
        // Should not throw
        try await handler.validate(context: context)
    }
    
    @Test("DEBUG validates existing item successfully")
    func testValidationSucceedsForExistingItem() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        let command = Command(
            verb: "debug",
            directObject: .item("test_item"),
            rawInput: "debug test_item"
        )
        let context = ActionContext(command: command, engine: engine)
        
        // Should not throw
        try await handler.validate(context: context)
    }
    
    @Test("DEBUG validates existing location successfully")
    func testValidationSucceedsForExistingLocation() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        let command = Command(
            verb: "debug",
            directObject: .location("test_location"),
            rawInput: "debug test_location"
        )
        let context = ActionContext(command: command, engine: engine)
        
        // Should not throw
        try await handler.validate(context: context)
    }
    
    @Test("DEBUG fails for non-existent item")
    func testValidationFailsForNonExistentItem() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        let command = Command(
            verb: "debug",
            directObject: .item("nonexistent_item"),
            rawInput: "debug nonexistent_item"
        )
        let context = ActionContext(command: command, engine: engine)
        
        do {
            try await handler.validate(context: context)
            Issue.record("Expected validation to throw an error, but it succeeded.")
        } catch let error as ActionResponse {
            #expect(error == .unknownEntity(.item("nonexistent_item")))
        } catch {
            Issue.record("Thrown error was not an ActionResponse: \(error)")
        }
    }
    
    @Test("DEBUG fails for non-existent location")
    func testValidationFailsForNonExistentLocation() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        let command = Command(
            verb: "debug",
            directObject: .location("nonexistent_location"),
            rawInput: "debug nonexistent_location"
        )
        let context = ActionContext(command: command, engine: engine)
        
        do {
            try await handler.validate(context: context)
            Issue.record("Expected validation to throw an error, but it succeeded.")
        } catch let error as ActionResponse {
            #expect(error == .unknownEntity(.location("nonexistent_location")))
        } catch {
            Issue.record("Thrown error was not an ActionResponse: \(error)")
        }
    }
    
    // MARK: - Processing Tests
    
    @Test("DEBUG player produces formatted output")
    func testProcessPlayerDebug() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        let command = Command(
            verb: "debug",
            directObject: .player,
            rawInput: "debug self"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            """)

        // Should contain markdown code block
        #expect(result.message.contains("```"))
        #expect(result.message.contains("Player"))
        
        // Should contain some player properties
        #expect(result.message.contains("location") || result.message.contains("score") || result.message.contains("moves"))
    }
    
    @Test("DEBUG item produces formatted output")
    func testProcessItemDebug() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        let command = Command(
            verb: "debug",
            directObject: .item("test_item"),
            rawInput: "debug test_item"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            """)

        // Should contain markdown code block
        #expect(result.message.contains("```"))
        #expect(result.message.contains("Item"))
        
        // Should contain item properties
        #expect(result.message.contains("test_item") || result.message.contains("id"))
        #expect(result.message.contains("test item") || result.message.contains("name"))
    }
    
    @Test("DEBUG location produces formatted output")
    func testProcessLocationDebug() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        let command = Command(
            verb: "debug",
            directObject: .location("test_location"),
            rawInput: "debug test_location"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            """)

        // Should contain markdown code block
        #expect(result.message.contains("```"))
        #expect(result.message.contains("Location"))
        
        // Should contain location properties
        #expect(result.message.contains("test_location") || result.message.contains("id"))
        #expect(result.message.contains("Test Location") || result.message.contains("name"))
    }
    
    @Test("DEBUG process fails with no direct object")
    func testProcessFailsWithNoDirectObject() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        let command = Command(
            verb: "debug",
            rawInput: "debug"
        )
        let context = ActionContext(command: command, engine: engine)
        
        do {
            let _ = try await handler.process(context: context)
            Issue.record("Expected process to throw an error, but it succeeded.")
        } catch let error as ActionResponse {
            #expect(error == .prerequisiteNotMet("DEBUG requires a direct object."))
        } catch {
            Issue.record("Thrown error was not an ActionResponse: \(error)")
        }
    }
    
    @Test("DEBUG process fails for non-existent item in snapshot")
    func testProcessFailsForNonExistentItemInSnapshot() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        let command = Command(
            verb: "debug",
            directObject: .item("nonexistent_item"),
            rawInput: "debug nonexistent_item"
        )
        let context = ActionContext(command: command, engine: engine)
        
        do {
            let _ = try await handler.process(context: context)
            Issue.record("Expected process to throw an error, but it succeeded.")
        } catch let error as ActionResponse {
            #expect(error == .unknownEntity(.item("nonexistent_item")))
        } catch {
            Issue.record("Thrown error was not an ActionResponse: \(error)")
        }
    }
    
    @Test("DEBUG process fails for non-existent location in snapshot")
    func testProcessFailsForNonExistentLocationInSnapshot() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        let command = Command(
            verb: "debug",
            directObject: .location("nonexistent_location"),
            rawInput: "debug nonexistent_location"
        )
        let context = ActionContext(command: command, engine: engine)
        
        do {
            let _ = try await handler.process(context: context)
            Issue.record("Expected process to throw an error, but it succeeded.")
        } catch let error as ActionResponse {
            #expect(error == .unknownEntity(.location("nonexistent_location")))
        } catch {
            Issue.record("Thrown error was not an ActionResponse: \(error)")
        }
    }
    
    // MARK: - Integration Tests
    
    @Test("DEBUG command full workflow for player")
    func testFullWorkflowForPlayer() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        let command = Command(
            verb: "debug",
            directObject: .player,
            rawInput: "debug self"
        )
        let context = ActionContext(command: command, engine: engine)
        
        // Validate
        try await handler.validate(context: context)
        
        // Process
        let result = try await handler.process(context: context)
        
        // Verify result
        #expect(result.message.contains("```"))
        #expect(result.stateChanges.isEmpty) // DEBUG should not modify state
        #expect(result.sideEffects.isEmpty) // DEBUG should not have side effects
    }
    
    @Test("DEBUG command full workflow for item")
    func testFullWorkflowForItem() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        let command = Command(
            verb: "debug",
            directObject: .item("test_item"),
            rawInput: "debug test_item"
        )
        let context = ActionContext(command: command, engine: engine)
        
        // Validate
        try await handler.validate(context: context)
        
        // Process
        let result = try await handler.process(context: context)
        
        // Verify result
        #expect(result.message.contains("```"))
        #expect(result.stateChanges.isEmpty) // DEBUG should not modify state
        #expect(result.sideEffects.isEmpty) // DEBUG should not have side effects
    }
    
    @Test("DEBUG command full workflow for location")
    func testFullWorkflowForLocation() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        let command = Command(
            verb: "debug",
            directObject: .location("test_location"),
            rawInput: "debug test_location"
        )
        let context = ActionContext(command: command, engine: engine)
        
        // Validate
        try await handler.validate(context: context)
        
        // Process
        let result = try await handler.process(context: context)
        
        // Verify result
        #expect(result.message.contains("```"))
        #expect(result.stateChanges.isEmpty) // DEBUG should not modify state
        #expect(result.sideEffects.isEmpty) // DEBUG should not have side effects
    }
    
    // MARK: - Output Format Tests
    
    @Test("DEBUG output is properly formatted with code blocks")
    func testOutputFormatting() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        let command = Command(
            verb: "debug",
            directObject: .player,
            rawInput: "debug self"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            """)

        // Should start and end with code block markers
        #expect(result.message.hasPrefix("```"))
        #expect(result.message.hasSuffix("```"))
        
        // Should have content between the markers
        let content = result.message.dropFirst(3).dropLast(3)
        #expect(!content.isEmpty)
    }
    
    @Test("DEBUG output contains meaningful entity data")
    func testOutputContainsMeaningfulData() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        // Test item debug
        let itemCommand = Command(
            verb: "debug",
            directObject: .item("test_item"),
            rawInput: "debug test_item"
        )
        let itemContext = ActionContext(command: itemCommand, engine: engine)
        let itemResult = try await handler.process(context: itemContext)
        
        // Should contain item-specific data
        #expect(itemResult.message.contains("test_item") || itemResult.message.contains("id"))
        #expect(itemResult.message.contains("takable") || itemResult.message.contains("properties"))
        
        // Test location debug
        let locationCommand = Command(
            verb: "debug",
            directObject: .location("test_location"),
            rawInput: "debug test_location"
        )
        let locationContext = ActionContext(command: locationCommand, engine: engine)
        let locationResult = try await handler.process(context: locationContext)
        
        // Should contain location-specific data
        #expect(locationResult.message.contains("test_location") || locationResult.message.contains("id"))
        #expect(locationResult.message.contains("north") || locationResult.message.contains("exits"))
    }
    
    // MARK: - Edge Cases
    
    @Test("DEBUG works with item that has complex properties")
    func testDebugComplexItem() async throws {
        let complexItem = Item(
            id: "complex_item",
            name: "complex item",
            longDescription: "A complex item with many properties.",
            properties: [.takable, .wearable, .openable, .container],
            size: 10,
            capacity: 5,
            parent: .location("test_location")
        )
        
        let game = MinimalGame(items: [complexItem])
        let mockIO = MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        
        let handler = DebugActionHandler()
        let command = Command(
            verb: "debug",
            directObject: .item("complex_item"),
            rawInput: "debug complex_item"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            """)

        // Should contain complex item data
        #expect(result.message.contains("```"))
        #expect(result.message.contains("complex_item"))
        
        // Should show various properties
        let hasProperties = result.message.contains("takable") || 
                           result.message.contains("wearable") || 
                           result.message.contains("openable") || 
                           result.message.contains("container")
        #expect(hasProperties)
    }
    
    @Test("DEBUG works with location that has complex exits")
    func testDebugComplexLocation() async throws {
        let complexLocation = Location(
            id: "complex_location",
            name: "Complex Location",
            description: "A location with multiple exits and properties.",
            exits: [
                .north: Exit(destination: "north_room"),
                .south: Exit(destination: "south_room", blockedMessage: "The door is locked."),
                .east: Exit(destination: "east_room", isLocked: true),
                .west: Exit(destination: "west_room")
            ],
            properties: .inherentlyLit
        )
        
        let game = MinimalGame(locations: [complexLocation])
        let mockIO = MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        
        let handler = DebugActionHandler()
        let command = Command(
            verb: "debug",
            directObject: .location("complex_location"),
            rawInput: "debug complex_location"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            """)

        // Should contain complex location data
        #expect(result.message.contains("```"))
        #expect(result.message.contains("complex_location"))
        
        // Should show exits
        let hasExits = result.message.contains("north") || 
                      result.message.contains("south") || 
                      result.message.contains("east") || 
                      result.message.contains("west")
        #expect(hasExits)
    }
    
    @Test("DEBUG works with player that has modified state")
    func testDebugModifiedPlayer() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        // Modify player state
        let scoreChange = StateChange(
            entityId: .player,
            propertyKey: .playerScore,
            newValue: .int(100)
        )
        try engine.gameState.apply(scoreChange)
        
        let movesChange = StateChange(
            entityId: .player,
            propertyKey: .playerMoves,
            newValue: .int(50)
        )
        try engine.gameState.apply(movesChange)
        
        let command = Command(
            verb: "debug",
            directObject: .player,
            rawInput: "debug self"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            """)
        
        // Should contain modified player data
        #expect(result.message.contains("```"))
        
        // Should show modified values (though exact format depends on customDump)
        let hasModifiedData = result.message.contains("100") || result.message.contains("50")
        #expect(hasModifiedData)
    }
    
    // MARK: - Error Consistency Tests
    
    @Test("DEBUG validation and process errors are consistent")
    func testValidationAndProcessErrorConsistency() async throws {
        let handler = DebugActionHandler()
        let engine = await createTestEngine()

        // Test with non-existent item
        let command = Command(
            verb: "debug",
            directObject: .item("nonexistent"),
            rawInput: "debug nonexistent"
        )
        let context = ActionContext(command: command, engine: engine)
        
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
