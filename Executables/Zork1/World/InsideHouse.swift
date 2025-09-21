import GnustoEngine

// MARK: - Inside the House

enum InsideHouse {
    static let attic = Location(
        id: .attic,
        .name("Attic"),
        .description(
            """
            This is the attic. The only exit is a stairway leading down.
            """
        ),
        .exits(
            .down(.kitchen, via: .stairs)
        ),
        .localGlobals(.stairs)
    )

    static let kitchen = Location(
        id: .kitchen,
        .name("Kitchen"),
        .exits(
            .west(.livingRoom),
            .up(.attic, via: .stairs)
            // Note: EAST and OUT exits to east-of-house conditional on kitchen window being open
            // Note: DOWN exit to studio conditional on FALSE-FLAG
        ),
        .inherentlyLit,
        .localGlobals(.kitchenWindow, .chimney, .stairs)
    )

    static let livingRoom = Location(
        id: .livingRoom,
        .name("Living Room"),
        .description(
            """
            You are in the living room. There is a doorway to the east, a wooden door with
            strange gothic lettering to the west, which appears to be nailed shut, a trophy case,
            and a large oriental rug in the center of the room.
            """
        ),
        .exits(
            .east(.kitchen),
            .west(blocked: "The door is nailed shut."),
            .down(.cellar, via: .trapDoor)
        ),
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
        .in(.attic)
    )

    static let bottle = Item(
        id: .bottle,
        .name("glass bottle"),
        .synonyms("bottle", "container"),
        .adjectives("clear", "glass"),
        .isTakable,
        .isTransparent,
        .isContainer,
        .isOpenable,
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
        .in(.kitchen),
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
        .in(.kitchen)
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
        .isSelfIgnitable,
        .firstDescription("A battery-powered brass lantern is on the trophy case."),
        .description("There is a brass lantern (battery-powered) here."),
        .size(15),
        .in(.livingRoom)
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
        .readText(
            """
            The map shows a forest with three clearings. The largest clearing contains
            a house. Three paths leave the large clearing. One of these paths, leading
            southwest, is marked "To Stone Barrow".
            """
        ),
        .size(2)
        // https://www.perplexity.ai/search/in-the-zork-1-source-code-at-h-cK9jApwqSb6EZONmBAkFqg
        // In the historicalsource/zork1 source code, the map is in the trophy case from the start
        // of the game. However in the final release, it only appears in the trophy case after all
        // of the treasures have been found and deposited.
        // .in(.item(.trophyCase))
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
        .in(.attic),
        .isSacred
        // Note: Has action handler ROPE-FUNCTION, SACREDBIT
    )

    static let rug = Item(
        id: .rug,
        .name("carpet"),
        .synonyms("rug", "carpet"),
        .adjectives("large", "oriental"),
        .omitDescription,
        .requiresTryTake,
        .in(.livingRoom)
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
        .adjectives("elvish", "ancient", "antique"),
        .isTakable,
        .isWeapon,
        .requiresTryTake,
        .firstDescription("Above the trophy case hangs an elvish sword of great antiquity."),
        .size(30),
        .in(.livingRoom)
        // Note: Has action handler SWORD-FCN, TVALUE 0
    )

    static let trapDoor = Item(
        id: .trapDoor,
        .name("trap door"),
        .synonyms("door", "trapdoor", "trap-door", "cover"),
        .adjectives("trap", "dusty"),

        .omitDescription,
        .isInvisible,
        .in(.livingRoom)
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
        .in(.livingRoom)
        // Note: Has action handler TROPHY-CASE-FCN
    )

    static let water = Item(
        id: .water,
        .name("quantity of water"),
        .description("It's just water."),
        .synonyms("water", "h2o", "liquid"),
        .in(.item(.bottle)),
        .isTakable,
        .isEdible,
        .isDrinkable
    )

    static let woodenDoor = Item(
        id: .woodenDoor,
        .name("wooden door"),
        .synonyms("door", "lettering", "writing"),
        .adjectives("wooden", "gothic", "strange", "west"),
        .isReadable,

        .omitDescription,
        .isTransparent,
        .readText("The engravings translate to \"This space intentionally left blank.\""),
        .in(.livingRoom)
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
    static let kitchenComputer = LocationComputer(for: .kitchen) {
        locationProperty(.description) { context in
            let kitchenWindow = await context.item(.kitchenWindow)
            let windowState = await kitchenWindow.isOpen ? "open" : "slightly ajar"
            return .string(
                """
                You are in the kitchen of the white house. A table seems to
                have been used recently for the preparation of food. A passage
                leads to the west and a dark staircase can be seen leading
                upward. A dark chimney leads down and to the east is a small
                window which is \(windowState).
                """
            )
        }
    }

    /// Handles special lamp interactions based on the original ZIL `LANTERN` routine.
    ///
    /// This handler manages lamp behavior including:
    /// - THROW: Smashes lamp and creates broken lamp
    /// - TURN ON: Lights lamp (unless burned out)
    /// - TURN OFF: Extinguishes lamp (unless burned out)
    /// - EXAMINE: Shows lamp state (burned out, on, or off)
    static let lampHandler = ItemEventHandler(for: .lamp) {
        before(.throw) { context, command in
            let playerLocation = await context.player.location
            let brokenLamp = await context.item(.brokenLamp)

            return await ActionResult(
                "The lamp has smashed into the floor, and the light has gone out.",
                context.item.clearFlag(.isOn),
                context.item.remove(),
                brokenLamp.move(to: .location(playerLocation.id))
            )
        }

        before(.lightSource) { context, command in
            let isBurnedOut = await context.item.hasFlag(.isBurnedOut)
            return isBurnedOut ? ActionResult("A burned-out lamp won't light.") : nil
        }

        before(.extinguish) { context, command in
            let isBurnedOut = await context.item.hasFlag(.isBurnedOut)
            return isBurnedOut ? ActionResult("The lamp has already burned out.") : nil
        }

        before(.examine) { context, command in
            let isBurnedOut = await context.item.hasFlag(.isBurnedOut)
            let isOn = await context.item.hasFlag(.isOn)

            let statusMessage =
                if isBurnedOut {
                    "has burned out."
                } else if isOn {
                    "is on."
                } else {
                    "is turned off."
                }

            return ActionResult("The lamp \(statusMessage)")
        }
    }

    static let waterHandler = ItemEventHandler(for: .water) {
        before(.drink) { context, command in
            guard await context.item(.bottle).isOpen else {
                throw ActionResponse.feedback("You'll have to open the glass bottle first.")
            }

            return ActionResult(
                "Thank you very much. I was rather thirsty (from all this talking, probably).",
                context.item.remove()
            )
        }
    }

    static let bottleHandler = ItemEventHandler(for: .bottle) {
        before(.throw) { context, command in
            let water = await context.item(.water)
            let hasWater = await water.parent == .item(context.item)

            return if hasWater {
                ActionResult(
                    """
                    The bottle hits the far wall and shatters.
                    The water spills to the floor and evaporates.
                    """,
                    context.item.remove(),
                    water.remove()
                )
            } else {
                ActionResult(
                    "The bottle hits the far wall and shatters.",
                    context.item.remove()
                )
            }
        }

        before(.attack) { context, command in
            let water = await context.item(.water)
            let hasWater = await water.parent == .item(context.item)

            return if hasWater {
                ActionResult(
                    """
                    A brilliant maneuver destroys the bottle.
                    The water spills to the floor and evaporates.
                    """,
                    context.item.remove(),
                    water.remove()
                )
            } else {
                ActionResult(
                    "A brilliant maneuver destroys the bottle.",
                    context.item.remove()
                )
            }
        }

        before(.push) { context, command in
            let water = await context.item(.water)
            let hasWater = await water.parent == .item(context.item)
            let isOpen = await context.item.hasFlag(.isOpen)

            return if isOpen && hasWater {
                ActionResult(
                    "The water spills to the floor and evaporates.",
                    water.remove()
                )
            } else {
                nil  // Let default shake handler take over
            }
        }
    }
}

extension InsideHouse {
    /// Handles special rug interactions based on the original ZIL `RUG-FCN`.
    ///
    /// This handler manages complex rug behavior including:
    /// - RAISE: Heavy rug notifications and irregularity hints
    /// - MOVE/PUSH: Moving the rug to reveal trap door
    /// - TAKE: Rug is too heavy to carry
    /// - LOOK UNDER: Temporary trap door revelation
    /// - CLIMB ON: Irregularity detection and magic carpet joke
    static let rugHandler = ItemEventHandler(for: .rug) {
        before(.take) { context, command in
            let wasRugMoved = await context.engine.hasFlag(.rugMoved)
            let baseMessage = "The rug is too heavy to lift"
            return if wasRugMoved {
                ActionResult("\(baseMessage).")
            } else {
                ActionResult(
                    """
                    \(baseMessage), but in trying to take it you have
                    noticed an irregularity beneath it.
                    """
                )
            }
        }

        before(.move, .push) { context, command in
            let wasRugMoved = await context.engine.hasFlag(.rugMoved)
            if wasRugMoved {
                return ActionResult(
                    """
                    Having moved the carpet previously, you find it impossible to move
                    it again.
                    """
                )
            } else {
                // Move the rug and reveal the trap door
                let trapDoor = await context.item(.trapDoor)
                return ActionResult(
                    """
                    With a great effort, the rug is moved to one side of the room,
                    revealing the dusty cover of a closed trap door.
                    """,
                    // Mark rug as moved
                    await context.engine.setFlag(.rugMoved),
                    // Make trap door visible
                    await trapDoor.clearFlag(.isInvisible)
                )
            }
        }

        before(.take) { context, command in
            ActionResult("The rug is extremely heavy and cannot be carried.")
        }

        before(.look) { context, command in
            let wasRugMoved = await context.engine.hasFlag(.rugMoved)
            let trapDoor = await context.item(.trapDoor)
            let trapDoorOpen = await trapDoor.hasFlag(.isOpen)

            // Only show trap door if rug hasn't been moved and trap door isn't open
            if !wasRugMoved && !trapDoorOpen {
                return ActionResult(
                    """
                    Underneath the rug is a closed trap door. As you drop the corner of the
                    rug, the trap door is once again concealed from view.
                    """
                )
            } else {
                return ActionResult("You find nothing of interest.")
            }
        }

        before(.climb) { context, command in
            let wasRugMoved = await context.engine.hasFlag(.rugMoved)
            let trapDoor = await context.item(.trapDoor)
            let trapDoorOpen = await trapDoor.hasFlag(.isOpen)

            return if !wasRugMoved && !trapDoorOpen {
                ActionResult(
                    """
                    As you sit, you notice an irregularity underneath it. Rather than be
                    uncomfortable, you stand up again.
                    """
                )
            } else {
                ActionResult("I suppose you think it's a magic carpet?")
            }
        }
    }

    /// Handles trap door interactions based on the original ZIL `TRAP-DOOR-FCN`.
    ///
    /// This handler manages the trap door's behavior depending on the player's location
    /// (Living Room vs. Cellar) and the state of the door.
    /// - **Living Room**: Allows opening, closing, and looking under the door with custom messages.
    /// - **Cellar**: Prevents opening from below and has special behavior for closing.
    /// - **Raise**: Treats `RAISE` as an alias for `OPEN`.
    static let trapDoorHandler = ItemEventHandler(for: .trapDoor) {
        before(.open, .pull) { context, command in
            let location = await context.player.location.id
            let isTrapDoorOpen = await context.item.hasFlag(.isOpen)

            return if isTrapDoorOpen {
                ActionResult("The trap door is already open.")
            } else if location == .cellar {
                ActionResult("The door is locked from above.")
            } else {
                ActionResult(
                    """
                    The door reluctantly opens to reveal a rickety staircase
                    descending into darkness.
                    """,
                    await context.item.setFlag(.isOpen)
                )
            }
        }

        before(.close) { context, command in
            let location = await context.player.location.id
            let isTrapDoorOpen = await context.item.hasFlag(.isOpen)

            return if !isTrapDoorOpen {
                ActionResult("The trap door is already closed.")
            } else if location == .cellar {
                ActionResult("You can't close the trap door from below.")
            } else {
                ActionResult(
                    "The door swings shut and closes.",
                    await context.item.clearFlag(.isOpen)
                )
            }
        }
    }

    /// Handles sword glow functionality based on the ZIL `SWORD-FCN` and `I-SWORD` routines.
    ///
    /// This handler manages:
    /// - TAKE: Enables the sword glow daemon when taken (equivalent to ENABLE <QUEUE I-SWORD -1>)
    /// - EXAMINE: Shows appropriate glow messages based on current glow state
    /// - Daemon activation: Checks current location and adjacent locations for monsters
    static let swordHandler = ItemEventHandler(for: .sword) {
        // Show glow message based on current glow level (like SWORD-FCN in ZIL)
        before(.examine) { context, command in
            switch await context.engine.global(.swordGlowLevel) ?? 0 {
            case 1:
                ActionResult("Your sword is glowing with a faint blue glow.")
            case 2:
                ActionResult("Your sword is glowing very brightly.")
            default:
                ActionResult("It's just a sword.")
            }
        }

        // Disable sword glow daemon when dropped
        after(.drop) { context, command in
            ActionResult(
                .stopDaemon(.swordDaemon)
            )
        }

        // Enable sword glow daemon when taken (like SWORD-FCN in ZIL)
        after(.take) { context, command in
            ActionResult(
                .runDaemon(.swordDaemon)
            )
        }
    }

    /// Sword glow daemon based on the ZIL `I-SWORD` interrupt routine.
    ///
    /// This daemon runs every turn when enabled and updates the sword glow level based on
    /// the presence of monsters in the current location or adjacent locations.
    /// - Level 0: No monsters nearby (no glow)
    /// - Level 1: Monster in adjacent location (faint blue glow)
    /// - Level 2: Monster in current location (very bright glow)
    static let swordDaemon = Daemon { engine, state in
        let currentLocation = await engine.player.location
        var newGlowLevel: SwordBrightness = .notGlowing

        // Check for monsters in current location (highest priority)
        for item in await currentLocation.items where await item.isCharacter {
            newGlowLevel = .glowingBrightly
            break
        }

        if newGlowLevel != .glowingBrightly {
            // Check adjacent locations for monsters
            for exit in await currentLocation.exits {
                guard let destination = exit.destinationID else { continue }
                let adjacentLocation = await engine.location(destination)
                for item in await adjacentLocation.items where await item.isCharacter {
                    newGlowLevel = .glowingFaintly
                    break
                }
            }
        }

        // Always update the glow level and show message if glowing
        let currentGlowLevel = await engine.global(.swordGlowLevel)?.toCodable(
            as: SwordBrightness.self
        )

        // Do nothing if the glow level has not changed
        if newGlowLevel == currentGlowLevel { return (nil, nil) }

        // Update and announce the glow level if it has changed
        return (
            try ActionResult(
                newGlowLevel.description,
                .setGlobalCodable(
                    id: .swordGlowLevel,
                    value: AnyCodableSendable(newGlowLevel)
                )
            ), nil
        )
    }
}
