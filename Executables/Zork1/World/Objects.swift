import GnustoEngine

extension Item {
    // MARK: - Global Objects and Scenery

    static let board = Item(
        id: "board",
        .name("board"),
        .synonyms("boards", "board"),
        .suppressDescription
        // Note: Has action handler BOARD-F
    )

    static let teeth = Item(
        id: "teeth",
        .name("set of teeth"),
        .synonyms("overboard", "teeth"),
        .suppressDescription
        // Note: Parent is GLOBAL-OBJECTS, has action handler TEETH-F
    )

    static let wall = Item(
        id: "wall",
        .name("surrounding wall"),
        .synonyms("wall", "walls"),
        .adjectives("surrounding")
        // Note: Parent is GLOBAL-OBJECTS
    )

    static let graniteWall = Item(
        id: "graniteWall",
        .name("granite wall"),
        .synonyms("wall"),
        .adjectives("granite"),
        .suppressDescription
        // Note: Parent is GLOBAL-OBJECTS, has action handler GRANITE-WALL-F
    )

    static let songbird = Item(
        id: "songbird",
        .name("songbird"),
        .synonyms("bird", "songbird"),
        .adjectives("song"),
        .suppressDescription
        // Note: Has action handler SONGBIRD-F
    )

    static let whiteHouse = Item(
        id: "whiteHouse",
        .name("white house"),
        .synonyms("house"),
        .adjectives("white", "beautiful", "colonial"),
        .suppressDescription
        // Note: Has action handler WHITE-HOUSE-F
    )

    static let forest = Item(
        id: "forest",
        .name("forest"),
        .synonyms("forest", "trees", "pines", "hemlocks"),
        .suppressDescription
        // Note: Has action handler FOREST-F
    )

    static let tree = Item(
        id: "tree",
        .name("tree"),
        .synonyms("tree", "branch"),
        .adjectives("large", "storm"),
        .isClimbable,
        .suppressDescription
    )

    static let mountainRange = Item(
        id: "mountainRange",
        .name("mountain range"),
        .synonyms("mountain", "range"),
        .adjectives("impassable", "flathead"),
        .isClimbable,
        .suppressDescription,
        .in(.location("mountains"))
        // Note: Has action handler MOUNTAIN-RANGE-F
    )

    static let globalWater = Item(
        id: "globalWater",
        .name("water"),
        .synonyms("water", "quantity"),
        .isEdible  // DRINKBIT
        // Note: Has action handler WATER-F
    )

    static let water = Item(
        id: "water",
        .name("quantity of water"),
        .synonyms("water", "quantity", "liquid", "h2o"),
        .isTakable,
        .requiresTryTake,
        .isEdible,  // DRINKBIT
        .size(4),
        .in(.item("bottle"))
        // Note: Has action handler WATER-F
    )

    static let kitchenWindow = Item(
        id: "kitchenWindow",
        .name("kitchen window"),
        .synonyms("window"),
        .adjectives("kitchen", "small"),
        .isDoor,
        .suppressDescription
        // Note: Has action handler KITCHEN-WINDOW-F
    )

    static let chimney = Item(
        id: "chimney",
        .name("chimney"),
        .synonyms("chimney"),
        .adjectives("dark", "narrow"),
        .isClimbable,
        .suppressDescription
        // Note: Has action handler CHIMNEY-F
    )

    // MARK: - Characters and Creatures

    static let ghosts = Item(
        id: "ghosts",
        .name("number of ghosts"),
        .synonyms("ghosts", "spirits", "fiends", "force"),
        .adjectives("invisible", "evil"),
        .isCharacter,  // ACTORBIT
        .suppressDescription,
        .in(.location("entranceToHades"))
        // Note: Has action handler GHOSTS-F
    )

    static let cyclops = Item(
        id: "cyclops",
        .name("cyclops"),
        .synonyms("cyclops", "monster", "eye"),
        .adjectives("hungry", "giant"),
        .isCharacter,  // ACTORBIT
        .suppressDescription,
        .requiresTryTake,
        .in(.location("cyclopsRoom"))
        // Note: Has action handler CYCLOPS-FCN, STRENGTH 10000
    )

    static let bat = Item(
        id: "bat",
        .name("bat"),
        .synonyms("bat", "vampire"),
        .adjectives("vampire", "deranged"),
        .isCharacter,  // ACTORBIT
        .requiresTryTake,
        .in(.location("batRoom"))
        // Note: Has action handler BAT-F, DESCFCN BAT-D
    )

    static let troll = Item(
        id: "troll",
        .name("troll"),
        .synonyms("troll"),
        .adjectives("nasty"),
        .isCharacter,  // ACTORBIT
        .isOpen,  // OPENBIT
        .requiresTryTake,
        .description("""
            A nasty-looking troll, brandishing a bloody axe, blocks all passages
            out of the room.
            """),
        .in(.location("trollRoom"))
        // Note: Has action handler TROLL-FCN, STRENGTH 2
    )

    // MARK: - Treasures

    static let skull = Item(
        id: "skull",
        .name("crystal skull"),
        .synonyms("skull", "head", "treasure"),
        .adjectives("crystal"),
        .isTakable,
        .firstDescription("""
            Lying in one corner of the room is a beautifully carved crystal skull.
            It appears to be grinning at you rather nastily.
            """),
        .in(.location("landOfLivingDead"))
        // Note: VALUE 10, TVALUE 10
    )

    static let sceptre = Item(
        id: "sceptre",
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
        .in(.item("coffin"))
        // Note: VALUE 4, TVALUE 6, has action handler SCEPTRE-FUNCTION
    )

    static let chalice = Item(
        id: "chalice",
        .name("chalice"),
        .synonyms("chalice", "cup", "silver", "treasure"),
        .adjectives("silver", "engravings"),
        .isTakable,
        .requiresTryTake,
        .isContainer,
        .description("There is a silver chalice, intricately engraved, here."),
        .capacity(5),
        .size(10),
        .in(.location("treasureRoom"))
        // Note: VALUE 10, TVALUE 5, has action handler CHALICE-FCN
    )

    static let trident = Item(
        id: "trident",
        .name("crystal trident"),
        .synonyms("trident", "fork", "treasure"),
        .adjectives("poseidon", "own", "crystal"),
        .isTakable,
        .firstDescription("On the shore lies Poseidon's own crystal trident."),
        .size(20),
        .in(.location("atlantisRoom"))
        // Note: VALUE 4, TVALUE 11
    )

    static let diamond = Item(
        id: "diamond",
        .name("huge diamond"),
        .synonyms("diamond", "treasure"),
        .adjectives("huge", "enormous"),
        .isTakable,
        .description("There is an enormous diamond (perfectly cut) here.")
        // Note: VALUE 10, TVALUE 10, parent location not specified in ZIL
    )

    static let jade = Item(
        id: "jade",
        .name("jade figurine"),
        .synonyms("figurine", "treasure"),
        .adjectives("exquisite", "jade"),
        .isTakable,
        .description("There is an exquisite jade figurine here."),
        .size(10),
        .in(.location("batRoom"))
        // Note: VALUE 5, TVALUE 5
    )

    static let emerald = Item(
        id: "emerald",
        .name("large emerald"),
        .synonyms("emerald", "treasure"),
        .adjectives("large"),
        .isTakable,
        .in(.item("buoy"))
        // Note: VALUE 5, TVALUE 10
    )

    static let bagOfCoins = Item(
        id: "bagOfCoins",
        .name("leather bag of coins"),
        .synonyms("bag", "coins", "treasure"),
        .adjectives("old", "leather"),
        .isTakable,
        .description("An old leather bag, bulging with coins, is here."),
        .size(15),
        .in(.location("maze5"))
        // Note: VALUE 10, TVALUE 5, has action handler BAG-OF-COINS-F
    )

    static let painting = Item(
        id: "painting",
        .name("painting"),
        .synonyms("painting", "art", "canvas", "treasure"),
        .adjectives("beautiful"),
        .isTakable,
        .isFlammable,  // BURNBIT
        .firstDescription("""
            Fortunately, there is still one chance for you to be a vandal, for on
            the far wall is a painting of unparalleled beauty.
            """),
        .description("A painting by a neglected genius is here."),
        .size(15),
        .in(.location("gallery"))
        // Note: VALUE 4, TVALUE 6, has action handler PAINTING-FCN
    )

    static let platinumBar = Item(
        id: "platinumBar",
        .name("platinum bar"),
        .synonyms("bar", "platinum", "treasure"),
        .adjectives("platinum", "large"),
        .isTakable,
        .description("On the ground is a large platinum bar."),
        .size(20),
        .in(.location("loudRoom"))
        // Note: VALUE 10, TVALUE 5, SACREDBIT
    )

    static let potOfGold = Item(
        id: "potOfGold",
        .name("pot of gold"),
        .synonyms("pot", "gold", "treasure"),
        .adjectives("gold"),
        .isTakable,
        .isInvisible,
        .firstDescription("At the end of the rainbow is a pot of gold."),
        .size(15),
        .in(.location("endOfRainbow"))
        // Note: VALUE 10, TVALUE 10
    )

    static let bracelet = Item(
        id: "bracelet",
        .name("sapphire-encrusted bracelet"),
        .synonyms("bracelet", "jewel", "sapphire", "treasure"),
        .adjectives("sapphire"),
        .isTakable,
        .size(10),
        .in(.location("gasRoom"))
        // Note: VALUE 5, TVALUE 5
    )

    static let trunk = Item(
        id: "trunk",
        .name("trunk of jewels"),
        .synonyms("trunk", "chest", "jewels", "treasure"),
        .adjectives("old"),
        .isTakable,
        .isInvisible,
        .firstDescription("Lying half buried in the mud is an old trunk, bulging with jewels."),
        .description("There is an old trunk here, bulging with assorted jewels."),
        .size(35),
        .in(.location("reservoir"))
        // Note: VALUE 15, TVALUE 5, has action handler TRUNK-F
    )

    static let torch = Item(
        id: "torch",
        .name("torch"),
        .synonyms("torch", "ivory", "treasure"),
        .adjectives("flaming", "ivory"),
        .isTakable,
        .isFlammable,  // FLAMEBIT
        .isOn,  // ONBIT
        .isLightSource,  // LIGHTBIT
        .firstDescription("Sitting on the pedestal is a flaming torch, made of ivory."),
        .size(20),
        .in(.item("pedestal"))
        // Note: VALUE 14, TVALUE 6, has action handler TORCH-OBJECT
    )

    static let egg = Item(
        id: "egg",
        .name("jewel-encrusted egg"),
        .synonyms("egg", "treasure"),
        .adjectives("birds", "encrusted", "jeweled"),
        .isTakable,
        .isContainer,
        .isSearchable,
        .capacity(6),
        .firstDescription("""
            In the bird's nest is a large egg encrusted with precious jewels,
            apparently scavenged by a childless songbird. The egg is covered with
            fine gold inlay, and ornamented in lapis lazuli and mother-of-pearl.
            Unlike most eggs, this one is hinged and closed with a delicate looking
            clasp. The egg appears extremely fragile.
            """),
        .in(.item("nest"))
        // Note: VALUE 5, TVALUE 5, has action handler EGG-OBJECT
    )

    static let brokenEgg = Item(
        id: "brokenEgg",
        .name("broken jewel-encrusted egg"),
        .synonyms("egg", "treasure"),
        .adjectives("broken", "birds", "encrusted", "jewel"),
        .isTakable,
        .isContainer,
        .isOpen,
        .capacity(6),
        .description("There is a somewhat ruined egg here.")
        // Note: TVALUE 2, parent not specified in ZIL
    )

    static let bauble = Item(
        id: "bauble",
        .name("beautiful brass bauble"),
        .synonyms("bauble", "treasure"),
        .adjectives("brass", "beautiful"),
        .isTakable
        // Note: VALUE 1, TVALUE 1, parent not specified in ZIL
    )

    static let canary = Item(
        id: "canary",
        .name("golden clockwork canary"),
        .synonyms("canary", "treasure"),
        .adjectives("clockwork", "gold", "golden"),
        .isTakable,
        .isSearchable,
        .firstDescription("""
            There is a golden clockwork canary nestled in the egg. It has ruby
            eyes and a silver beak. Through a crystal window below its left
            wing you can see intricate machinery inside. It appears to have
            wound down.
            """),
        .in(.item("egg"))
        // Note: VALUE 6, TVALUE 4, has action handler CANARY-OBJECT
    )

    static let brokenCanary = Item(
        id: "brokenCanary",
        .name("broken clockwork canary"),
        .synonyms("canary", "treasure"),
        .adjectives("broken", "clockwork", "gold", "golden"),
        .isTakable,
        .firstDescription("""
            There is a golden clockwork canary nestled in the egg. It seems to
            have recently had a bad experience. The mountings for its jewel-like
            eyes are empty, and its silver beak is crumpled. Through a cracked
            crystal window below its left wing you can see the remains of
            intricate machinery. It is not clear what result winding it would
            have, as the mainspring seems sprung.
            """),
        .in(.item("brokenEgg"))
        // Note: TVALUE 1, has action handler CANARY-OBJECT
    )

    // MARK: - Containers and Furniture

    static let loweredBasket = Item(
        id: "loweredBasket",
        .name("basket"),
        .synonyms("cage", "dumbwaiter", "basket"),
        .adjectives("lowered"),
        .requiresTryTake,
        .description("From the chain is suspended a basket."),
        .in(.location("lowerShaft"))
        // Note: Has action handler BASKET-F
    )

    static let raisedBasket = Item(
        id: "raisedBasket",
        .name("basket"),
        .synonyms("cage", "dumbwaiter", "basket"),
        .isTransparent,  // TRANSBIT
        .requiresTryTake,
        .isContainer,
        .isOpen,
        .description("At the end of the chain is a basket."),
        .capacity(50),
        .in(.location("shaftRoom"))
        // Note: Has action handler BASKET-F
    )

    static let altar = Item(
        id: "altar",
        .name("altar"),
        .synonyms("altar"),
        .suppressDescription,
        .isSurface,  // SURFACEBIT
        .isContainer,
        .isOpen,
        .capacity(50),
        .in(.location("southTemple"))
    )

    static let kitchenTable = Item(
        id: "kitchenTable",
        .name("kitchen table"),
        .synonyms("table"),
        .adjectives("kitchen"),
        .suppressDescription,
        .isContainer,
        .isOpen,
        .isSurface,
        .capacity(50),
        .in(.location("kitchen"))
    )

    static let atticTable = Item(
        id: "atticTable",
        .name("table"),
        .synonyms("table"),
        .suppressDescription,
        .isContainer,
        .isOpen,
        .isSurface,
        .capacity(40),
        .in(.location("attic"))
    )

    static let toolChest = Item(
        id: "toolChest",
        .name("group of tool chests"),
        .synonyms("chest", "chests", "group", "toolchests"),
        .adjectives("tool"),
        .isContainer,
        .isOpen,
        .requiresTryTake,
        .in(.location("maintenanceRoom"))
        // Note: SACREDBIT, has action handler TOOL-CHEST-FCN
    )

    static let trophyCase = Item(
        id: "trophyCase",
        .name("trophy case"),
        .synonyms("case"),
        .adjectives("trophy"),
        .isTransparent,  // TRANSBIT
        .isContainer,
        .suppressDescription,
        .requiresTryTake,
        .isSearchable,
        .capacity(10000),
        .in(.location("livingRoom"))
        // Note: Has action handler TROPHY-CASE-FCN
    )

    static let mailbox = Item(
        id: "mailbox",
        .name("small mailbox"),
        .synonyms("mailbox", "box"),
        .adjectives("small"),
        .isContainer,
        .requiresTryTake,
        .capacity(10),
        .in(.location("westOfHouse"))
        // Note: Has action handler MAILBOX-F
    )

    static let machine = Item(
        id: "machine",
        .name("machine"),
        .synonyms("machine", "pdp10", "dryer", "lid"),
        .isContainer,
        .suppressDescription,
        .requiresTryTake,
        .capacity(50),
        .in(.location("machineRoom"))
        // Note: Has action handler MACHINE-F
    )

    static let nest = Item(
        id: "nest",
        .name("bird's nest"),
        .synonyms("nest"),
        .adjectives("birds"),
        .isTakable,
        .isFlammable,  // BURNBIT
        .isContainer,
        .isOpen,
        .isSearchable,
        .firstDescription("Beside you on the branch is a small bird's nest."),
        .capacity(20),
        .in(.location("upATree"))
    )

    static let pedestal = Item(
        id: "pedestal",
        .name("pedestal"),
        .synonyms("pedestal"),
        .adjectives("white", "marble"),
        .suppressDescription,
        .isContainer,
        .isOpen,
        .isSurface,
        .capacity(30),
        .in(.location("torchRoom"))
        // Note: Has action handler DUMB-CONTAINER
    )

    // MARK: - Bottles and Containers

    static let bottle = Item(
        id: "bottle",
        .name("glass bottle"),
        .synonyms("bottle", "container"),
        .adjectives("clear", "glass"),
        .isTakable,
        .isTransparent,  // TRANSBIT
        .isContainer,
        .firstDescription("A bottle is sitting on the table."),
        .capacity(4),
        .in(.item("kitchenTable"))
        // Note: Has action handler BOTTLE-FUNCTION
    )

    static let sandwichBag = Item(
        id: "sandwichBag",
        .name("brown sack"),
        .synonyms("bag", "sack"),
        .adjectives("brown", "elongated", "smelly"),
        .isTakable,
        .isContainer,
        .isFlammable,  // BURNBIT
        .firstDescription("On the table is an elongated brown sack, smelling of hot peppers."),
        .capacity(9),
        .size(9),
        .in(.item("kitchenTable"))
        // Note: Has action handler SANDWICH-BAG-FCN
    )

    static let coffin = Item(
        id: "coffin",
        .name("gold coffin"),
        .synonyms("coffin", "casket", "treasure"),
        .adjectives("solid", "gold"),
        .isTakable,
        .isContainer,
        .isSearchable,
        .description("The solid-gold coffin used for the burial of Ramses II is here."),
        .capacity(35),
        .size(55),
        .in(.location("egyptRoom"))
        // Note: VALUE 10, TVALUE 15, SACREDBIT
    )

    static let buoy = Item(
        id: "buoy",
        .name("red buoy"),
        .synonyms("buoy"),
        .adjectives("red"),
        .isTakable,
        .isContainer,
        .firstDescription("There is a red buoy here (probably a warning)."),
        .capacity(20),
        .size(10),
        .in(.location("river4"))
        // Note: Has action handler TREASURE-INSIDE
    )

    static let tube = Item(
        id: "tube",
        .name("tube"),
        .synonyms("tube", "tooth", "paste"),
        .isTakable,
        .isContainer,
        .isReadable,
        .description("There is an object which looks like a tube of toothpaste here."),
        .readText("""
            ---> Frobozz Magic Gunk Company <---|
                      All-Purpose Gunk
            """),
        .capacity(7),
        .size(5),
        .in(.location("maintenanceRoom"))
        // Note: Has action handler TUBE-FUNCTION
    )

    // MARK: - Food and Consumables

    static let lunch = Item(
        id: "lunch",
        .name("lunch"),
        .synonyms("food", "sandwich", "lunch", "dinner"),
        .adjectives("hot", "pepper"),
        .isTakable,
        .isEdible,  // FOODBIT
        .description("A hot pepper sandwich is here."),
        .in(.item("sandwichBag"))
    )

    static let garlic = Item(
        id: "garlic",
        .name("clove of garlic"),
        .synonyms("garlic", "clove"),
        .isTakable,
        .isEdible,  // FOODBIT
        .size(4),
        .in(.item("sandwichBag"))
        // Note: Has action handler GARLIC-F
    )

    // MARK: - Weapons and Tools

    static let axe = Item(
        id: "axe",
        .name("bloody axe"),
        .synonyms("axe", "ax"),
        .adjectives("bloody"),
        .isWeapon,
        .requiresTryTake,
        .isTakable,
        .suppressDescription,
        .size(25),
        .in(.item("troll"))
        // Note: Has action handler AXE-F
    )

    static let knife = Item(
        id: "knife",
        .name("nasty knife"),
        .synonyms("knives", "knife", "blade"),
        .adjectives("nasty", "unrusty"),
        .isTakable,
        .isWeapon,
        .requiresTryTake,
        .firstDescription("On a table is a nasty-looking knife."),
        .in(.item("atticTable"))
        // Note: Has action handler KNIFE-F
    )

    static let rustyKnife = Item(
        id: "rustyKnife",
        .name("rusty knife"),
        .synonyms("knives", "knife"),
        .adjectives("rusty"),
        .isTakable,
        .requiresTryTake,
        .isWeapon,
        .isTool,
        .firstDescription("Beside the skeleton is a rusty knife."),
        .size(20),
        .in(.location("maze5"))
        // Note: Has action handler RUSTY-KNIFE-FCN
    )

    static let sword = Item(
        id: "sword",
        .name("sword"),
        .synonyms("sword", "orcrist", "glamdring", "blade"),
        .adjectives("elvish", "old", "antique"),
        .isTakable,
        .isWeapon,
        .requiresTryTake,
        .firstDescription("Above the trophy case hangs an elvish sword of great antiquity."),
        .size(30),
        .in(.location("livingRoom"))
        // Note: Has action handler SWORD-FCN, TVALUE 0
    )

    static let stiletto = Item(
        id: "stiletto",
        .name("stiletto"),
        .synonyms("stiletto"),
        .adjectives("vicious"),
        .isWeapon,
        .requiresTryTake,
        .isTakable,
        .suppressDescription,
        .size(10),
        .in(.item("thief"))
        // Note: Has action handler STILETTO-FUNCTION
    )

    static let pump = Item(
        id: "pump",
        .name("hand-held air pump"),
        .synonyms("pump", "air-pump", "tool", "tools"),
        .adjectives("small", "hand-held"),
        .isTakable,
        .isTool,
        .in(.location("reservoirNorth"))
    )

    static let screwdriver = Item(
        id: "screwdriver",
        .name("screwdriver"),
        .synonyms("screwdriver", "tool", "tools", "driver"),
        .adjectives("screw"),
        .isTakable,
        .isTool,
        .in(.location("maintenanceRoom"))
    )

    static let keys = Item(
        id: "keys",
        .name("skeleton key"),
        .synonyms("key"),
        .adjectives("skeleton"),
        .isTakable,
        .isTool,
        .size(10),
        .in(.location("maze5"))
    )

    static let shovel = Item(
        id: "shovel",
        .name("shovel"),
        .synonyms("shovel", "tool", "tools"),
        .isTakable,
        .isTool,
        .size(15),
        .in(.location("sandyBeach"))
    )

    static let wrench = Item(
        id: "wrench",
        .name("wrench"),
        .synonyms("wrench", "tool", "tools"),
        .isTakable,
        .isTool,
        .size(10),
        .in(.location("maintenanceRoom"))
    )

    static let putty = Item(
        id: "putty",
        .name("viscous material"),
        .synonyms("material", "gunk"),
        .adjectives("viscous"),
        .isTakable,
        .isTool,
        .size(6),
        .in(.item("tube"))
        // Note: Has action handler PUTTY-FCN
    )

    // MARK: - Lamps and Light Sources

    static let lamp = Item(
        id: "lamp",
        .name("brass lantern"),
        .synonyms("lamp", "lantern", "light"),
        .adjectives("brass"),
        .isTakable,
        .isLightSource,  // LIGHTBIT
        .firstDescription("A battery-powered brass lantern is on the trophy case."),
        .description("There is a brass lantern (battery-powered) here."),
        .size(15),
        .in(.location("livingRoom"))
        // Note: Has action handler LANTERN
    )

    static let brokenLamp = Item(
        id: "brokenLamp",
        .name("broken lantern"),
        .synonyms("lamp", "lantern"),
        .adjectives("broken"),
        .isTakable
        // Note: Parent not specified in ZIL
    )

    static let burnedOutLantern = Item(
        id: "burnedOutLantern",
        .name("burned-out lantern"),
        .synonyms("lantern", "lamp"),
        .adjectives("rusty", "burned", "dead", "useless"),
        .isTakable,
        .firstDescription("The deceased adventurer's useless lantern is here."),
        .size(20),
        .in(.location("maze5"))
    )

    static let candles = Item(
        id: "candles",
        .name("pair of candles"),
        .synonyms("candles", "pair"),
        .adjectives("burning"),
        .isTakable,
        .isFlammable,  // FLAMEBIT
        .isOn,  // ONBIT
        .isLightSource,  // LIGHTBIT
        .firstDescription("On the two ends of the altar are burning candles."),
        .size(10),
        .in(.location("southTemple"))
        // Note: Has action handler CANDLES-FCN
    )

    // MARK: - Books and Readable Items

    static let book = Item(
        id: "book",
        .name("black book"),
        .synonyms("book", "prayer", "page", "books"),
        .adjectives("large", "black"),
        .isReadable,
        .isTakable,
        .isContainer,
        .isFlammable,  // BURNBIT
        .firstDescription("On the altar is a large black book, open to page 569."),
        .readText("""
            Commandment #12592

            Oh ye who go about saying unto each:  "Hello sailor":
            Dost thou know the magnitude of thy sin before the gods?
            Yea, verily, thou shalt be ground between two stones.
            Shall the angry gods cast thy body into the whirlpool?
            Surely, thy eye shall be put out with a sharp stick!
            Even unto the ends of the earth shalt thou wander and
            Unto the land of the dead shalt thou be sent at last.
            Surely thou shalt repent of thy cunning.
            """),
        .size(10),
        .in(.item("altar"))
        // Note: Has action handler BLACK-BOOK, TURNBIT
    )

    static let advertisement = Item(
        id: "advertisement",
        .name("leaflet"),
        .synonyms("advertisement", "leaflet", "booklet", "mail"),
        .adjectives("small"),
        .isReadable,
        .isTakable,
        .isFlammable,  // BURNBIT
        .description("A small leaflet is on the ground."),
        .readText("""
            "WELCOME TO ZORK!

            ZORK is a game of adventure, danger, and low cunning. In it you
            will explore some of the most amazing territory ever seen by mortals.
            No computer should be without one!"
            """),
        .size(2),
        .in(.item("mailbox"))
    )

    static let match = Item(
        id: "match",
        .name("matchbook"),
        .synonyms("match", "matches", "matchbook"),
        .adjectives("match"),
        .isReadable,
        .isTakable,
        .description("""
            There is a matchbook whose cover says "Visit Beautiful FCD#3" here.
            """),
        .readText("""

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
            """),
        .size(2),
        .in(.location("damLobby"))
        // Note: Has action handler MATCH-FUNCTION
    )

    static let guide = Item(
        id: "guide",
        .name("tour guidebook"),
        .synonyms("guide", "book", "books", "guidebooks"),
        .adjectives("tour", "guide"),
        .isReadable,
        .isTakable,
        .isFlammable,  // BURNBIT
        .firstDescription("""
            Some guidebooks entitled "Flood Control Dam #3" are on the reception
            desk.
            """),
        .readText("""
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
            bureaucrats, 2347 secretaries (at least two of whom could type),
            12,256 paper shufflers, 52,469 rubber stampers, 245,193 red tape
            processors, and nearly one million dead trees.

            We will now point out some of the more interesting features
            of FCD#3 as we conduct you on a guided tour of the facilities:

                    1) You start your tour here in the Dam Lobby. You will notice
            on your right that....
            """),
        .in(.location("damLobby"))
    )

    static let prayer = Item(
        id: "prayer",
        .name("prayer"),
        .synonyms("prayer", "inscription"),
        .adjectives("ancient", "old"),
        .isReadable,
        .suppressDescription,
        .readText("""
            The prayer is inscribed in an ancient script, rarely used today. It seems
            to be a philippic against small insects, absent-mindedness, and the picking
            up and dropping of small objects. The final verse consigns trespassers to
            the land of the dead. All evidence indicates that the beliefs of the ancient
            Zorkers were obscure.
            """),
        .in(.location("northTemple"))
        // Note: SACREDBIT
    )

    static let engravings = Item(
        id: "engravings",
        .name("wall with engravings"),
        .synonyms("wall", "engravings", "inscription"),
        .adjectives("old", "ancient"),
        .isReadable,
        .description("There are old engravings on the walls here."),
        .readText("""
            The engravings were incised in the living rock of the cave wall by
            an unknown hand. They depict, in symbolic form, the beliefs of the
            ancient Zorkers. Skillfully interwoven with the bas reliefs are excerpts
            illustrating the major religious tenets of that time. Unfortunately, a
            later age seems to have considered them blasphemous and just as skillfully
            excised them.
            """),
        .in(.location("engravingsCave"))
        // Note: SACREDBIT
    )

    static let ownersManual = Item(
        id: "ownersManual",
        .name("ZORK owner's manual"),
        .synonyms("manual", "piece", "paper"),
        .adjectives("zork", "owners", "small"),
        .isReadable,
        .isTakable,
        .firstDescription("Loosely attached to a wall is a small piece of paper."),
        .readText("""
            Congratulations!

            You are the privileged owner of ZORK I: The Great Underground Empire,
            a self-contained and self-maintaining universe. If used and maintained
            in accordance with normal operating practices for small universes, ZORK
            will provide many months of trouble-free operation.
            """),
        .in(.location("studio"))
    )

    static let map = Item(
        id: "map",
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
        .in(.item("trophyCase"))
    )

    static let boatLabel = Item(
        id: "boatLabel",
        .name("tan label"),
        .synonyms("label", "fineprint", "print"),
        .adjectives("tan", "fine"),
        .isReadable,
        .isTakable,
        .isFlammable,  // BURNBIT
        .readText("""
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
            """),
        .size(2),
        .in(.item("inflatedBoat"))
    )

    // MARK: - Doors and Structural Elements

    static let trapDoor = Item(
        id: "trapDoor",
        .name("trap door"),
        .synonyms("door", "trapdoor", "trap-door", "cover"),
        .adjectives("trap", "dusty"),
        .isDoor,
        .suppressDescription,
        .isInvisible,
        .in(.location("livingRoom"))
        // Note: Has action handler TRAP-DOOR-FCN
    )

    static let boardedWindow = Item(
        id: "boardedWindow",
        .name("boarded window"),
        .synonyms("window"),
        .adjectives("boarded"),
        .suppressDescription
        // Note: Has action handler BOARDED-WINDOW-FCN
    )

    static let frontDoor = Item(
        id: "frontDoor",
        .name("door"),
        .synonyms("door"),
        .adjectives("front", "boarded"),
        .isDoor,
        .suppressDescription,
        .in(.location("westOfHouse"))
        // Note: Has action handler FRONT-DOOR-FCN
    )

    static let barrowDoor = Item(
        id: "barrowDoor",
        .name("stone door"),
        .synonyms("door"),
        .adjectives("huge", "stone"),
        .isDoor,
        .suppressDescription,
        .isOpen,
        .in(.location("stoneBarrow"))
        // Note: Has action handler BARROW-DOOR-FCN
    )

    static let woodenDoor = Item(
        id: "woodenDoor",
        .name("wooden door"),
        .synonyms("door", "lettering", "writing"),
        .adjectives("wooden", "gothic", "strange", "west"),
        .isReadable,
        .isDoor,
        .suppressDescription,
        .isTransparent,  // TRANSBIT
        .readText("The engravings translate to \"This space intentionally left blank.\""),
        .in(.location("livingRoom"))
        // Note: Has action handler FRONT-DOOR-FCN
    )

    static let barrow = Item(
        id: "barrow",
        .name("stone barrow"),
        .synonyms("barrow", "tomb"),
        .adjectives("massive", "stone"),
        .suppressDescription,
        .in(.location("stoneBarrow"))
        // Note: Has action handler BARROW-FCN
    )

    static let grate = Item(
        id: "grate",
        .name("grating"),
        .synonyms("grate", "grating"),
        .isDoor,
        .suppressDescription,
        .isInvisible
        // Note: Has action handler GRATE-FUNCTION
    )

    static let crack = Item(
        id: "crack",
        .name("crack"),
        .synonyms("crack"),
        .adjectives("narrow"),
        .suppressDescription
        // Note: Has action handler CRACK-FCN
    )

    // MARK: - Vehicles and Boats

    static let inflatedBoat = Item(
        id: "inflatedBoat",
        .name("magic boat"),
        .synonyms("boat", "raft"),
        .adjectives("inflat", "magic", "plastic", "seaworthy"),
        .isTakable,
        .isFlammable,  // BURNBIT
        .isVehicle,  // VEHBIT
        .isOpen,
        .isSearchable,
        .capacity(100),
        .size(20)
        // Note: Has action handler RBOAT-FUNCTION, VTYPE NONLANDBIT, parent not specified
    )

    static let puncturedBoat = Item(
        id: "puncturedBoat",
        .name("punctured boat"),
        .synonyms("boat", "pile", "plastic"),
        .adjectives("plastic", "puncture", "large"),
        .isTakable,
        .isFlammable,  // BURNBIT
        .size(20)
        // Note: Has action handler DBOAT-FUNCTION, parent not specified
    )

    static let inflatableBoat = Item(
        id: "inflatableBoat",
        .name("pile of plastic"),
        .synonyms("boat", "pile", "plastic", "valve"),
        .adjectives("plastic", "inflat"),
        .isTakable,
        .isFlammable,  // BURNBIT
        .description("""
            There is a folded pile of plastic here which has a small valve
            attached.
            """),
        .size(20),
        .in(.location("damBase"))
        // Note: Has action handler IBOAT-FUNCTION
    )

    // MARK: - Buttons and Controls

    static let yellowButton = Item(
        id: "yellowButton",
        .name("yellow button"),
        .synonyms("button", "switch"),
        .adjectives("yellow"),
        .suppressDescription,
        .in(.location("maintenanceRoom"))
        // Note: Has action handler BUTTON-F
    )

    static let brownButton = Item(
        id: "brownButton",
        .name("brown button"),
        .synonyms("button", "switch"),
        .adjectives("brown"),
        .suppressDescription,
        .in(.location("maintenanceRoom"))
        // Note: Has action handler BUTTON-F
    )

    static let redButton = Item(
        id: "redButton",
        .name("red button"),
        .synonyms("button", "switch"),
        .adjectives("red"),
        .suppressDescription,
        .in(.location("maintenanceRoom"))
        // Note: Has action handler BUTTON-F
    )

    static let blueButton = Item(
        id: "blueButton",
        .name("blue button"),
        .synonyms("button", "switch"),
        .adjectives("blue"),
        .suppressDescription,
        .in(.location("maintenanceRoom"))
        // Note: Has action handler BUTTON-F
    )

    static let machineSwitch = Item(
        id: "machineSwitch",
        .name("switch"),
        .synonyms("switch"),
        .suppressDescription,
        .in(.location("machineRoom"))
        // Note: Has action handler MSWITCH-FUNCTION, TURNBIT
    )

    static let controlPanel = Item(
        id: "controlPanel",
        .name("control panel"),
        .synonyms("panel"),
        .adjectives("control"),
        .suppressDescription,
        .in(.location("damRoom"))
    )

    // MARK: - Mirrors and Reflective Objects

    static let mirror1 = Item(
        id: "mirror1",
        .name("mirror"),
        .synonyms("reflection", "mirror", "enormous"),
        .requiresTryTake,
        .suppressDescription,
        .in(.location("mirrorRoom1"))
        // Note: Has action handler MIRROR-MIRROR
    )

    static let mirror2 = Item(
        id: "mirror2",
        .name("mirror"),
        .synonyms("reflection", "mirror", "enormous"),
        .requiresTryTake,
        .suppressDescription,
        .in(.location("mirrorRoom2"))
        // Note: Has action handler MIRROR-MIRROR
    )

    // MARK: - Bells and Sound Objects

    static let bell = Item(
        id: "bell",
        .name("brass bell"),
        .synonyms("bell"),
        .adjectives("small", "brass"),
        .isTakable,
        .in(.location("northTemple"))
        // Note: Has action handler BELL-F
    )

    static let hotBell = Item(
        id: "hotBell",
        .name("red hot brass bell"),
        .synonyms("bell"),
        .adjectives("brass", "hot", "red", "small"),
        .requiresTryTake,
        .description("On the ground is a red hot bell.")
        // Note: Has action handler HOT-BELL-F, parent not specified
    )

    // MARK: - Miscellaneous Items

    static let coal = Item(
        id: "coal",
        .name("small pile of coal"),
        .synonyms("coal", "pile", "heap"),
        .adjectives("small"),
        .isTakable,
        .isFlammable,  // BURNBIT
        .size(20),
        .in(.location("deadEnd5"))
    )

    static let timbers = Item(
        id: "timbers",
        .name("broken timber"),
        .synonyms("timbers", "pile"),
        .adjectives("wooden", "broken"),
        .isTakable,
        .size(50),
        .in(.location("timberRoom"))
    )

    static let slide = Item(
        id: "slide",
        .name("chute"),
        .synonyms("chute", "ramp", "slide"),
        .adjectives("steep", "metal", "twisting"),
        .isClimbable
        // Note: Has action handler SLIDE-FUNCTION
    )

    static let rug = Item(
        id: "rug",
        .name("carpet"),
        .synonyms("rug", "carpet"),
        .adjectives("large", "oriental"),
        .suppressDescription,
        .requiresTryTake,
        .in(.location("livingRoom"))
        // Note: Has action handler RUG-FCN
    )

    static let gunk = Item(
        id: "gunk",
        .name("small piece of vitreous slag"),
        .synonyms("gunk", "piece", "slag"),
        .adjectives("small", "vitreous"),
        .isTakable,
        .requiresTryTake,
        .size(10)
        // Note: Has action handler GUNK-FUNCTION, parent not specified
    )

    static let bodies = Item(
        id: "bodies",
        .name("pile of bodies"),
        .synonyms("bodies", "body", "remains", "pile"),
        .adjectives("mangled"),
        .suppressDescription,
        .requiresTryTake
        // Note: Has action handler BODY-FUNCTION
    )

    static let leaves = Item(
        id: "leaves",
        .name("pile of leaves"),
        .synonyms("leaves", "leaf", "pile"),
        .isTakable,
        .isFlammable,  // BURNBIT
        .requiresTryTake,
        .description("On the ground is a pile of leaves."),
        .size(25),
        .in(.location("gratingClearing"))
        // Note: Has action handler LEAF-PILE
    )

    static let rope = Item(
        id: "rope",
        .name("rope"),
        .synonyms("rope", "hemp", "coil"),
        .adjectives("large"),
        .isTakable,
        .requiresTryTake,
        .firstDescription("A large coil of rope is lying in the corner."),
        .size(10),
        .in(.location("attic"))
        // Note: Has action handler ROPE-FUNCTION, SACREDBIT
    )

    static let sand = Item(
        id: "sand",
        .name("sand"),
        .synonyms("sand"),
        .suppressDescription,
        .in(.location("sandyCave"))
        // Note: Has action handler SAND-FUNCTION
    )

    static let scarab = Item(
        id: "scarab",
        .name("beautiful jeweled scarab"),
        .synonyms("scarab", "bug", "beetle", "treasure"),
        .adjectives("beauti", "carved", "jeweled"),
        .isTakable,
        .isInvisible,
        .size(8),
        .in(.location("sandyCave"))
        // Note: VALUE 5, TVALUE 5
    )

    static let largeBag = Item(
        id: "largeBag",
        .name("large bag"),
        .synonyms("bag"),
        .adjectives("large", "thiefs"),
        .requiresTryTake,
        .suppressDescription,
        .in(.item("thief"))
        // Note: Has action handler LARGE-BAG-F
    )

    static let bones = Item(
        id: "bones",
        .name("skeleton"),
        .synonyms("bones", "skeleton", "body"),
        .requiresTryTake,
        .suppressDescription,
        .in(.location("maze5"))
        // Note: Has action handler SKELETON
    )

    static let thief = Item(
        id: "thief",
        .name("thief"),
        .synonyms("thief", "robber", "man", "person"),
        .adjectives("shady", "suspicious", "seedy"),
        .isCharacter,  // ACTORBIT
        .isInvisible,
        .isContainer,
        .isOpen,
        .requiresTryTake,
        .description("""
            There is a suspicious-looking individual, holding a large bag, leaning
            against one wall. He is armed with a deadly stiletto.
            """),
        .in(.location("roundRoom"))
        // Note: Has action handler ROBBER-FUNCTION, STRENGTH 5
    )

    // MARK: - Dam and Maintenance Items

    static let bolt = Item(
        id: "bolt",
        .name("bolt"),
        .synonyms("bolt", "nut"),
        .adjectives("metal", "large"),
        .suppressDescription,
        .requiresTryTake,
        .in(.location("damRoom"))
        // Note: Has action handler BOLT-F, TURNBIT
    )

    static let bubble = Item(
        id: "bubble",
        .name("green bubble"),
        .synonyms("bubble"),
        .adjectives("small", "green", "plastic"),
        .suppressDescription,
        .requiresTryTake,
        .in(.location("damRoom"))
        // Note: Has action handler BUBBLE-F
    )

    static let dam = Item(
        id: "dam",
        .name("dam"),
        .synonyms("dam", "gate", "gates", "fcd#3"),
        .suppressDescription,
        .requiresTryTake,
        .in(.location("damRoom"))
        // Note: Has action handler DAM-FUNCTION
    )

    static let leak = Item(
        id: "leak",
        .name("leak"),
        .synonyms("leak", "drip", "pipe"),
        .suppressDescription,
        .isInvisible,
        .in(.location("maintenanceRoom"))
        // Note: Has action handler LEAK-FUNCTION
    )

    // MARK: - Scenery and Environmental Items

    static let railing = Item(
        id: "railing",
        .name("wooden railing"),
        .synonyms("railing", "rail"),
        .adjectives("wooden"),
        .suppressDescription,
        .in(.location("domeRoom"))
    )

    static let rainbow = Item(
        id: "rainbow",
        .name("rainbow"),
        .synonyms("rainbow"),
        .suppressDescription,
        .isClimbable
        // Note: Has action handler RAINBOW-FCN
    )

    static let river = Item(
        id: "river",
        .name("river"),
        .synonyms("river"),
        .adjectives("frigid"),
        .suppressDescription
        // Note: Has action handler RIVER-FUNCTION
    )

    static let climbableCliff = Item(
        id: "climbableCliff",
        .name("cliff"),
        .synonyms("wall", "cliff", "walls", "ledge"),
        .adjectives("rocky", "sheer"),
        .suppressDescription,
        .isClimbable
        // Note: Has action handler CLIFF-OBJECT
    )

    static let whiteCliff = Item(
        id: "whiteCliff",
        .name("white cliffs"),
        .synonyms("cliff", "cliffs"),
        .adjectives("white"),
        .suppressDescription,
        .isClimbable
        // Note: Has action handler WCLIF-OBJECT
    )

    static let ladder = Item(
        id: "ladder",
        .name("wooden ladder"),
        .synonyms("ladder"),
        .adjectives("wooden", "rickety", "narrow"),
        .suppressDescription,
        .isClimbable
    )
}
