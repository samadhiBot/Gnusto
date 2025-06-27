import CustomDump
import Foundation
import Testing

@testable import GnustoEngine

@Suite("Item Extensions")
struct ItemExtensionTests {

    // MARK: - Test Data Setup

    private func createTestItem(
        id: String = "testItem",
        name: String = "test item"
    ) -> Item {
        Item(
            id: ItemID(rawValue: id),
            .name(name),
            .description("A test item."),
            .in(.location("testRoom"))
        )
    }

    // MARK: - withDefiniteArticle Tests

    @Test("withDefiniteArticle prepends 'the' to normal items")
    func testWithDefiniteArticleNormalItem() {
        let item = createTestItem(name: "brass lamp")
        #expect(item.withDefiniteArticle == "the brass lamp")
    }

    @Test("withDefiniteArticle returns name without article for omitArticle items")
    func testWithDefiniteArticleOmitArticle() {
        let item = Item(
            id: "water",
            .name("water"),
            .description("A test item."),
            .in(.location("testRoom")),
            .omitArticle
        )
        #expect(item.withDefiniteArticle == "water")
    }

    @Test("withDefiniteArticle handles empty names")
    func testWithDefiniteArticleEmptyName() {
        let item = createTestItem(name: "")
        #expect(item.withDefiniteArticle == "the ")
    }

    @Test("withDefiniteArticle handles single character names")
    func testWithDefiniteArticleSingleCharacter() {
        let item = createTestItem(name: "x")
        #expect(item.withDefiniteArticle == "the x")
    }

    // MARK: - withIndefiniteArticle Tests

    @Test("withIndefiniteArticle uses 'an' for vowel-starting items")
    func testWithIndefiniteArticleVowelStart() {
        let vowelItems = [
            ("apple", "an apple"),
            ("elephant", "an elephant"),
            ("ice cream", "an ice cream"),
            ("orange", "an orange"),
            ("umbrella", "an umbrella"),
        ]

        for (name, expected) in vowelItems {
            let item = createTestItem(name: name)
            #expect(item.withIndefiniteArticle == expected)
        }
    }

    @Test("withIndefiniteArticle uses 'a' for consonant-starting items")
    func testWithIndefiniteArticleConsonantStart() {
        let consonantItems = [
            ("book", "a book"),
            ("cat", "a cat"),
            ("dog", "a dog"),
            ("flower", "a flower"),
            ("guitar", "a guitar"),
        ]

        for (name, expected) in consonantItems {
            let item = createTestItem(name: name)
            #expect(item.withIndefiniteArticle == expected)
        }
    }

    @Test("withIndefiniteArticle handles case insensitive vowels")
    func testWithIndefiniteArticleCaseInsensitive() {
        let items = [
            ("Apple", "an Apple"),
            ("ELEPHANT", "an ELEPHANT"),
            ("Book", "a Book"),
            ("CAT", "a CAT"),
        ]

        for (name, expected) in items {
            let item = createTestItem(name: name)
            #expect(item.withIndefiniteArticle == expected)
        }
    }

    @Test("withIndefiniteArticle returns name without article for omitArticle items")
    func testWithIndefiniteArticleOmitArticle() {
        let item = Item(
            id: "water",
            .name("water"),
            .description("A test item."),
            .in(.location("testRoom")),
            .omitArticle
        )
        #expect(item.withIndefiniteArticle == "water")
    }

    @Test("withIndefiniteArticle handles empty names")
    func testWithIndefiniteArticleEmptyName() {
        let item = createTestItem(name: "")
        #expect(item.withIndefiniteArticle == "")
    }

    @Test("withIndefiniteArticle handles single character names")
    func testWithIndefiniteArticleSingleCharacter() {
        let vowelItem = createTestItem(name: "a")
        #expect(vowelItem.withIndefiniteArticle == "an a")

        let consonantItem = createTestItem(name: "b")
        #expect(consonantItem.withIndefiniteArticle == "a b")
    }

    @Test("withIndefiniteArticle handles numbers and special characters")
    func testWithIndefiniteArticleSpecialCharacters() {
        let item1 = createTestItem(name: "8-ball")
        #expect(item1.withIndefiniteArticle == "an 8-ball")

        let item2 = createTestItem(name: "2-dollar bill")
        #expect(item2.withIndefiniteArticle == "a 2-dollar bill")
    }

    // MARK: - Array<Item> find Tests

    @Test("find returns correct item when ID exists")
    func testFindExistingItem() {
        let item1 = createTestItem(id: "item1", name: "first item")
        let item2 = createTestItem(id: "item2", name: "second item")
        let item3 = createTestItem(id: "item3", name: "third item")
        let items = [item1, item2, item3]

        let foundItem = items.find("item2")
        #expect(foundItem?.id == "item2")
        #expect(foundItem?.name == "second item")
    }

    @Test("find returns nil when ID does not exist")
    func testFindNonExistentItem() {
        let item1 = createTestItem(id: "item1", name: "first item")
        let item2 = createTestItem(id: "item2", name: "second item")
        let items = [item1, item2]

        let foundItem = items.find("nonexistent")
        #expect(foundItem == nil)
    }

    @Test("find returns nil for empty array")
    func testFindInEmptyArray() {
        let items: [Item] = []
        let foundItem = items.find("anyId")
        #expect(foundItem == nil)
    }

    @Test("find returns first match when duplicate IDs exist")
    func testFindWithDuplicateIDs() {
        let item1 = createTestItem(id: "duplicate", name: "first duplicate")
        let item2 = createTestItem(id: "duplicate", name: "second duplicate")
        let items = [item1, item2]

        let foundItem = items.find("duplicate")
        #expect(foundItem?.name == "first duplicate")
    }

    // MARK: - Array<Item> listWithDefiniteArticles Tests

    @Test("listWithDefiniteArticles returns 'nothing' for empty array")
    func testListWithDefiniteArticlesEmpty() {
        let items: [Item] = []
        #expect(items.listWithDefiniteArticles == "nothing")
    }

    @Test("listWithDefiniteArticles returns single item with definite article")
    func testListWithDefiniteArticlesSingleItem() {
        let item = createTestItem(name: "brass lamp")
        let items = [item]
        #expect(items.listWithDefiniteArticles == "the brass lamp")
    }

    @Test("listWithDefiniteArticles returns two items with 'and'")
    func testListWithDefiniteArticlesTwoItems() {
        let item1 = createTestItem(id: "item1", name: "book")
        let item2 = createTestItem(id: "item2", name: "apple")
        let items = [item1, item2]
        #expect(items.listWithDefiniteArticles == "the apple and the book")
    }

    @Test("listWithDefiniteArticles returns three items with Oxford comma")
    func testListWithDefiniteArticlesThreeItems() {
        let item1 = createTestItem(id: "item1", name: "book")
        let item2 = createTestItem(id: "item2", name: "apple")
        let item3 = createTestItem(id: "item3", name: "candle")
        let items = [item1, item2, item3]
        #expect(items.listWithDefiniteArticles == "the apple, the book, and the candle")
    }

    @Test("listWithDefiniteArticles sorts items alphabetically")
    func testListWithDefiniteArticlesSorting() {
        let item1 = createTestItem(id: "item1", name: "zebra")
        let item2 = createTestItem(id: "item2", name: "apple")
        let item3 = createTestItem(id: "item3", name: "mountain")
        let items = [item1, item2, item3]
        #expect(items.listWithDefiniteArticles == "the apple, the mountain, and the zebra")
    }

    @Test("listWithDefiniteArticles handles omitArticle items")
    func testListWithDefiniteArticlesOmitArticle() {
        let item1 = Item(
            id: "item1",
            .name("water"),
            .description("A test item."),
            .in(.location("testRoom")),
            .omitArticle
        )
        let item2 = createTestItem(id: "item2", name: "lamp")
        let items = [item1, item2]
        #expect(items.listWithDefiniteArticles == "the lamp and water")
    }

    // MARK: - Array<Item> listWithIndefiniteArticles Tests

    @Test("listWithIndefiniteArticles returns 'nothing' for empty array")
    func testListWithIndefiniteArticlesEmpty() {
        let items: [Item] = []
        #expect(items.listWithIndefiniteArticles == "nothing")
    }

    @Test("listWithIndefiniteArticles returns single item with indefinite article")
    func testListWithIndefiniteArticlesSingleItem() {
        let item = createTestItem(name: "apple")
        let items = [item]
        #expect(items.listWithIndefiniteArticles == "an apple")
    }

    @Test("listWithIndefiniteArticles returns two items with 'and'")
    func testListWithIndefiniteArticlesTwoItems() {
        let item1 = createTestItem(id: "item1", name: "book")
        let item2 = createTestItem(id: "item2", name: "apple")
        let items = [item1, item2]
        #expect(items.listWithIndefiniteArticles == "an apple and a book")
    }

    @Test("listWithIndefiniteArticles returns three items with Oxford comma")
    func testListWithIndefiniteArticlesThreeItems() {
        let item1 = createTestItem(id: "item1", name: "book")
        let item2 = createTestItem(id: "item2", name: "apple")
        let item3 = createTestItem(id: "item3", name: "elephant")
        let items = [item1, item2, item3]
        #expect(items.listWithIndefiniteArticles == "an apple, a book, and an elephant")
    }

    @Test("listWithIndefiniteArticles sorts items alphabetically")
    func testListWithIndefiniteArticlesSorting() {
        let item1 = createTestItem(id: "item1", name: "zebra")
        let item2 = createTestItem(id: "item2", name: "apple")
        let item3 = createTestItem(id: "item3", name: "mountain")
        let items = [item1, item2, item3]
        #expect(items.listWithIndefiniteArticles == "an apple, a mountain, and a zebra")
    }

    @Test("listWithIndefiniteArticles handles omitArticle items")
    func testListWithIndefiniteArticlesOmitArticle() {
        let item1 = Item(
            id: "item1",
            .name("water"),
            .description("A test item."),
            .in(.location("testRoom")),
            .omitArticle
        )
        let item2 = createTestItem(id: "item2", name: "apple")
        let items = [item1, item2]
        #expect(items.listWithIndefiniteArticles == "an apple and water")
    }

    @Test("listWithIndefiniteArticles handles mixed vowel and consonant starts")
    func testListWithIndefiniteArticlesMixedStarts() {
        let item1 = createTestItem(id: "item1", name: "orange")  // vowel
        let item2 = createTestItem(id: "item2", name: "book")  // consonant
        let item3 = createTestItem(id: "item3", name: "apple")  // vowel
        let item4 = createTestItem(id: "item4", name: "desk")  // consonant
        let items = [item1, item2, item3, item4]
        #expect(items.listWithIndefiniteArticles == "an apple, a book, a desk, and an orange")
    }

    // MARK: - Edge Cases and Integration Tests

    @Test("extensions work together correctly")
    func testExtensionsIntegration() {
        let item = createTestItem(name: "umbrella")

        // Test that both article methods work
        #expect(item.withDefiniteArticle == "the umbrella")
        #expect(item.withIndefiniteArticle == "an umbrella")

        // Test in array context
        let items = [item]
        #expect(items.listWithDefiniteArticles == "the umbrella")
        #expect(items.listWithIndefiniteArticles == "an umbrella")
    }

    @Test("extensions handle unicode characters")
    func testExtensionsWithUnicodeCharacters() {
        let item = createTestItem(name: "émilie")
        #expect(item.withDefiniteArticle == "the émilie")
        #expect(item.withIndefiniteArticle == "an émilie")
    }

    @Test("extensions handle very long names")
    func testExtensionsWithLongNames() {
        let longName = "extremely long item name that goes on and on and on"
        let item = createTestItem(name: longName)
        #expect(item.withDefiniteArticle == "the \(longName)")
        #expect(item.withIndefiniteArticle == "an \(longName)")
    }
}
