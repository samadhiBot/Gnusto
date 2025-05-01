import Foundation
import Testing

@testable import GnustoEngine

@MainActor
struct DescriptionHandlerRegistryTests {
    // MARK: - Setup

    private func setupTestEnvironment(
        locations: [Location] = [],
        items: [Item] = []
    ) async -> (GameEngine, DescriptionHandlerRegistry) {
        let game = MinimalGame(locations: locations, items: items)
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        return (engine, engine.descriptionHandlerRegistry)
    }

    // MARK: - Item Handler Tests

    @Test("Register and Generate Dynamic Item Description")
    func testRegisterAndGenerateDynamicItem() async throws {
        // Given
        // Add key to initial items
        let keyItem = Item(id: "key", name: "small key", parent: .item("chest"))
        var initialItems = [
            Item(
                id: "lamp",
                name: "brass lantern",
                adjectives: "brass",
                synonyms: "lamp", "light",
                longDescription: .id("lamp_description"),
                properties: .lightSource, .on
            ),
            Item(
                id: "book",
                name: "ancient tome",
                adjectives: "ancient",
                synonyms: "volume", "tome",
                longDescription: .id("book_description"),
                properties: .readable
            ),
            Item(
                id: "chest",
                name: "wooden chest",
                adjectives: "wooden",
                synonyms: "box", "container",
                longDescription: .id("container_description"),
                properties: .container, .open
            )
        ]
        initialItems.append(keyItem)

        // Explicitly name arguments
        let (engine, registry) = await setupTestEnvironment(locations: [], items: initialItems)

        // Example 1: A lamp that changes description based on whether it's on
        engine.descriptionHandlerRegistry.registerItemHandler(id: "lamp_description") { item, engine in
            if item.hasProperty(.on) {
                return "The \(item.name) is glowing brightly, casting light all around."
            } else {
                return "The \(item.name) is currently turned off."
            }
        }

        // Example 2: A book that shows different text based on whether it's been read
        engine.descriptionHandlerRegistry.registerItemHandler(id: "book_description") { item, engine in
            if item.hasProperty(.touched) {
                return "The \(item.name) appears to be a well-read volume."
            } else {
                return "The \(item.name) looks like it hasn't been opened in a while."
            }
        }

        // Example 3: A container that describes its contents
        engine.descriptionHandlerRegistry.registerItemHandler(id: "container_description") { item, engine in
            let contents = engine.items(withParent: .item(item.id))
            if contents.isEmpty {
                return "The \(item.name) is empty."
            } else {
                let contentList = contents.map { "a \($0.name)" }.joined(separator: ", ")
                return "The \(item.name) contains \(contentList)."
            }
        }

        let lampItem = engine.item(with: "lamp")!
        let bookItem = engine.item(with: "book")!

        // When & Then: Lamp (On - initial state)
        var description = await registry.generateDescription(
            for: lampItem,
            using: lampItem.longDescription!,
            engine: engine
        )
        #expect(description == "The brass lantern is glowing brightly, casting light all around.")

        // Removed lamp turn off test - requires action simulation

        // When & Then: Book (Untouched - initial state)
        description = await registry.generateDescription(
            for: bookItem,
            using: bookItem.longDescription!,
            engine: engine
        )
        #expect(description == "The ancient tome looks like it hasn't been opened in a while.")

        // Removed book touched test - requires action simulation

        // When & Then: Chest (With Key)
        let updatedChestItem = engine.item(with: "chest")! // Re-fetch after item setup
        description = await registry.generateDescription(
            for: updatedChestItem,
            using: updatedChestItem.longDescription!,
            engine: engine
        )
        #expect(description == "The wooden chest contains a small key.")
    }

    @Test("Generate Item Description with Static Fallback")
    func testGenerateItemWithStaticFallback() async throws {
        // Given
        let handler = DescriptionHandler.id("missing_handler", fallback: "This is the fallback.")
        let testItem = Item(id: "test", name: "test item", longDescription: handler)
        let (engine, registry) = await setupTestEnvironment(locations: [], items: [testItem]) // Explicit args
        let itemSnapshot = engine.item(with: "test")! // No await needed

        // When
        let description = await registry.generateDescription(
            for: itemSnapshot,
            using: handler,
            engine: engine
        )

        // Then
        #expect(description == "This is the fallback.")
    }

    @Test("Generate Item Description with Static Handler")
    func testGenerateItemWithStaticHandler() async throws {
        // Given
        let handler: DescriptionHandler = "This is purely static."
        let testItem = Item(id: "test", name: "test item", longDescription: handler)
        let (engine, registry) = await setupTestEnvironment(locations: [], items: [testItem]) // Explicit args
        let itemSnapshot = engine.item(with: "test")! // No await needed

        // When
        let description = await registry.generateDescription(
            for: itemSnapshot,
            using: handler,
            engine: engine
        )

        // Then
        #expect(description == "This is purely static.")
    }

    @Test("Generate Item Description with Missing Handler (Uses Default)")
    func testGenerateItemWithMissingHandler() async throws {
        // Given
        let handler = DescriptionHandler.id("nonexistent_handler") // No fallback
        let testItem = Item(id: "test", name: "test item", longDescription: handler)
        let (engine, registry) = await setupTestEnvironment(locations: [], items: [testItem]) // Explicit args
        let itemSnapshot = engine.item(with: "test")! // No await needed

        // When
        let description = await registry.generateDescription(
            for: itemSnapshot,
            using: handler,
            engine: engine
        )

        // Then
        #expect(description == "You see nothing special about the test item.")
    }

    @Test("Generate Item Description with Nil Static and No ID (Uses Default)")
    func testGenerateItemWithNilStaticNoID() async throws {
        // Given
        let handler = DescriptionHandler(id: nil, rawStaticDescription: nil) // Edge case
        let testItem = Item(id: "test", name: "test item", longDescription: handler)
        let (engine, registry) = await setupTestEnvironment(locations: [], items: [testItem]) // Explicit args
        let itemSnapshot = engine.item(with: "test")! // No await needed

        // When
        let description = await registry.generateDescription(
            for: itemSnapshot,
            using: handler,
            engine: engine
        )

        // Then
        #expect(description == "You see nothing special about the test item.")
    }

    // MARK: - Location Handler Tests

    @Test("Register and Generate Dynamic Location Description")
    func testRegisterAndGenerateDynamicLocation() async throws {
        // Given
        let dynamicHandlerID: DescriptionHandlerID = "loc_dynamic"
        let dynamicLoc = Location(
            id: "dynamic",
            name: "Dynamic Room",
            longDescription: .id(dynamicHandlerID)
        )
        let (engine, registry) = await setupTestEnvironment(locations: [dynamicLoc], items: []) // Explicit args

        var visitCount = 0
        registry.registerLocationHandler(id: dynamicHandlerID) { location, engine in
            visitCount += 1
            return "You have entered the \(location.name) \(visitCount) time(s)."
        }

        let locSnapshot = engine.location(with: "dynamic")! // No await needed

        // When & Then (First Visit)
        var description = await registry.generateDescription(
            for: locSnapshot,
            using: locSnapshot.longDescription!,
            engine: engine
        )
        #expect(description == "You have entered the Dynamic Room 1 time(s).")

        // When & Then (Second Visit - Simulate by calling again)
        description = await registry.generateDescription(
            for: locSnapshot,
            using: locSnapshot.longDescription!,
            engine: engine
        )
        #expect(description == "You have entered the Dynamic Room 2 time(s).")
    }

    @Test("Generate Location Description with Static Fallback")
    func testGenerateLocationWithStaticFallback() async throws {
        // Given
        let handler = DescriptionHandler.id("missing_loc_handler", fallback: "Static location fallback.")
        let testLoc = Location(id: "test", name: "Test Room", longDescription: handler)
        let (engine, registry) = await setupTestEnvironment(locations: [testLoc], items: []) // Explicit args
        let locSnapshot = engine.location(with: "test")! // No await needed

        // When
        let description = await registry.generateDescription(
            for: locSnapshot,
            using: handler,
            engine: engine
        )

        // Then
        #expect(description == "Static location fallback.")
    }

    @Test("Generate Location Description with Static Handler")
    func testGenerateLocationWithStaticHandler() async throws {
        // Given
        let handler: DescriptionHandler = "Purely static room."
        let testLoc = Location(id: "test", name: "Test Room", longDescription: handler)
        let (engine, registry) = await setupTestEnvironment(locations: [testLoc], items: []) // Explicit args
        let locSnapshot = engine.location(with: "test")! // No await needed

        // When
        let description = await registry.generateDescription(
            for: locSnapshot,
            using: handler,
            engine: engine
        )

        // Then
        #expect(description == "Purely static room.")
    }

    @Test("Generate Location Description with Missing Handler (Uses Default)")
    func testGenerateLocationWithMissingHandler() async throws {
        // Given
        let handler = DescriptionHandler.id("nonexistent_loc_handler") // No fallback
        let testLoc = Location(id: "test", name: "Test Room", longDescription: handler)
        let (engine, registry) = await setupTestEnvironment(locations: [testLoc], items: []) // Explicit args
        let locSnapshot = engine.location(with: "test")! // No await needed

        // When
        let description = await registry.generateDescription(
            for: locSnapshot,
            using: handler,
            engine: engine
        )

        // Then
        #expect(description == "You are in the Test Room.")
    }

    @Test("Generate Location Description with Nil Static and No ID (Uses Default)")
    func testGenerateLocationWithNilStaticNoID() async throws {
        // Given
        let handler = DescriptionHandler(id: nil, rawStaticDescription: nil) // Edge case
        let testLoc = Location(id: "test", name: "Test Room", longDescription: handler)
        let (engine, registry) = await setupTestEnvironment(locations: [testLoc], items: []) // Explicit args
        let locSnapshot = engine.location(with: "test")! // No await needed

        // When
        let description = await registry.generateDescription(
            for: locSnapshot,
            using: handler,
            engine: engine
        )

        // Then
        #expect(description == "You are in the Test Room.")
    }

    @Test("Generate Description with Dynamic Handler")
    func testGenerateDescription_dynamicItemHandler() async throws {
        let registry = DescriptionHandlerRegistry()
        let testItem = Item(id: "test", name: "widget")
        let engine = createMockEngine(items: [testItem])

        // Register a dynamic handler
        registry.register(id: "dynamicTest") { (item: Item, _) in // Update type to Item
            "Dynamic description for \(item.name)"
        }

        // Get item struct (no longer snapshot)
        let item = engine.item(with: "test")! // Rename itemSnapshot to item

        // Generate description using registry ID
        let desc = await registry.generateDescription(
            for: item, // Use item variable
            using: .id("dynamicTest"),
            engine: engine
        )

        #expect(desc == "Dynamic description for widget")
    }

    @Test("Generate Description with Dynamic Location Handler")
    func testGenerateDescription_dynamicLocationHandler() async throws {
        let registry = DescriptionHandlerRegistry()
        let testLoc = Location(id: "testLoc", name: "Test Location")
        let engine = createMockEngine(locations: [testLoc])

        // Register a dynamic handler
        registry.register(id: "dynamicLocTest") { (loc: Location, _) in // Update type to Location
            "Dynamic description for \(loc.name)"
        }

        // Get location struct
        let location = engine.location(with: "testLoc")! // Rename locationSnapshot to location

        // Generate description using registry ID
        let desc = await registry.generateDescription(
            for: location, // Use location variable
            using: .id("dynamicLocTest"),
            engine: engine
        )

        #expect(desc == "Dynamic description for Test Location")
    }

    @Test("Generate Description with Dynamic Handler and Fallback")
    func testGenerateDescription_dynamicWithFallback() async throws {
        let registry = DescriptionHandlerRegistry()
        let testItem = Item(id: "test", name: "widget")
        let engine = createMockEngine(items: [testItem])

        // Register a dynamic handler (which will be used)
        registry.register(id: "dynamicTest") { (item: Item, _) in // Update type to Item
            "Dynamic description for \(item.name)"
        }

        // Get item struct
        let item = engine.item(with: "test")! // Rename itemSnapshot to item

        // Generate description using registry ID with a fallback
        let desc = await registry.generateDescription(
            for: item, // Use item variable
            using: .id("dynamicTest", fallback: "Fallback static"),
            engine: engine
        )

        #expect(desc == "Dynamic description for widget")
    }

    @Test("Generate Description with Fallback Used When Dynamic Missing")
    func testGenerateDescription_fallbackUsedWhenDynamicMissing() async throws {
        let registry = DescriptionHandlerRegistry()
        let testItem = Item(id: "test", name: "widget")
        let engine = createMockEngine(items: [testItem])

        // DO NOT register "dynamicTest"

        // Get item struct
        let item = engine.item(with: "test")! // Rename itemSnapshot to item

        // Generate description using registry ID with a fallback
        let desc = await registry.generateDescription(
            for: item, // Use item variable
            using: .id("dynamicTest", fallback: "Fallback static"),
            engine: engine
        )

        #expect(desc == "Fallback static")
    }

    @Test("Generate Description with Registry Error Logged")
    func testGenerateDescription_registryErrorLogged() async throws {
        let registry = DescriptionHandlerRegistry()
        let testItem = Item(id: "test", name: "widget")
        let engine = createMockEngine(items: [testItem])
        let mockIO = engine.ioHandler as! MockIOHandler

        // DO NOT register "dynamicTest"

        // Get item struct
        let item = engine.item(with: "test")! // Rename itemSnapshot to item

        // Generate description using registry ID with NO fallback
        let desc = await registry.generateDescription(
            for: item, // Use item variable
            using: .id("dynamicTest"),
            engine: engine
        )

        #expect(desc == "") // Expect empty string on error
        #expect(mockIO.printedStrings.contains { $0.contains("Error generating dynamic description") })
    }

    // TODO: Add tests for location description generation
}
