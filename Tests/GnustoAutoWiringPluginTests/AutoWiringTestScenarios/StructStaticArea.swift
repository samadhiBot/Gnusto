import GnustoEngine

struct StructStaticArea {
    static let room = Location(
        id: .room,
        .name("Room"),
        .description("A simple room."),
        .inherentlyLit
    )

    static let chair = Item(
        id: .chair,
        .name("chair"),
        .description("A wooden chair."),
        .in(.location(.room))
    )
}
