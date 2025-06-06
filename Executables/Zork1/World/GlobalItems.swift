import GnustoEngine

enum GlobalItems {
    static let board = Item(
        id: .board,
        .name("board"),
        .synonyms("boards", "board"),
        .suppressDescription
        // Note: Has action handler BOARD-F
    )

    static let chimney = Item(
        id: .chimney,
        .name("chimney"),
        .synonyms("chimney"),
        .adjectives("dark", "narrow"),
        .isClimbable,
        .suppressDescription
        // Note: Has action handler CHIMNEY-F
    )

    static let forest = Item(
        id: .forest,
        .name("forest"),
        .synonyms("forest", "trees", "pines", "hemlocks"),
        .suppressDescription
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
        .suppressDescription
        // Note: Parent is GLOBAL-OBJECTS, has action handler GRANITE-WALL-F
    )

    static let kitchenWindow = Item(
        id: .kitchenWindow,
        .name("kitchen window"),
        .synonyms("window"),
        .adjectives("kitchen", "small"),
        .isDoor,
        .suppressDescription
        // Note: Has action handler KITCHEN-WINDOW-F
    )

    static let mountainRange = Item(
        id: .mountainRange,
        .name("mountain range"),
        .synonyms("mountain", "range"),
        .adjectives("impassable", "flathead"),
        .isClimbable,
        .suppressDescription,
        .in(.location(.mountains))
        // Note: Has action handler MOUNTAIN-RANGE-F
    )

    static let songbird = Item(
        id: .songbird,
        .name("songbird"),
        .synonyms("bird", "songbird"),
        .adjectives("song"),
        .suppressDescription
        // Note: Has action handler SONGBIRD-F
    )

    static let stairs = Item(
        id: .stairs,
        .name("stairs"),
        .synonyms("stairs", "staircase", "stairway", "steps"),
        .suppressDescription
        // Note: Global scenery object referenced in multiple rooms
    )

    static let teeth = Item(
        id: .teeth,
        .name("set of teeth"),
        .synonyms("overboard", "teeth"),
        .suppressDescription
        // Note: Parent is GLOBAL-OBJECTS, has action handler TEETH-F
    )

    static let tree = Item(
        id: .tree,
        .name("tree"),
        .synonyms("tree", "branch"),
        .adjectives("large", "storm"),
        .isClimbable,
        .suppressDescription
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
        .suppressDescription
        // Note: Has action handler WHITE-HOUSE-F
    )
}
