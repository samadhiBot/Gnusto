import GnustoEngine

/// Defines locations and items found within the cave system.
@MainActor enum CaveRegion {
    /// Locations within the cave system.
    static let locations: [Location] = [
        crystalGrotto,
        darkChamber,
        hiddenVault,
        ironDoorRoom,
        narrowPassage,
        startRoom,
        treasureRoom,
        undergroundPool,
    ]

    /// Items found within the cave system or related to it.
    static let items: [Item] = [
        brassLantern,
        darkPool,
        goldCrown,
        ironDoor,
        largeGem,
        mysteriousAltar,
        silverCoin,
        stonePedestal,
        woodenChest,
    ]
}

// MARK: - Locations

extension CaveRegion {
    // Starting location
    static let startRoom = Location(
        id: "startRoom",
        name: "Cave Entrance",
        description: """
                You stand at the entrance to a dark cave. Sunlight streams in from the
                opening to the south behind you, but the passage ahead to the north quickly
                disappears into darkness. A narrow passage leads east.
                """,
        exits: [
            .north: Exit(destination: "darkChamber"),
            .south: Exit(destination: "outside"), // Exit to ForestRegion
            .east: Exit(destination: "narrowPassage"),
        ],
        properties: .inherentlyLit
    )

    // Main cave areas
    static let darkChamber = Location(
        id: "darkChamber",
        name: "Dark Chamber",
        description: """
                This is a large cavern with walls that disappear into darkness overhead.
                Strange echoes bounce around as you move. The cave continues to the north,
                and the entrance is back to the south. Another passage leads west.
                """,
        exits: [
            .north: Exit(destination: "treasureRoom"),
            .south: Exit(destination: "startRoom"),
            .west: Exit(destination: "crystalGrotto"),
        ]
    )

    static let treasureRoom = Location(
        id: "treasureRoom",
        name: "Treasure Room",
        description: """
                This small chamber sparkles with reflections from numerous precious gems
                embedded in the walls. A stone pedestal in the center of the room holds
                what appears to be a golden crown. The only obvious exit is south.
                """,
        exits: [
            .south: Exit(destination: "darkChamber"),
        ]
    )

    // Additional cave sections
    static let narrowPassage = Location(
        id: "narrowPassage",
        name: "Narrow Passage",
        description: """
                The walls close in here, forming a tight corridor that slopes downward.
                You have to duck to avoid hitting your head on the low ceiling. The passage
                continues east, and the cave entrance is to the west.
                """,
        exits: [
            .west: Exit(destination: "startRoom"),
            .east: Exit(destination: "ironDoorRoom"),
        ]
    )

    static let ironDoorRoom = Location(
        id: "ironDoorRoom",
        name: "Iron Door Chamber",
        description: """
                This small chamber appears to be a dead end. The narrow passage leads back
                to the west. The eastern wall is dominated by a massive iron door.
                """,
        exits: [
            .west: Exit(destination: "narrowPassage"),
            // East exit is added dynamically by hooks based on door state
        ]
    )

    static let hiddenVault = Location(
        id: "hiddenVault",
        name: "Hidden Vault",
        description: """
                Beyond the iron door lies a secret vault. The walls are lined with carvings
                of ancient runes that seem to glow with a faint, otherworldly light. A small
                altar stands in the center of the room. The only way out is back through
                the iron door to the west.
                """,
        exits: [
            .west: Exit(destination: "ironDoorRoom"), // Assumes door is open
        ]
    )

    static let crystalGrotto = Location(
        id: "crystalGrotto",
        name: "Crystal Grotto",
        description: """
                This spectacular cavern is filled with towering crystal formations that
                catch and reflect any light in dazzling patterns. The floor is studded with
                smaller crystals in various hues. The dark chamber lies to the east, and a hole
                in the floor leads down.
                """,
        exits: [
            .east: Exit(destination: "darkChamber"),
            .down: Exit(destination: "undergroundPool"),
        ]
    )

    static let undergroundPool = Location(
        id: "undergroundPool",
        name: "Underground Pool",
        description: """
                A still, dark pool of water occupies most of this chamber. The water is so
                clear and still that it mirrors the ceiling perfectly. Faint phosphorescent
                fungi on the walls cast everything in a ghostly blue glow. A passage leads back up.
                """,
        exits: [
            .up: Exit(destination: "crystalGrotto"),
        ],
        properties: .inherentlyLit // Fungi provide light
    )
}

// MARK: - Items

extension CaveRegion {
    // Player tool found at start
    static let brassLantern = Item(
        id: Components.Lantern.Constants.itemID,
        name: "lantern",
        adjectives: "brass",
        synonyms: "lamp", "light",
        description: "A sturdy brass lantern, useful for exploring dark places.",
        properties: .takable, .lightSource, .device,
        parent: .location("startRoom")
    )

    // Treasure room items
    static let goldCrown = Item(
        id: "goldCrown",
        name: "crown",
        adjectives: "gold", "golden",
        description: "A magnificent golden crown, adorned with precious jewels.",
        properties: .takable, .wearable,
        parent: .item("stonePedestal") // Placed on the pedestal
    )

    static let stonePedestal = Item(
        id: "stonePedestal",
        name: "pedestal",
        adjectives: "stone",
        description: "A weathered stone pedestal in the center of the room.",
        properties: .surface, .ndesc, // Use .ndesc instead of .scenery, imply !takable
        parent: .location("treasureRoom")
    )

    // Iron Door puzzle items (door itself)
    static let ironDoor = Item(
        id: "ironDoor",
        name: "door",
        adjectives: "iron", "massive",
        description: """
                A massive door made of solid iron. Ancient runes are inscribed around its \
                frame. There's a keyhole below the handle.
                """,
        properties: .door, // Initially closed and locked? Logic might handle state.
        parent: .location("ironDoorRoom")
    )

    // Crystal Grotto items
    static let woodenChest = Item(
        id: "woodenChest",
        name: "chest",
        adjectives: "wooden", "old",
        description: "An old wooden chest with brass fittings. The lid is currently closed.",
        properties: .container, .openable, // Starts closed (no .open property)
        parent: .location("crystalGrotto")
    )

    static let silverCoin = Item(
        id: "silverCoin",
        name: "coin",
        adjectives: "silver", "ancient",
        description: "An ancient silver coin with unfamiliar markings.",
        properties: .takable,
        parent: .item("woodenChest") // Inside the chest
    )

    // Hidden Vault items
    static let mysteriousAltar = Item(
        id: "mysteriousAltar",
        name: "altar",
        adjectives: "mysterious", "stone",
        description: """
                A stone altar with intricate carvings. A shallow basin on top contains an \
                iridescent liquid that seems to shift colors as you watch.
                """,
        properties: .ndesc, // Use .ndesc instead of .scenery
        parent: .location("hiddenVault")
    )

    static let largeGem = Item(
        id: "largeGem",
        name: "gem",
        adjectives: "large", "glowing",
        synonyms: "crystal", "stone",
        description: """
                A large gem that seems to pulse with an inner light. As you examine it, \
                the color shifts between deep blue and violet.
                """,
        properties: .takable, .lightSource, // Provides light, might not need .on
        parent: .location("hiddenVault") // On the altar? Or just in the room?
    )

    // Underground Pool items
    static let darkPool = Item(
        id: "darkPool",
        name: "pool",
        adjectives: "dark", "still",
        synonyms: "water",
        description: """
                The water is perfectly still and incredibly clear. Looking down, you can see \
                small, strange artifacts scattered on the bottom, just out of reach.
                """,
        properties: .ndesc, // Use .ndesc instead of .scenery
        parent: .location("undergroundPool")
    )
}
