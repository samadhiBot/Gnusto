import GnustoEngine

// MARK: - Inside the House

enum InsideHouse {
    static let attic = Location(
        id: .attic,
        .name("Attic"),
        .description("""
            This is the attic. The only exit is a stairway leading down.
            """),
        .exits([
            .down: .to(.kitchen)
        ]),
        .localGlobals(.stairs)
    )

    static let kitchen = Location(
        id: .kitchen,
        .name("Kitchen"),
        .description("""
            You are in the kitchen of the white house. A table seems to have been used recently for the preparation of food. A passage leads to the west and a dark staircase can be seen leading upward. A dark chimney leads down and to the north is a small window which is open.
            """),
        .exits([
            .west: .to(.livingRoom),
            .up: .to(.attic),
            // Note: EAST and OUT exits to east-of-house conditional on kitchen window being open
            // Note: DOWN exit to studio conditional on FALSE-FLAG
        ]),
        .inherentlyLit,
        .localGlobals(.kitchenWindow, .chimney, .stairs)
    )

    static let livingRoom = Location(
        id: .livingRoom,
        .name("Living Room"),
        .description("""
            You are in the living room. There is a doorway to the east, a wooden door with
            strange gothic lettering to the west, which appears to be nailed shut, a trophy case,
            and a large oriental rug in the center of the room.
            """),
        .exits([
            .east: .to(.kitchen),
            .west: .blocked("The door is nailed shut."),
            .down: .to(.cellar, via: .trapDoor),
        ]),
        .inherentlyLit,
        .localGlobals(.stairs)
    )

    // MARK: - Items

    static let atticTable = Item(
        id: .atticTable,
        .name("table"),
        .synonyms("table"),
        .suppressDescription,
        .isContainer,
        .isOpen,
        .isSurface,
        .capacity(40),
        .in(.location(.attic))
    )

    static let bottle = Item(
        id: .bottle,
        .name("glass bottle"),
        .synonyms("bottle", "container"),
        .adjectives("clear", "glass"),
        .isTakable,
        .isTransparent,
        .isContainer,
        .firstDescription("A bottle is sitting on the table."),
        .capacity(4),
        .in(.item(.kitchenTable))
        // Note: Has action handler BOTTLE-FUNCTION
    )

    static let brownSack = Item(
        id: .brownSack,
        .name("brown sack"),
        .description("An elongated brown sack, smelling of hot peppers."),
        .adjectives("brown", "elongated", "smelly"),
        .synonyms("bag", "sack"),
        .in(.item(.kitchenTable)),
        .isTakable,
        .isContainer,
        .isOpenable
    )

    static let carpet = Item(
        id: .carpet,
        .name("large oriental rug"),
        .description("""
            The rug is extremely heavy and cannot be carried. There appears to be something
            underneath it.
            """),
        .adjectives("large", "oriental"),
        .synonyms("rug", "carpet"),
        .in(.location(.livingRoom)),
        .isScenery
    )

    static let chimney = Item(
        id: .chimney,
        .name("chimney"),
        .description("The chimney leads upward, and looks climbable."),
        .adjectives("dark", "narrow"),
        .synonyms("chimney"),
        .in(.location(.kitchen)),
        .isScenery,
        .isClimbable
    )

    static let garlic = Item(
        id: .garlic,
        .name("clove of garlic"),
        .synonyms("garlic", "clove"),
        .isTakable,
        .isEdible,
        .size(4),
        .in(.item(.sandwichBag))
        // Note: Has action handler GARLIC-F
    )

    static let kitchenTable = Item(
        id: .kitchenTable,
        .name("kitchen table"),
        .synonyms("table"),
        .adjectives("kitchen"),
        .suppressDescription,
        .isContainer,
        .isOpen,
        .isSurface,
        .capacity(50),
        .in(.location(.kitchen))
    )

    static let knife = Item(
        id: .knife,
        .name("nasty knife"),
        .synonyms("knives", "knife", "blade"),
        .adjectives("nasty", "unrusty"),
        .isTakable,
        .isWeapon,
        .requiresTryTake,
        .firstDescription("On a table is a nasty-looking knife."),
        .in(.item(.atticTable))
        // Note: Has action handler KNIFE-F
    )

    static let lamp = Item(
        id: .lamp,
        .name("brass lantern"),
        .synonyms("lamp", "lantern", "light"),
        .adjectives("brass"),
        .isTakable,
        .isLightSource,  // LIGHTBIT
        .firstDescription("A battery-powered brass lantern is on the trophy case."),
        .description("There is a brass lantern (battery-powered) here."),
        .size(15),
        .in(.location(.livingRoom))
        // Note: Has action handler LANTERN
    )

    static let lunch = Item(
        id: .lunch,
        .name("lunch"),
        .synonyms("food", "sandwich", "lunch", "dinner"),
        .adjectives("hot", "pepper"),
        .isTakable,
        .isEdible,
        .description("A hot pepper sandwich is here."),
        .in(.item(.sandwichBag))
    )

    static let map = Item(
        id: .map,
        .name("ancient map"),
        .synonyms("parchment", "map"),
        .adjectives("antique", "old", "ancient"),
        .isInvisible,
        .isReadable,
        .isTakable,
        .firstDescription("In the trophy case is an ancient parchment which appears to be a map."),
        .readText("""
            The map shows a forest with three clearings. The largest clearing contains
            a house. Three paths leave the large clearing. One of these paths, leading
            southwest, is marked "To Stone Barrow".
            """),
        .size(2),
        .in(.item(.trophyCase))
    )

    static let rope = Item(
        id: .rope,
        .name("rope"),
        .synonyms("rope", "hemp", "coil"),
        .adjectives("large"),
        .isTakable,
        .requiresTryTake,
        .firstDescription("A large coil of rope is lying in the corner."),
        .size(10),
        .in(.location(.attic))
        // Note: Has action handler ROPE-FUNCTION, SACREDBIT
    )

    static let rug = Item(
        id: .rug,
        .name("carpet"),
        .synonyms("rug", "carpet"),
        .adjectives("large", "oriental"),
        .suppressDescription,
        .requiresTryTake,
        .in(.location(.livingRoom))
        // Note: Has action handler RUG-FCN
    )

    static let sandwichBag = Item(
        id: .sandwichBag,
        .name("brown sack"),
        .synonyms("bag", "sack"),
        .adjectives("brown", "elongated", "smelly"),
        .isTakable,
        .isContainer,
        .isFlammable,
        .firstDescription("On the table is an elongated brown sack, smelling of hot peppers."),
        .capacity(9),
        .size(9),
        .in(.item(.kitchenTable))
        // Note: Has action handler SANDWICH-BAG-FCN
    )

    static let sword = Item(
        id: .sword,
        .name("sword"),
        .synonyms("sword", "orcrist", "glamdring", "blade"),
        .adjectives("elvish", "old", "antique"),
        .isTakable,
        .isWeapon,
        .requiresTryTake,
        .firstDescription("Above the trophy case hangs an elvish sword of great antiquity."),
        .size(30),
        .in(.location(.livingRoom))
        // Note: Has action handler SWORD-FCN, TVALUE 0
    )

    static let trapDoor = Item(
        id: .trapDoor,
        .name("trap door"),
        .synonyms("door", "trapdoor", "trap-door", "cover"),
        .adjectives("trap", "dusty"),
        .isDoor,
        .suppressDescription,
        .isInvisible,
        .in(.location(.livingRoom))
        // Note: Has action handler TRAP-DOOR-FCN
    )

    static let trophyCase = Item(
        id: .trophyCase,
        .name("trophy case"),
        .synonyms("case"),
        .adjectives("trophy"),
        .isTransparent,
        .isContainer,
        .suppressDescription,
        .requiresTryTake,
        .isSearchable,
        .capacity(10000),
        .in(.location(.livingRoom))
        // Note: Has action handler TROPHY-CASE-FCN
    )

    static let water = Item(
        id: .water,
        .name("quantity of water"),
        .description("It's just water."),
        .synonyms("water", "h2o", "liquid"),
        .in(.item(.bottle)),
        .isTakable
    )

    static let woodenDoor = Item(
        id: .woodenDoor,
        .name("wooden door"),
        .synonyms("door", "lettering", "writing"),
        .adjectives("wooden", "gothic", "strange", "west"),
        .isReadable,
        .isDoor,
        .suppressDescription,
        .isTransparent,
        .readText("The engravings translate to \"This space intentionally left blank.\""),
        .in(.location(.livingRoom))
        // Note: Has action handler FRONT-DOOR-FCN
    )
}
