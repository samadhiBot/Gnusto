import GnustoEngine

struct InstanceArea {
    func basement() -> Location {
        Location(
            id: .basement,
            .name("Basement"),
            .description("A dark basement."),
            .inherentlyLit
        )
    }

    func flashlight() -> Item {
        Item(
            id: .flashlight,
            .name("flashlight"),
            .description("A bright flashlight."),
            .in(.location(.basement)),
            .isTakable
        )
    }
}
