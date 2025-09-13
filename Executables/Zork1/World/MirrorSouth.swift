import GnustoEngine

enum MirrorSouth {
    static let mirrorRoomSouth = Location(
        id: .mirrorRoomSouth,
        .name("Mirror Room"),
        .description(
            """
            You are in a large room with a huge mirror hanging on one wall.
            """
        ),
        .exits(
            .west(.windingPassage),
            .north(.narrowPassage),
            .east(.tinyCave)
        ),
        .inherentlyLit
    )

    static let narrowPassage = Location(
        id: .narrowPassage,
        .name("Narrow Passage"),
        .description(
            """
            This is a long and narrow corridor where a long north-south passageway
            briefly narrows even further.
            """
        ),
        .exits(
            .north(.roundRoom),
            .south(.mirrorRoomSouth)
        )
    )

    static let tinyCave = Location(
        id: .tinyCave,
        .name("Cave"),
        .description(
            """
            This is a tiny cave with entrances west and north, and a dark,
            forbidding staircase leading down.
            """
        ),
        .exits(
            .north(.mirrorRoomSouth),
            .west(.windingPassage),
            .down(.entranceToHades)
        ),
        .localGlobals(.stairs)
    )

    static let windingPassage = Location(
        id: .windingPassage,
        .name("Winding Passage"),
        .description(
            """
            This is a winding passage. It seems that there are only exits
            on the east and north.
            """
        ),
        .exits(
            .north(.mirrorRoomSouth),
            .east(.tinyCave)
        )
    )

}

// MARK: - Items

extension MirrorSouth {
    static let mirror2 = Item(
        id: .mirror2,
        .name("mirror"),
        .synonyms("reflection", "mirror", "enormous"),
        .requiresTryTake,
        .omitDescription,
        .in(.mirrorRoomSouth)
        // Note: Has action handler MIRROR-MIRROR
    )
}
