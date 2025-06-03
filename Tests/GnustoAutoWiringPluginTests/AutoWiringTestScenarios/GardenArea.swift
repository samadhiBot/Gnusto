import GnustoEngine

enum GardenArea {
    static let backYard = Location(
        id: .backYard,
        .name("Back Yard"),
        .description("A small back yard."),
        .exits([.north: .to(.kitchen)]),
        .inherentlyLit
    )

    static let frontYard = Location(
        id: .frontYard,
        .name("Front Yard"),
        .description("A neat front yard."),
        .exits([.south: .to(.livingRoom)]),
        .inherentlyLit
    )

    static let gardenShovel = Item(
        id: .gardenShovel,
        .name("garden shovel"),
        .description("A sturdy garden shovel."),
        .in(.location(.backYard)),
        .isTakable
    )

    static let mailbox = Item(
        id: .mailbox,
        .name("mailbox"),
        .description("A red mailbox."),
        .in(.location(.frontYard)),
        .isContainer,
        .isOpenable
    )
}
