import GnustoEngine

// MARK: - Around House Area

enum AroundHouse {
    // MARK: - Locations

    static let westOfHouse = Location(
        id: .westOfHouse,
        .name("West of House"),
        .description("""
            You are standing in an open field west of a white house, with a boarded front door.
            """),
        .exits([
            .north: .to(.northOfHouse),
            .south: .to(.southOfHouse),
            .northeast: .to(.northOfHouse),
            .southeast: .to(.southOfHouse),
            .west: .to(.forest1),
            .east: Exit(
                destination: .blockedExit,
                blockedMessage: "The door is boarded and you can't remove the boards."
            ),
        ]),
        .inherentlyLit
    )

    static let northOfHouse = Location(
        id: .northOfHouse,
        .name("North of House"),
        .description("""
            You are facing the north side of a white house. There is no door here, and all the \
            windows are boarded up. To the north a narrow path winds through the trees.
            """),
        .exits([
            .south: .to(.westOfHouse),
            .west: .to(.westOfHouse),
            .east: .to(.eastOfHouse),
            .southeast: .to(.southOfHouse),
            .southwest: .to(.westOfHouse),
            .north: .to(.path),
        ]),
        .inherentlyLit
    )

    static let southOfHouse = Location(
        id: .southOfHouse,
        .name("South of House"),
        .description("""
            You are facing the south side of a white house. There is no door here, and all the \
            windows are boarded.
            """),
        .exits([
            .north: .to(.westOfHouse),
            .west: .to(.westOfHouse),
            .east: .to(.eastOfHouse),
            .northeast: .to(.westOfHouse),
            .northwest: .to(.westOfHouse),
            .southeast: .to(.eastOfHouse),
        ]),
        .inherentlyLit
    )

    static let eastOfHouse = Location(
        id: .eastOfHouse,
        .name("Behind House"),
        .description("""
            You are behind the white house. A path leads into the forest to the east. In one \
            corner of the house there is a small window which is slightly ajar.
            """),
        .exits([
            .north: .to(.northOfHouse),
            .south: .to(.southOfHouse),
            .west: Exit(
                destination: .kitchen,
                doorID: .kitchenWindow
            ),
            .northwest: .to(.northOfHouse),
            .southwest: .to(.southOfHouse),
            .east: .to(.clearing),
        ]),
        .inherentlyLit
    )

    // MARK: - Items

    static let mailbox = Item(
        id: .mailbox,
        .name("small mailbox"),
        .description("It's a small mailbox."),
        .adjectives("small"),
        .synonyms("box"),
        .in(.location(.westOfHouse)),
        .isContainer,
        .isOpenable,
        .isOpen,
        .isTakable
    )

    static let leaflet = Item(
        id: .leaflet,
        .name("leaflet"),
        .description("""
            "WELCOME TO ZORK!

            ZORK is a game of adventure, danger, and low cunning. In it you will explore some of the most amazing territory ever seen by mortals. No computer should be without one!"
            """),
        .synonyms("mail"),
        .in(.item(.mailbox)),
        .isReadable,
        .isTakable
    )

    static let whiteHouse = Item(
        id: .whiteHouse,
        .name("white house"),
        .description("The house is a beautiful colonial house which is painted white. It is clear that the owners must have been extremely wealthy."),
        .adjectives("white", "beautiful", "colonial"),
        .synonyms("house", "home", "building"),
        .in(.location(.westOfHouse))
    )

    static let frontDoor = Item(
        id: .frontDoor,
        .name("front door"),
        .description("The door is boarded and you can't remove the boards."),
        .adjectives("front", "boarded"),
        .synonyms("door", "boards"),
        .in(.location(.westOfHouse))
    )

    static let boardedWindow = Item(
        id: .boardedWindow,
        .name("boarded window"),
        .description("The windows are boarded up. There is no way you could enter through them."),
        .adjectives("boarded"),
        .synonyms("window", "windows", "boards"),
        .in(.location(.southOfHouse))
    )

    static let kitchenWindow = Item(
        id: .kitchenWindow,
        .name("kitchen window"),
        .description("The window is slightly ajar, but not enough to allow entry."),
        .adjectives("kitchen", "small"),
        .synonyms("window"),
        .in(.location(.eastOfHouse)),
        .isOpenable,
        .isScenery
    )
}
