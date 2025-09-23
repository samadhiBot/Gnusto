import GnustoEngine

enum RoundRoom {
    static let chasmRoom = Location(
        id: .chasmRoom,
        .name("Chasm"),
        .description(
            """
            A chasm runs southwest to northeast and the path follows it. You are
            on the south side of the chasm, where a crack opens into a passage.
            """
        ),
        .exits(
            .northeast(.reservoirSouth),
            .southwest(.ewPassage),
            .up(.ewPassage),
            .south(.nsPassage)
            // Note: DOWN exit has custom message
        ),
        .localGlobals(.crack, .stairs)
    )

    static let dampCave = Location(
        id: .dampCave,
        .name("Damp Cave"),
        .description(
            """
            This cave has exits to the west and east, and narrows to a crack toward
            the south. The earth is particularly damp here.
            """
        ),
        .exits(
            .west(.loudRoom),
            .east(.whiteCliffsNorth)
            // Note: SOUTH exit has custom message about being too narrow
        ),
        .localGlobals(.crack)
    )

    static let deepCanyon = Location(
        id: .deepCanyon,
        .name("Deep Canyon"),
        .description(
            """
            You are on the south side of a deep canyon.
            """
        ),
        .exits(
            .northwest(.reservoirSouth),
            .east(.damRoom),
            .southwest(.nsPassage),
            .down(.loudRoom)
        ),
        .localGlobals(.stairs)
    )

    static let ewPassage = Location(
        id: .ewPassage,
        .name("East-West Passage"),
        .description(
            """
            This is a narrow east-west passageway. There is a narrow stairway
            leading down at the north end of the room.
            """
        ),
        .exits(
            .east(.roundRoom),
            .west(.trollRoom),
            .down(.chasmRoom),
            .north(.chasmRoom)
        ),
        .localGlobals(.stairs)
    )

    static let loudRoom = Location(
        id: .loudRoom,
        .name("Loud Room"),
        .description(
            """
            This is a room where every sound is amplified.
            """
        ),
        .exits(
            .east(.dampCave),
            .west(.roundRoom),
            .up(.deepCanyon)
        ),
        .localGlobals(.stairs)
    )

    static let nsPassage = Location(
        id: .nsPassage,
        .name("North-South Passage"),
        .description(
            """
            This is a high north-south passage, which forks to the northeast.
            """
        ),
        .exits(
            .north(.chasmRoom),
            .northeast(.deepCanyon),
            .south(.roundRoom)
        )
    )

    static let roundRoom = Location(
        id: .roundRoom,
        .name("Round Room"),
        .description(
            """
            This is a circular stone room with passages in all directions. Several
            of them have unfortunately been blocked by cave-ins.
            """
        ),
        .exits(
            .east(.loudRoom),
            .west(.ewPassage),
            .north(.nsPassage),
            .south(.narrowPassage),
            .southeast(.engravingsCave)
        ),
        .inherentlyLit
    )
}

// MARK: - Items

extension RoundRoom {
    static let climbableCliff = Item(
        id: .climbableCliff,
        .name("cliff"),
        .synonyms("wall", "cliff", "walls", "ledge"),
        .adjectives("rocky", "sheer"),
        .omitDescription,
        .isClimbable
        // Note: Has action handler CLIFF-OBJECT
    )

    static let crack = Item(
        id: .crack,
        .name("crack"),
        .synonyms("crack"),
        .adjectives("narrow"),
        .omitDescription
        // Note: Has action handler CRACK-FCN
    )

    // Note: largeBag is now defined in Thief.swift to keep thief-related items together

    static let platinumBar = Item(
        id: .platinumBar,
        .name("platinum bar"),
        .synonyms("bar", "platinum", "treasure"),
        .adjectives("platinum", "large"),
        .isTakable,
        .description("On the ground is a large platinum bar."),
        .size(20),
        .in(.loudRoom),
        .value(10),
        .isSacred
        // Note: VALUE 10, TVALUE 5, SACREDBIT
    )

    static let stiletto = Item(
        id: .stiletto,
        .name("stiletto"),
        .synonyms("stiletto"),
        .adjectives("vicious"),
        .isWeapon,
        .requiresTryTake,
        .isTakable,
        .omitDescription,
        .size(10),
        .in(.item(.thief))
        // Note: Has action handler STILETTO-FUNCTION
    )
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
