import GnustoEngine

enum RoundRoom {
    static let chasmRoom = Location(.chasmRoom)
        .name("Chasm")
        .description(
            """
            A chasm runs southwest to northeast and the path follows it. You are
            on the south side of the chasm, where a crack opens into a passage.
            """
        )
        .northeast(.reservoirSouth)
        .southwest(.ewPassage)
        .up(.ewPassage)
        .south(.nsPassage)
        // Note: DOWN exit has custom message
        .scenery(.crack, .stairs)

    static let dampCave = Location(.dampCave)
        .name("Damp Cave")
        .description(
            """
            This cave has exits to the west and east, and narrows to a crack toward
            the south. The earth is particularly damp here.
            """
        )
        .west(.loudRoom)
        .east(.whiteCliffsNorth)
        // Note: SOUTH exit has custom message about being too narrow
        .scenery(.crack)

    static let deepCanyon = Location(.deepCanyon)
        .name("Deep Canyon")
        .description(
            """
            You are on the south side of a deep canyon.
            """
        )
        .northwest(.reservoirSouth)
        .east(.damRoom)
        .southwest(.nsPassage)
        .down(.loudRoom)
        .scenery(.stairs)

    static let ewPassage = Location(.ewPassage)
        .name("East-West Passage")
        .description(
            """
            This is a narrow east-west passageway. There is a narrow stairway
            leading down at the north end of the room.
            """
        )
        .east(.roundRoom)
        .west(.trollRoom)
        .down(.chasmRoom)
        .north(.chasmRoom)
        .scenery(.stairs)

    static let loudRoom = Location(.loudRoom)
        .name("Loud Room")
        .description(
            """
            This is a room where every sound is amplified.
            """
        )
        .east(.dampCave)
        .west(.roundRoom)
        .up(.deepCanyon)
        .scenery(.stairs)

    static let nsPassage = Location(.nsPassage)
        .name("North-South Passage")
        .description(
            """
            This is a high north-south passage, which forks to the northeast.
            """
        )
        .north(.chasmRoom)
        .northeast(.deepCanyon)
        .south(.roundRoom)

    static let roundRoom = Location(.roundRoom)
        .name("Round Room")
        .description(
            """
            This is a circular stone room with passages in all directions. Several
            of them have unfortunately been blocked by cave-ins.
            """
        )
        .east(.loudRoom)
        .west(.ewPassage)
        .north(.nsPassage)
        .south(.narrowPassage)
        .southeast(.engravingsCave)
        .inherentlyLit
}

// MARK: - Items

extension RoundRoom {
    static let crack = Item(.crack)
        .name("crack")
        .synonyms("crack")
        .adjectives("narrow")
        .omitDescription
        // Note: Has action handler CRACK-FCN

        // Note: largeBag is now defined in Thief.swift to keep thief-related items together

    static let platinumBar = Item(.platinumBar)
        .name("platinum bar")
        .synonyms("bar", "platinum", "treasure")
        .adjectives("platinum", "large")
        .isTakable
        .description("On the ground is a large platinum bar.")
        .size(20)
        .in(.loudRoom)
        .value(10)
        .isSacred
        // Note: VALUE 10, TVALUE 5, SACREDBIT
}

extension RoundRoom {
    /// Entering the round room starts the thief daemon.
    static let roundRoomHandler = LocationEventHandler(for: .roundRoom) {
        onEnter { context in
            if await !context.location.hasFlag(.isVisited) {
                try ActionResult(
                    .runDaemon(.thiefDaemon)
                )
            } else {
                nil
            }
        }

    }
}
