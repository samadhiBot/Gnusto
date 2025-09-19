import GnustoEngine

// MARK: - Locations

enum Underground {
    static let cellar: Location = Location(
        id: .cellar,
        .name("Cellar"),
        .description(
            """
            You are in a dark and damp cellar with a narrow passageway leading north, and a
            crawlway to the south. On the west is the bottom of a steep metal ramp which is
            unclimbable.
            """
        ),
        .exits(
            .north(.trollRoom),
            .south(.eastOfChasm),
            .west(.steepRamp),
            .up(.livingRoom, via: .trapDoor, blocked: "The trap door is locked from above.")
        )
    )

    static let complexJunction = Location(
        id: .complexJunction,
        .name("Complex Junction"),
        .description("This is a complex junction with passages leading in many directions."),
        .exits(
            .northwest(.roundRoom)
        )
    )

    static let deadEnd = Location(
        id: .deadEnd,
        .name("Dead End"),
        .description("You have come to a dead end."),
        .exits(
            .west(.roundRoom)
        )
    )

    static let eastOfChasm = Location(
        id: .eastOfChasm,
        .name("East of Chasm"),
        .description(
            """
            You are on the east edge of a chasm, the bottom of which cannot be seen. A narrow
            passage goes north, and the path you are on continues to the east.
            """
        ),
        .exits(
            .north(.cellar),
            .east(.gallery)
        )
    )

    static let eastWestPassage = Location(
        id: .eastWestPassage,
        .name("East-West Passage"),
        .description(
            """
            This is a narrow east-west passageway. There is a narrow stairway leading down at
            the north end of the room.
            """
        ),
        .exits(
            .east(.roundRoom),
            .down(.reservoir)
        )
    )

    static let gallery = Location(
        id: .gallery,
        .name("Gallery"),
        .description(
            """
            This is an art gallery. Most of the paintings have been stolen by vandals with
            exceptional taste. The vandals left through either the north or west exits.
            """
        ),
        .exits(
            .north(.studio),
            .west(.eastOfChasm)
        )
    )

    static let maze1 = Location(
        id: .maze1,
        .name("Maze"),
        .description("This is part of a maze of twisty little passages, all alike."),
        .exits(
            .east(.trollRoom)
        )
    )

    static let northSouthPassage = Location(
        id: .northSouthPassage,
        .name("North-South Passage"),
        .description("This is a long north-south passage."),
        .exits(
            .south(.roundRoom)
        )
    )

    static let northeastPassage = Location(
        id: .northeastPassage,
        .name("Northeast Passage"),
        .description("This is a northeast passage."),
        .exits(
            .southwest(.roundRoom)
        )
    )

    static let northwestPassage = Location(
        id: .northwestPassage,
        .name("Northwest Passage"),
        .description("This is a northwest passage."),
        .exits(
            .southeast(.roundRoom)
        )
    )

    static let reservoir = Location(
        id: .reservoir,
        .name("Reservoir"),
        .description("This is a large underground reservoir."),
        .exits(
            .up(.eastWestPassage)
        )
    )

    static let roundRoom = Location(
        id: .roundRoom,
        .name("Round Room"),
        .description(
            """
            This is a circular stone room with passages in all directions. Several of them
            have unfortunate endings.
            """
        ),
        .exits(
            .north(.northSouthPassage),
            .northeast(.northeastPassage),
            .east(.deadEnd),
            .southeast(.complexJunction),
            .south(.southPassage),
            .southwest(.southwestPassage),
            .west(.eastWestPassage),
            .northwest(.northwestPassage)
        ),
        .inherentlyLit
    )

    static let southPassage = Location(
        id: .southPassage,
        .name("South Passage"),
        .description("This is a south passage."),
        .exits(
            .north(.roundRoom)
        )
    )

    static let southwestPassage = Location(
        id: .southwestPassage,
        .name("Southwest Passage"),
        .description("This is a southwest passage."),
        .exits(
            .northeast(.roundRoom)
        )
    )

    static let steepRamp = Location(
        id: .steepRamp,
        .name("Bottom of Ramp"),
        .description(
            """
            You are at the bottom of a steep metal ramp. The ramp leads up to the west, but it
            is too steep and smooth to climb.
            """
        ),
        .exits(
            .east(.cellar)
        )
    )

    static let studio = Location(
        id: .studio,
        .name("Studio"),
        .description(
            """
            This appears to have been an artist's studio. The walls and floors are splattered
            with paints of 69 different colors. Strangely enough, nothing of value is hanging
            here. At the south end of the room is an open door (also covered with paint). A
            dark and narrow chimney leads up from a fireplace; although you might be able to
            get up it, it seems unlikely you could get back down.
            """
        ),
        .exits(
            .south(.gallery),
            .up(.kitchen, blocked: "You try to climb the chimney, but it's too narrow and steep.")
        )
    )
}

// MARK: - Items

extension Underground {
    static let steepRampItem = Item(
        id: .steepRampItem,
        .name("steep metal ramp"),
        .description("The ramp is too steep and smooth to climb."),
        .adjectives("steep", "metal"),
        .synonyms("ramp"),
        .in(.cellar),
        .omitDescription,
        .isClimbable
    )
}

// MARK: - Event Handlers

extension Underground {
    /// Handles the cellar-specific logic, primarily the automatic closing of the trap door
    /// upon first entry.
    ///
    /// This is based on the ZIL `CELLAR-FCN` routine. When the player enters the cellar for the
    /// first time while the trap door is open, the door slams shut and is barred, preventing
    /// an easy return. This is controlled by a custom flag.
    static let cellarHandler = LocationEventHandler(for: .cellar) {
        onEnter { context in
            let isTrapDoorOpen = await context.item(.trapDoor).isOpen
            let isTrapDoorBarred = await context.engine.hasFlag(.trapDoorBarred)

            if isTrapDoorOpen, !isTrapDoorBarred {
                return await ActionResult(
                    "The trap door crashes shut, and you hear someone barring it.",
                    context.item(.trapDoor).clearFlag(.isOpen),
                    context.engine.setFlag(.trapDoorBarred)
                )
            }

            return nil
        }
    }
}
