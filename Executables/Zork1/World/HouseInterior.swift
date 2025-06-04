import GnustoEngine

// MARK: - House Interior Area

enum HouseInterior {
    // MARK: - Locations

    static let kitchen = Location(
        id: .kitchen,
        .name("Kitchen"),
        .description("""
            You are in the kitchen of the white house. A table seems to have been used recently \
            for the preparation of food. A passage leads to the west and a dark staircase can be \
            seen leading upward. A dark chimney leads down and to the east is a small window which \
            is open.
            """),
        .exits([
            .west: .to(.livingRoom),
            .up: .to(.attic),
            .east: .to(.eastOfHouse),
        ]),
        .inherentlyLit
    )

    static let livingRoom = Location(
        id: .livingRoom,
        .name("Living Room"),
        .description("""
            You are in the living room. There is a doorway to the east, a wooden door with \
            strange gothic lettering to the west, which appears to be nailed shut, a trophy case, \
            and a large oriental rug in the center of the room.
            """),
        .exits([
            .east: .to(.kitchen),
            .west: .blocked("The door is nailed shut."),
            .down: Exit(
                destination: .cellar,
                doorID: .trapDoor
            ),
        ]),
        .inherentlyLit
    )

    static let attic = Location(
        id: .attic,
        .name("Attic"),
        .description("This is the attic. The only exit is a stairway leading down."),
        .exits([
            .down: .to(.kitchen),
        ]),
        .inherentlyLit
    )

    // MARK: - Items

    static let kitchenTable = Item(
        id: .kitchenTable,
        .name("kitchen table"),
        .description("The table seems to have been used recently for the preparation of food."),
        .adjectives("kitchen"),
        .synonyms("table"),
        .in(.location(.kitchen)),
        .isScenery,
        .isContainer,
        .isOpenable,
        .isOpen,
        .isSurface
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

    static let bottle = Item(
        id: .bottle,
        .name("glass bottle"),
        .description("It's a glass bottle."),
        .adjectives("glass", "clear"),
        .synonyms("bottle"),
        .in(.item(.kitchenTable)),
        .isTakable,
        .isContainer,
        .isOpenable
    )

    static let water = Item(
        id: .water,
        .name("quantity of water"),
        .description("It's just water."),
        .synonyms("water", "h2o", "liquid"),
        .in(.item(.bottle)),
        .isTakable
    )

    static let lunch = Item(
        id: .lunch,
        .name("lunch"),
        .description("A hot pepper sandwich."),
        .adjectives("hot", "pepper"),
        .synonyms("sandwich", "food", "dinner"),
        .in(.item(.brownSack)),
        .isTakable
    )

    static let garlic = Item(
        id: .garlic,
        .name("clove of garlic"),
        .description("It's a clove of garlic."),
        .synonyms("garlic", "clove"),
        .in(.item(.brownSack)),
        .isTakable
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

    static let trophyCase = Item(
        id: .trophyCase,
        .name("trophy case"),
        .description("The trophy case is securely fastened to the wall."),
        .adjectives("trophy"),
        .synonyms("case"),
        .in(.location(.livingRoom)),
        .isScenery,
        .isContainer,
        .isOpenable,
        .isTransparent
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

    static let trapDoor = Item(
        id: .trapDoor,
        .name("trap door"),
        .description("It's a closed trap door."),
        .adjectives("trap"),
        .synonyms("door", "trapdoor"),
        .in(.location(.livingRoom)),
        .isScenery,
        .isOpenable
        // TODO: Should be initially invisible under carpet, revealed by "move rug"
    )

    static let woodenDoor = Item(
        id: .woodenDoor,
        .name("wooden door"),
        .description("""
            The wooden door has strange gothic lettering above it and appears to be nailed shut.
            """),
        .adjectives("wooden", "strange", "gothic"),
        .synonyms("door"),
        .in(.location(.livingRoom)),
        .isScenery
    )

    static let rope = Item(
        id: .rope,
        .name("rope"),
        .description("It's a sturdy rope."),
        .synonyms("rope"),
        .in(.location(.attic)),
        .isTakable
    )

    static let knife = Item(
        id: .knife,
        .name("nasty knife"),
        .description("It's a vicious-looking knife."),
        .adjectives("nasty", "vicious"),
        .synonyms("knife"),
        .in(.location(.attic)),
        .isTakable,
        .isWeapon
    )

    static let sword = Item(
        id: .sword,
        .name("sword"),
        .description("It's an elvish sword of great antiquity."),
        .adjectives("elvish"),
        .synonyms("sword", "blade"),
        .in(.location(.livingRoom)),
        .isTakable,
        .isWeapon
    )

    static let lamp = Item(
        id: .lamp,
        .name("brass lantern"),
        .description("""
            The brass lantern is turned off. The brass lantern contains a clear glass globe
            which is currently dark.
            """),
        .adjectives("brass"),
        .synonyms("lantern", "lamp", "light"),
        .in(.location(.livingRoom)),
        .isTakable,
        .isLightSource,
        .isDevice
    )
}
