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
        .description("""
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
            .south: .blocked("The windows are all boarded.")
        ]),
        .inherentlyLit,
        .localGlobals(.boardedWindow, .board, .whiteHouse, .forest)
    )

    static let southOfHouse = Location(
        id: .southOfHouse,
        .name("South of House"),
        .description("""
            You are facing the south side of a white house. There is no door here,
            and all the windows are boarded.
            """),
        .exits([
            .west: .to(.westOfHouse),
            .east: .to(.eastOfHouse),
            .northeast: .to(.eastOfHouse),
            .northwest: .to(.westOfHouse),
            .south: .to(.forest3),
            .north: .blocked("The windows are all boarded.")
        ]),
        .inherentlyLit,
        .localGlobals(.boardedWindow, .board, .whiteHouse, .forest)
    )

    static let stoneBarrow = Location(
        id: .stoneBarrow,
        .name("Stone Barrow"),
        .description("""
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
        .description("""
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
        .readText("""
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
        .capacity(10),
        .in(.location(.westOfHouse))
        // Note: Has action handler MAILBOX-F
    )

    static let whiteHouse = Item(
        id: .whiteHouse,
        .name("white house"),
        .description("""
            The house is a beautiful colonial house which is painted white.
            It is clear that the owners must have been extremely wealthy.
            """),
        .adjectives("white", "beautiful", "colonial"),
        .synonyms("house", "home", "building"),
        .in(.location(.westOfHouse)),
        .omitDescription
    )
}

// MARK: - Computers

extension OutsideHouse {
    static let eastOfHouseComputer = LocationComputer { attributeID, gameState in
        switch attributeID {
        case .description:
            let windowState = if gameState.items[.kitchenWindow]?.hasFlag(.isOpen) == true {
                "open"
            } else {
                "slightly ajar"
            }
            return .string("""
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
            if gameState.items[.kitchenWindow]?.hasFlag(.isOpen) == true {
                return .string("The window is now open wide enough to allow entry.")
            } else {
                return .string("The window is slightly ajar, but not enough to allow entry.")
            }
        default:
            return nil
        }
    }

}

// MARK: - Event handlers

extension OutsideHouse {
    static let boardsHandler = ItemEventHandler { engine, event in
        switch event {
        case .beforeTurn(let command):
            switch command.verb {
            case .take: ActionResult("The boards are securely fastened.")
            default: nil
            }
        case .afterTurn: nil
        }
    }

    static let kitchenWindowHandler = ItemEventHandler { engine, event in
        switch event {
        case .beforeTurn(let command):
            switch command.verb {
            case .open:
                if try await engine.hasFlag(.isOpen, on: .kitchenWindow) {
                    return ActionResult("Too late for that, the window is already open.")
                } else {
                    let kitchenWindow = try await engine.item(.kitchenWindow)
                    return await ActionResult(
                        message: "With great effort, you open the window far enough to allow entry.",
                        stateChange: engine.setFlag(.isOpen, on: kitchenWindow)
                    )
                }
            default: return nil
            }
        case .afterTurn: return nil
        }
    }

    static let mailboxHandler = ItemEventHandler { engine, event in
        switch event {
        case .beforeTurn(let command):
            switch command.verb {
            case .take: ActionResult("It is securely anchored.")
            default: nil
            }
        case .afterTurn: nil
        }
    }
}
