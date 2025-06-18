import GnustoEngine

// MARK: - Outside the White House

enum OutsideHouse {
    static let eastOfHouse = Location(
        id: .eastOfHouse,
        .name("Behind House"),
        .exits([
            .north: .to(.northOfHouse),
            .south: .to(.southOfHouse),
            .west: .to(.kitchen, via: .kitchenWindow),
            .northwest: .to(.northOfHouse),
            .southwest: .to(.southOfHouse),
            .east: .to(.clearing),
            .inside: .to(.kitchen, via: .kitchenWindow),
        ]),
        .inherentlyLit,
        .localGlobals(.whiteHouse, .kitchenWindow, .forest)
    )

    static let northOfHouse = Location(
        id: .northOfHouse,
        .name("North of House"),
        .description(
            """
            You are facing the north side of a white house. There is no door here,
            and all the windows are boarded up. To the north a narrow path winds
            through the trees.
            """),
        .exits([
            .southwest: .to(.westOfHouse),
            .southeast: .to(.eastOfHouse),
            .west: .to(.westOfHouse),
            .east: .to(.eastOfHouse),
            .north: .to(.forestPath),
            .south: .blocked("The windows are all boarded."),
        ]),
        .inherentlyLit,
        .localGlobals(.boardedWindow, .board, .whiteHouse, .forest)
    )

    static let southOfHouse = Location(
        id: .southOfHouse,
        .name("South of House"),
        .description(
            """
            You are facing the south side of a white house. There is no door here,
            and all the windows are boarded.
            """),
        .exits([
            .west: .to(.westOfHouse),
            .east: .to(.eastOfHouse),
            .northeast: .to(.eastOfHouse),
            .northwest: .to(.westOfHouse),
            .south: .to(.forest3),
            .north: .blocked("The windows are all boarded."),
        ]),
        .inherentlyLit,
        .localGlobals(.boardedWindow, .board, .whiteHouse, .forest)
    )

    static let stoneBarrow = Location(
        id: .stoneBarrow,
        .name("Stone Barrow"),
        .description(
            """
            You are standing in front of a massive barrow of stone. In the east face
            is a huge stone door which is open. You cannot see into the dark of the tomb.
            """),
        .exits([
            .northeast: .to(.westOfHouse)
        ]),
        .inherentlyLit
    )

    static let westOfHouse = Location(
        id: .westOfHouse,
        .name("West of House"),
        .description(
            """
            You are standing in an open field west of a white house, with a boarded front door.
            """),
        .exits([
            .north: .to(.northOfHouse),
            .south: .to(.southOfHouse),
            .northeast: .to(.northOfHouse),
            .southeast: .to(.southOfHouse),
            .west: .to(.forest1),
            // Note: SW and IN exits to Stone Barrow conditional on WON-FLAG
            .east: .blocked("The door is boarded and you can't remove the boards."),
        ]),
        .inherentlyLit,
        .localGlobals(.whiteHouse, .board, .forest)
    )
}

// MARK: - Items

extension OutsideHouse {
    static let advertisement = Item(
        id: .advertisement,
        .name("leaflet"),
        .synonyms("advertisement", "leaflet", "booklet", "mail"),
        .adjectives("small"),
        .isReadable,
        .isTakable,
        .isFlammable,
        .description("A small leaflet is on the ground."),
        .readText(
            """
            "WELCOME TO ZORK!

            ZORK is a game of adventure, danger, and low cunning. In it you
            will explore some of the most amazing territory ever seen by mortals.
            No computer should be without one!"
            """),
        .size(2),
        .in(.item(.mailbox))
    )

    static let boardedWindow = Item(
        id: .boardedWindow,
        .name("boarded window"),
        .description("The windows are boarded up. There is no way you could enter through them."),
        .adjectives("boarded"),
        .synonyms("window", "windows"),
        .in(.location(.southOfHouse))
    )

    static let boards = Item(
        id: .boards,
        .name("boards"),
        .description("The boards are securely fastened and cannot be removed."),
        .synonyms("board"),
        .omitDescription
    )

    static let frontDoor = Item(
        id: .frontDoor,
        .name("door"),
        .synonyms("door"),
        .adjectives("front", "boarded"),
        .isDoor,
        .omitDescription,
        .in(.location(.westOfHouse))
        // Note: Has action handler FRONT-DOOR-FCN
    )

    static let kitchenWindow = Item(
        id: .kitchenWindow,
        .name("kitchen window"),
        .adjectives("kitchen", "small"),
        .synonyms("window"),
        .in(.location(.eastOfHouse)),
        .isDoor,
        .isOpenable,
        .omitDescription
    )

    static let mailbox = Item(
        id: .mailbox,
        .name("small mailbox"),
        .synonyms("mailbox", "box"),
        .adjectives("small"),
        .isContainer,
        .requiresTryTake,
        .isOpenable,
        .capacity(10),
        .in(.location(.westOfHouse))
    )

    static let whiteHouse = Item(
        id: .whiteHouse,
        .name("white house"),
        .adjectives("white", "beautiful", "colonial"),
        .synonyms("house", "home", "building"),
        .omitDescription
    )
}

// MARK: - Computers

extension OutsideHouse {
    static let eastOfHouseComputer = LocationComputer { attributeID, gameState in
        switch attributeID {
        case .description:
            let windowState =
                try gameState
                .hasFlag(.isOpen, on: .kitchenWindow) ? "open" : "slightly ajar"
            return .string(
                """
                You are behind the white house. A path leads into the forest
                to the east. In one corner of the house there is a small window
                which is \(windowState).
                """)
        default:
            return nil
        }
    }

    static let kitchenWindowComputer = ItemComputer { attributeID, gameState in
        switch attributeID {
        case .description:
            if try gameState.hasFlag(.isOpen, on: .kitchenWindow) {
                .string("The window is now open wide enough to allow entry.")
            } else {
                .string("The window is slightly ajar, but not enough to allow entry.")
            }
        default:
            nil
        }
    }
}

// MARK: - Event handlers

extension OutsideHouse {
    static let boardsHandler = ItemEventHandler { engine, event -> ActionResult? in
        switch event {
        case .beforeTurn(let command):
            switch command.verb {
            case .take: return ActionResult("The boards are securely fastened.")
            default: return nil
            }
        case .afterTurn:
            return nil
        }
    }

    static let kitchenWindowHandler = ItemEventHandler { engine, event -> ActionResult? in
        switch event {
        case .beforeTurn(let command):
            switch command.verb {
            case .open:
                if try await engine.hasFlag(.isOpen, on: .kitchenWindow) {
                    return ActionResult("Too late for that, the window is already open.")
                } else {
                    let kitchenWindow = try await engine.item(.kitchenWindow)
                    return await ActionResult(
                        "With great effort, you open the window far enough to allow entry.",
                        engine.setFlag(.isOpen, on: kitchenWindow)
                    )
                }
            case .look where command.preposition == "through":
                let currentLocation = await engine.playerLocationID
                if currentLocation == .kitchen {
                    return ActionResult("You can see a clear area leading towards a forest.")
                } else {
                    return ActionResult("You can see what appears to be a kitchen.")
                }
            default: return nil
            }
        case .afterTurn: return nil
        }
    }

    static let mailboxHandler = ItemEventHandler { engine, event -> ActionResult? in
        event.whenBeforeTurn(verb: .take) {
            ActionResult("It is securely anchored.")
        }
    }

    static let whiteHouseHandler = ItemEventHandler { engine, event -> ActionResult? in
        switch event {
        case .beforeTurn(let command):
            let currentLocation = await engine.playerLocationID

            // Check if player is inside the house
            let insideHouseLocations: Set<LocationID> = [.kitchen, .livingRoom, .attic]
            if insideHouseLocations.contains(currentLocation) {
                switch command.verb {
                case VerbID("find"):
                    return ActionResult("Why not find your brains?")
                // TODO: Handle WALK-AROUND verb when available
                default:
                    return nil
                }
            }

            // Check if player is at the house (at one of the four sides)
            let atHouseLocations: Set<LocationID> = [
                .eastOfHouse, .westOfHouse, .northOfHouse, .southOfHouse,
            ]
            if !atHouseLocations.contains(currentLocation) {
                // Player is not at the house
                switch command.verb {
                case VerbID("find"):
                    if currentLocation == .gratingClearing {
                        return ActionResult("It seems to be to the west.")
                    } else {
                        return ActionResult("It was here just a minute ago....")
                    }
                default:
                    return ActionResult("You're not at the house.")
                }
            }

            // Player is at the house (at one of the four sides)
            switch command.verb {
            case VerbID("find"):
                return ActionResult("It's right here! Are you blind or something?")

            // TODO: Handle WALK-AROUND verb when available

            case .examine, .look:
                return ActionResult(
                    """
                    The house is a beautiful colonial house which is painted white.
                    It is clear that the owners must have been extremely wealthy.
                    """)

            case .open:
                // Handle THROUGH/OPEN verbs (ZIL combines these)
                if currentLocation == .eastOfHouse {
                    let isWindowOpen = try await engine.hasFlag(.isOpen, on: .kitchenWindow)
                    if isWindowOpen {
                        // Move player to kitchen
                        return ActionResult(
                            nil,
                            await engine.movePlayer(to: .location(.kitchen))
                        )
                    } else {
                        // Update pronoun to refer to kitchen window
                        let kitchenWindow = try await engine.item(.kitchenWindow)
                        return ActionResult(
                            "The window is closed.",
                            await engine.updatePronouns(to: kitchenWindow)
                        )
                    }
                } else {
                    return ActionResult("I can't see how to get in from here.")
                }

            case VerbID("burn"):
                return ActionResult("You must be joking.")

            default:
                return nil
            }

        case .afterTurn:
            return nil
        }
    }
}
