import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ItemProxy Tests")
struct ItemProxyTests {

    // MARK: - Core Functionality Tests

    @Test("ItemProxy basic creation and identity")
    func testItemProxyBasics() async throws {
        // Given
        let testItem = Item("testItem")
            .name("test item")
            .description("A test item for proxy testing.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let proxy = await engine.item("testItem")

        // Then
        #expect(proxy.id == "testItem")
    }

    @Test("ItemProxy property access")
    func testItemProxyPropertyAccess() async throws {
        // Given
        let testItem = Item("testItem")
            .name("test item")
            .description("A test item.")
            .synonyms("item", "object")
            .adjectives("test", "sample")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("testItem")

        // When/Then - Test basic property access
        let name = await proxy.property(.name)?.toString
        #expect(name == "test item")

        let description = await proxy.property(.description)?.toString
        #expect(description == "A test item.")

        let isTakable = await proxy.property(.isTakable)?.toBool
        #expect(isTakable == true)

        let isContainer = await proxy.property(.isContainer)?.toBool
        #expect(isContainer != true)  // nil or false
    }

    @Test("ItemProxy equality and hashing")
    func testItemProxyEquality() async throws {
        // Given
        let item1 = Item("item1")
            .name("first item")
            .in(.startRoom)

        let item2 = Item("item2")
            .name("second item")
            .in(.startRoom)

        let game = MinimalGame(
            items: item1, item2
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let proxy1a = await engine.item("item1")
        let proxy1b = await engine.item("item1")
        let proxy2 = await engine.item("item2")

        // Then
        #expect(proxy1a == proxy1b)
        #expect(proxy1a != proxy2)
        #expect(proxy1a.hashValue == proxy1b.hashValue)

        // Test Comparable
        #expect(proxy1a < proxy2)  // "item1" < "item2"
    }
}
