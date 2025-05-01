import Testing
import Foundation // For JSONEncoder/Decoder
@testable import GnustoEngine

@Suite("Item Class Tests")
struct ItemTests {

    // --- Test Setup ---
    let defaultItemID: ItemID = "defaultItem"
    let defaultItemName = "thing"

    func createDefaultItem() -> Item {
        // Default parent is .nowhere
        Item(id: defaultItemID, name: defaultItemName)
    }

    func createCustomItem() -> Item {
        // Let's assume this custom item starts directly held by the player
        Item(
            id: "customItem",
            name: "lantern",
            adjectives: "brass", "shiny",
            synonyms: "lamp", "light",
            shortDescription: "The brass lantern is here.",
            firstDescription: "A shiny brass lantern rests here.",
            longDescription: "A sturdy brass lantern.",
            text: "Engraved on the bottom: \"Property of Frobozz Magic Lantern Co.\"",
            heldText: "It feels warm.",
            properties: .takable, .lightSource, .on, .openable,
            size: 10,
            capacity: 5,
            parent: .player
        )
    }

    // --- Tests ---

    @Test("Item Default Initialization")
    func testItemDefaultInitialization() throws {
        let item = createDefaultItem()

        #expect(item.id == defaultItemID)
        #expect(item.name == defaultItemName)
        #expect(item.adjectives.isEmpty)
        #expect(item.synonyms.isEmpty)
        #expect(item.shortDescription == nil)
        #expect(item.firstDescription == nil)
        #expect(item.longDescription == nil)
        #expect(item.text == nil)
        #expect(item.heldText == nil)
        #expect(item.properties.isEmpty)
        #expect(item.size == 5) // ZILF default
        #expect(item.capacity == -1) // ZILF default
        #expect(item.parent == .nowhere) // Check default parent
        #expect(item.readableText == nil)
        #expect(item.lockKey == nil)
    }

    @Test("Item Custom Initialization")
    func testItemCustomInitialization() throws {
        let item = createCustomItem()

        #expect(item.id == "customItem")
        #expect(item.name == "lantern")
        #expect(item.adjectives == ["brass", "shiny"])
        #expect(item.synonyms == ["lamp", "light"])
        #expect(item.shortDescription?.rawStaticDescription == "The brass lantern is here.")
        #expect(item.firstDescription?.rawStaticDescription == "A shiny brass lantern rests here.")
        #expect(item.longDescription?.rawStaticDescription == "A sturdy brass lantern.")
        #expect(item.text == "Engraved on the bottom: \"Property of Frobozz Magic Lantern Co.\"", "Text mismatch")
        #expect(item.heldText == "It feels warm.")
        #expect(item.properties == [.takable, .lightSource, .on, .openable])
        #expect(item.size == 10)
        #expect(item.capacity == 5)
        #expect(item.parent == .player) // Check custom parent
        #expect(item.readableText == nil)
        #expect(item.lockKey == nil)
    }

    @Test("Item Property Management")
    func testItemPropertyManagement() throws {
        var item = createDefaultItem()

        #expect(!item.hasProperty(.takable))

        item.addProperty(.takable)
        #expect(item.hasProperty(.takable))
        #expect(item.properties.count == 1)

        item.addProperty(.takable) // Adding again should have no effect
        #expect(item.properties.count == 1)

        item.addProperty(.lightSource)
        #expect(item.hasProperty(.lightSource))
        #expect(item.properties.count == 2)

        item.removeProperty(.takable)
        #expect(!item.hasProperty(.takable))
        #expect(item.hasProperty(.lightSource))
        #expect(item.properties.count == 1)

        item.removeProperty(.takable) // Removing again should have no effect
        #expect(item.properties.count == 1)

        item.removeProperty(.lightSource)
        #expect(!item.hasProperty(.lightSource))
        #expect(item.properties.isEmpty)
    }

    @Test("Item Codable Conformance")
    func testItemCodable() throws {
        var originalItem = createCustomItem()
        originalItem.readableText = "Readable text."
        originalItem.lockKey = "key1"

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys] // For easier debugging
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalItem)
        let decodedItem = try decoder.decode(Item.self, from: jsonData)

        #expect(decodedItem.id == originalItem.id)
        #expect(decodedItem.name == originalItem.name)
        #expect(decodedItem.adjectives == originalItem.adjectives)
        #expect(decodedItem.synonyms == originalItem.synonyms)
        #expect(decodedItem.shortDescription == originalItem.shortDescription)
        #expect(decodedItem.firstDescription == originalItem.firstDescription)
        #expect(decodedItem.longDescription == originalItem.longDescription)
        #expect(decodedItem.text == originalItem.text)
        #expect(decodedItem.heldText == originalItem.heldText)
        #expect(decodedItem.properties == originalItem.properties)
        #expect(decodedItem.size == originalItem.size)
        #expect(decodedItem.capacity == originalItem.capacity)
        #expect(decodedItem.parent == originalItem.parent)
        #expect(decodedItem.readableText == originalItem.readableText)
        #expect(decodedItem.lockKey == originalItem.lockKey)
    }

    @Test("Item Reference Semantics")
    func testItemReferenceSemantics() throws {
        let item1 = createDefaultItem()
        var item2 = item1 // Assign reference, not a copy

        item2.name = "modified thing"
        item2.addProperty(.invisible)
        item2.parent = .location("limbo") // Modify parent

        #expect(item1.name == "modified thing") // Change in item2 reflects in item1
        #expect(item1.hasProperty(.invisible))
        #expect(item1.parent == .location("limbo")) // Parent change reflects
        #expect(item1 == item2) // Verify they point to the same instance
    }
}
