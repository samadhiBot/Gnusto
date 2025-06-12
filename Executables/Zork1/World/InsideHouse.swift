import GnustoEngine

// MARK: - Inside the House

enum InsideHouse {
    static let attic = Location(
        id: .attic,
        .name("Attic"),
        .description("""
            This is the attic. The only exit is a stairway leading down.
            """),
        .exits([
            .down: .to(.kitchen, via: .stairs)
        ]),
        .localGlobals(.stairs)
    )

    static let kitchen = Location(
        id: .kitchen,
        .name("Kitchen"),
        .exits([
            .west: .to(.livingRoom),
            .up: .to(.attic, via: .stairs),
            // Note: EAST and OUT exits to east-of-house conditional on kitchen window being open
            // Note: DOWN exit to studio conditional on FALSE-FLAG
        ]),
        .inherentlyLit,
        .localGlobals(.kitchenWindow, .chimney, .stairs)
    )

    static let livingRoom = Location(
        id: .livingRoom,
        .name("Living Room"),
        .description("""
            You are in the living room. There is a doorway to the east, a wooden door with
            strange gothic lettering to the west, which appears to be nailed shut, a trophy case,
            and a large oriental rug in the center of the room.
            """),
        .exits([
            .east: .to(.kitchen),
            .west: .blocked("The door is nailed shut."),
            .down: .to(.cellar, via: .trapDoor),
        ]),
        .inherentlyLit,
        .localGlobals(.stairs)
    )
}

// MARK: - Items

extension InsideHouse {
    static let atticTable = Item(
        id: .atticTable,
        .name("table"),
        .synonyms("table"),
        .omitDescription,
        .isContainer,
        .isOpen,
        .isSurface,
        .capacity(40),
        .in(.location(.attic))
    )

    static let bottle = Item(
        id: .bottle,
        .name("glass bottle"),
        .synonyms("bottle", "container"),
        .adjectives("clear", "glass"),
        .isTakable,
        .isTransparent,
        .isContainer,
        .firstDescription("A bottle is sitting on the table."),
        .capacity(4),
        .in(.item(.kitchenTable))
        // Note: Has action handler BOTTLE-FUNCTION
    )

    static let chimney = Item(
        id: .chimney,
        .name("chimney"),
        .description("The chimney leads upward, and looks climbable."),
        .adjectives("dark", "narrow"),
        .synonyms("chimney"),
        .in(.location(.kitchen)),
        .omitDescription,
        .isClimbable
    )

    static let garlic = Item(
        id: .garlic,
        .name("clove of garlic"),
        .synonyms("garlic", "clove"),
        .isTakable,
        .isEdible,
        .size(4),
        .in(.item(.sandwichBag))
        // Note: Has action handler GARLIC-F
    )

    static let kitchenTable = Item(
        id: .kitchenTable,
        .name("kitchen table"),
        .synonyms("table"),
        .adjectives("kitchen"),
        .omitDescription,
        .isContainer,
        .isOpen,
        .isSurface,
        .capacity(50),
        .in(.location(.kitchen))
    )

    static let knife = Item(
        id: .knife,
        .name("nasty knife"),
        .synonyms("knives", "knife", "blade"),
        .adjectives("nasty", "unrusty"),
        .isTakable,
        .isWeapon,
        .requiresTryTake,
        .firstDescription("On a table is a nasty-looking knife."),
        .in(.item(.atticTable))
        // Note: Has action handler KNIFE-F
    )

    static let lamp = Item(
        id: .lamp,
        .name("brass lantern"),
        .synonyms("lamp", "lantern", "light"),
        .adjectives("brass"),
        .isTakable,
        .isLightSource,
        .isDevice,
        .firstDescription("A battery-powered brass lantern is on the trophy case."),
        .description("There is a brass lantern (battery-powered) here."),
        .size(15),
        .in(.location(.livingRoom))
        // Note: Has action handler LANTERN
    )

    static let lunch = Item(
        id: .lunch,
        .name("lunch"),
        .synonyms("food", "sandwich", "lunch", "dinner"),
        .adjectives("hot", "pepper"),
        .isTakable,
        .isEdible,
        .description("A hot pepper sandwich is here."),
        .in(.item(.sandwichBag))
    )

    static let map = Item(
        id: .map,
        .name("ancient map"),
        .synonyms("parchment", "map"),
        .adjectives("antique", "old", "ancient"),
        .isInvisible,
        .isReadable,
        .isTakable,
        .firstDescription("In the trophy case is an ancient parchment which appears to be a map."),
        .readText("""
            The map shows a forest with three clearings. The largest clearing contains
            a house. Three paths leave the large clearing. One of these paths, leading
            southwest, is marked "To Stone Barrow".
            """),
        .size(2),
        .in(.item(.trophyCase))
    )

    static let rope = Item(
        id: .rope,
        .name("rope"),
        .synonyms("rope", "hemp", "coil"),
        .adjectives("large"),
        .isTakable,
        .requiresTryTake,
        .firstDescription("A large coil of rope is lying in the corner."),
        .size(10),
        .in(.location(.attic))
        // Note: Has action handler ROPE-FUNCTION, SACREDBIT
    )

    static let rug = Item(
        id: .rug,
        .name("carpet"),
        .synonyms("rug", "carpet"),
        .adjectives("large", "oriental"),
        .omitDescription,
        .requiresTryTake,
        .in(.location(.livingRoom))
        // Note: Has action handler RUG-FCN
    )

    static let sandwichBag = Item(
        id: .sandwichBag,
        .name("brown sack"),
        .synonyms("bag", "sack"),
        .adjectives("brown", "elongated", "smelly"),
        .isTakable,
        .isContainer,
        .isOpenable,
        .isFlammable,
        .firstDescription("On the table is an elongated brown sack, smelling of hot peppers."),
        .capacity(9),
        .size(9),
        .in(.item(.kitchenTable))
        // Note: Has action handler SANDWICH-BAG-FCN
    )

    static let sword = Item(
        id: .sword,
        .name("sword"),
        .synonyms("sword", "orcrist", "glamdring", "blade"),
        .adjectives("elvish", "old", "antique"),
        .isTakable,
        .isWeapon,
        .requiresTryTake,
        .firstDescription("Above the trophy case hangs an elvish sword of great antiquity."),
        .size(30),
        .in(.location(.livingRoom))
        // Note: Has action handler SWORD-FCN, TVALUE 0
    )

    static let trapDoor = Item(
        id: .trapDoor,
        .name("trap door"),
        .synonyms("door", "trapdoor", "trap-door", "cover"),
        .adjectives("trap", "dusty"),
        .isDoor,
        .omitDescription,
        .isInvisible,
        .in(.location(.livingRoom))
        // Note: Has action handler TRAP-DOOR-FCN
    )

    static let trophyCase = Item(
        id: .trophyCase,
        .name("trophy case"),
        .synonyms("case"),
        .adjectives("trophy"),
        .isTransparent,
        .isContainer,
        .omitDescription,
        .requiresTryTake,
        .isSearchable,
        .capacity(10000),
        .in(.location(.livingRoom))
        // Note: Has action handler TROPHY-CASE-FCN
    )

    static let water = Item(
        id: .water,
        .name("quantity of water"),
        .description("It's just water."),
        .synonyms("water", "h2o", "liquid"),
        .in(.item(.bottle)),
        .isTakable
    )

    static let woodenDoor = Item(
        id: .woodenDoor,
        .name("wooden door"),
        .synonyms("door", "lettering", "writing"),
        .adjectives("wooden", "gothic", "strange", "west"),
        .isReadable,
        .isDoor,
        .omitDescription,
        .isTransparent,
        .readText("The engravings translate to \"This space intentionally left blank.\""),
        .in(.location(.livingRoom))
        // Note: Has action handler FRONT-DOOR-FCN
    )

    static let brokenLamp = Item(
        id: .brokenLamp,
        .name("broken lamp"),
        .synonyms("lamp", "lantern", "light"),
        .adjectives("broken", "smashed"),
        .description("There is a broken lamp here."),
        .size(15),
        .in(.nowhere)
    )
}

// MARK: - Computers

extension InsideHouse {
    static let kitchenComputer = LocationComputer { attributeID, gameState in
        switch attributeID {
        case .description:
            let windowState = if try gameState.hasFlag(.isOpen, on: .kitchenWindow) {
                "open"
            } else {
                "slightly ajar"
            }
            return .string("""
                You are in the kitchen of the white house. A table seems to
                have been used recently for the preparation of food. A passage
                leads to the west and a dark staircase can be seen leading
                upward. A dark chimney leads down and to the east is a small
                window which is \(windowState).
                """)
        default:
            return nil
        }
    }

        /// Handles special lamp interactions based on the original ZIL `LANTERN` routine.
    ///
    /// This handler manages lamp behavior including:
    /// - THROW: Smashes lamp and creates broken lamp
    /// - TURN ON: Lights lamp (unless burned out)
    /// - TURN OFF: Extinguishes lamp (unless burned out)
    /// - EXAMINE: Shows lamp state (burned out, on, or off)
    static let lampHandler = ItemEventHandler { engine, event in
        switch event {
        case .beforeTurn(let command):
            // Flag to track if lamp is burned out (equivalent to ZIL's RMUNGBIT)
            let burnedOutFlag = AttributeID("isBurnedOut")

            let isBurnedOut = try await engine.hasFlag(burnedOutFlag, on: .lamp)
            let isOn = try await engine.hasFlag(.isOn, on: .lamp)

            switch command.verb {
            case VerbID("throw"):
                let playerLocation = try await engine.playerLocation()

                                let changes: [StateChange] = [
                    // Turn off the lamp's light source
                    try await engine.clearFlag(.isOn, on: .lamp),
                    // Remove the lamp
                    try await engine.move(.lamp, to: .nowhere),
                    // Add broken lamp to current location
                    try await engine.move(.brokenLamp, to: .location(playerLocation.id))
                ].compactMap { $0 }

                return ActionResult(
                    message: "The lamp has smashed into the floor, and the light has gone out.",
                    stateChanges: changes
                )

            case .turnOn:
                return isBurnedOut ? ActionResult("A burned-out lamp won't light.") : nil

            case .turnOff:
                return isBurnedOut ? ActionResult("The lamp has already burned out.") : nil

            case .examine:
                let statusMessage = if isBurnedOut {
                    "has burned out."
                } else if isOn {
                    "is on."
                } else {
                    "is turned off."
                }

                return ActionResult("The lamp \(statusMessage)")

            default:
                return nil // Let other handlers deal with it
            }
        case .afterTurn:
            return nil
        }
    }
}

// MARK: - Event handlers

extension InsideHouse {
    /// Handles special rug interactions based on the original ZIL `RUG-FCN`.
    ///
    /// This handler manages complex rug behavior including:
    /// - RAISE: Heavy rug notifications and irregularity hints
    /// - MOVE/PUSH: Moving the rug to reveal trap door
    /// - TAKE: Rug is too heavy to carry
    /// - LOOK UNDER: Temporary trap door revelation
    /// - CLIMB ON: Irregularity detection and magic carpet joke
    static let rugHandler = ItemEventHandler { engine, event in
        switch event {
        case .beforeTurn(let command):
            let wasRugMoved = await engine.hasFlag(.rugMoved)
            let trapDoorOpen = try await engine.hasFlag(.isOpen, on: .trapDoor)

            switch command.verb {
            case .raise:
                let baseMessage = "The rug is too heavy to lift"
                if wasRugMoved {
                    return ActionResult("\(baseMessage).")
                } else {
                    return ActionResult("""
                        \(baseMessage), but in trying to take it you have
                        noticed an irregularity beneath it.
                        """)
                }

            case .move, .push:
                if wasRugMoved {
                    return ActionResult("""
                        Having moved the carpet previously, you find it impossible to move
                        it again.
                        """)
                } else {
                    // Move the rug and reveal the trap door
                    let trapDoor = try await engine.item(.trapDoor)
                    return ActionResult(
                        message: """
                            With a great effort, the rug is moved to one side of the room,
                            revealing the dusty cover of a closed trap door.
                            """,
                        stateChanges: [
                            // Mark rug as moved
                            await engine.setFlag(.rugMoved),
                            // Make trap door visible
                            await engine.clearFlag(.isInvisible, on: trapDoor)
                        ]
                    )
                }

            case .take:
                return ActionResult("The rug is extremely heavy and cannot be carried.")

            case .lookUnder:
                // Only show trap door if rug hasn't been moved and trap door isn't open
                if !wasRugMoved && !trapDoorOpen {
                    return ActionResult("""
                        Underneath the rug is a closed trap door. As you drop the corner of the
                        rug, the trap door is once again concealed from view.
                        """)
                } else {
                    return ActionResult("You find nothing of interest.")
                }

            case .climbOn:
                if !wasRugMoved && !trapDoorOpen {
                    return ActionResult("""
                        As you sit, you notice an irregularity underneath it. Rather than be
                        uncomfortable, you stand up again.
                        """)
                } else {
                    return ActionResult("I suppose you think it's a magic carpet?")
                }

            default:
                return nil // Let other handlers deal with it
            }
        case .afterTurn:
            return nil
        }
    }

    /// Handles trap door interactions based on the original ZIL `TRAP-DOOR-FCN`.
    ///
    /// This handler manages the trap door's behavior depending on the player's location
    /// (Living Room vs. Cellar) and the state of the door.
    /// - **Living Room**: Allows opening, closing, and looking under the door with custom messages.
    /// - **Cellar**: Prevents opening from below and has special behavior for closing.
    /// - **Raise**: Treats `RAISE` as an alias for `OPEN`.
    static let trapDoorHandler = ItemEventHandler { engine, event in
        guard case .beforeTurn(let command) = event else { return nil }

        let location = await engine.playerLocationID
        let isTrapDoorOpen = try await engine.hasFlag(.isOpen, on: .trapDoor)

        switch command.verb {
        case .open, .raise:
            if isTrapDoorOpen {
                return ActionResult("The trap door is already open.")
            }
            if location == .cellar {
                return ActionResult("The door is locked from above.")
            }
            return ActionResult(
                message: """
                    The door reluctantly opens to reveal a rickety staircase
                    descending into darkness.
                    """,
                stateChanges: [
                    try await engine.setFlag(.isOpen, on: .trapDoor)
                ]
            )

        case .close:
            if !isTrapDoorOpen {
                return ActionResult("The trap door is already closed.")
            }
            if location == .cellar {
                return ActionResult("You can't close the trap door from below.")
            }
            return ActionResult(
                message: "The door swings shut and closes.",
                stateChanges: [
                    try await engine.clearFlag(.isOpen, on: .trapDoor)
                ]
            )

        case .lookUnder:
            if location == .cellar { break }
            if isTrapDoorOpen {
                return ActionResult("You see a rickety staircase descending into darkness.")
            } else {
                return ActionResult("It's closed.")
            }

        default:
            break
        }

        return nil
    }

    /// Handles sword glow functionality based on the ZIL `SWORD-FCN` and `I-SWORD` routines.
    ///
    /// This handler manages:
    /// - TAKE: Enables the sword glow daemon when taken (equivalent to ENABLE <QUEUE I-SWORD -1>)
    /// - EXAMINE: Shows appropriate glow messages based on current glow state
    /// - Daemon activation: Checks current location and adjacent locations for monsters
    static let swordHandler = ItemEventHandler { engine, event in
        switch event {
        case .beforeTurn(let command):
            switch command.verb {
            case .take:
                // Enable sword glow daemon when taken (like SWORD-FCN in ZIL)
                return ActionResult(
                    message: "Taken.",
                    sideEffects: [
                        SideEffect(type: .runDaemon, targetID: .daemon(.swordDaemon))
                    ]
                )

            case .drop:
                // Disable sword glow daemon when dropped
                return ActionResult(
                    message: "Dropped.",
                    sideEffects: [
                        SideEffect(type: .stopDaemon, targetID: .daemon(.swordDaemon))
                    ]
                )

            case .examine:
                // Show glow message based on current glow level (like SWORD-FCN in ZIL)
                let glowLevel = await engine.global(.swordGlowLevel) ?? 0
                let baseDescription = "Your sword is glowing"

                switch glowLevel {
                case 1:
                    return ActionResult("\(baseDescription) with a faint blue glow.")
                case 2:
                    return ActionResult("\(baseDescription) very brightly.")
                default:
                    return ActionResult("It's just a sword.")
                }

            default:
                return nil
            }

        case .afterTurn:
            return nil
        }
    }

    /// Sword glow daemon based on the ZIL `I-SWORD` interrupt routine.
    ///
    /// This daemon runs every turn when enabled and updates the sword glow level based on
    /// the presence of monsters in the current location or adjacent locations.
    /// - Level 0: No monsters nearby (no glow)
    /// - Level 1: Monster in adjacent location (faint blue glow)
    /// - Level 2: Monster in current location (very bright glow)
    static let swordDaemon = DaemonDefinition { engine in
        print("🎾 swordGlowDaemon")

        let currentLocation = try await engine.playerLocation()
        var newGlowLevel = 0

        // Check for monsters in current location (highest priority)
        let currentLocationItems = try await engine.itemsInLocation(currentLocation.id)
        let monstersInCurrentLocation = currentLocationItems.filter { $0.isMonster }

        if !monstersInCurrentLocation.isEmpty {
            newGlowLevel = 2 // Very bright glow
        } else {
            // Check adjacent locations for monsters
            for exit in currentLocation.exits.values {
                guard let destination = exit.destinationID else { continue }
                let adjacentLocationItems = try await engine.itemsInLocation(destination)
                let monstersInAdjacentLocation = adjacentLocationItems.filter { $0.isMonster }

                if !monstersInAdjacentLocation.isEmpty {
                    newGlowLevel = 1 // Faint blue glow
                    break
                }
            }
        }

        // Update glow level if changed
        let currentGlowLevel = await engine.global(.swordGlowLevel) ?? 0
        if newGlowLevel != currentGlowLevel {
            let glowChange = StateChange(
                entityID: .global,
                attribute: .globalState(attributeID: .swordGlowLevel),
                oldValue: currentGlowLevel == 0 ? nil : .int(currentGlowLevel),
                newValue: .int(newGlowLevel)
            )
            return ActionResult(stateChanges: [glowChange])
        }

        return nil
    }
}

private extension Item {
    var isMonster: Bool {
        switch id {
        case .troll, .thief, .cyclops, .bat, .ghosts: true
        default: false
        }
    }
}
