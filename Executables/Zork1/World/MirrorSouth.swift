import GnustoEngine

enum MirrorSouth {
    static let mirrorRoomSouth = Location(.mirrorRoomSouth)
        .name("Mirror Room")
        .description(
            """
            You are in a large room with a huge mirror hanging on one wall.
            """
        )
        .west(.windingPassage)
        .north(.narrowPassage)
        .east(.tinyCave)
        .inherentlyLit

    static let narrowPassage = Location(.narrowPassage)
        .name("Narrow Passage")
        .description(
            """
            This is a long and narrow corridor where a long north-south passageway
            briefly narrows even further.
            """
        )
        .north(.roundRoom)
        .south(.mirrorRoomSouth)

    static let tinyCave = Location(.tinyCave)
        .name("Cave")
        .description(
            """
            This is a tiny cave with entrances west and north, and a dark,
            forbidding staircase leading down.
            """
        )
        .north(.mirrorRoomSouth)
        .west(.windingPassage)
        .down(.entranceToHades)
        .localGlobals(.stairs)

    static let windingPassage = Location(.windingPassage)
        .name("Winding Passage")
        .description(
            """
            This is a winding passage. It seems that there are only exits
            on the east and north.
            """
        )
        .north(.mirrorRoomSouth)
        .east(.tinyCave)

}

// MARK: - Items

extension MirrorSouth {
    static let mirror2 = Item(.mirror2)
        .name("mirror")
        .synonyms("reflection", "mirror", "enormous")
        .requiresTryTake
        .omitDescription
        .in(.mirrorRoomSouth)
        // Note: Has action handler MIRROR-MIRROR
}
