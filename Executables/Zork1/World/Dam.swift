import GnustoEngine

enum Dam {
    static let damLobby = Location(.damLobby)
        .name("Dam Lobby")
        .description(
            """
            This room appears to have been the waiting room for groups touring
            the dam. There are open doorways here to the north and east marked
            "Private", and there is a path leading south over the top of the dam.
            """
        )
        .south(.damRoom)
        .north(.maintenanceRoom)
        .east(.maintenanceRoom)
        .inherentlyLit

    static let damRoom = Location(.damRoom)
        .name("Dam")
        .description("You are standing on top of the Flood Control Dam #3.")
        .south(.deepCanyon)
        .down(.damBase)
        .east(.damBase)
        .north(.damLobby)
        .west(.damLobby)
        .inherentlyLit
        .scenery(.globalWater)

    static let maintenanceRoom = Location(.maintenanceRoom)
        .name("Maintenance Room")
        .description(
            """
            This is what appears to have been the maintenance room for Flood
            Control Dam #3. Apparently, this room has been ransacked recently, for
            most of the valuable equipment is gone. On the wall in front of you is a
            group of buttons colored blue, yellow, brown, and red. There are doorways to
            the west and south.
            """
        )
        .south(.damLobby)
        .west(.damLobby)
}

// MARK: - Items

extension Dam {
    static let blueButton = Item(.blueButton)
        .name("blue button")
        .synonyms("button", "switch")
        .adjectives("blue")
        .omitDescription
        .in(.maintenanceRoom)
        // Note: Has action handler BUTTON-F

    static let bolt = Item(.bolt)
        .name("bolt")
        .synonyms("bolt", "nut")
        .adjectives("metal", "large")
        .omitDescription
        .requiresTryTake
        .in(.damRoom)
        // Note: Has action handler BOLT-F, TURNBIT

    static let brownButton = Item(.brownButton)
        .name("brown button")
        .synonyms("button", "switch")
        .adjectives("brown")
        .omitDescription
        .in(.maintenanceRoom)
        // Note: Has action handler BUTTON-F

    static let bubble = Item(.bubble)
        .name("green bubble")
        .synonyms("bubble")
        .adjectives("small", "green", "plastic")
        .omitDescription
        .requiresTryTake
        .in(.damRoom)
        // Note: Has action handler BUBBLE-F

    static let controlPanel = Item(.controlPanel)
        .name("control panel")
        .synonyms("panel")
        .adjectives("control")
        .omitDescription
        .in(.damRoom)

    static let dam = Item(.dam)
        .name("dam")
        .synonyms("dam", "gate", "gates", "fcd#3")
        .omitDescription
        .requiresTryTake
        .in(.damRoom)
        // Note: Has action handler DAM-FUNCTION

    static let guide = Item(.guide)
        .name("tour guidebook")
        .synonyms("guide", "book", "books", "guidebooks")
        .adjectives("tour", "guide")
        .isReadable
        .isTakable
        .isFlammable
        .firstDescription(
            """
            Some guidebooks entitled "Flood Control Dam #3" are on the reception
            desk.
            """
        )
        .readText(
            """
            "	Flood Control Dam #3

            FCD#3 was constructed in year 783 of the Great Underground Empire to
            harness the mighty Frigid River. This work was supported by a grant of
            37 million zorkmids from your omnipotent local tyrant Lord Dimwit
            Flathead the Excessive. This impressive structure is composed of
            370,000 cubic feet of concrete, is 256 feet tall at the center, and 193
            feet wide at the top. The lake created behind the dam has a volume
            of 1.7 billion cubic feet, an area of 12 million square feet, and a
            shore line of 36 thousand feet.

            The construction of FCD#3 took 112 days from ground breaking to
            the dedication. It required a work force of 384 slaves, 34 slave
            drivers, 12 engineers, 2 turtle doves, and a partridge in a pear
            tree. The work was managed by a command team composed of 2345
            bureaucrats, 2347 secretaries (at least two of whom could type)
            12,256 paper shufflers, 52,469 rubber stampers, 245,193 red tape
            processors, and nearly one million dead trees.

            We will now point out some of the more interesting features
            of FCD#3 as we conduct you on a guided tour of the facilities:

                    1) You start your tour here in the Dam Lobby. You will notice
            on your right that....
            """
        )
        .in(.damLobby)

    static let inflatableBoat = Item(.inflatableBoat)
        .name("pile of plastic")
        .synonyms("boat", "pile", "plastic", "valve")
        .adjectives("plastic", "inflat")
        .isTakable
        .isFlammable
        .description(
            """
            There is a folded pile of plastic here which has a small valve
            attached.
            """
        )
        .size(20)
        .in(.damBase)
        // Note: Has action handler IBOAT-FUNCTION

    static let leak = Item(.leak)
        .name("leak")
        .synonyms("leak", "drip", "pipe")
        .omitDescription
        .isInvisible
        .in(.maintenanceRoom)
        // Note: Has action handler LEAK-FUNCTION

    static let match = Item(.match)
        .name("matchbook")
        .synonyms("match", "matches", "matchbook")
        .adjectives("match")
        .isReadable
        .isTakable
        .description(
            """
            There is a matchbook whose cover says "Visit Beautiful FCD#3" here.
            """
        )
        .readText(
            """

            (Close cover before striking)

            YOU too can make BIG MONEY in the exciting field of PAPER SHUFFLING!

            Mr. Anderson of Muddle, Mass. says: "Before I took this course I
            was a lowly bit twiddler. Now with what I learned at GUE Tech
            I feel really important and can obfuscate and confuse with the best."

            Dr. Blank had this to say: "Ten short days ago all I could look
            forward to was a dead-end job as a doctor. Now I have a promising
            future and make really big Zorkmids."

            GUE Tech can't promise these fantastic results to everyone. But when
            you earn your degree from GUE Tech, your future will be brighter.
            """
        )
        .size(2)
        .in(.damLobby)
        // Note: Has action handler MATCH-FUNCTION

    static let putty = Item(.putty)
        .name("viscous material")
        .synonyms("material", "gunk")
        .adjectives("viscous")
        .isTakable
        .isTool
        .size(6)
        .in(.item(.tube))
        // Note: Has action handler PUTTY-FCN

    static let redButton = Item(.redButton)
        .name("red button")
        .synonyms("button", "switch")
        .adjectives("red")
        .omitDescription
        .in(.maintenanceRoom)
        // Note: Has action handler BUTTON-F

    static let screwdriver = Item(.screwdriver)
        .name("screwdriver")
        .synonyms("screwdriver", "tool", "tools", "driver")
        .adjectives("screw")
        .isTakable
        .isTool
        .in(.maintenanceRoom)

    static let toolChest = Item(.toolChest)
        .name("group of tool chests")
        .synonyms("chest", "chests", "group", "toolchests")
        .adjectives("tool")
        .isContainer
        .isOpen
        .requiresTryTake
        .in(.maintenanceRoom)
        .isSacred
        // Note: SACREDBIT, has action handler TOOL-CHEST-FCN

    static let tube = Item(.tube)
        .name("tube")
        .synonyms("tube", "tooth", "paste")
        .isTakable
        .isContainer
        .isReadable
        .description("There is an object which looks like a tube of toothpaste here.")
        .readText(
            """
            ---> Frobozz Magic Gunk Company <---|
                      All-Purpose Gunk
            """
        )
        .capacity(7)
        .size(5)
        .in(.maintenanceRoom)
        // Note: Has action handler TUBE-FUNCTION

    static let wrench = Item(.wrench)
        .name("wrench")
        .synonyms("wrench", "tool", "tools")
        .isTakable
        .isTool
        .size(10)
        .in(.maintenanceRoom)

    static let yellowButton = Item(.yellowButton)
        .name("yellow button")
        .synonyms("button", "switch")
        .adjectives("yellow")
        .omitDescription
        .in(.maintenanceRoom)
        // Note: Has action handler BUTTON-F
}
