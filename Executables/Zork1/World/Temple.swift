import GnustoEngine

enum Temple {
    static let domeRoom = Location(
        id: .domeRoom,
        .name("Dome Room"),
        .description(
            """
            You are at the top of a large dome.
            """
        ),
        .exits(
            .west(.engravingsCave)
            // Note: DOWN exit to torch room conditional on DOME-FLAG
        )
    )

    static let egyptRoom = Location(
        id: .egyptRoom,
        .name("Egyptian Room"),
        .description(
            """
            This is a room which looks like an Egyptian tomb. There is an
            ascending staircase to the west.
            """
        ),
        .exits(
            .west(.northTemple),
            .up(.northTemple)
        ),
        .localGlobals(.stairs)
    )

    static let engravingsCave = Location(
        id: .engravingsCave,
        .name("Engravings Cave"),
        .description(
            """
            You have entered a low cave with passages leading northwest and east.
            """
        ),
        .exits(
            .northwest(.roundRoom),
            .east(.domeRoom)
        )
    )

    static let northTemple = Location(
        id: .northTemple,
        .name("Temple"),
        .description(
            """
            This is the north end of a large temple. On the east wall is an
            ancient inscription, probably a prayer in a long-forgotten language.
            Below the prayer is a staircase leading down. The west wall is solid
            granite. The exit to the north end of the room is through huge
            marble pillars.
            """
        ),
        .exits(
            .down(.egyptRoom),
            .east(.egyptRoom),
            .north(.torchRoom),
            .outside(.torchRoom),
            .up(.torchRoom),
            .south(.southTemple)
        ),
        .inherentlyLit,
        .localGlobals(.stairs)
    )

    static let southTemple = Location(
        id: .southTemple,
        .name("Altar"),
        .description(
            """
            This is the south end of a large temple. In front of you is what
            appears to be an altar. In one corner is a small hole in the floor
            which leads into darkness. You probably could not get back up it.
            """
        ),
        .exits(
            .north(.northTemple)
            // Note: DOWN exit to tiny cave conditional on COFFIN-CURE
        ),
        .inherentlyLit
    )

    static let torchRoom = Location(
        id: .torchRoom,
        .name("Torch Room"),
        .description(
            """
            This is a large room with a white marble pedestal in the center.
            """
        ),
        .exits(
            // Note: UP exit has custom message about not reaching rope
            .south(.northTemple),
            .down(.northTemple)
        ),
        .localGlobals(.stairs)
    )
}

// MARK: - Items

extension Temple {
    static let altar = Item(
        id: .altar,
        .name("altar"),
        .synonyms("altar"),
        .omitDescription,
        .isSurface,  // SURFACEBIT
        .isContainer,
        .isOpen,
        .capacity(50),
        .in(.southTemple)
    )

    static let bell = Item(
        id: .bell,
        .name("brass bell"),
        .synonyms("bell"),
        .adjectives("small", "brass"),
        .isTakable,
        .in(.northTemple)
        // Note: Has action handler BELL-F
    )

    static let book = Item(
        id: .book,
        .name("black book"),
        .synonyms("book", "prayer", "page", "books"),
        .adjectives("large", "black"),
        .isReadable,
        .isTakable,
        .isContainer,
        .isFlammable,
        .firstDescription("On the altar is a large black book, open to page 569."),
        .readText(
            """
            Commandment #12592

            Oh ye who go about saying unto each:  "Hello sailor":
            Dost thou know the magnitude of thy sin before the gods?
            Yea, verily, thou shalt be ground between two stones.
            Shall the angry gods cast thy body into the whirlpool?
            Surely, thy eye shall be put out with a sharp stick!
            Even unto the ends of the earth shalt thou wander and
            Unto the land of the dead shalt thou be sent at last.
            Surely thou shalt repent of thy cunning.
            """
        ),
        .size(10),
        .in(.item(.altar))
        // Note: Has action handler BLACK-BOOK, TURNBIT
    )

    static let candles = Item(
        id: .candles,
        .name("pair of candles"),
        .synonyms("candles", "pair"),
        .adjectives("burning"),
        .isTakable,
        .isFlammable,  // FLAMEBIT
        .isOn,  // ONBIT
        .isLightSource,  // LIGHTBIT
        .firstDescription("On the two ends of the altar are burning candles."),
        .size(10),
        .in(.southTemple)
        // Note: Has action handler CANDLES-FCN
    )

    static let coffin = Item(
        id: .coffin,
        .name("gold coffin"),
        .synonyms("coffin", "casket", "treasure"),
        .adjectives("solid", "gold"),
        .isTakable,
        .isContainer,
        .isSearchable,
        .description("The solid-gold coffin used for the burial of Ramses II is here."),
        .capacity(35),
        .size(55),
        .in(.egyptRoom),
        .value(10),
        .isSacred
        // Note: VALUE 10, TVALUE 15, SACREDBIT
    )

    static let engravings = Item(
        id: .engravings,
        .name("wall with engravings"),
        .synonyms("wall", "engravings", "inscription"),
        .adjectives("old", "ancient"),
        .isReadable,
        .description("There are old engravings on the walls here."),
        .readText(
            """
            The engravings were incised in the living rock of the cave wall by
            an unknown hand. They depict, in symbolic form, the beliefs of the
            ancient Zorkers. Skillfully interwoven with the bas reliefs are excerpts
            illustrating the major religious tenets of that time. Unfortunately, a
            later age seems to have considered them blasphemous and just as skillfully
            excised them.
            """
        ),
        .in(.engravingsCave),
        .isSacred
        // Note: SACREDBIT
    )

    static let pedestal = Item(
        id: .pedestal,
        .name("pedestal"),
        .synonyms("pedestal"),
        .adjectives("white", "marble"),
        .omitDescription,
        .isContainer,
        .isOpen,
        .isSurface,
        .capacity(30),
        .in(.torchRoom)
        // Note: Has action handler DUMB-CONTAINER
    )

    static let prayer = Item(
        id: .prayer,
        .name("prayer"),
        .synonyms("prayer", "inscription"),
        .adjectives("ancient", "old"),
        .isReadable,
        .omitDescription,
        .readText(
            """
            The prayer is inscribed in an ancient script, rarely used today. It seems
            to be a philippic against small insects, absent-mindedness, and the picking
            up and dropping of small objects. The final verse consigns trespassers to
            the land of the dead. All evidence indicates that the beliefs of the ancient
            Zorkers were obscure.
            """
        ),
        .in(.northTemple),
        .isSacred
        // Note: SACREDBIT
    )

    static let railing = Item(
        id: .railing,
        .name("wooden railing"),
        .synonyms("railing", "rail"),
        .adjectives("wooden"),
        .omitDescription,
        .in(.domeRoom)
    )

    static let sceptre = Item(
        id: .sceptre,
        .name("sceptre"),
        .synonyms("sceptre", "scepter", "treasure"),
        .adjectives("sharp", "egyptian", "ancient", "enameled"),
        .isTakable,
        .isWeapon,
        .description("An ornamented sceptre, tapering to a sharp point, is here."),
        .firstDescription(
            """
            A sceptre, possibly that of ancient Egypt itself, is in the coffin. The
            sceptre is ornamented with colored enamel, and tapers to a sharp point.
            """
        ),
        .size(3),
        .in(.item(.coffin)),
        .value(4)
        // Note: VALUE 4, TVALUE 6, has action handler SCEPTRE-FUNCTION
    )

    static let torch = Item(
        id: .torch,
        .name("torch"),
        .synonyms("torch", "ivory", "treasure"),
        .adjectives("flaming", "ivory"),
        .isTakable,
        .isFlammable,  // FLAMEBIT
        .isOn,  // ONBIT
        .isLightSource,  // LIGHTBIT
        .firstDescription("Sitting on the pedestal is a flaming torch, made of ivory."),
        .size(20),
        .in(.item(.pedestal)),
        .value(14)
        // Note: VALUE 14, TVALUE 6, has action handler TORCH-OBJECT
    )
}
