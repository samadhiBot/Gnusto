import GnustoEngine

/// Defines locations and items found within the forest region.
enum ForestRegion {
    /// Locations within the forest.
    static let locations: [Location] = [
        outside,
        streamBank,
    ]

    /// Items found within the forest region.
    static let items: [Item] = [
        clearWater,
        rustyKey,
    ]
}

// MARK: - Locations

extension ForestRegion {
    // Outdoor areas
    static let outside = Location(
        id: "outside",
        name: "Forest Path",
        description: """
                A winding path leads through a dense forest. To the north, you can see \
                the entrance to a cave. A small stream flows to the west.
                """,
        exits: [
            .north: Exit(destination: .startRoom), // Exit to CaveRegion
            .west: Exit(destination: "streamBank"),
        ],
        isLit: true, .outside
    )

    static let streamBank = Location(
        id: "streamBank",
        name: "Stream Bank",
        description: """
                You stand beside a clear, bubbling stream. The water flows from north to south, \
                disappearing into thick undergrowth. The forest path is to the east.
                """,
        exits: [
            .east: Exit(destination: "outside"),
        ],
        isLit: true, .outside
    )
}

// MARK: - Items

extension ForestRegion {
    // Iron Door puzzle items (key)
    static let rustyKey = Item(
        id: "rustyKey",
        name: "key",
        adjectives: "rusty", "iron",
        description: "An old, rusty iron key. It looks heavy and ornate.",
        properties: .takable,
        parent: .location("streamBank") // Key is found here
    )

    // Atmospheric items
    static let clearWater = Item(
        id: "clearWater",
        name: "water",
        adjectives: "clear", "cold",
        synonyms: "stream", "liquid",
        description: "Clear, cold water that looks refreshing.",
        properties: .ndesc, // Use .ndesc instead of .scenery
        parent: .location("streamBank")
    )
}
