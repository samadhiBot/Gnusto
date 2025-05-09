import Testing
import Foundation

@testable import GnustoEngine

@Suite("Item Tests")
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
            description: "A sturdy brass lantern.",
            parent: .player,
            attributes: [
                .adjectives: .stringSet(["brass", "shiny"]),
                .synonyms: .stringSet(["lamp", "light"]),
                .shortDescription: .string("The brass lantern is here."),
                .firstDescription: .string("A shiny brass lantern rests here."),
                .readText: .string("Engraved on the bottom: \"Property of Frobozz Magic Lantern Co.\""),
                .readWhileHeldText: .string("It feels warm."),
                .isTakable: true,
                .isLightSource: true,
                .isOn: true,
                .isOpenable: true,
                .size: .int(10),
                .capacity: .int(5)
            ]
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
        #expect(item.attributes[.shortDescription] == nil)
        #expect(item.attributes[.firstDescription] == nil)
        #expect(item.attributes[.description] == nil)
        #expect(item.attributes[.readText] == nil)
        #expect(item.attributes[.readWhileHeldText] == nil)
        #expect(item.size == 1) // Default size
        #expect(item.capacity == 1000) // Default capacity
        #expect(item.parent == .nowhere) // Check default parent
        #expect(item.attributes[.lockKey] == nil)
    }

    @Test("Item Custom Initialization")
    func testItemCustomInitialization() throws {
        let item = createCustomItem()

        #expect(item.id == "customItem")
        #expect(item.name == "lantern")
        #expect(item.adjectives == ["brass", "shiny"])
        #expect(item.synonyms == ["lamp", "light"])
        #expect(item.attributes[.shortDescription] == .string("The brass lantern is here."))
        #expect(item.attributes[.firstDescription] == .string("A shiny brass lantern rests here."))
        #expect(item.attributes[.description] == .string("A sturdy brass lantern."))
        #expect(item.attributes[.readText] == .string("Engraved on the bottom: \"Property of Frobozz Magic Lantern Co.\""))
        #expect(item.attributes[.readWhileHeldText] == .string("It feels warm."))
        #expect(item.hasFlag(.isTakable))
        #expect(item.hasFlag(.isLightSource))
        #expect(item.hasFlag(.isOn))
        #expect(item.hasFlag(.isOpenable))
        #expect(item.size == 10)
        #expect(item.capacity == 5)
        #expect(item.parent == .player) // Check custom parent
        #expect(item.attributes[.lockKey] == nil)
    }

    @Test("Item Attribute Management")
    func testItemAttributeManagement() throws {
        var item = createDefaultItem()

        #expect(!item.hasFlag(.isTakable))
        #expect(item.attributes.isEmpty) // Default item has no attributes initially

        item.attributes[.isTakable] = true
        #expect(item.hasFlag(.isTakable))
        #expect(item.attributes.count == 1)

        item.attributes[.isTakable] = true // Setting again should have no effect
        #expect(item.attributes.count == 1)

        item.attributes[.isLightSource] = true
        #expect(item.hasFlag(.isLightSource))
        #expect(item.attributes.count == 2)

        item.attributes[.isTakable] = nil // Remove the key
        #expect(!item.hasFlag(.isTakable))
        #expect(item.hasFlag(.isLightSource))
        #expect(item.attributes.count == 1)

        item.attributes[.isTakable] = nil // Removing again should have no effect
        #expect(item.attributes.count == 1)

        item.attributes[.isLightSource] = nil // Remove the other key
        #expect(!item.hasFlag(.isLightSource))
        #expect(item.attributes.isEmpty)
    }

    @Test("Item Codable Conformance")
    func testItemCodable() throws {
        var originalItem = createCustomItem()
        originalItem.attributes[.readText] = .string("Readable text.")
        originalItem.attributes[.lockKey] = "key1"

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys] // For easier debugging
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalItem)
        let decodedItem = try decoder.decode(Item.self, from: jsonData)

        #expect(decodedItem.id == originalItem.id)
        #expect(decodedItem.name == originalItem.name)
        #expect(decodedItem.adjectives == originalItem.adjectives)
        #expect(decodedItem.synonyms == originalItem.synonyms)
        #expect(decodedItem.attributes[.shortDescription] == originalItem.attributes[.shortDescription])
        #expect(decodedItem.attributes[.firstDescription] == originalItem.attributes[.firstDescription])
        #expect(decodedItem.attributes[.description] == originalItem.attributes[.description])
        #expect(decodedItem.attributes[.readText] == originalItem.attributes[.readText])
        #expect(decodedItem.attributes[.readWhileHeldText] == originalItem.attributes[.readWhileHeldText])
        #expect(decodedItem.size == originalItem.size)
        #expect(decodedItem.capacity == originalItem.capacity)
        #expect(decodedItem.parent == originalItem.parent)
        #expect(decodedItem.attributes[.lockKey] == originalItem.attributes[.lockKey])
    }

    @Test("Item Value Semantics")
    func testItemValueSemantics() throws {
        let item1 = createDefaultItem()
        var item2 = item1 // Assign creates a copy for structs

        // Modify the copy (item2)
        item2.name = "modified thing"
        item2.attributes[.isInvisible] = true
        item2.parent = .location("limbo")

        // Assert that the original (item1) is unchanged
        #expect(item1.name == "thing")
        #expect(!item1.hasFlag(.isInvisible))
        #expect(item1.parent == .nowhere)

        // Assert that item2 has the changes
        #expect(item2.name == "modified thing")
        #expect(item2.hasFlag(.isInvisible))
        #expect(item2.parent == .location("limbo"))

        // Assert that item1 and item2 are now different
        #expect(item1 != item2)
    }
}
