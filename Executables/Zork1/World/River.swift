import GnustoEngine

enum River {
    static let aragainFalls = Location(.aragainFalls)
        .name("Aragain Falls")
        .description(
            """
            You are at the top of Aragain Falls.
            """
        )
        // Note: WEST and UP exits to rainbow conditional on RAINBOW-FLAG
        // Note: DOWN exit has custom message
        .north(.shore)
        .inherentlyLit
        .scenery(.globalWater, .river, .rainbow)

    static let canyonBottom = Location(.canyonBottom)
        .name("Canyon Bottom")
        .description(
            """
            You are beneath the walls of the river canyon which may be climbable
            here. The lesser part of the runoff of Aragain Falls flows by below.
            To the north is a narrow path.
            """
        )
        .up(.cliffMiddle)
        .north(.endOfRainbow)
        .inherentlyLit
        .scenery(.globalWater, .climbableCliff, .river)

    static let canyonView = Location(.canyonView)
        .name("Canyon View")
        .description(
            """
            You are at the top of the Great Canyon on its west wall. From here
            there is a marvelous view of the canyon and parts of the Frigid River
            upstream. Across the canyon, the walls of the White Cliffs join the
            mighty ramparts of the Flathead Mountains to the east. Following the
            Canyon upstream to the north, Aragain Falls may be seen, complete with
            rainbow. The mighty Frigid River flows out from a great dark cavern. To
            the west and south can be seen an immense forest, stretching for miles
            around. A path leads northwest. It is possible to climb down into
            the canyon from here.
            """
        )
        .east(.cliffMiddle)
        .down(.cliffMiddle)
        .northwest(.eastClearing)
        .south("Storm-tossed trees block your way.")
        .west(.forest3)
        .inherentlyLit
        .scenery(.climbableCliff, .river, .rainbow)

    static let cliffMiddle = Location(.cliffMiddle)
        .name("Rocky Ledge")
        .description(
            """
            You are on a ledge about halfway up the wall of the river canyon.
            You can see from here that the main flow from Aragain Falls twists
            along a passage which it is impossible for you to enter. Below you is the
            canyon bottom. Above you is more cliff, which appears
            climbable.
            """
        )
        .up(.canyonView)
        .down(.canyonBottom)
        .inherentlyLit
        .scenery(.climbableCliff, .river)

    static let damBase = Location(.damBase)
        .name("Dam Base")
        .description(
            """
            You are at the base of Flood Control Dam #3, which looms above you
            and to the north. The river Frigid is flowing by here. Along the
            river are the White Cliffs which seem to form giant walls stretching
            from north to south along the shores of the river as it winds its
            way downstream.
            """
        )
        .north(.damRoom)
        .up(.damRoom)
        .inherentlyLit
        .scenery(.globalWater, .river)

    static let endOfRainbow = Location(.endOfRainbow)
        .name("End of Rainbow")
        .description(
            """
            You are on a small, rocky beach on the continuation of the Frigid
            River past the Falls. The beach is narrow due to the presence of the
            White Cliffs. The river canyon opens here and sunlight shines in
            from above. A rainbow crosses over the falls to the east and a narrow
            path continues to the southwest.
            """
        )
        // Note: UP, NE, EAST exits to rainbow conditional on RAINBOW-FLAG
        .southwest(.canyonBottom)
        .inherentlyLit
        .scenery(.globalWater, .rainbow, .river)

    static let onRainbow = Location(.onRainbow)
        .name("On the Rainbow")
        .description(
            """
            You are on top of a rainbow (I bet you never thought you would walk
            on a rainbow), with a magnificent view of the Falls. The rainbow
            travels east-west here.
            """
        )
        .west(.endOfRainbow)
        .east(.aragainFalls)
        .inherentlyLit
        .scenery(.rainbow)

    static let river1 = Location(.river1)
        .name("Frigid River")
        .description(
            """
            You are on the Frigid River in the vicinity of the Dam. The river
            flows quietly here. There is a landing on the west shore.
            """
        )
        // Note: UP exit has custom message about strong currents
        .west(.damBase)
        // Note: LAND exit to dam base
        .down(.river2)
        // Note: EAST exit has custom message about White Cliffs
        // Note: This is NONLANDBIT in ZIL
        .inherentlyLit
        .scenery(.globalWater, .river)

    static let river2 = Location(.river2)
        .name("Frigid River")
        .description(
            """
            The river turns a corner here making it impossible to see the
            Dam. The White Cliffs loom on the east bank and large rocks prevent
            landing on the west.
            """
        )
        // Note: UP exit has custom message about strong currents
        .down(.river3)
        // Note: LAND, EAST, WEST exits have custom messages
        // Note: This is NONLANDBIT in ZIL
        .scenery(.globalWater, .river)

    static let river3 = Location(.river3)
        .name("Frigid River")
        .description(
            """
            The river descends here into a valley. There is a narrow beach on the
            west shore below the cliffs. In the distance a faint rumbling can be
            heard.
            """
        )
        // Note: UP exit has custom message about strong currents
        .down(.river4)
        // Note: LAND and WEST exits to white cliffs north
        // Note: This is NONLANDBIT in ZIL
        .scenery(.globalWater, .river)

    static let river4 = Location(.river4)
        .name("Frigid River")
        .description(
            """
            The river is running faster here and the sound ahead appears to be
            that of rushing water. On the east shore is a sandy beach. A small
            area of beach can also be seen below the cliffs on the west shore.
            """
        )
        // Note: UP exit has custom message about strong currents
        .down(.river5)
        // Note: LAND exit has custom message
        .west(.whiteCliffsSouth)
        .east(.sandyBeach)
        // Note: This is NONLANDBIT in ZIL
        .scenery(.globalWater, .river)

    static let river5 = Location(.river5)
        .name("Frigid River")
        .description(
            """
            The sound of rushing water is nearly unbearable here. On the east
            shore is a large landing area.
            """
        )
        // Note: UP exit has custom message about strong currents
        .east(.shore)
        // Note: LAND exit to shore
        // Note: This is NONLANDBIT in ZIL
        .inherentlyLit
        .scenery(.globalWater, .river)

    static let sandyBeach = Location(.sandyBeach)
        .name("Sandy Beach")
        .description(
            """
            You are on a large sandy beach on the east shore of the river, which is
            flowing quickly by. A path runs beside the river to the south here, and
            a passage is partially buried in sand to the northeast.
            """
        )
        .northeast(.sandyCave)
        .south(.shore)
        .scenery(.globalWater, .river)

    static let sandyCave = Location(.sandyCave)
        .name("Sandy Cave")
        .description(
            """
            This is a sand-filled cave whose exit is to the southwest.
            """
        )
        .southwest(.sandyBeach)

    static let shore = Location(.shore)
        .name("Shore")
        .description(
            """
            You are on the east shore of the river. The water here seems somewhat
            treacherous. A path travels from north to south here, the south end
            quickly turning around a sharp corner.
            """
        )
        .north(.sandyBeach)
        .south(.aragainFalls)
        .inherentlyLit
        .scenery(.globalWater, .river)

    static let whiteCliffsNorth = Location(.whiteCliffsNorth)
        .name("White Cliffs Beach")
        .description(
            """
            You are on a narrow strip of beach which runs along the base of the
            White Cliffs. There is a narrow path heading south along the Cliffs
            and a tight passage leading west into the cliffs themselves.
            """
        )
        .scenery(.globalWater, .whiteCliff, .river)

    static let whiteCliffsSouth = Location(.whiteCliffsSouth)
        .name("White Cliffs Beach")
        .description(
            """
            You are on a rocky, narrow strip of beach beside the Cliffs. A
            narrow path leads north along the shore.
            """
        )
        .scenery(.globalWater, .whiteCliff, .river)
}

// MARK: - Items

extension River {
    static let boatLabel = Item(.boatLabel)
        .name("tan label")
        .synonyms("label", "fineprint", "print")
        .adjectives("tan", "fine")
        .isReadable
        .isTakable
        .isFlammable
        .readText(
            """
              !!!!FROBOZZ MAGIC BOAT COMPANY!!!!

            Hello, Sailor!

            Instructions for use:

               To get into a body of water, say "Launch".
               To get to shore, say "Land" or the direction in which you want
            to maneuver the boat.

            Warranty:

              This boat is guaranteed against all defects for a period of 76
            milliseconds from date of purchase or until first used, whichever comes first.

            Warning:
               This boat is made of thin plastic.
               Good Luck!
            """
        )
        .size(2)
        .in(.item(.inflatedBoat))

    static let buoy = Item(.buoy)
        .name("red buoy")
        .synonyms("buoy")
        .adjectives("red")
        .isTakable
        .isContainer
        .firstDescription("There is a red buoy here (probably a warning).")
        .capacity(20)
        .size(10)
        .in(.river4)
        // Note: Has action handler TREASURE-INSIDE

    static let climbableCliff = Item(.climbableCliff)
        .name("cliff")
        .synonyms("wall", "cliff", "walls", "ledge")
        .adjectives("rocky", "sheer")
        .omitDescription
        .isClimbable
        // Note: Has action handler CLIFF-OBJECT

    static let emerald = Item(.emerald)
        .name("large emerald")
        .synonyms("emerald", "treasure")
        .adjectives("large")
        .isTakable
        .in(.item(.buoy))
        .value(5)
        // Note: VALUE 5, TVALUE 10

    static let inflatedBoat = Item(.inflatedBoat)
        .name("magic boat")
        .synonyms("boat", "raft")
        .adjectives("inflat", "magic", "plastic", "seaworthy")
        .isTakable
        .isFlammable
        .isVehicle  // VEHBIT
        .isOpen
        .isSearchable
        .capacity(100)
        .size(20)
        // Note: Has action handler RBOAT-FUNCTION, VTYPE NONLANDBIT, parent not specified

    static let potOfGold = Item(.potOfGold)
        .name("pot of gold")
        .synonyms("pot", "gold", "treasure")
        .adjectives("gold")
        .isTakable
        .firstDescription("At the end of the rainbow is a pot of gold.")
        .size(15)
        .in(.endOfRainbow)
        .value(10)
        // Note: VALUE 10, TVALUE 10

    static let puncturedBoat = Item(.puncturedBoat)
        .name("punctured boat")
        .synonyms("boat", "pile", "plastic")
        .adjectives("plastic", "puncture", "large")
        .isTakable
        .isFlammable
        .size(20)
        // Note: Has action handler DBOAT-FUNCTION, parent not specified

    static let rainbow = Item(.rainbow)
        .name("rainbow")
        .synonyms("rainbow")
        .omitDescription
        .isClimbable
        // Note: Has action handler RAINBOW-FCN

    static let river = Item(.river)
        .name("river")
        .synonyms("river")
        .adjectives("frigid")
        .omitDescription
        // Note: Has action handler RIVER-FUNCTION

    static let sand = Item(.sand)
        .name("sand")
        .synonyms("sand")
        .omitDescription
        .in(.sandyCave)
        // Note: Has action handler SAND-FUNCTION

    static let scarab = Item(.scarab)
        .name("beautiful jeweled scarab")
        .synonyms("scarab", "bug", "beetle", "treasure")
        .adjectives("beauti", "carved", "jeweled")
        .isTakable
        .isInvisible
        .size(8)
        .in(.sandyCave)
        .value(5)
        // Note: VALUE 5, TVALUE 5

    static let shovel = Item(.shovel)
        .name("shovel")
        .synonyms("shovel", "tool", "tools")
        .isTakable
        .isTool
        .size(15)
        .in(.sandyBeach)

    static let whiteCliff = Item(.whiteCliff)
        .name("white cliffs")
        .synonyms("cliff", "cliffs")
        .adjectives("white")
        .omitDescription
        .isClimbable
        // Note: Has action handler WCLIF-OBJECT
}
