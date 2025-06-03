import GnustoEngine

enum HouseArea {
    static let livingRoom = Location(
        id: .livingRoom,
        .name("Living Room"),
        .description("A cozy living room."),
        .inherentlyLit
    )

    static let kitchen = Location(
        id: .kitchen,
        .name("Kitchen"),
        .description("A modern kitchen."),
        .exits([.west: .to(.livingRoom)]),
        .inherentlyLit
    )

    static let houseKey = Item(
        id: .houseKey,
        .name("house key"),
        .description("A small brass key."),
        .in(.location(.livingRoom)),
        .isTakable
    )

    static let cookbook = Item(
        id: .cookbook,
        .name("cookbook"),
        .description("A well-worn cookbook."),
        .in(.location(.kitchen)),
        .isTakable,
        .isReadable
    )
}
