import GnustoEngine

enum Hades {
    static let entranceToHades = Location(
        id: .entranceToHades,
        .name("Entrance to Hades"),
        .description(
            """
            You are outside a large gate. The gate is flanked by a pair of
            burning torches, and there is an open doorway leading into the
            realm of the dead.
            """
        ),
        .exits(
            .up(.tinyCave)
            // Note: IN and SOUTH exits to land of living dead conditional on LLD-FLAG
        ),
        .inherentlyLit,
        .localGlobals(.bodies)
    )

    static let landOfLivingDead = Location(
        id: .landOfLivingDead,
        .name("Land of the Dead"),
        .description(
            """
            You have entered the Land of the Living Dead. Thousands of lost souls
            can be heard weeping and moaning. In the corner are stacked the remains
            of dozens of previous adventurers less fortunate than yourself.
            A passage exits to the north.
            """
        ),
        .exits(
            .outside(.entranceToHades),
            .north(.entranceToHades)
        ),
        .inherentlyLit,
        .localGlobals(.bodies)
    )
}

// MARK: - Items

extension Hades {

    static let ghosts = Item(
        id: .ghosts,
        .name("number of ghosts"),
        .synonyms("ghosts", "spirits", "fiends", "force"),
        .adjectives("invisible", "evil"),
        .omitDescription,
        .in(.entranceToHades)
        // Note: Has action handler GHOSTS-F
    )

    static let skull = Item(
        id: .skull,
        .name("crystal skull"),
        .synonyms("skull", "head", "treasure"),
        .adjectives("crystal"),
        .isTakable,
        .firstDescription(
            """
            Lying in one corner of the room is a beautifully carved crystal skull.
            It appears to be grinning at you rather nastily.
            """
        ),
        .in(.landOfLivingDead),
        .value(10)
        // Note: VALUE 10, TVALUE 10
    )
}
