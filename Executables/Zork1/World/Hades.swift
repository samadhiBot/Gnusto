import GnustoEngine

struct Hades {
    let entranceToHades = Location(.entranceToHades)
        .name("Entrance to Hades")
        .description(
            """
            You are outside a large gate. The gate is flanked by a pair of
            burning torches, and there is an open doorway leading into the
            realm of the dead.
            """
        )
        .up(.tinyCave)
        // Note: IN and SOUTH exits to land of living dead conditional on LLD-FLAG
        .inherentlyLit
        .localGlobals(.bodies)

    let landOfLivingDead = Location(.landOfLivingDead)
        .name("Land of the Dead")
        .description(
            """
            You have entered the Land of the Living Dead. Thousands of lost souls
            can be heard weeping and moaning. In the corner are stacked the remains
            of dozens of previous adventurers less fortunate than yourself.
            A passage exits to the north.
            """
        )
        .outside(.entranceToHades)
        .north(.entranceToHades)
        .inherentlyLit
        .localGlobals(.bodies)

    // MARK: - Items

    let bodies = Item(.bodies)
        .name("pile of bodies")
        .synonyms("bodies", "body", "remains", "pile")
        .adjectives("mangled")
        .omitDescription
        .requiresTryTake
        // Note: Has action handler BODY-FUNCTION

    let ghosts = Item(.ghosts)
        .name("number of ghosts")
        .synonyms("ghosts", "spirits", "fiends", "force")
        .adjectives("invisible", "evil")
        .omitDescription
        .in(.entranceToHades)
        // Note: Has action handler GHOSTS-F

    let skull = Item(.skull)
        .name("crystal skull")
        .synonyms("skull", "head", "treasure")
        .adjectives("crystal")
        .isTakable
        .firstDescription(
            """
            Lying in one corner of the room is a beautifully carved crystal skull.
            It appears to be grinning at you rather nastily.
            """
        )
        .in(.landOfLivingDead)
        .value(10)
        // Note: VALUE 10, TVALUE 10
}
