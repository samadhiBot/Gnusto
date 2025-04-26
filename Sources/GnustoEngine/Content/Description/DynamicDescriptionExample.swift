import Foundation

/// Example showing how to use dynamic descriptions in a game.
public struct DynamicDescriptionExample {
    /// Example of a dynamic description handler that changes based on item state.
    public static func registerExampleHandlers(engine: GameEngine) async {
        // Example 1: A lamp that changes description based on whether it's on
        await engine.descriptionHandlerRegistry.registerItemHandler(id: "lamp_description") { item, engine in
            if item.hasProperty(.on) {
                return "The \(item.name) is glowing brightly, casting light all around."
            } else {
                return "The \(item.name) is currently turned off."
            }
        }

        // Example 2: A book that shows different text based on whether it's been read
        await engine.descriptionHandlerRegistry.registerItemHandler(id: "book_description") { item, engine in
            if item.hasProperty(.touched) {
                return "The \(item.name) appears to be a well-read volume."
            } else {
                return "The \(item.name) looks like it hasn't been opened in a while."
            }
        }

        // Example 3: A container that describes its contents
        await engine.descriptionHandlerRegistry.registerItemHandler(id: "container_description") { item, engine in
            let contents = engine.itemSnapshots(withParent: .item(item.id))
            if contents.isEmpty {
                return "The \(item.name) is empty."
            } else {
                let contentList = contents.map { "a \($0.name)" }.joined(separator: ", ")
                return "The \(item.name) contains \(contentList)."
            }
        }
    }

    /// Example of creating items with dynamic descriptions.
    public static func createExampleItems() -> [Item] {
        [
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
    }
}
