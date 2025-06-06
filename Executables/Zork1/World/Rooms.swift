import GnustoEngine

extension Location {

    // MARK: - Maze


    // MARK: - Cyclops and Hideaway

    static let cyclopsRoom = Location(
        id: .cyclopsRoom,
        .name("Cyclops Room"),
        .description("""
            This is the lair of the cyclops. The smell is terrible, and the floor is littered with bones.
            """),
        .exits([
            .northwest: .to(.maze15),
            // Note: EAST exit to strange passage conditional on MAGIC-FLAG
            // Note: UP exit to treasure room conditional on CYCLOPS-FLAG
        ]),
        .isLand,
        .localGlobals(.stairs)
    )

    static let strangePassage = Location(
        id: .strangePassage,
        .name("Strange Passage"),
        .description("""
            This is a long passage. To the west is one entrance. On the
            east there is an old wooden door, with a large opening in it (about
            cyclops sized).
            """),
        .exits([
            .west: .to(.cyclopsRoom),
            .inside: .to(.cyclopsRoom),
            .east: .to(.livingRoom)
        ]),
        .isLand
    )

    static let treasureRoom = Location(
        id: .treasureRoom,
        .name("Treasure Room"),
        .description("""
            This is a large room, whose east wall is solid granite. A number
            of discarded bags, which crumble at your touch, are scattered about
            on the floor. There is an exit down a staircase.
            """),
        .exits([
            .down: .to(.cyclopsRoom)
        ]),
        .isLand,
        .localGlobals(.stairs)
    )

    // MARK: - Reservoir Area

    static let reservoirSouth = Location(
        id: .reservoirSouth,
        .name("Reservoir South"),
        .description("""
            You are in a large chamber with water flowing from the north.
            """),
        .exits([
            .southeast: .to(.deepCanyon),
            .southwest: .to(.chasmRoom),
            .east: .to(.damRoom),
            .west: .to(.streamView),
            // Note: NORTH exit to reservoir conditional on LOW-TIDE
        ]),
        .isLand,
        .localGlobals(.globalWater)
    )

    static let reservoir = Location(
        id: .reservoir,
        .name("Reservoir"),
        .description("""
            This is a large reservoir of water.
            """),
        .exits([
            .north: .to(.reservoirNorth),
            .south: .to(.reservoirSouth),
            .up: .to(.inStream),
            .west: .to(.inStream),
            // Note: DOWN exit has custom message about dam blocking way
        ]),
        // Note: This is NONLANDBIT in ZIL
        .localGlobals(.globalWater)
    )

    static let reservoirNorth = Location(
        id: .reservoirNorth,
        .name("Reservoir North"),
        .description("""
            You are in the northern end of the reservoir.
            """),
        .exits([
            .north: .to(.atlantisRoom),
            // Note: SOUTH exit to reservoir conditional on LOW-TIDE
        ]),
        .isLand,
        .localGlobals(.globalWater, .stairs)
    )

    static let streamView = Location(
        id: .streamView,
        .name("Stream View"),
        .description("""
            You are standing on a path beside a gently flowing stream. The path
            follows the stream, which flows from west to east.
            """),
        .exits([
            .east: .to(.reservoirSouth),
            // Note: WEST exit has custom message about stream being too small
        ]),
        .isLand,
        .localGlobals(.globalWater)
    )

    static let inStream = Location(
        id: .inStream,
        .name("Stream"),
        .description("""
            You are on the gently flowing stream. The upstream route is too narrow
            to navigate, and the downstream route is invisible due to twisting
            walls. There is a narrow beach to land on.
            """),
        .exits([
            // Note: UP and WEST exits have custom messages about narrow channel
            // Note: LAND exit to stream view
            .down: .to(.reservoir),
            .east: .to(.reservoir)
        ]),
        // Note: This is NONLANDBIT in ZIL
        .localGlobals(.globalWater)
    )

    // MARK: - Mirror Rooms and Vicinity

    static let mirrorRoom1 = Location(
        id: .mirrorRoom1,
        .name("Mirror Room"),
        .description("""
            You are in a large room with a huge mirror hanging on one wall.
            """),
        .exits([
            .north: .to(.coldPassage),
            .west: .to(.twistingPassage),
            .east: .to(.smallCave)
        ]),
        .isLand
    )

    static let mirrorRoom2 = Location(
        id: .mirrorRoom2,
        .name("Mirror Room"),
        .description("""
            You are in a large room with a huge mirror hanging on one wall.
            """),
        .exits([
            .west: .to(.windingPassage),
            .north: .to(.narrowPassage),
            .east: .to(.tinyCave)
        ]),
        .isLand,
        .inherentlyLit
    )

    static let smallCave = Location(
        id: .smallCave,
        .name("Cave"),
        .description("""
            This is a tiny cave with entrances west and north, and a staircase
            leading down.
            """),
        .exits([
            .north: .to(.mirrorRoom1),
            .down: .to(.atlantisRoom),
            .south: .to(.atlantisRoom),
            .west: .to(.twistingPassage)
        ]),
        .isLand,
        .localGlobals(.stairs)
    )

    static let tinyCave = Location(
        id: .tinyCave,
        .name("Cave"),
        .description("""
            This is a tiny cave with entrances west and north, and a dark,
            forbidding staircase leading down.
            """),
        .exits([
            .north: .to(.mirrorRoom2),
            .west: .to(.windingPassage),
            .down: .to(.entranceToHades)
        ]),
        .isLand,
        .localGlobals(.stairs)
    )

    static let coldPassage = Location(
        id: .coldPassage,
        .name("Cold Passage"),
        .description("""
            This is a cold and damp corridor where a long east-west passageway
            turns into a southward path.
            """),
        .exits([
            .south: .to(.mirrorRoom1),
            .west: .to(.slideRoom)
        ]),
        .isLand
    )

    static let narrowPassage = Location(
        id: .narrowPassage,
        .name("Narrow Passage"),
        .description("""
            This is a long and narrow corridor where a long north-south passageway
            briefly narrows even further.
            """),
        .exits([
            .north: .to(.roundRoom),
            .south: .to(.mirrorRoom2)
        ]),
        .isLand
    )

    static let windingPassage = Location(
        id: .windingPassage,
        .name("Winding Passage"),
        .description("""
            This is a winding passage. It seems that there are only exits
            on the east and north.
            """),
        .exits([
            .north: .to(.mirrorRoom2),
            .east: .to(.tinyCave)
        ]),
        .isLand
    )

    static let twistingPassage = Location(
        id: .twistingPassage,
        .name("Twisting Passage"),
        .description("""
            This is a winding passage. It seems that there are only exits
            on the east and north.
            """),
        .exits([
            .north: .to(.mirrorRoom1),
            .east: .to(.smallCave)
        ]),
        .isLand
    )

    static let atlantisRoom = Location(
        id: .atlantisRoom,
        .name("Atlantis Room"),
        .description("""
            This is an ancient room, long under water. There is an exit to
            the south and a staircase leading up.
            """),
        .exits([
            .up: .to(.smallCave),
            .south: .to(.reservoirNorth)
        ]),
        .isLand,
        .localGlobals(.stairs)
    )

    // MARK: - Round Room and Vicinity

    static let ewPassage = Location(
        id: .ewPassage,
        .name("East-West Passage"),
        .description("""
            This is a narrow east-west passageway. There is a narrow stairway
            leading down at the north end of the room.
            """),
        .exits([
            .east: .to(.roundRoom),
            .west: .to(.trollRoom),
            .down: .to(.chasmRoom),
            .north: .to(.chasmRoom)
        ]),
        .isLand,
        .localGlobals(.stairs)
    )

    static let roundRoom = Location(
        id: .roundRoom,
        .name("Round Room"),
        .description("""
            This is a circular stone room with passages in all directions. Several
            of them have unfortunately been blocked by cave-ins.
            """),
        .exits([
            .east: .to(.loudRoom),
            .west: .to(.ewPassage),
            .north: .to(.nsPassage),
            .south: .to(.narrowPassage),
            .southeast: .to(.engravingsCave)
        ]),
        .isLand
    )

    static let deepCanyon = Location(
        id: .deepCanyon,
        .name("Deep Canyon"),
        .description("""
            You are on the south side of a deep canyon.
            """),
        .exits([
            .northwest: .to(.reservoirSouth),
            .east: .to(.damRoom),
            .southwest: .to(.nsPassage),
            .down: .to(.loudRoom)
        ]),
        .isLand,
        .localGlobals(.stairs)
    )

    static let dampCave = Location(
        id: .dampCave,
        .name("Damp Cave"),
        .description("""
            This cave has exits to the west and east, and narrows to a crack toward
            the south. The earth is particularly damp here.
            """),
        .exits([
            .west: .to(.loudRoom),
            .east: .to(.whiteCliffsNorth),
            // Note: SOUTH exit has custom message about being too narrow
        ]),
        .isLand,
        .localGlobals(.crack)
    )

    static let loudRoom = Location(
        id: .loudRoom,
        .name("Loud Room"),
        .description("""
            This is a room where every sound is amplified.
            """),
        .exits([
            .east: .to(.dampCave),
            .west: .to(.roundRoom),
            .up: .to(.deepCanyon)
        ]),
        .isLand,
        .localGlobals(.stairs)
    )

    static let nsPassage = Location(
        id: .nsPassage,
        .name("North-South Passage"),
        .description("""
            This is a high north-south passage, which forks to the northeast.
            """),
        .exits([
            .north: .to(.chasmRoom),
            .northeast: .to(.deepCanyon),
            .south: .to(.roundRoom)
        ]),
        .isLand
    )

    static let chasmRoom = Location(
        id: .chasmRoom,
        .name("Chasm"),
        .description("""
            A chasm runs southwest to northeast and the path follows it. You are
            on the south side of the chasm, where a crack opens into a passage.
            """),
        .exits([
            .northeast: .to(.reservoirSouth),
            .southwest: .to(.ewPassage),
            .up: .to(.ewPassage),
            .south: .to(.nsPassage),
            // Note: DOWN exit has custom message
        ]),
        .isLand,
        .localGlobals(.crack, .stairs)
    )

    // MARK: - Hades Area

    static let entranceToHades = Location(
        id: .entranceToHades,
        .name("Entrance to Hades"),
        .description("""
            You are outside a large gate. The gate is flanked by a pair of
            burning torches, and there is an open doorway leading into the
            realm of the dead.
            """),
        .exits([
            .up: .to(.tinyCave),
            // Note: IN and SOUTH exits to land of living dead conditional on LLD-FLAG
        ]),
        .isLand,
        .inherentlyLit,
        .localGlobals(.bodies)
    )

    static let landOfLivingDead = Location(
        id: .landOfLivingDead,
        .name("Land of the Dead"),
        .description("""
            You have entered the Land of the Living Dead. Thousands of lost souls
            can be heard weeping and moaning. In the corner are stacked the remains
            of dozens of previous adventurers less fortunate than yourself.
            A passage exits to the north.
            """),
        .exits([
            .outside: .to(.entranceToHades),
            .north: .to(.entranceToHades)
        ]),
        .isLand,
        .inherentlyLit,
        .localGlobals(.bodies)
    )

    // MARK: - Dome, Temple, Egypt Area

    static let engravingsCave = Location(
        id: .engravingsCave,
        .name("Engravings Cave"),
        .description("""
            You have entered a low cave with passages leading northwest and east.
            """),
        .exits([
            .northwest: .to(.roundRoom),
            .east: .to(.domeRoom)
        ]),
        .isLand
    )

    static let egyptRoom = Location(
        id: .egyptRoom,
        .name("Egyptian Room"),
        .description("""
            This is a room which looks like an Egyptian tomb. There is an
            ascending staircase to the west.
            """),
        .exits([
            .west: .to(.northTemple),
            .up: .to(.northTemple)
        ]),
        .isLand,
        .localGlobals(.stairs)
    )

    static let domeRoom = Location(
        id: .domeRoom,
        .name("Dome Room"),
        .description("""
            You are at the top of a large dome.
            """),
        .exits([
            .west: .to(.engravingsCave),
            // Note: DOWN exit to torch room conditional on DOME-FLAG
        ]),
        .isLand
    )

    static let torchRoom = Location(
        id: .torchRoom,
        .name("Torch Room"),
        .description("""
            This is a large room with a white marble pedestal in the center.
            """),
        .exits([
            // Note: UP exit has custom message about not reaching rope
            .south: .to(.northTemple),
            .down: .to(.northTemple)
        ]),
        .isLand,
        .localGlobals(.stairs)
    )

    static let northTemple = Location(
        id: .northTemple,
        .name("Temple"),
        .description("""
            This is the north end of a large temple. On the east wall is an
            ancient inscription, probably a prayer in a long-forgotten language.
            Below the prayer is a staircase leading down. The west wall is solid
            granite. The exit to the north end of the room is through huge
            marble pillars.
            """),
        .exits([
            .down: .to(.egyptRoom),
            .east: .to(.egyptRoom),
            .north: .to(.torchRoom),
            .outside: .to(.torchRoom),
            .up: .to(.torchRoom),
            .south: .to(.southTemple)
        ]),
        .isLand,
        .inherentlyLit,
        .isSacred,
        .localGlobals(.stairs)
    )

    static let southTemple = Location(
        id: .southTemple,
        .name("Altar"),
        .description("""
            This is the south end of a large temple. In front of you is what
            appears to be an altar. In one corner is a small hole in the floor
            which leads into darkness. You probably could not get back up it.
            """),
        .exits([
            .north: .to(.northTemple),
            // Note: DOWN exit to tiny cave conditional on COFFIN-CURE
        ]),
        .isLand,
        .inherentlyLit,
        .isSacred
    )

    // MARK: - Dam Area

    static let damRoom = Location(
        id: .damRoom,
        .name("Dam"),
        .description("""
            You are standing on top of the Flood Control Dam #3.
            """),
        .exits([
            .south: .to(.deepCanyon),
            .down: .to(.damBase),
            .east: .to(.damBase),
            .north: .to(.damLobby),
            .west: .to(.reservoirSouth)
        ]),
        .isLand,
        .inherentlyLit,
        .localGlobals(.globalWater)
    )

    static let damLobby = Location(
        id: .damLobby,
        .name("Dam Lobby"),
        .description("""
            This room appears to have been the waiting room for groups touring
            the dam. There are open doorways here to the north and east marked
            "Private", and there is a path leading south over the top of the dam.
            """),
        .exits([
            .south: .to(.damRoom),
            .north: .to(.maintenanceRoom),
            .east: .to(.maintenanceRoom)
        ]),
        .isLand,
        .inherentlyLit
    )

    static let maintenanceRoom = Location(
        id: .maintenanceRoom,
        .name("Maintenance Room"),
        .description("""
            This is what appears to have been the maintenance room for Flood
            Control Dam #3. Apparently, this room has been ransacked recently, for
            most of the valuable equipment is gone. On the wall in front of you is a
            group of buttons colored blue, yellow, brown, and red. There are doorways to
            the west and south.
            """),
        .exits([
            .south: .to(.damLobby),
            .west: .to(.damLobby)
        ]),
        .isLand
    )

    // MARK: - River Area

    static let damBase = Location(
        id: .damBase,
        .name("Dam Base"),
        .description("""
            You are at the base of Flood Control Dam #3, which looms above you
            and to the north. The river Frigid is flowing by here. Along the
            river are the White Cliffs which seem to form giant walls stretching
            from north to south along the shores of the river as it winds its
            way downstream.
            """),
        .exits([
            .north: .to(.damRoom),
            .up: .to(.damRoom)
        ]),
        .isLand,
        .inherentlyLit,
        .isSacred,
        .localGlobals(.globalWater, .river)
    )

    static let river1 = Location(
        id: .river1,
        .name("Frigid River"),
        .description("""
            You are on the Frigid River in the vicinity of the Dam. The river
            flows quietly here. There is a landing on the west shore.
            """),
        .exits([
            // Note: UP exit has custom message about strong currents
            .west: .to(.damBase),
            // Note: LAND exit to dam base
            .down: .to(.river2),
            // Note: EAST exit has custom message about White Cliffs
        ]),
        // Note: This is NONLANDBIT in ZIL
        .isSacred,
        .inherentlyLit,
        .localGlobals(.globalWater, .river)
    )

    static let river2 = Location(
        id: .river2,
        .name("Frigid River"),
        .description("""
            The river turns a corner here making it impossible to see the
            Dam. The White Cliffs loom on the east bank and large rocks prevent
            landing on the west.
            """),
        .exits([
            // Note: UP exit has custom message about strong currents
            .down: .to(.river3),
            // Note: LAND, EAST, WEST exits have custom messages
        ]),
        // Note: This is NONLANDBIT in ZIL
        .isSacred,
        .localGlobals(.globalWater, .river)
    )

    static let river3 = Location(
        id: .river3,
        .name("Frigid River"),
        .description("""
            The river descends here into a valley. There is a narrow beach on the
            west shore below the cliffs. In the distance a faint rumbling can be
            heard.
            """),
        .exits([
            // Note: UP exit has custom message about strong currents
            .down: .to(.river4),
            // Note: LAND and WEST exits to white cliffs north
        ]),
        // Note: This is NONLANDBIT in ZIL
        .isSacred,
        .localGlobals(.globalWater, .river)
    )

    static let whiteCliffsNorth = Location(
        id: .whiteCliffsNorth,
        .name("White Cliffs Beach"),
        .description("""
            You are on a narrow strip of beach which runs along the base of the
            White Cliffs. There is a narrow path heading south along the Cliffs
            and a tight passage leading west into the cliffs themselves.
            """),
        .exits([:]),
        .isLand,
        .isSacred,
        .localGlobals(.globalWater, .whiteCliff, .river)
    )

    static let whiteCliffsSouth = Location(
        id: .whiteCliffsSouth,
        .name("White Cliffs Beach"),
        .description("""
            You are on a rocky, narrow strip of beach beside the Cliffs. A
            narrow path leads north along the shore.
            """),
        .exits([:]),
        .isLand,
        .isSacred,
        .localGlobals(.globalWater, .whiteCliff, .river)
    )

    static let river4 = Location(
        id: .river4,
        .name("Frigid River"),
        .description("""
            The river is running faster here and the sound ahead appears to be
            that of rushing water. On the east shore is a sandy beach. A small
            area of beach can also be seen below the cliffs on the west shore.
            """),
        .exits([
            // Note: UP exit has custom message about strong currents
            .down: .to(.river5),
            // Note: LAND exit has custom message
            .west: .to(.whiteCliffsSouth),
            .east: .to(.sandyBeach)
        ]),
        // Note: This is NONLANDBIT in ZIL
        .isSacred,
        .localGlobals(.globalWater, .river)
    )

    static let river5 = Location(
        id: .river5,
        .name("Frigid River"),
        .description("""
            The sound of rushing water is nearly unbearable here. On the east
            shore is a large landing area.
            """),
        .exits([
            // Note: UP exit has custom message about strong currents
            .east: .to(.shore),
            // Note: LAND exit to shore
        ]),
        // Note: This is NONLANDBIT in ZIL
        .isSacred,
        .inherentlyLit,
        .localGlobals(.globalWater, .river)
    )

    static let shore = Location(
        id: .shore,
        .name("Shore"),
        .description("""
            You are on the east shore of the river. The water here seems somewhat
            treacherous. A path travels from north to south here, the south end
            quickly turning around a sharp corner.
            """),
        .exits([
            .north: .to(.sandyBeach),
            .south: .to(.aragainFalls)
        ]),
        .isLand,
        .isSacred,
        .inherentlyLit,
        .localGlobals(.globalWater, .river)
    )

    static let sandyBeach = Location(
        id: .sandyBeach,
        .name("Sandy Beach"),
        .description("""
            You are on a large sandy beach on the east shore of the river, which is
            flowing quickly by. A path runs beside the river to the south here, and
            a passage is partially buried in sand to the northeast.
            """),
        .exits([
            .northeast: .to(.sandyCave),
            .south: .to(.shore)
        ]),
        .isLand,
        .isSacred,
        .localGlobals(.globalWater, .river)
    )

    static let sandyCave = Location(
        id: .sandyCave,
        .name("Sandy Cave"),
        .description("""
            This is a sand-filled cave whose exit is to the southwest.
            """),
        .exits([
            .southwest: .to(.sandyBeach)
        ]),
        .isLand
    )

    static let aragainFalls = Location(
        id: .aragainFalls,
        .name("Aragain Falls"),
        .description("""
            You are at the top of Aragain Falls.
            """),
        .exits([
            // Note: WEST and UP exits to rainbow conditional on RAINBOW-FLAG
            // Note: DOWN exit has custom message
            .north: .to(.shore)
        ]),
        .isLand,
        .isSacred,
        .inherentlyLit,
        .localGlobals(.globalWater, .river, .rainbow)
    )

    static let onRainbow = Location(
        id: .onRainbow,
        .name("On the Rainbow"),
        .description("""
            You are on top of a rainbow (I bet you never thought you would walk
            on a rainbow), with a magnificent view of the Falls. The rainbow
            travels east-west here.
            """),
        .exits([
            .west: .to(.endOfRainbow),
            .east: .to(.aragainFalls)
        ]),
        .isLand,
        .inherentlyLit,
        .isSacred,
        .localGlobals(.rainbow)
    )

    static let endOfRainbow = Location(
        id: .endOfRainbow,
        .name("End of Rainbow"),
        .description("""
            You are on a small, rocky beach on the continuation of the Frigid
            River past the Falls. The beach is narrow due to the presence of the
            White Cliffs. The river canyon opens here and sunlight shines in
            from above. A rainbow crosses over the falls to the east and a narrow
            path continues to the southwest.
            """),
        .exits([
            // Note: UP, NE, EAST exits to rainbow conditional on RAINBOW-FLAG
            .southwest: .to(.canyonBottom)
        ]),
        .isLand,
        .inherentlyLit,
        .localGlobals(.globalWater, .rainbow, .river)
    )

    static let canyonBottom = Location(
        id: .canyonBottom,
        .name("Canyon Bottom"),
        .description("""
            You are beneath the walls of the river canyon which may be climbable
            here. The lesser part of the runoff of Aragain Falls flows by below.
            To the north is a narrow path.
            """),
        .exits([
            .up: .to(.cliffMiddle),
            .north: .to(.endOfRainbow)
        ]),
        .isLand,
        .inherentlyLit,
        .isSacred,
        .localGlobals(.globalWater, .climbableCliff, .river)
    )

    static let cliffMiddle = Location(
        id: .cliffMiddle,
        .name("Rocky Ledge"),
        .description("""
            You are on a ledge about halfway up the wall of the river canyon.
            You can see from here that the main flow from Aragain Falls twists
            along a passage which it is impossible for you to enter. Below you is the
            canyon bottom. Above you is more cliff, which appears
            climbable.
            """),
        .exits([
            .up: .to(.canyonView),
            .down: .to(.canyonBottom)
        ]),
        .isLand,
        .inherentlyLit,
        .isSacred,
        .localGlobals(.climbableCliff, .river)
    )

    static let canyonView = Location(
        id: .canyonView,
        .name("Canyon View"),
        .description("""
            You are at the top of the Great Canyon on its west wall. From here
            there is a marvelous view of the canyon and parts of the Frigid River
            upstream. Across the canyon, the walls of the White Cliffs join the
            mighty ramparts of the Flathead Mountains to the east. Following the
            Canyon upstream to the north, Aragain Falls may be seen, complete with
            rainbow. The mighty Frigid River flows out from a great dark cavern. To
            the west and south can be seen an immense forest, stretching for miles
            around. A path leads northwest. It is possible to climb down into
            the canyon from here.
            """),
        .exits([
            .east: .to(.cliffMiddle),
            .down: .to(.cliffMiddle),
            .northwest: .to(.clearing),
            .west: .to(.forest3),
            // Note: SOUTH exit has custom message
        ]),
        .isLand,
        .inherentlyLit,
        .isSacred,
        .localGlobals(.climbableCliff, .river, .rainbow)
    )

    // MARK: - Coal Mine Area

    static let mineEntrance = Location(
        id: .mineEntrance,
        .name("Mine Entrance"),
        .description("""
            You are standing at the entrance of what might have been a coal mine.
            The shaft enters the west wall, and there is another exit on the south
            end of the room.
            """),
        .exits([
            .south: .to(.slideRoom),
            .inside: .to(.squeakyRoom),
            .west: .to(.squeakyRoom)
        ]),
        .isLand
    )

    static let squeakyRoom = Location(
        id: .squeakyRoom,
        .name("Squeaky Room"),
        .description("""
            You are in a small room. Strange squeaky sounds may be heard coming
            from the passage at the north end. You may also escape to the east.
            """),
        .exits([
            .north: .to(.batRoom),
            .east: .to(.mineEntrance)
        ]),
        .isLand
    )

    static let batRoom = Location(
        id: .batRoom,
        .name("Bat Room"),
        .description("""
            You are in a room infested with bats. Strange squeaky sounds fill the air.
            """),
        .exits([
            .south: .to(.squeakyRoom),
            .east: .to(.shaftRoom)
        ]),
        .isLand,
        .isSacred
    )

    static let shaftRoom = Location(
        id: .shaftRoom,
        .name("Shaft Room"),
        .description("""
            This is a large room, in the middle of which is a small shaft
            descending through the floor into darkness below. To the west and
            the north are exits from this room. Constructed over the top of the
            shaft is a metal framework to which a heavy iron chain is attached.
            """),
        .exits([
            // Note: DOWN exit has custom message
            .west: .to(.batRoom),
            .north: .to(.smellyRoom)
        ]),
        .isLand
    )

    static let smellyRoom = Location(
        id: .smellyRoom,
        .name("Smelly Room"),
        .description("""
            This is a small nondescript room. However, from the direction
            of a small descending staircase a foul odor can be detected. To the
            south is a narrow tunnel.
            """),
        .exits([
            .down: .to(.gasRoom),
            .south: .to(.shaftRoom)
        ]),
        .isLand,
        .localGlobals(.stairs)
    )

    static let gasRoom = Location(
        id: .gasRoom,
        .name("Gas Room"),
        .description("""
            This is a small room which smells strongly of coal gas. There is a
            short climb up some stairs and a narrow tunnel leading east.
            """),
        .exits([
            .up: .to(.smellyRoom),
            .east: .to(.mine1)
        ]),
        .isLand,
        .isSacred,
        .localGlobals(.stairs)
    )

    static let ladderTop = Location(
        id: .ladderTop,
        .name("Ladder Top"),
        .description("""
            This is a very small room. In the corner is a rickety wooden
            ladder, leading downward. It might be safe to descend. There is
            also a staircase leading upward.
            """),
        .exits([
            .down: .to(.ladderBottom),
            .up: .to(.mine4)
        ]),
        .isLand,
        .localGlobals(.ladder, .stairs)
    )

    static let ladderBottom = Location(
        id: .ladderBottom,
        .name("Ladder Bottom"),
        .description("""
            This is a rather wide room. On one side is the bottom of a
            narrow wooden ladder. To the west and the south are passages
            leaving the room.
            """),
        .exits([
            .south: .to(.deadEnd5),
            .west: .to(.timberRoom),
            .up: .to(.ladderTop)
        ]),
        .isLand,
        .localGlobals(.ladder)
    )

    static let deadEnd5 = Location(
        id: .deadEnd5,
        .name("Dead End"),
        .description("""
            You have come to a dead end in the mine.
            """),
        .exits([
            .north: .to(.ladderBottom)
        ]),
        .isLand
    )

    static let timberRoom = Location(
        id: .timberRoom,
        .name("Timber Room"),
        .description("""
            This is a long and narrow passage, which is cluttered with broken
            timbers. A wide passage comes from the east and turns at the
            west end of the room into a very narrow passageway. From the west
            comes a strong draft.
            """),
        .exits([
            .east: .to(.ladderBottom),
            // Note: WEST exit to lower shaft conditional on EMPTY-HANDED
        ]),
        .isLand,
        .isSacred
    )

    static let lowerShaft = Location(
        id: .lowerShaft,
        .name("Drafty Room"),
        .description("""
            This is a small drafty room in which is the bottom of a long
            shaft. To the south is a passageway and to the east a very narrow
            passage. In the shaft can be seen a heavy iron chain.
            """),
        .exits([
            .south: .to(.machineRoom),
            // Note: OUT and EAST exits to timber room conditional on EMPTY-HANDED
        ]),
        .isLand,
        .isSacred
    )

    static let machineRoom = Location(
        id: .machineRoom,
        .name("Machine Room"),
        .description("""
            This room contains a large machine.
            """),
        .exits([
            .north: .to(.lowerShaft)
        ]),
        .isLand
    )

    // MARK: - Coal Mine Proper

    static let mine1 = Location(
        id: .mine1,
        .name("Coal Mine"),
        .description("""
            This is a nondescript part of a coal mine.
            """),
        .exits([
            .north: .to(.gasRoom),
            .east: .to(.mine1),
            .northeast: .to(.mine2)
        ]),
        .isLand
    )

    static let mine2 = Location(
        id: .mine2,
        .name("Coal Mine"),
        .description("""
            This is a nondescript part of a coal mine.
            """),
        .exits([
            .north: .to(.mine2),
            .south: .to(.mine1),
            .southeast: .to(.mine3)
        ]),
        .isLand
    )

    static let mine3 = Location(
        id: .mine3,
        .name("Coal Mine"),
        .description("""
            This is a nondescript part of a coal mine.
            """),
        .exits([
            .south: .to(.mine3),
            .southwest: .to(.mine4),
            .east: .to(.mine2)
        ]),
        .isLand
    )

    static let mine4 = Location(
        id: .mine4,
        .name("Coal Mine"),
        .description("""
            This is a nondescript part of a coal mine.
            """),
        .exits([
            .north: .to(.mine3),
            .west: .to(.mine4),
            .down: .to(.ladderTop)
        ]),
        .isLand
    )

    static let slideRoom = Location(
        id: .slideRoom,
        .name("Slide Room"),
        .description("""
            This is a small chamber, which appears to have been part of a
            coal mine. On the south wall of the chamber the letters "Granite
            Wall" are etched in the rock. To the east is a long passage, and
            there is a steep metal slide twisting downward. To the north is
            a small opening.
            """),
        .exits([
            .east: .to(.coldPassage),
            .north: .to(.mineEntrance),
            .down: .to(.cellar)
        ]),
        .isLand,
        .localGlobals(.slide)
    )
}
