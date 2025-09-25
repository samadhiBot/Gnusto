import GnustoEngine

// MARK: - Global Items

enum GlobalItems {
    static let bauble = Item(
        id: .bauble,
        .name("beautiful brass bauble"),
        .synonyms("bauble", "treasure"),
        .adjectives("brass", "beautiful"),
        .isTakable,
        .value(1)
        // Note: VALUE 1, TVALUE 1, parent not specified in ZIL
    )

    static let board = Item(
        id: .board,
        .name("board"),
        .synonyms("boards", "board"),
        .omitDescription
        // Note: Has action handler BOARD-F
    )

    static let boardedWindow = Item(
        id: .boardedWindow,
        .name("boarded window"),
        .synonyms("window"),
        .adjectives("boarded"),
        .omitDescription
        // Note: Has action handler BOARDED-WINDOW-FCN
    )

    static let brokenCanary = Item(
        id: .brokenCanary,
        .name("broken clockwork canary"),
        .synonyms("canary", "treasure"),
        .adjectives("broken", "clockwork", "gold", "golden"),
        .isTakable,
        .firstDescription(
            """
            There is a golden clockwork canary nestled in the egg. It seems to
            have recently had a bad experience. The mountings for its jewel-like
            eyes are empty, and its silver beak is crumpled. Through a cracked
            crystal window below its left wing you can see the remains of
            intricate machinery. It is not clear what result winding it would
            have, as the mainspring seems sprung.
            """
        ),
        .in(.item(.brokenEgg)),
        .value(1)
        // Note: TVALUE 1, has action handler CANARY-OBJECT
    )

    static let brokenEgg = Item(
        id: .brokenEgg,
        .name("broken jewel-encrusted egg"),
        .synonyms("egg", "treasure"),
        .adjectives("broken", "birds", "encrusted", "jewel"),
        .isTakable,
        .isContainer,
        .isOpen,
        .capacity(6),
        .description("There is a somewhat ruined egg here."),
        .value(2)
        // Note: TVALUE 2, parent not specified in ZIL
    )

    static let brokenLamp = Item(
        id: .brokenLamp,
        .name("broken lantern"),
        .synonyms("lamp", "lantern"),
        .adjectives("broken"),
        .isTakable
        // Note: Parent not specified in ZIL
    )

    static let canary = Item(
        id: .canary,
        .name("golden clockwork canary"),
        .synonyms("canary", "treasure"),
        .adjectives("clockwork", "gold", "golden"),
        .isTakable,
        .isSearchable,
        .firstDescription(
            """
            There is a golden clockwork canary nestled in the egg. It has ruby
            eyes and a silver beak. Through a crystal window below its left
            wing you can see intricate machinery inside. It appears to have
            wound down.
            """
        ),
        .in(.item(.egg)),
        .value(6)
        // Note: VALUE 6, TVALUE 4, has action handler CANARY-OBJECT
    )

    static let chimney = Item(
        id: .chimney,
        .name("chimney"),
        .synonyms("chimney"),
        .adjectives("dark", "narrow"),
        .isClimbable,
        .omitDescription
        // Note: Has action handler CHIMNEY-F
    )

    static let egg = Item(
        id: .egg,
        .name("jewel-encrusted egg"),
        .synonyms("egg", "treasure"),
        .adjectives("birds", "encrusted", "jeweled"),
        .isTakable,
        .isContainer,
        .isSearchable,
        .capacity(6),
        .firstDescription(
            """
            In the bird's nest is a large egg encrusted with precious jewels,
            apparently scavenged by a childless songbird. The egg is covered with
            fine gold inlay, and ornamented in lapis lazuli and mother-of-pearl.
            Unlike most eggs, this one is hinged and closed with a delicate looking
            clasp. The egg appears extremely fragile.
            """
        ),
        .in(.item(.nest)),
        .value(5)
        // Note: VALUE 5, TVALUE 5, has action handler EGG-OBJECT
    )

    static let forest = Item(
        id: .forest,
        .name("forest"),
        .synonyms("forest", "trees", "pines", "hemlocks"),
        .omitDescription
        // Note: Has action handler FOREST-F
    )

    static let globalWater = Item(
        id: .globalWater,
        .name("water"),
        .synonyms("water", "quantity"),
        .isEdible  // DRINKBIT
        // Note: Has action handler WATER-F
    )

    static let graniteWall = Item(
        id: .graniteWall,
        .name("granite wall"),
        .synonyms("wall"),
        .adjectives("granite"),
        .omitDescription
        // Note: Parent is GLOBAL-OBJECTS, has action handler GRANITE-WALL-F
    )

    static let gunk = Item(
        id: .gunk,
        .name("small piece of vitreous slag"),
        .synonyms("gunk", "piece", "slag"),
        .adjectives("small", "vitreous"),
        .isTakable,
        .requiresTryTake,
        .size(10)
        // Note: Has action handler GUNK-FUNCTION, parent not specified
    )

    static let hotBell = Item(
        id: .hotBell,
        .name("red hot brass bell"),
        .synonyms("bell"),
        .adjectives("brass", "hot", "red", "small"),
        .requiresTryTake,
        .description("On the ground is a red hot bell.")
        // Note: Has action handler HOT-BELL-F, parent not specified
    )

    static let ladder = Item(
        id: .ladder,
        .name("wooden ladder"),
        .synonyms("ladder"),
        .adjectives("wooden", "rickety", "narrow"),
        .omitDescription,
        .isClimbable
    )

    static let mountainRange = Item(
        id: .mountainRange,
        .name("mountain range"),
        .synonyms("mountain", "range"),
        .adjectives("impassable", "flathead"),
        .isClimbable,
        .omitDescription,
        .in(.mountains)
        // Note: Has action handler MOUNTAIN-RANGE-F
    )

    static let slide = Item(
        id: .slide,
        .name("chute"),
        .synonyms("chute", "ramp", "slide"),
        .adjectives("steep", "metal", "twisting"),
        .isClimbable
        // Note: Has action handler SLIDE-FUNCTION
    )

    static let stairs = Item(
        id: .stairs,
        .name("stairs"),
        .synonyms("stairs", "staircase", "stairway", "steps"),
        .omitDescription,
        .isClimbable
        // Note: Global scenery object referenced in multiple rooms
    )

    static let teeth = Item(
        id: .teeth,
        .name("set of teeth"),
        .synonyms("overboard", "teeth"),
        .omitDescription
        // Note: Parent is GLOBAL-OBJECTS, has action handler TEETH-F
    )

    static let tree = Item(
        id: .tree,
        .name("tree"),
        .synonyms("tree", "branch"),
        .adjectives("large", "storm"),
        .isClimbable,
        .omitDescription
    )

    static let wall = Item(
        id: .wall,
        .name("surrounding wall"),
        .synonyms("wall", "walls"),
        .adjectives("surrounding")
        // Note: Parent is GLOBAL-OBJECTS
    )

    static let water = Item(
        id: .water,
        .name("quantity of water"),
        .synonyms("water", "quantity", "liquid", "h2o"),
        .isTakable,
        .requiresTryTake,
        .isEdible,  // DRINKBIT
        .size(4),
        .in(.item(.bottle))
        // Note: Has action handler WATER-F
    )

    static let whiteHouse = Item(
        id: .whiteHouse,
        .name("white house"),
        .synonyms("house"),
        .adjectives("white", "beautiful", "colonial"),
        .omitDescription
        // Note: Has action handler WHITE-HOUSE-F
    )
}

extension GlobalItems {
    static let boardHandler = ItemEventHandler(for: .boards) {
        before(.examine, .take) { _, _ in
            ActionResult("The boards are securely fastened.")
        }
    }
}
