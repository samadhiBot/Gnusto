import GnustoEngine

// MARK: - Zork Items

enum ZorkItems {
    // MARK: - West of House Items

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
        .synonyms("advertisement", "booklet", "mail"),
        .in(.item(.mailbox)),
        .isTakable,
        .isReadable
    )

    // MARK: - House and Structure Items

    static let whiteHouse = Item(
        id: .whiteHouse,
        .name("white house"),
        .description("""
            The house is a beautiful colonial house which is painted white. It is clear that the owners must have been extremely wealthy.
            """),
        .adjectives("white", "beautiful", "colonial"),
        .synonyms("house", "home", "building"),
        .in(.location(.westOfHouse)),
        .isScenery
    )

    static let frontDoor = Item(
        id: .frontDoor,
        .name("boarded front door"),
        .description("The front door is boarded up with heavy wooden planks."),
        .adjectives("front", "boarded", "wooden"),
        .synonyms("door", "boards", "planks", "entrance"),
        .in(.location(.westOfHouse)),
        .isScenery
    )

    static let boardedWindow = Item(
        id: .boardedWindow,
        .name("boarded window"),
        .description("The windows are all boarded up."),
        .adjectives("boarded"),
        .synonyms("window", "windows"),
        .in(.location(.northOfHouse)),
        .isScenery
    )

    static let kitchenWindow = Item(
        id: .kitchenWindow,
        .name("kitchen window"),
        .description("""
            The window is slightly ajar, but not enough to allow entry.
            """),
        .adjectives("kitchen", "small"),
        .synonyms("window"),
        .in(.location(.eastOfHouse)),
        .isScenery,
        .isOpenable
    )

    // MARK: - Forest Items

    static let tree = Item(
        id: .tree,
        .name("tree"),
        .description("It's a large tree with low branches."),
        .adjectives("large", "climbable"),
        .synonyms("branch", "branches", "trunk"),
        .in(.location(.path)),
        .isScenery,
        .isClimbable
    )

    static let leaves = Item(
        id: .leaves,
        .name("leaves"),
        .description("The ground is covered with leaves."),
        .adjectives("fallen", "autumn"),
        .synonyms("leaf"),
        .in(.location(.forest1)),
        .isScenery
    )

    // MARK: - Clearing Items

    static let grating = Item(
        id: .grating,
        .name("grating"),
        .description("""
            It's a steel grating, locked with a brass padlock. Scratched into the metal is the word "ZORKMID".
            """),
        .adjectives("steel", "metal"),
        .synonyms("lock", "padlock", "cover"),
        .in(.location(.gratingClearing)),
        .isScenery,
        .isOpenable,
        .isLocked
    )
}
