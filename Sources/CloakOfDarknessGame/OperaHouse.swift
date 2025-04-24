import GnustoEngine

struct OperaHouse: ItemDefinitions, LocationDefinitions {
    // MARK: - Bar

    let bar = Location(
        id: "bar",
        name: "Bar",
        description: "The bar, much rougher than you'd have guessed after the opulence of the foyer to the north, is completely empty. There seems to be some sort of message scrawled in the sawdust on the floor.",
        exits: [
            .north: Exit(destination: "foyer"),
        ]
        // Note: Bar lighting is handled dynamically by hooks
    )

    let message = Item(
        id: "message",
        name: "message",
        properties: .ndesc, .read,
        parent: .location("bar"),
        readableText: "You have won!"
    )

    // MARK: - Cloakroom

    let cloakroom = Location(
        id: "cloakroom",
        name: "Cloakroom",
        description: """
                The walls of this small room were clearly once lined with hooks, though now only \
                one remains. The exit is a door to the east.
                """,
        exits: [
            .east: Exit(destination: "foyer"),
        ],
        properties: .inherentlyLit
    )

    let hook = Item(
        id: "hook",
        name: "hook",
        adjectives: "brass",
        synonyms: "peg",
        properties: .surface,
        parent: .location("cloakroom")
    )

    // MARK: - Foyer of the Opera House

    let foyer = Location(
        id: "foyer",
        name: "Foyer of the Opera House",
        description: """
                You are standing in a spacious hall, splendidly decorated in red and gold, which \
                serves as the lobby of the opera house. The walls are adorned with portraits of \
                famous singers, and the floor is covered with a thick crimson carpet. A grand \
                staircase leads upwards, and there are doorways to the south and west.
                """,
        exits: [
            .south: Exit(destination: "bar"),
            .west: Exit(destination: "cloakroom"),
        ],
        properties: .inherentlyLit
    )

    // MARK: - Items

    let cloak = Item(
        id: "cloak",
        name: "cloak",
        adjectives: "handsome", "velvet",
        properties: .takable, .wearable, .worn,
        parent: .player
    )

//    let playerItem = Item(
//        id: "player",
//        name: "yourself",
//        synonyms: "me", "myself",
//        properties: .person
//    )
}
