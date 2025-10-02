import GnustoEngine

// MARK: - Locations

enum Underground {
    static let cellar = Location(.cellar)
        .name("Cellar")
        .description(
            """
            You are in a dark and damp cellar with a narrow passageway leading north, and a
            crawlway to the south. On the west is the bottom of a steep metal ramp which is
            unclimbable.
            """
        )
        .north(.trollRoom)
        .south(.eastOfChasm)
        .west(.steepRamp)
        .up(.livingRoom, via: .trapDoor, blocked: "The trap door is locked from above.")
        .localGlobals(.trapDoor, .slide, .stairs)

    static let complexJunction = Location(.complexJunction)
        .name("Complex Junction")
        .description("This is a complex junction with passages leading in many directions.")
        .northwest(.roundRoom)

    static let deadEnd = Location(.deadEnd)
        .name("Dead End")
        .description("You have come to a dead end.")
        .west(.roundRoom)

    static let eastOfChasm = Location(.eastOfChasm)
        .name("East of Chasm")
        .description(
            """
            You are on the east edge of a chasm, the bottom of which cannot be seen. A narrow
            passage goes north, and the path you are on continues to the east.
            """
        )
        .north(.cellar)
        .east(.gallery)
        .down("The chasm probably leads straight to the infernal regions.")

    /*
     <ROUTINE CHASM-PSEUDO ()
     <COND (<OR <VERB? LEAP>
     <AND <VERB? PUT> <EQUAL? ,PRSO ,ME>>>
     <TELL
     "You look before leaping, and realize that you would never survive." CR>)
     (<VERB? CROSS>
     <TELL "It's too far to jump, and there's no bridge." CR>)
     (<AND <VERB? PUT THROW-OFF> <EQUAL? ,PRSI ,PSEUDO-OBJECT>>
     <TELL
     "The " D ,PRSO " drops out of sight into the chasm." CR>
     <REMOVE-CAREFULLY ,PRSO>)>>
     */

    static let eastWestPassage = Location(.eastWestPassage)
        .name("East-West Passage")
        .description(
            """
            This is a narrow east-west passageway. There is a narrow stairway leading down at
            the north end of the room.
            """
        )
        .east(.roundRoom)
        .down(.reservoir)

    static let gallery = Location(.gallery)
        .name("Gallery")
        .description(
            """
            This is an art gallery. Most of the paintings have been stolen by vandals with
            exceptional taste. The vandals left through either the north or west exits.
            """
        )
        .north(.studio)
        .west(.eastOfChasm)
        .inherentlyLit

    static let northSouthPassage = Location(.northSouthPassage)
        .name("North-South Passage")
        .description("This is a long north-south passage.")
        .south(.roundRoom)

    static let northeastPassage = Location(.northeastPassage)
        .name("Northeast Passage")
        .description("This is a northeast passage.")
        .southwest(.roundRoom)

    static let northwestPassage = Location(.northwestPassage)
        .name("Northwest Passage")
        .description("This is a northwest passage.")
        .southeast(.roundRoom)

    static let southPassage = Location(.southPassage)
        .name("South Passage")
        .description("This is a south passage.")
        .north(.roundRoom)

    static let southwestPassage = Location(.southwestPassage)
        .name("Southwest Passage")
        .description("This is a southwest passage.")
        .northeast(.roundRoom)

    static let steepRamp = Location(.steepRamp)
        .name("Bottom of Ramp")
        .description(
            """
            You are at the bottom of a steep metal ramp. The ramp leads up to the west, but it
            is too steep and smooth to climb.
            """
        )
        .east(.cellar)

    static let studio = Location(.studio)
        .name("Studio")
        .description(
            """
            This appears to have been an artist's studio. The walls and floors are splattered
            with paints of 69 different colors. Strangely enough, nothing of value is hanging
            here. At the south end of the room is an open door (also covered with paint). A
            dark and narrow chimney leads up from a fireplace; although you might be able to
            get up it, it seems unlikely you could get back down.
            """
        )
        .south(.gallery)
        .up(.kitchen, blocked: "You try to climb the chimney, but it's too narrow and steep.")
}

// MARK: - Items

extension Underground {
    static let axe = Item(.axe)
        .name("bloody axe")
        .synonyms("axe", "ax")
        .adjectives("bloody")
        .isWeapon
        .requiresTryTake
        .isTakable
        .omitDescription
        .size(25)
        .in(.item(.troll))
        // Note: Has action handler AXE-F

    static let ownersManual = Item(.ownersManual)
        .name("ZORK owner's manual")
        .synonyms("manual", "piece", "paper")
        .adjectives("zork", "owners", "small")
        .isReadable
        .isTakable
        .firstDescription("Loosely attached to a wall is a small piece of paper.")
        .readText(
            """
            Congratulations!

            You are the privileged owner of ZORK I: The Great Underground Empire,
            a self-contained and self-maintaining universe. If used and maintained
            in accordance with normal operating practices for small universes, ZORK
            will provide many months of trouble-free operation.
            """
        )
        .in(.studio)

    static let painting = Item(.painting)
        .name("painting")
        .synonyms("painting", "art", "canvas", "treasure")
        .adjectives("beautiful")
        .isTakable
        .isFlammable
        .firstDescription(
            """
            Fortunately, there is still one chance for you to be a vandal, for on
            the far wall is a painting of unparalleled beauty.
            """
        )
        .description("A painting by a neglected genius is here.")
        .size(15)
        .in(.gallery)
        .value(4)
        // Note: VALUE 4, TVALUE 6, has action handler PAINTING-FCN

    static let steepRampItem = Item(.steepRampItem)
        .name("steep metal ramp")
        .description("The ramp is too steep and smooth to climb.")
        .adjectives("steep", "metal")
        .synonyms("ramp")
        .in(.cellar)
        .omitDescription
        .isClimbable
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
