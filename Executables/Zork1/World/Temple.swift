import GnustoEngine

enum Temple {
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
}

// MARK: - Items

extension Temple {
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
        .in(.location(.egyptRoom))
        // Note: VALUE 10, TVALUE 15, SACREDBIT
    )

    static let sceptre = Item(
        id: .sceptre,
        .name("sceptre"),
        .synonyms("sceptre", "scepter", "treasure"),
        .adjectives("sharp", "egyptian", "ancient", "enameled"),
        .isTakable,
        .isWeapon,
        .description("An ornamented sceptre, tapering to a sharp point, is here."),
        .firstDescription("""
            A sceptre, possibly that of ancient Egypt itself, is in the coffin. The
            sceptre is ornamented with colored enamel, and tapers to a sharp point.
            """),
        .size(3),
        .in(.item(.coffin))
        // Note: VALUE 4, TVALUE 6, has action handler SCEPTRE-FUNCTION
    )
}
