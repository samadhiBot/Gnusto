import GnustoEngine

struct OperaHouse: AreaContents {
    // MARK: - Foyer of the Opera House

    let foyer = Location(
        id: "foyer",
        .name("Foyer of the Opera House"),
        .description("""
                You are standing in a spacious hall, splendidly decorated in red
                and gold, with glittering chandeliers overhead. The entrance from
                the street is to the north, and there are doorways south and west.
                """),
        .exits([
            .south: Exit(destination: "bar"),
            .west: Exit(destination: "cloakroom"),
            .north: Exit(
                destination: "street",
                blockedMessage: """
                    You've only just arrived, and besides, the weather outside
                    seems to be getting worse.
                    """
            )
        ]),
        .inherentlyLit
    )

    // MARK: - Cloakroom

    let cloakroom = Location(
        id: "cloakroom",
        .name("Cloakroom"),
        .description("""
            The walls of this small room were clearly once lined with hooks,
            though now only one remains. The exit is a door to the east.
            """),
        .exits([
            .east: Exit(destination: "foyer"),
        ]),
        .inherentlyLit
    )

    let hook = Item(
        id: "hook",
        .adjectives("small", "brass"),
        .in(.location("cloakroom")),
        .isSurface,
        .name("small brass hook"),
        .synonyms("peg"),
    )

    static func hookDescription(_ engine: GameEngine, _ command: Command) async throws -> Bool {
        guard
            command.verbID == "examine",
            let cloak = await engine.item("cloak")
        else {
            return false
        }
        let hookDetail = if cloak.parent == .item("hook") {
            "with a cloak hanging on it"
        } else {
            "screwed to the wall"
        }
        throw ActionError.customResponse("It's just a small brass hook, \(hookDetail).")
    }

    // MARK: - Bar

    let bar = Location(
        id: "bar",
        .name("Bar"),
        .description("""
            The bar, much rougher than you'd have guessed after the opulence
            of the foyer to the north, is completely empty. There seems to be
            some sort of message scrawled in the sawdust on the floor.
            """),
        .exits([
            .north: Exit(destination: "foyer"),
        ])
        // Note: Bar lighting is handled dynamically by hooks
    )

    let message = Item(
        id: "message",
        .name("crumpled message"),
        .description("A message appears to be written on the note."),
        .in(.location("bar")),
//        .hasNoDescription,
        .isReadable,
    )

    // MARK: - Items

    let cloak = Item(
        id: "cloak",
        .name("velvet cloak"),
        .description("A handsome velvet cloak, of exquisite quality."),
        .in(.player),
        .isTakable,
        .isWearable,
        .isWorn,
    )
}
