import GnustoEngine

// MARK: - Outside the White House

enum OutsideHouse {
    static let eastOfHouse = Location(.eastOfHouse)
        .name("Behind House")
        .north(.northOfHouse)
        .south(.southOfHouse)
        .west(.kitchen, via: .kitchenWindow)
        .northwest(.northOfHouse)
        .southwest(.southOfHouse)
        .east(.eastClearing)
        .inside(.kitchen, via: .kitchenWindow)
        .inherentlyLit
        .localGlobals(.whiteHouse, .kitchenWindow, .forest)

    static let northOfHouse = Location(.northOfHouse)
        .name("North of House")
        .description(
            """
            You are facing the north side of a white house. There is no door here,
            and all the windows are boarded up. To the north a narrow path winds
            through the trees.
            """
        )
        .southwest(.westOfHouse)
        .southeast(.eastOfHouse)
        .west(.westOfHouse)
        .east(.eastOfHouse)
        .north(.forestPath)
        .south(blocked: "The windows are all boarded.")
        .inherentlyLit
        .localGlobals(.boardedWindow, .board, .whiteHouse, .forest)

    static let southOfHouse = Location(.southOfHouse)
        .name("South of House")
        .description(
            """
            You are facing the south side of a white house. There is no door here,
            and all the windows are boarded.
            """
        )
        .west(.westOfHouse)
        .east(.eastOfHouse)
        .northeast(.eastOfHouse)
        .northwest(.westOfHouse)
        .south(.forest3)
        .north(blocked: "The windows are all boarded.")
        .inherentlyLit
        .localGlobals(.boardedWindow, .board, .whiteHouse, .forest)

    static let stoneBarrow = Location(.stoneBarrow)
        .name("Stone Barrow")
        .description(
            """
            You are standing in front of a massive barrow of stone. In the east face
            is a huge stone door which is open. You cannot see into the dark of the tomb.
            """
        )
        .northeast(.westOfHouse)
        .inherentlyLit

    static let westOfHouse = Location(.westOfHouse)
        .name("West of House")
        .description(
            """
            You are standing in an open field west of a white house, with a boarded front door.
            """
        )
        .north(.northOfHouse)
        .south(.southOfHouse)
        .northeast(.northOfHouse)
        .southeast(.southOfHouse)
        .west(.forest1)
        // Note: SW and IN exits to Stone Barrow conditional on WON-FLAG
        .east(blocked: "The door is boarded and you can't remove the boards.")
        .inherentlyLit
        .localGlobals(.whiteHouse, .board, .forest)
}

// MARK: - Items

extension OutsideHouse {
    static let advertisement = Item(.advertisement)
        .name("leaflet")
        .synonyms("advertisement", "leaflet", "booklet", "mail")
        .adjectives("small")
        .isReadable
        .isTakable
        .isFlammable
        .description("A small leaflet is on the ground.")
        .readText(
            """
            "WELCOME TO ZORK!

            ZORK is a game of adventure, danger, and low cunning. In it you
            will explore some of the most amazing territory ever seen by mortals.
            No computer should be without one!"
            """
        )
        .size(2)
        .in(.item(.mailbox))

    static let boardedWindow = Item(.boardedWindow)
        .name("boarded window")
        .description("The windows are boarded up. There is no way you could enter through them.")
        .adjectives("boarded")
        .synonyms("window", "windows")
        .in(.southOfHouse)

    static let boards = Item(.boards)
        .name("boards")
        .description("The boards are securely fastened and cannot be removed.")
        .synonyms("board")
        .omitDescription

    static let frontDoor = Item(.frontDoor)
        .name("door")
        .synonyms("door")
        .adjectives("front", "boarded")

        .omitDescription
        .in(.westOfHouse)
        // Note: Has action handler FRONT-DOOR-FCN

    static let kitchenWindow = Item(.kitchenWindow)
        .name("kitchen window")
        .adjectives("kitchen", "small")
        .synonyms("window")
        .in(.eastOfHouse)
        .isOpenable
        .omitDescription

    static let mailbox = Item(.mailbox)
        .name("small mailbox")
        .synonyms("mailbox", "box")
        .adjectives("small")
        .isContainer
        .requiresTryTake
        .isOpenable
        .capacity(10)
        .in(.westOfHouse)

    static let whiteHouse = Item(.whiteHouse)
        .name("white house")
        .adjectives("white", "beautiful", "colonial")
        .synonyms("house", "home", "building")
        .omitDescription
}

// MARK: - Computers

extension OutsideHouse {
    static let eastOfHouseComputer = LocationComputer(for: .eastOfHouse) {
        locationProperty(.description) { context in
            let kitchenWindow = await context.item(.kitchenWindow)
            let windowState = await kitchenWindow.isOpen ? "open" : "slightly ajar"
            return .string(
                """
                You are behind the white house. A path leads into the forest
                to the east. In one corner of the house there is a small window
                which is \(windowState).
                """)
        }
    }

    static let kitchenWindowComputer = ItemComputer(for: .kitchenWindow) {
        itemProperty(ItemPropertyID.description) { context in
            await context.item.hasFlag(.isOpen)
                ? "The window is now open wide enough to allow entry."
                : "The window is slightly ajar, but not enough to allow entry."
        }
    }
}

// MARK: - Event handlers

extension OutsideHouse {
    static let boardsHandler = ItemEventHandler(for: .boards) {
        before(.take) { _, _ in
            ActionResult("The boards are securely fastened.")
        }
    }

    static let kitchenWindowHandler = ItemEventHandler(for: .kitchenWindow) {
        before(.open) { context, _ in
            if await context.item.hasFlag(.isOpen) {
                return ActionResult("Too late for that, the window is already open.")
            } else {
                return await ActionResult(
                    "With great effort, you open the window far enough to allow entry.",
                    context.item.setFlag(.isOpen)
                )
            }
        }

        before(.look) { context, command in
            guard command.preposition == Preposition("through") else { return nil }
            let currentLocation = await context.player.location.id
            if currentLocation == .kitchen {
                return ActionResult("You can see a clear area leading towards a forest.")
            } else {
                return ActionResult("You can see what appears to be a kitchen.")
            }
        }
    }

    static let mailboxHandler = ItemEventHandler(for: .mailbox) {
        before(.take) { _, _ in
            ActionResult("It is securely anchored.")
        }
    }

    static let whiteHouseHandler = ItemEventHandler(for: .whiteHouse) {
        //        before(.find) { context, command in
        //            let currentLocation = await context.player.location.id
        //
        //            // Check if player is inside the house
        //            let insideHouseLocations: Set<LocationID> = [.kitchen, .livingRoom, .attic]
        //            if insideHouseLocations.contains(currentLocation) {
        //                return ActionResult("Why not find your brains?")
        //            } else {
        //                // Check if player is at the house (at one of the four sides)
        //                let atHouseLocations: Set<LocationID> = [
        //                    .eastOfHouse, .westOfHouse, .northOfHouse, .southOfHouse,
        //                ]
        //                if !atHouseLocations.contains(currentLocation) {
        //                    // Player is not at the house
        //                    if currentLocation == .northClearing {
        //                        return ActionResult("It seems to be to the west.")
        //                    } else {
        //                        return ActionResult("It was here just a minute ago....")
        //                    }
        //                } else {
        //                    // Player is at the house - provide context-appropriate response
        //                    return ActionResult("You're standing right next to it!")
        //                }
        //            }
        //        }

        before(.examine, .look) { context, _ in
            let currentLocation = await context.player.location.id
            return
                if [.eastOfHouse, .westOfHouse, .northOfHouse, .southOfHouse].contains(
                    currentLocation
                )
            {
                ActionResult(
                    """
                    The house is a beautiful colonial house which is painted white.
                    It is clear that the owners must have been extremely wealthy.
                    """
                )
            } else {
                ActionResult("You can't see any house from here.")
            }
        }

        before(.open) { context, _ in
            let currentLocation = await context.player.location.id
            let atHouseLocations: Set<LocationID> = [
                .eastOfHouse, .westOfHouse, .northOfHouse, .southOfHouse,
            ]
            if !atHouseLocations.contains(currentLocation) {
                return ActionResult("You're not at the house.")
            } else {
                // Only east of house has an openable window
                if currentLocation == .eastOfHouse {
                    let kitchenWindow = await context.item(.kitchenWindow)
                    if await kitchenWindow.hasFlag(.isOpen) {
                        // Move player to kitchen
                        return ActionResult(
                            nil,
                            await context.player.move(to: .kitchen)
                        )
                    } else {
                        return ActionResult("The window is closed.")
                    }
                } else {
                    return ActionResult("The only opening on this side is boarded up.")
                }
            }
        }

        before(.burn) { context, _ in
            let currentLocation = await context.player.location.id
            let atHouseLocations: Set<LocationID> = [
                .eastOfHouse, .westOfHouse, .northOfHouse, .southOfHouse,
            ]
            if atHouseLocations.contains(currentLocation) {
                return ActionResult("Burn down the house? Are you some sort of vandal?")
            } else {
                return ActionResult("There's nothing to burn here.")
            }
        }
    }
}
