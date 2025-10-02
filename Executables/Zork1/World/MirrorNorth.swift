import GnustoEngine

enum MirrorNorth {
    static let atlantisRoom = Location(.atlantisRoom)
        .name("Atlantis Room")
        .description(
            """
            This is an ancient room, long under water. There is an exit to
            the south and a staircase leading up.
            """
        )
        .up(.smallCave)
        .south(.reservoirNorth)
        .localGlobals(.stairs)

    static let coldPassage = Location(.coldPassage)
        .name("Cold Passage")
        .description(
            """
            This is a cold and damp corridor where a long east-west passageway
            turns into a southward path.
            """
        )
        .south(.mirrorRoomNorth)
        .west(.slideRoom)

    static let mirrorRoomNorth = Location(.mirrorRoomNorth)
        .name("Mirror Room")
        .description(
            """
            You are in a large room with a huge mirror hanging on one wall.
            """
        )
        .north(.coldPassage)
        .west(.twistingPassage)
        .east(.smallCave)

    static let smallCave = Location(.smallCave)
        .name("Cave")
        .description(
            """
            This is a tiny cave with entrances west and north, and a staircase
            leading down.
            """
        )
        .north(.mirrorRoomNorth)
        .down(.atlantisRoom)
        .south(.atlantisRoom)
        .west(.twistingPassage)
        .localGlobals(.stairs)

    static let twistingPassage = Location(.twistingPassage)
        .name("Twisting Passage")
        .description(
            """
            This is a winding passage. It seems that there are only exits
            on the east and north.
            """
        )
        .north(.mirrorRoomNorth)
        .east(.smallCave)
}

// MARK: - Items

extension MirrorNorth {
    static let trident = Item(.trident)
        .name("crystal trident")
        .synonyms("trident", "fork", "treasure")
        .adjectives("poseidon", "own", "crystal")
        .isTakable
        .firstDescription("On the shore lies Poseidon's own crystal trident.")
        .size(20)
        .in(.atlantisRoom)
        .value(4)
    // Note: VALUE 4, TVALUE 11

    static let mirror1 = Item(.mirror1)
        .name("mirror")
        .synonyms("reflection", "mirror", "enormous")
        .requiresTryTake
        .omitDescription
        .in(.mirrorRoomNorth)
    // Note: Has action handler MIRROR-MIRROR
}
