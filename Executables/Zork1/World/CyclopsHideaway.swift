import GnustoEngine

enum CyclopsHideaway {
    static let cyclopsRoom = Location(
        id: .cyclopsRoom,
        .name("Cyclops Room"),
        .description("""
            This is the lair of the cyclops. The smell is terrible, and the floor is littered with bones.
            """),
        .exits([
            .northwest: .to(.maze15),
            // Note: EAST exit to strange passage conditional on MAGIC-FLAG
            // Note: UP exit to treasure room conditional on CYCLOPS-FLAG
        ]),
        .isLand,
        .localGlobals(.stairs)
    )

    static let strangePassage = Location(
        id: .strangePassage,
        .name("Strange Passage"),
        .description("""
            This is a long passage. To the west is one entrance. On the
            east there is an old wooden door, with a large opening in it (about
            cyclops sized).
            """),
        .exits([
            .west: .to(.cyclopsRoom),
            .inside: .to(.cyclopsRoom),
            .east: .to(.livingRoom)
        ]),
        .isLand
    )

    static let treasureRoom = Location(
        id: .treasureRoom,
        .name("Treasure Room"),
        .description("""
            This is a large room, whose east wall is solid granite. A number
            of discarded bags, which crumble at your touch, are scattered about
            on the floor. There is an exit down a staircase.
            """),
        .exits([
            .down: .to(.cyclopsRoom)
        ]),
        .isLand,
        .localGlobals(.stairs)
    )
}

// MARK: - Items

extension CyclopsHideaway {
    static let bodies = Item(
        id: .bodies,
        .name("pile of bodies"),
        .synonyms("bodies", "body", "remains", "pile"),
        .adjectives("mangled"),
        .suppressDescription,
        .requiresTryTake
        // Note: Has action handler BODY-FUNCTION
    )

    static let chalice = Item(
        id: .chalice,
        .name("chalice"),
        .synonyms("chalice", "cup", "silver", "treasure"),
        .adjectives("silver", "engravings"),
        .isTakable,
        .requiresTryTake,
        .isContainer,
        .description("There is a silver chalice, intricately engraved, here."),
        .capacity(5),
        .size(10),
        .in(.location(.treasureRoom))
        // Note: VALUE 10, TVALUE 5, has action handler CHALICE-FCN
    )

    static let cyclops = Item(
        id: .cyclops,
        .name("cyclops"),
        .synonyms("cyclops", "monster", "eye"),
        .adjectives("hungry", "giant"),
        .isCharacter,  // ACTORBIT
        .suppressDescription,
        .requiresTryTake,
        .in(.location(.cyclopsRoom))
        // Note: Has action handler CYCLOPS-FCN, STRENGTH 10000
    )
}
