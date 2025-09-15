import GnustoEngine

// MARK: - Stone Barrow Area

enum StoneBarrow {
    // MARK: - Locations

    static let stoneBarrow = Location(
        id: .stoneBarrow,
        .name("Stone Barrow"),
        .description(
            """
            You are standing in front of a large stone barrow. There appears to be an entrance
            to the east.
            """
        ),
        .exits(
            .west(.forest1),
            .east(blocked: "The entrance is sealed.")
        ),
        .inherentlyLit
    )

    // MARK: - Items
    // (No items currently in this area)
}
