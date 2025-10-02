import GnustoEngine

enum CyclopsHideaway {
    static let cyclopsRoom = Location(.cyclopsRoom)
        .name("Cyclops Room")
        .description(
            """
            This is the lair of the cyclops. The smell is terrible, and the floor is littered with bones.
            """
        )
        .northwest(.maze15)
        .localGlobals(.stairs)
        // Note: EAST exit to strange passage conditional on MAGIC-FLAG
        // Note: UP exit to treasure room conditional on CYCLOPS-FLAG

    static let strangePassage = Location(.strangePassage)
        .name("Strange Passage")
        .description(
            """
            This is a long passage. To the west is one entrance. On the
            east there is an old wooden door, with a large opening in it (about
            cyclops sized).
            """
        )
        .west(.cyclopsRoom)
        .inside(.cyclopsRoom)
        .east(.livingRoom)

    static let treasureRoom = Location(.treasureRoom)
        .name("Treasure Room")
        .description(
            """
            This is a large room, whose east wall is solid granite. A number
            of discarded bags, which crumble at your touch, are scattered about
            on the floor. There is an exit down a staircase.
            """
        )
        .down(.cyclopsRoom)
        .localGlobals(.stairs)
}

// MARK: - Items

extension CyclopsHideaway {

    static let chalice = Item(.chalice)
        .name("chalice")
        .synonyms("chalice", "cup", "silver", "treasure")
        .adjectives("silver", "engravings")
        .isTakable
        .requiresTryTake
        .isContainer
        .description("There is a silver chalice, intricately engraved, here.")
        .capacity(5)
        .size(10)
        .in(.treasureRoom)
        .value(10)
        // Note: VALUE 10, TVALUE 5, has action handler CHALICE-FCN

    static let cyclops = Item(.cyclops)
        .name("cyclops")
        .synonyms("cyclops", "monster", "eye")
        .adjectives("hungry", "giant")
        .omitDescription
        .requiresTryTake
        .in(.cyclopsRoom)
        // Note: Has action handler CYCLOPS-FCN, STRENGTH 10000
}
