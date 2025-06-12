import GnustoEngine

// MARK: - Locations

enum Underground {
    static let cellar: Location = Location(
        id: .cellar,
        .name("Cellar"),
        .description("""
            You are in a dark and damp cellar with a narrow passageway leading north, and a
            crawlway to the south. On the west is the bottom of a steep metal ramp which is
            unclimbable.
            """),
        .exits([
            .north: .to(.trollRoom),
            .south: .to(.eastOfChasm),
            .west: .to(.steepRamp),
            .up: .to(.livingRoom, via: .trapDoor, else: "The trap door is locked from above."),
        ])
    )

    static let complexJunction = Location(
        id: .complexJunction,
        .name("Complex Junction"),
        .description("This is a complex junction with passages leading in many directions."),
        .exits([
            .northwest: .to(.roundRoom),
        ])
    )

    static let deadEnd = Location(
        id: .deadEnd,
        .name("Dead End"),
        .description("You have come to a dead end."),
        .exits([
            .west: .to(.roundRoom),
        ])
    )

    static let eastOfChasm = Location(
        id: .eastOfChasm,
        .name("East of Chasm"),
        .description("""
            You are on the east edge of a chasm, the bottom of which cannot be seen. A narrow
            passage goes north, and the path you are on continues to the east.
            """),
        .exits([
            .north: .to(.cellar),
            .east: .to(.gallery),
        ])
    )

    static let eastWestPassage = Location(
        id: .eastWestPassage,
        .name("East-West Passage"),
        .description("""
            This is a narrow east-west passageway. There is a narrow stairway leading down at
            the north end of the room.
            """),
        .exits([
            .east: .to(.roundRoom),
            .west: .to(.trollRoom),
            .down: .to(.reservoir),
        ])
    )

    static let gallery = Location(
        id: .gallery,
        .name("Gallery"),
        .description("""
            This is an art gallery. Most of the paintings have been stolen by vandals with
            exceptional taste. The vandals left through either the north or west exits.
            """),
        .exits([
            .north: .to(.studio),
            .west: .to(.eastOfChasm),
        ])
    )

    static let maze1 = Location(
        id: .maze1,
        .name("Maze"),
        .description("This is part of a maze of twisty little passages, all alike."),
        .exits([
            .east: .to(.trollRoom),
        ])
    )

    static let northSouthPassage = Location(
        id: .northSouthPassage,
        .name("North-South Passage"),
        .description("This is a long north-south passage."),
        .exits([
            .south: .to(.roundRoom),
        ])
    )

    static let northeastPassage = Location(
        id: .northeastPassage,
        .name("Northeast Passage"),
        .description("This is a northeast passage."),
        .exits([
            .southwest: .to(.roundRoom),
        ])
    )

    static let northwestPassage = Location(
        id: .northwestPassage,
        .name("Northwest Passage"),
        .description("This is a northwest passage."),
        .exits([
            .southeast: .to(.roundRoom),
        ])
    )

    static let reservoir = Location(
        id: .reservoir,
        .name("Reservoir"),
        .description("This is a large underground reservoir."),
        .exits([
            .up: .to(.eastWestPassage),
        ])
    )

    static let roundRoom = Location(
        id: .roundRoom,
        .name("Round Room"),
        .description("""
            This is a circular stone room with passages in all directions. Several of them
            have unfortunate endings.
            """),
        .exits([
            .north: .to(.northSouthPassage),
            .northeast: .to(.northeastPassage),
            .east: .to(.deadEnd),
            .southeast: .to(.complexJunction),
            .south: .to(.southPassage),
            .southwest: .to(.southwestPassage),
            .west: .to(.eastWestPassage),
            .northwest: .to(.northwestPassage),
        ])
    )

    static let southPassage = Location(
        id: .southPassage,
        .name("South Passage"),
        .description("This is a south passage."),
        .exits([
            .north: .to(.roundRoom),
        ])
    )

    static let southwestPassage = Location(
        id: .southwestPassage,
        .name("Southwest Passage"),
        .description("This is a southwest passage."),
        .exits([
            .northeast: .to(.roundRoom),
        ])
    )

    static let steepRamp = Location(
        id: .steepRamp,
        .name("Bottom of Ramp"),
        .description("""
            You are at the bottom of a steep metal ramp. The ramp leads up to the west, but it
            is too steep and smooth to climb.
            """),
        .exits([
            .east: .to(.cellar),
        ])
    )

    static let studio = Location(
        id: .studio,
        .name("Studio"),
        .description("""
            This appears to have been an artist's studio. The walls and floors are splattered
            with paints of 69 different colors. Strangely enough, nothing of value is hanging
            here. At the south end of the room is an open door (also covered with paint). A
            dark and narrow chimney leads up from a fireplace; although you might be able to
            get up it, it seems unlikely you could get back down.
            """),
        .exits([
            .south: .to(.gallery),
            .up: .to(
                .kitchen,
                else: "You try to climb the chimney, but it's too narrow and steep."
            ),
        ])
    )

    static let trollRoom = Location(
        id: .trollRoom,
        .name("Troll Room"),
        .description("""
            This is a small room with passages to the east and south and a forbidding hole
            leading west. Bloodstains and deep scratches (perhaps made by an axe) mar the
            walls.
            """),
        .exits([
            .east: .to(.eastWestPassage),
            .south: .to(.cellar),
            .west: .to(.maze1),
        ])
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
        .in(.location(.cellar)),
        .omitDescription,
        .isClimbable
    )

    /*
     <OBJECT TROLL
     (IN TROLL-ROOM)
     (SYNONYM TROLL)
     (ADJECTIVE NASTY)
     (DESC "troll")
     (FLAGS ACTORBIT OPENBIT TRYTAKEBIT)
     (ACTION TROLL-FCN)
     (LDESC
     "A nasty-looking troll, brandishing a bloody axe, blocks all passages
     out of the room.")
     (STRENGTH 2)>
     */

    static let troll = Item(
        id: .troll,
        .name("troll"),
        .synonyms("troll"),
        .adjectives("nasty"),
        .description("""
            A nasty-looking troll, brandishing a bloody axe,
            blocks all passages out of the room.
            """),
        .isCharacter,
        .isOpen,
        .requiresTryTake,
        .in(.location(.trollRoom))
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
    static let cellarHandler = LocationEventHandler { engine, event in
        guard case .onEnter = event else { return nil }

        let isTrapDoorOpen = try await engine.hasFlag(.isOpen, on: .trapDoor)
        let isTrapDoorBarred = await engine.hasFlag(.trapDoorBarred)

        if isTrapDoorOpen, !isTrapDoorBarred {
            return ActionResult(
                message: "The trap door crashes shut, and you hear someone barring it.",
                changes:
                    try await engine.clearFlag(.isOpen, on: .trapDoor),
                    await engine.setFlag(.trapDoorBarred)
            )
        }

        return nil
    }

    static let trollHandler = ItemEventHandler { engine, event in
        guard case .beforeTurn(let command) = event else { return nil }
        
        switch command.verb {
//        case .tell:
//            return ActionResult("The troll isn't much of a conversationalist.")
            
//        case .examine:
//            return ActionResult(
//                try await engine.item(.troll).longDescription
//            )
            
        case .give, .drop:
            guard let object = command.directObject else {
                return nil
            }
            let objectName = try await engine.item(object).name

            // Handle giving/throwing the axe to the troll
            let isPlayerHoldingAxe = try engine.playerIsHolding(.axe)

            if object == .axe && isPlayerHoldingAxe {
                return ActionResult(
                    message: "The troll scratches his head in confusion, then takes the axe.",
                    changes:
                        try await engine.setFlag(.isFighting, on: .troll),
                        try await engine.move(.axe, to: .item(.troll))
                )
            }
            
            // Handle giving/throwing the troll or axe itself
            if object == .troll || object == .axe {
                return ActionResult(
                    "You would have to get the \(objectName) first, and that seems unlikely."
                )
            }
            
            // Handle other objects
            let baseMessage = if command.verb == .drop {
                "The troll, who is remarkably coordinated, catches the \(objectName)"
            } else {
                "The troll, who is not overly proud, graciously accepts the gift"
            }

            // Handle weapons
            if [.knife, .sword, .axe].contains(object) {
                if Int.random(in: 1...100) <= 20 {
                    try await engine.removeCarefully(object)
                    try await engine.removeCarefully(.troll)
                    try await engine.item(.troll).handleMode(.dead)
                    try await engine.setFlag(.trollFlag)
                    return ActionResult(
                        message: """
                            \(baseMessage) and eats it hungrily. Poor troll,
                            he dies from an internal hemorrhage and his carcass
                            disappears in a sinister black fog.
                            """,
                        changes:
                            try await engine.remove(.troll),
                            try await engine.remove(object),
                    )
                } else {
                    return ActionResult(
                        message: """
                            \(baseMessage) and, being for the moment sated, throws it back.
                            Fortunately, the troll has poor control, and the \(objectName)
                            falls to the floor. He does not look pleased.
                            """,
                        changes:
                            try await engine.move(object, to: .location(.trollRoom)),
                            try await engine.setFlag(.isFighting, on: .troll)
                    )
                }
            } else {
                try await engine.removeCarefully(object)
                return ActionResult("""
                    \(baseMessage) and not having the most discriminating
                    tastes, gleefully eats it.
                    """)
            }
            
        case .take, .move:
            return ActionResult("""
                The troll spits in your face, grunting "Better luck next time"
                in a rather barbarous accent.
                """)

        case .push:
            return ActionResult("The troll laughs at your puny gesture.")

        case .listen:
            return ActionResult("""
                Every so often the troll says something, probably 
                uncomplimentary, in his guttural tongue.
                """)

        case .thinkAbout:
            if try await engine.hasFlag(.trollFlag) {
                return ActionResult("Unfortunately, the troll can't hear you.")
            }
            return nil

        default:
            return nil
        }
    }

//    // MARK: - Troll Mode Handlers
//
//    private static func handleTrollBusyMode(_ engine: Engine) async throws {
//        if try await engine.item(.axe).location == .troll {
//            return
//        }
//
//        if try await engine.item(.axe).location == .location(.trollRoom) && Int.random(in: 1...100) <= 75 {
//            try await engine.item(.axe).isNotDescribable = true
//            try await engine.item(.axe).isWeapon = false
//            try await engine.move(.axe, to: .troll)
//            try await engine.item(.troll).longDescription = "A nasty-looking troll, brandishing a bloody axe, blocks all passages out of the room."
//
//            if try await engine.item(.troll).location == .location(.trollRoom) {
//                try await engine.tell("The troll, angered and humiliated, recovers his weapon. He appears to have an axe to grind with you.")
//            }
//        } else if try await engine.item(.troll).location == .location(.trollRoom) {
//            try await engine.item(.troll).longDescription = "A pathetically babbling troll is here."
//            try await engine.tell("The troll, disarmed, cowers in terror, pleading for his life in the guttural tongue of the trolls.")
//        }
//    }
//
//    private static func handleTrollDeadMode(_ engine: Engine) async throws {
//        if try await engine.item(.axe).location == .troll {
//            try await engine.move(.axe, to: .location(.trollRoom))
//            try await engine.item(.axe).isNotDescribable = false
//            try await engine.item(.axe).isWeapon = true
//        }
//        try await engine.setFlag(.trollFlag)
//    }
//
//    private static func handleTrollUnconsciousMode(_ engine: Engine) async throws {
//        try await engine.item(.troll).isFighting = false
//        if try await engine.item(.axe).location == .troll {
//            try await engine.move(.axe, to: .location(.trollRoom))
//            try await engine.item(.axe).isNotDescribable = false
//            try await engine.item(.axe).isWeapon = true
//        }
//        try await engine.item(.troll).longDescription = "An unconscious troll is sprawled on the floor. All passages out of the room are open."
//        try await engine.setFlag(.trollFlag)
//    }
//
//    private static func handleTrollConsciousMode(_ engine: Engine) async throws {
//        if try await engine.item(.troll).location == .location(.trollRoom) {
//            try await engine.item(.troll).isFighting = true
//            try await engine.tell("The troll stirs, quickly resuming a fighting stance.")
//        }
//
//        if try await engine.item(.axe).location == .troll {
//            try await engine.item(.troll).longDescription = "A nasty-looking troll, brandishing a bloody axe, blocks all passages out of the room."
//        } else if try await engine.item(.axe).location == .location(.trollRoom) {
//            try await engine.item(.axe).isNotDescribable = true
//            try await engine.item(.axe).isWeapon = false
//            try await engine.move(.axe, to: .troll)
//            try await engine.item(.troll).longDescription = "A nasty-looking troll, brandishing a bloody axe, blocks all passages out of the room."
//        } else {
//            try await engine.item(.troll).longDescription = "A troll is here."
//        }
//        try await engine.clearFlag(.trollFlag)
//    }
//
//    private static func handleTrollFirstMode(_ engine: Engine) async throws -> Bool {
//        if Int.random(in: 1...100) <= 33 {
//            try await engine.item(.troll).isFighting = true
//            return true
//        }
//        return false
//    }
}
