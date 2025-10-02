import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("Item Tests")
struct ItemTests {

    // MARK: - Test Setup

    let defaultItemID: ItemID = "defaultItem"
    let defaultItemName = "thing"

    func createDefaultItem() -> Item {
        Item(defaultItemID)
            .name(defaultItemName)
    }

    func createCustomItem() -> Item {
        Item("customItem")
            .adjectives("brass", "shiny")
            .capacity(5)
            .description("A sturdy brass lantern.")
            .firstDescription("A shiny brass lantern rests here.")
            .in(.player)
            .isLightSource
            .isOn
            .isOpenable
            .isTakable
            .name("lantern")
            .readText("Engraved on the bottom: \"Property of Frobozz Magic Lantern Co.\"")
            .readWhileHeldText("It feels warm.")
            .shortDescription("The brass lantern is here.")
            .size(10)
            .synonyms("lamp", "light")
    }

    // MARK: - Core Struct Tests

    @Test("Item Default Initialization")
    func testItemDefaultInitialization() throws {
        let item = createDefaultItem()

        #expect(item.id == defaultItemID)
        #expect(item.properties[.name]?.toString == defaultItemName)
        #expect(item.properties[.adjectives] == nil)  // Not set, so nil
        #expect(item.properties[.synonyms] == nil)  // Not set, so nil
        #expect(item.properties[.shortDescription] == nil)
        #expect(item.properties[.firstDescription] == nil)
        #expect(item.properties[.description] == nil)
        #expect(item.properties[.readText] == nil)
        #expect(item.properties[.readWhileHeldText] == nil)
        #expect(item.properties[.size] == nil)  // Not set, so nil
        #expect(item.properties[.capacity] == nil)  // Not set, so nil
        #expect(item.properties[.parentEntity] == nil)  // Not set, so nil
        #expect(item.properties[.lockKey] == nil)
    }

    @Test("Item Custom Initialization")
    func testItemCustomInitialization() throws {
        let item = createCustomItem()

        #expect(item.id == "customItem")
        #expect(item.properties[.name]?.toString == "lantern")
        #expect(item.properties[.adjectives]?.toStrings == ["brass", "shiny"])
        #expect(item.properties[.synonyms]?.toStrings == ["lamp", "light"])
        #expect(item.properties[.shortDescription] == .string("The brass lantern is here."))
        #expect(item.properties[.firstDescription] == .string("A shiny brass lantern rests here."))
        #expect(item.properties[.description] == .string("A sturdy brass lantern."))
        #expect(
            item.properties[.readText]
                == .string("Engraved on the bottom: \"Property of Frobozz Magic Lantern Co.\""))
        #expect(item.properties[.readWhileHeldText] == .string("It feels warm."))
        #expect(item.properties[.isTakable]?.toBool == true)
        #expect(item.properties[.isLightSource]?.toBool == true)
        #expect(item.properties[.isOn]?.toBool == true)
        #expect(item.properties[.isOpenable]?.toBool == true)
        #expect(item.properties[.size] == 10)
        #expect(item.properties[.capacity] == 5)
        #expect(item.properties[.lockKey] == nil)
    }

    @Test("Item Property Management")
    func testItemPropertyManagement() throws {
        var item = createDefaultItem()

        #expect(item.properties[.isTakable] == nil)  // Not set, so nil
        #expect(item.properties == [.name: "thing"])

        item.properties[.isTakable] = true
        #expect(item.properties[.isTakable]?.toBool == true)
        #expect(
            item.properties == [
                .name: "thing",
                .isTakable: true,
            ])

        item.properties[.isTakable] = true  // Setting again should have no effect
        #expect(
            item.properties == [
                .name: "thing",
                .isTakable: true,
            ])

        item.properties[.isLightSource] = true
        #expect(item.properties[.isLightSource]?.toBool == true)
        #expect(
            item.properties == [
                .name: "thing",
                .isTakable: true,
                .isLightSource: true,
            ])

        item.properties[.isTakable] = nil  // Remove the key
        #expect(item.properties[.isTakable] == nil)  // Now nil
        #expect(item.properties[.isLightSource]?.toBool == true)
        #expect(
            item.properties == [
                .name: "thing",
                .isLightSource: true,
            ])

        item.properties[.isTakable] = nil  // Removing again should have no effect
        #expect(
            item.properties == [
                .name: "thing",
                .isLightSource: true,
            ])

        item.properties[.isLightSource] = nil  // Remove the other key
        #expect(item.properties[.isLightSource] == nil)  // Now nil
        #expect(item.properties == [.name: "thing"])
    }

    @Test("Item Codable Conformance")
    func testItemCodable() throws {
        var originalItem = createCustomItem()
        originalItem.properties[.readText] = .string("Readable text.")
        originalItem.properties[.lockKey] = "key1"

        let encoder = JSONEncoder.sorted()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]  // For easier debugging
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalItem)
        let decodedItem = try decoder.decode(Item.self, from: jsonData)

        #expect(decodedItem.id == originalItem.id)
        #expect(decodedItem.properties[.name] == originalItem.properties[.name])
        #expect(decodedItem.properties[.adjectives] == originalItem.properties[.adjectives])
        #expect(decodedItem.properties[.synonyms] == originalItem.properties[.synonyms])
        #expect(
            decodedItem.properties[.shortDescription] == originalItem.properties[.shortDescription])
        #expect(
            decodedItem.properties[.firstDescription] == originalItem.properties[.firstDescription])
        #expect(decodedItem.properties[.description] == originalItem.properties[.description])
        #expect(decodedItem.properties[.readText] == originalItem.properties[.readText])
        #expect(
            decodedItem.properties[.readWhileHeldText]
                == originalItem.properties[.readWhileHeldText])
        #expect(decodedItem.properties[.size] == originalItem.properties[.size])
        #expect(decodedItem.properties[.capacity] == originalItem.properties[.capacity])
        #expect(decodedItem.properties[.parentEntity] == originalItem.properties[.parentEntity])
        #expect(decodedItem.properties[.lockKey] == originalItem.properties[.lockKey])
    }

    @Test("Item Value Semantics")
    func testItemValueSemantics() throws {
        let item1 = createDefaultItem()
        var item2 = item1  // Assign creates a copy for structs

        // Modify the copy (item2)
        item2.properties[.name] = "modified thing"
        item2.properties[.isInvisible] = true
        item2.properties[.parentEntity] = .parentEntity(.location("limbo"))

        // Assert that the original (item1) is unchanged
        #expect(item1.properties[.name]?.toString == "thing")
        #expect(item1.properties[.isInvisible] == nil)  // Not set, so nil
        #expect(item1.properties[.parentEntity] == nil)  // Not set, so nil

        // Assert that item2 has the changes
        #expect(item2.properties[.name]?.toString == "modified thing")
        #expect(item2.properties[.isInvisible]?.toBool == true)
        #expect(item2.properties[.parentEntity]?.toParentEntity == .location("limbo"))

        // Assert that item1 and item2 are now different
        #expect(item1 != item2)
    }

    // MARK: - Proxy Integration Tests

    @Test("ItemProxy provides access to static properties")
    func testItemProxyStaticProperties() async throws {
        let item = createCustomItem()
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let proxy = await engine.item("customItem")

        // Test that proxy correctly accesses static properties
        #expect(proxy.id == "customItem")

        let nameValue = await proxy.property(.name)
        #expect(nameValue?.toString == "lantern")

        let sizeValue = await proxy.property(.size)
        #expect(sizeValue == 10)

        let isTakableValue = await proxy.property(.isTakable)
        #expect(isTakableValue?.toBool == true)
    }

    @Test("ItemProxy equality and hashing")
    func testItemProxyEqualityAndHashing() async throws {
        let item1 = Item("item1")
            .name("First Item")

        let item2 = Item("item2")
            .name("Second Item")

        let game = MinimalGame(items: item1, item2)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let proxy1a = await engine.item("item1")
        let proxy1b = await engine.item("item1")  // Same item, different proxy instances
        let proxy2 = await engine.item("item2")

        // Test equality - same item should be equal
        #expect(proxy1a == proxy1b)  // Same item, different proxy instances
        #expect(proxy1a != proxy2)  // Different items

        // Test hashing - same items should hash the same
        var hasher1a = Hasher()
        proxy1a.hash(into: &hasher1a)

        var hasher1b = Hasher()
        proxy1b.hash(into: &hasher1b)

        var hasher2 = Hasher()
        proxy2.hash(into: &hasher2)

        #expect(hasher1a.finalize() == hasher1b.finalize())
        #expect(hasher1a.finalize() != hasher2.finalize())
    }

    @Test("ItemProxy handles missing properties gracefully")
    func testItemProxyMissingProperties() async throws {
        let item = Item("minimal")
            .name("Minimal Item")

        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let proxy = await engine.item("minimal")

        // Test that proxy returns nil for unset properties
        let descriptionValue = await proxy.property(.description)
        #expect(descriptionValue == nil)

        let capacityValue = await proxy.property(.capacity)
        #expect(capacityValue == nil)  // Not set, so nil

        let isTakableValue = await proxy.property(.isTakable)
        #expect(isTakableValue == nil)  // Not set, so nil
    }

    @Test("ItemProxy comparison and sorting")
    func testItemProxyComparison() async throws {
        let itemA = Item("apple")
            .name("Apple")

        let itemB = Item("banana")
            .name("Banana")

        let itemC = Item("cherry")
            .name("Cherry")

        let game = MinimalGame(items: itemA, itemB, itemC)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let proxyA = await engine.item("apple")
        let proxyB = await engine.item("banana")
        let proxyC = await engine.item("cherry")

        // Test comparison based on ID
        #expect(proxyA < proxyB)
        #expect(proxyB < proxyC)
        #expect(proxyA < proxyC)

        // Test sorting
        let unsorted = [proxyC, proxyA, proxyB]
        let sorted = unsorted.sorted()
        #expect(sorted.map(\.id.rawValue) == ["apple", "banana", "cherry"])
    }
}
