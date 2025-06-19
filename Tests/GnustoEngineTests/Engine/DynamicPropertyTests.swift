import CustomDump
import Testing

@testable import GnustoEngine

/// Tests for the dynamic property system (compute handlers and state integration).
struct DynamicPropertyTests {

    // MARK: - Basic Get/Set Tests

    @Test("Get/Set Simple Dynamic Item Value")
    func testGetSetSimpleItemValue() async throws {
        let testItem = Item(
            id: "testItem",
            .name("widget"),
            .in(.location("testLocation")),
            .description("A test widget")
        )

        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber"),
            .description("A dark, dark room.")
        )

        let game = MinimalGame(
            locations: [testLocation],
            items: [testItem]
        )
        let (engine, mockIO) = await GameEngine.test()

        // Set initial value through StateChange builder
        let item = try await engine.item("testItem")
        if let change = await engine.setAttribute(.init("simpleProp"), on: item, to: .int(10)) {
            try await engine.apply(change)
        }

        // Get initial value
        let initialValue: Int? = try await engine.attribute("simpleProp", of: "testItem")
        #expect(initialValue == 10)

        // Set new value
        let updatedItem = try await engine.item("testItem")
        if let change = await engine.setAttribute(.init("simpleProp"), on: updatedItem, to: .int(20)) {
            try await engine.apply(change)
        }

        // Verify new value in GameState
        let finalItem = await engine.gameState.items["testItem"]
        #expect(finalItem?.attributes["simpleProp"] == StateValue.int(20))

        // Verify getting the value again works
        let finalValue: Int? = try await engine.attribute("simpleProp", of: "testItem")
        #expect(finalValue == 20)
    }

    // MARK: - Compute Handler Tests

    @Test("Item Compute Handler from GameBlueprint")
    func testGameBlueprintItemComputeHandlersIntegration() async throws {
        let testItem = Item(
            id: "testItem",
            .name("magic sword"),
            .in(.location("testLocation"))
        )

        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber")
        )

        let game = MinimalGame(
            locations: [testLocation],
            items: [testItem],
            itemComputers: [
                "testItem": ItemComputer { attributeID, gameState in
                    switch attributeID {
                    case .description:
                        return .string("This sword glows with magic sword energy!")
                    default:
                        return nil
                    }
                }
            ]
        )
        let (engine, mockIO) = await GameEngine.test()

        // Fetch the dynamic description
        let description: String? = try await engine.attribute(.description, of: ItemID("testItem"))
        #expect(description == "This sword glows with magic sword energy!")
    }

    @Test("Location Compute Handler from GameBlueprint")
    func testGameBlueprintLocationComputeHandlersIntegration() async throws {
        let testLocation = Location(
            id: "testLocation",
            .name("Magic Chamber")
        )

        let game = MinimalGame(
            locations: [testLocation],
            locationComputers: [
                "testLocation": LocationComputer { attributeID, gameState in
                    switch attributeID {
                    case .description:
                        return .string("The Magic Chamber sparkles with mystical energy!")
                    default:
                        return nil
                    }
                }
            ]
        )
        let (engine, mockIO) = await GameEngine.test()

        // Fetch the dynamic description
        let description: String? = try await engine.attribute(.description, of: LocationID("testLocation"))
        #expect(description == "The Magic Chamber sparkles with mystical energy!")
    }

    // MARK: - Look Action Integration Tests

    @Test("Look with Dynamic Item Description")
    func testLookWithDynamicItemDescription() async throws {
        let testItem = Item(
            id: "magicSword",
            .name("magic sword"),
            .in(.player)
        )

        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber"),
            .description("A simple test room.")
        )

        let game = MinimalGame(
            player: Player(in: testLocation.id),
            locations: [testLocation],
            items: [testItem],
            itemComputers: [
                "magicSword": ItemComputer { attributeID, gameState in
                    switch attributeID {
                    case .description:
                        return .string("The blade shimmers with arcane power.")
                    default:
                        return nil
                    }
                }
            ]
        )

        let (engine, mockIO) = await GameEngine.test()

        // Test looking at the item
        let command = Command(
            verb: .look,
            directObject: .item(testItem.id),
            rawInput: "look magic sword"
        )

        // Act
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "The blade shimmers with arcane power.")
    }

    @Test("Look with Dynamic Location Description")
    func testLookWithDynamicLocationDescription() async throws {
        let testLocation = Location(
            id: "testLocation",
            .name("Enchanted Forest"),
            .description("A magical place"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: testLocation.id),
            locations: [testLocation],
            locationComputers: [
                "testLocation": LocationComputer { attributeID, gameState in
                    switch attributeID {
                    case .description:
                        return .string("Ethereal mists dance between towering oaks.")
                    default:
                        return nil
                    }
                }
            ]
        )

        let (engine, mockIO) = await GameEngine.test()

        // Trigger room description
        try await engine.describeCurrentLocation(forceFullDescription: true)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            — Enchanted Forest —

            Ethereal mists dance between towering oaks.
            """)
    }

    // MARK: - Error Handling Tests

    @Test("Compute Handler Error Handling")
    func testComputeHandlerErrorHandling() async throws {
        let testItem = Item(
            id: "testItem",
            .name("broken device"),
            .in(.location("testLocation"))
        )

        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber")
        )

        let game = MinimalGame(
            locations: [testLocation],
            items: [testItem],
            itemComputers: [
                "testItem": ItemComputer { attributeID, gameState in
                    throw ActionResponse.internalEngineError("Test error")
                }
            ]
        )
        let (engine, mockIO) = await GameEngine.test()

        // The compute handler throws an error, so it should fall back to stored value
        // Since there's no stored description, it should return nil and then try the stored value
        // which also doesn't exist, so the attribute fetch should return nil
        let description: String? = try await engine.attribute(.description, of: ItemID("testItem"))
        #expect(description == nil)
    }

    @Test("Non-existent Compute Handler Falls Back to Static")
    func testNonExistentComputeHandlerFallback() async throws {
        let testItem = Item(
            id: "testItem",
            .name("simple widget"),
            .in(.location("testLocation")),
            .description("A basic widget.")
        )

        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber")
        )

        let game = MinimalGame(
            locations: [testLocation],
            items: [testItem]
        )
        let (engine, mockIO) = await GameEngine.test()

        // Should fall back to static description
        let description: String? = try await engine.attribute(.description, of: ItemID("testItem"))
        #expect(description == "A basic widget.")
    }

    // MARK: - Set Location Description

    @Test("Set Location Description")
    func testSetLocationDescription() async throws {
        let testLocation = Location(
            id: "testLocation",
            .name("Test Chamber"),
            .description("Original description")
        )

        let game = MinimalGame(
            locations: [testLocation]
        )
        let (engine, mockIO) = await GameEngine.test()

        // Change description using StateChange builder
        let location = try await engine.location("testLocation")
        if let change = await engine.setDescription(on: location, to: "New dynamic description") {
            try await engine.apply(change)
        }

        // Verify the change
        let finalLocation = await engine.gameState.locations["testLocation"]
        #expect(finalLocation?.attributes[.description] == StateValue.string("New dynamic description"))

        // Verify via attribute access
        let desc: String? = try await engine.attribute(.description, of: LocationID("testLocation"))
        #expect(desc == "New dynamic description")
    }
}
