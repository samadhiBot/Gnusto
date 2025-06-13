import GnustoEngine

enum Troll {
    static let troll = Item(
        id: .troll,
        .name("troll"),
        .synonyms("troll"),
        .adjectives("nasty"),
        .description("""
            A nasty-looking troll, brandishing a bloody axe,
            blocks all passages out of the room.
            """),
        .in(.location(.trollRoom)),
        .isCharacter,
        .isOpen,
        .requiresTryTake,
        .strength(2)
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

//    static let trollHandler = ItemEventHandler { engine, event in
//        guard case .beforeTurn(let command) = event else { return nil }
//
//        switch command.verb {
//            //        case .tell:
//            //            return ActionResult("The troll isn't much of a conversationalist.")
//
//            //        case .examine:
//            //            return ActionResult(
//            //                try await engine.item(.troll).longDescription
//            //            )
//
//        case .give, .drop:
//            guard let object = command.directObject else {
//                return nil
//            }
//            let objectName = try await engine.item(object).name
//
//            // Handle giving/throwing the axe to the troll
//            let isPlayerHoldingAxe = try engine.playerIsHolding(.axe)
//
//            if object == .axe && isPlayerHoldingAxe {
//                return ActionResult(
//                    message: "The troll scratches his head in confusion, then takes the axe.",
//                    changes:
//                        try await engine.setFlag(.isFighting, on: .troll),
//                    try await engine.move(.axe, to: .item(.troll))
//                )
//            }
//
//            // Handle giving/throwing the troll or axe itself
//            if object == .troll || object == .axe {
//                return ActionResult(
//                    "You would have to get the \(objectName) first, and that seems unlikely."
//                )
//            }
//
//            // Handle other objects
//            let baseMessage = if command.verb == .drop {
//                "The troll, who is remarkably coordinated, catches the \(objectName)"
//            } else {
//                "The troll, who is not overly proud, graciously accepts the gift"
//            }
//
//            // Handle weapons
//            if [.knife, .sword, .axe].contains(object) {
//                if engine.randomizer() <= 0.2 {
//                    try await engine.item(.troll).handleMode(.dead)
//                    try await engine.setFlag(.trollFlag)
//                    return ActionResult(
//                        message: """
//                            \(baseMessage) and eats it hungrily. Poor troll,
//                            he dies from an internal hemorrhage and his carcass
//                            disappears in a sinister black fog.
//                            """,
//                        changes:
//                            try await engine.remove(.troll),
//                        try await engine.remove(object),
//                    )
//                } else {
//                    return ActionResult(
//                        message: """
//                            \(baseMessage) and, being for the moment sated, throws it back.
//                            Fortunately, the troll has poor control, and the \(objectName)
//                            falls to the floor. He does not look pleased.
//                            """,
//                        changes:
//                            try await engine.move(object, to: .location(.trollRoom)),
//                        try await engine.setFlag(.isFighting, on: .troll)
//                    )
//                }
//            } else {
//                try await engine.removeCarefully(object)
//                return ActionResult("""
//                    \(baseMessage) and not having the most discriminating
//                    tastes, gleefully eats it.
//                    """)
//            }
//
//        case .take, .move:
//            return ActionResult("""
//                The troll spits in your face, grunting "Better luck next time"
//                in a rather barbarous accent.
//                """)
//
//        case .push:
//            return ActionResult("The troll laughs at your puny gesture.")
//
//        case .listen:
//            return ActionResult("""
//                Every so often the troll says something, probably 
//                uncomplimentary, in his guttural tongue.
//                """)
//
//        case .thinkAbout:
//            if try await engine.hasFlag(.trollFlag) {
//                return ActionResult("Unfortunately, the troll can't hear you.")
//            }
//            return nil
//
//        default:
//            return nil
//        }
//    }
}

/*
FUNCTION TROLL_FCN(MODE = null)
    IF current_verb == TELL THEN
        SET global P_CONT = false
        PRINT "The troll isn't much of a conversationalist."
        
    ELSE IF MODE == F_BUSY THEN
        IF AXE is in TROLL's inventory THEN
            RETURN false
        ELSE IF AXE is in current room AND random_chance(75, 90) THEN
            SET AXE.NDESCBIT = true
            SET AXE.WEAPONBIT = false
            MOVE AXE to TROLL's inventory
            SET TROLL.LDESC = "A nasty-looking troll, brandishing a bloody axe, blocks all passages out of the room."
            IF TROLL is in current room THEN
                PRINT "The troll, angered and humiliated, recovers his weapon. He appears to have an axe to grind with you."
            RETURN true
        ELSE
            RETURN true
            
        IF TROLL is in current room THEN
            SET TROLL.LDESC = "A pathetically babbling troll is here."
            PRINT "The troll, disarmed, cowers in terror, pleading for his life in the guttural tongue of the trolls."
            RETURN true
            
    ELSE IF MODE == F_DEAD THEN
        IF AXE is in TROLL's inventory THEN
            MOVE AXE to current room
            SET AXE.NDESCBIT = false
            SET AXE.WEAPONBIT = true
        SET global TROLL_FLAG = true
        
    ELSE IF MODE == F_UNCONSCIOUS THEN
        SET TROLL.FIGHTBIT = false
        IF AXE is in TROLL's inventory THEN
            MOVE AXE to current room
            SET AXE.NDESCBIT = false
            SET AXE.WEAPONBIT = true
        SET TROLL.LDESC = "An unconscious troll is sprawled on the floor. All passages out of the room are open."
        SET global TROLL_FLAG = true
        
    ELSE IF MODE == F_CONSCIOUS THEN
        IF TROLL is in current room THEN
            SET TROLL.FIGHTBIT = true
            PRINT "The troll stirs, quickly resuming a fighting stance."
            
        IF AXE is in TROLL's inventory THEN
            SET TROLL.LDESC = "A nasty-looking troll, brandishing a bloody axe, blocks all passages out of the room."
        ELSE IF AXE is in TROLL_ROOM THEN
            SET AXE.NDESCBIT = true
            SET AXE.WEAPONBIT = false
            MOVE AXE to TROLL's inventory
            SET TROLL.LDESC = "A nasty-looking troll, brandishing a bloody axe, blocks all passages out of the room."
        ELSE
            SET TROLL.LDESC = "A troll is here."
            
        SET global TROLL_FLAG = false
        
    ELSE IF MODE == F_FIRST THEN
        IF random_chance(33) THEN
            SET TROLL.FIGHTBIT = true
            SET global P_CONT = false
            RETURN true
            
    ELSE IF MODE is null THEN
        IF current_verb == EXAMINE THEN
            PRINT TROLL.LDESC
            
        ELSE IF (current_verb == THROW OR GIVE) AND direct_object exists AND indirect_object == TROLL
                OR current_verb == TAKE OR MOVE OR MUNG THEN
            CALL AWAKEN(TROLL)
            
            IF current_verb == THROW OR GIVE THEN
                IF direct_object == AXE AND AXE is in player's inventory THEN
                    PRINT "The troll scratches his head in confusion, then takes the axe."
                    SET TROLL.FIGHTBIT = true
                    MOVE AXE to TROLL's inventory
                    RETURN true
                ELSE IF direct_object == TROLL OR AXE THEN
                    PRINT "You would have to get the " + direct_object + " first, and that seems unlikely."
                    RETURN true
                    
                IF current_verb == THROW THEN
                    PRINT "The troll, who is remarkably coordinated, catches the " + direct_object
                ELSE
                    PRINT "The troll, who is not overly proud, graciously accepts the gift"
                    
                IF random_chance(20) AND (direct_object == KNIFE OR SWORD OR AXE) THEN
                    REMOVE direct_object
                    PRINT " and eats it hungrily. Poor troll, he dies from an internal hemorrhage and his carcass disappears in a sinister black fog."
                    REMOVE TROLL
                    CALL TROLL.ACTION(F_DEAD)
                    SET global TROLL_FLAG = true
                ELSE IF direct_object == KNIFE OR SWORD OR AXE THEN
                    MOVE direct_object to current room
                    PRINT " and, being for the moment sated, throws it back. Fortunately, the troll has poor control, and the " + direct_object + " falls to the floor. He does not look pleased."
                    SET TROLL.FIGHTBIT = true
                ELSE
                    PRINT " and not having the most discriminating tastes, gleefully eats it."
                    REMOVE direct_object
                    
            ELSE IF current_verb == TAKE OR MOVE THEN
                PRINT "The troll spits in your face, grunting \"Better luck next time\" in a rather barbarous accent."
                
            ELSE IF current_verb == MUNG THEN
                PRINT "The troll laughs at your puny gesture."
                
        ELSE IF current_verb == LISTEN THEN
            PRINT "Every so often the troll says something, probably uncomplimentary, in his guttural tongue."
            
        ELSE IF TROLL_FLAG is true AND current_verb == HELLO THEN
            PRINT "Unfortunately, the troll can't hear you."
END FUNCTION
 
 */
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
