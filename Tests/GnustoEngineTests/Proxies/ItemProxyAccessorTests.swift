import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ItemProxy Accessor Tests")
struct ItemProxyAccessorTests {
    @Test("ItemProxy name and description accessors")
    func testNameAndDescriptionAccessors() async throws {
        // Given
        let itemWithDescription = Item(
            id: "book",
            .name("leather book"),
            .description("A worn leather-bound tome."),
            .in(.startRoom)
        )

        let itemWithoutDescription = Item(
            id: "coin",
            .name("gold coin"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: itemWithDescription, itemWithoutDescription
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let bookProxy = try await engine.item("book")
        let name = await bookProxy.name
        #expect(name == "leather book")

        let description = await bookProxy.description
        #expect(description == "A worn leather-bound tome.")

        let coinProxy = try await engine.item("coin")
        let coinDescription = await coinProxy.description
        #expect(coinDescription == "The gold coin reveals itself to be exactly what it appears--nothing more, nothing less.")
    }

    @Test("ItemProxy flag checking methods")
    func testFlagCheckingMethods() async throws {
        // Given
        let container = Item(
            id: "container",
            .name("wooden box"),
            .isContainer,
            .isOpenable,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: container
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = try await engine.item("container")

        // When/Then - Test single flag checking
        #expect(await proxy.hasFlag(.isContainer) == true)
        #expect(await proxy.hasFlag(.isOpenable) == true)
        #expect(await proxy.hasFlag(.isOpen) == true)
        #expect(await proxy.hasFlag(.isTakable) == true)
        #expect(await proxy.hasFlag(.isWeapon) == false)

        // Test multiple flag checking
        #expect(await proxy.hasFlags(all: .isContainer, .isOpenable) == true)
        #expect(await proxy.hasFlags(all: .isContainer, .isWeapon) == false)
        #expect(await proxy.hasFlags(none: .isWeapon, .isLocked) == true)
        #expect(await proxy.hasFlags(none: .isContainer) == false)
        #expect(await proxy.hasFlags(any: .isContainer, .isWeapon) == true)
        #expect(await proxy.hasFlags(any: .isWeapon, .isLocked) == false)
    }

    @Test("ItemProxy boolea property accessors")
    func testBooleanPropertyAccessors() async throws {
        // Given
        let container = Item(
            id: "container",
            .name("wooden box"),
            .isContainer,
            .isOpenable,
            .isOpen,
            .isTakable,
            .capacity(10),
            .in(.startRoom)
        )

        let weapon = Item(
            id: "sword",
            .name("sharp sword"),
            .isWeapon,
            .isTakable,
            .in(.startRoom)
        )

        let character = Item(
            id: "guard",
            .name("town guard"),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let fightingCharacter = Item(
            id: "monster",
            .name("angry monster"),
            .characterSheet(
                .init(isFighting: true)
            ),
            .in(.startRoom)
        )

        let surface = Item(
            id: "table",
            .name("wooden table"),
            .isSurface,
            .in(.startRoom)
        )

        let lightSource = Item(
            id: "lamp",
            .name("brass lamp"),
            .isLightSource,
            .isDevice,
            .isOn,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: container, weapon, character, fightingCharacter, surface, lightSource
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let containerProxy = try await engine.item("container")
        #expect(await containerProxy.isContainer == true)
        #expect(await containerProxy.isOpenable == true)
        #expect(await containerProxy.isOpen == true)
        #expect(await containerProxy.isTakable == true)
        #expect(await containerProxy.isEmpty == true)
        #expect(await containerProxy.isNotEmpty == false)
        #expect(await containerProxy.isVisible == true)

        let weaponProxy = try await engine.item("sword")
        #expect(await weaponProxy.isWeapon == true)
        #expect(await weaponProxy.isContainer == false)

        let characterProxy = try await engine.item("guard")
        #expect(try await characterProxy.isCharacter == true)
        #expect((try? await characterProxy.isFighting) == false)

        let fightingProxy = try await engine.item("monster")
        #expect(try await fightingProxy.isCharacter == true)
        #expect((try? await fightingProxy.isFighting) == true)

        let surfaceProxy = try await engine.item("table")
        #expect(await surfaceProxy.isSurface == true)

        let lampProxy = try await engine.item("lamp")
        #expect(await lampProxy.isProvidingLight == true)
    }

    @Test("ItemProxy container and capacity methods")
    func testContainerAndCapacityMethods() async throws {
        // Given
        let container = Item(
            id: "container",
            .name("small box"),
            .isContainer,
            .isOpen,
            .capacity(5),
            .in(.startRoom)
        )

        let smallItem = Item(
            id: "coin",
            .name("gold coin"),
            .size(1),
            .isTakable,
            .in(.item("container"))
        )

        let largeItem = Item(
            id: "boulder",
            .name("heavy boulder"),
            .size(10),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: container, smallItem, largeItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let containerProxy = try await engine.item("container")
        #expect(await containerProxy.capacity == 5)
        #expect(await containerProxy.currentLoad == 1)  // coin has size 1
        #expect(await containerProxy.canHold("coin") == true)  // can hold another coin
        #expect(await containerProxy.canHold("boulder") == false)  // boulder is size 10

        let contents = try await containerProxy.contents
        #expect(contents.count == 1)
        #expect(contents[0].id == "coin")

        #expect(await containerProxy.isEmpty == false)
        #expect(await containerProxy.isNotEmpty == true)
    }

    @Test("ItemProxy parent and location methods")
    func testParentAndLocationMethods() async throws {
        // Given
        let container = Item(
            id: "container",
            .name("wooden box"),
            .isContainer,
            .isOpen,
            .in(.startRoom)
        )

        let itemInRoom = Item(
            id: "roomItem",
            .name("room item"),
            .isTakable,
            .in(.startRoom)
        )

        let itemInContainer = Item(
            id: "containerItem",
            .name("container item"),
            .isTakable,
            .in(.item("container"))
        )

        let itemWithPlayer = Item(
            id: "playerItem",
            .name("player item"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: container, itemInRoom, itemInContainer, itemWithPlayer
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let roomItemProxy = try await engine.item("roomItem")
        let roomItemParent = try await roomItemProxy.parent
        if case .location(let locationProxy) = roomItemParent {
            #expect(locationProxy.id == .startRoom)
        } else {
            #expect(Bool(false), "Expected location parent")
        }
        #expect(try await roomItemProxy.playerIsHolding == false)
        #expect(try await roomItemProxy.playerCanCarry == true)

        let containerItemProxy = try await engine.item("containerItem")
        let containerItemParent = try await containerItemProxy.parent
        if case .item(let itemProxy) = containerItemParent {
            #expect(itemProxy.id == "container")
        } else {
            #expect(Bool(false), "Expected item parent")
        }

        let playerItemProxy = try await engine.item("playerItem")
        let playerItemParent = try await playerItemProxy.parent
        #expect(playerItemParent == .player)
        #expect(try await playerItemProxy.playerIsHolding == true)
    }

    @Test("ItemProxy article methods")
    func testArticleMethods() async throws {
        // Given
        let regularItem = Item(
            id: "book",
            .name("leather book"),
            .in(.startRoom)
        )

        let pluralItem = Item(
            id: "coins",
            .name("gold coins"),
            .isPlural,
            .in(.startRoom)
        )

        let noArticleItem = Item(
            id: "water",
            .name("water"),
            .omitArticle,
            .in(.startRoom)
        )

        let vowelItem = Item(
            id: "apple",
            .name("apple"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: regularItem, pluralItem, noArticleItem, vowelItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let bookProxy = try await engine.item("book")
        #expect(await bookProxy.withDefiniteArticle == "the leather book")
        #expect(await bookProxy.withIndefiniteArticle == "a leather book")

        let coinsProxy = try await engine.item("coins")
        #expect(await coinsProxy.withDefiniteArticle == "the gold coins")
        #expect(await coinsProxy.withIndefiniteArticle == "some gold coins")

        let waterProxy = try await engine.item("water")
        #expect(await waterProxy.withDefiniteArticle == "water")
        #expect(await waterProxy.withIndefiniteArticle == "water")

        let appleProxy = try await engine.item("apple")
        #expect(await appleProxy.withDefiniteArticle == "the apple")
        #expect(await appleProxy.withIndefiniteArticle == "an apple")
    }

    @Test("ItemProxy response method")
    func testResponseMethod() async throws {
        // Given
        let object = Item(
            id: "book",
            .name("leather book"),
            .in(.startRoom)
        )

        let character = Item(
            id: "guard",
            .name("town guard"),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let enemy = Item(
            id: "monster",
            .name("angry monster"),
            .characterSheet(
                .init(isFighting: true)
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: object, character, enemy
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let objectProxy = try await engine.item("book")
        let objectResponse = try await objectProxy.response(
            object: { "object: \($0)" },
            character: { "character: \($0)" },
            enemy: { "enemy: \($0)" }
        )
        #expect(objectResponse == "object: the leather book")

        let characterProxy = try await engine.item("guard")
        let characterResponse = try await characterProxy.response(
            object: { "object: \($0)" },
            character: { "character: \($0)" },
            enemy: { "enemy: \($0)" }
        )
        #expect(characterResponse == "character: the town guard")

        let enemyProxy = try await engine.item("monster")
        let enemyResponse = try await enemyProxy.response(
            object: { "object: \($0)" },
            character: { "character: \($0)" },
            enemy: { "enemy: \($0)" }
        )
        #expect(enemyResponse == "enemy: the angry monster")
    }

    @Test("ItemProxy alias")
    func testItemProxyAlias() async throws {
        // Given
        let item = Item(
            id: "sword",
            .name("sharp sword"),
            .adjectives("sharp", "gleaming", "shining", "steel"),
            .synonyms("blade", "weapon", "sabre"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: item
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let sword = try await engine.item("sword")

        let adjectives = await sword.adjectives
        expectNoDifference(adjectives, ["gleaming", "sharp", "shining", "steel"])

        let synonyms = await sword.synonyms
        expectNoDifference(synonyms, ["blade", "sabre", "weapon"])

        // Test alias generation (should combine adjective + synonym)
        let alias1 = try await sword.alias()
        expectNoDifference(alias1, "sabre")

        let alias2 = try await sword.alias(.withDefiniteArticle)
        expectNoDifference(alias2, "the steel sabre")

        let alias3 = try await sword.alias(.withIndefiniteArticle)
        expectNoDifference(alias3, "a sabre")

        let alias4 = try await sword.alias(.withPossessiveAdjective)
        expectNoDifference(alias4, "your weapon")
    }

    @Test("ItemProxy alias without adjectives")
    func testItemProxyAliasWithoutAdjectives() async throws {
        // Given
        let item = Item(
            id: "sword",
            .name("sharp sword"),
            .synonyms("blade", "weapon", "sabre"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: item
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let sword = try await engine.item("sword")

        let adjectives = await sword.adjectives
        expectNoDifference(adjectives, ["sharp"])

        let synonyms = await sword.synonyms
        expectNoDifference(synonyms, ["blade", "sabre", "weapon"])

        // Test alias generation (should combine adjective + synonym)
        let alias1 = try await sword.alias()
        expectNoDifference(alias1, "sabre")

        let alias2 = try await sword.alias(.withDefiniteArticle)
        expectNoDifference(alias2, "the sharp sabre")

        let alias3 = try await sword.alias(.withIndefiniteArticle)
        expectNoDifference(alias3, "a sabre")

        let alias4 = try await sword.alias(.withPossessiveAdjective)
        expectNoDifference(alias4, "your weapon")
    }

    @Test("ItemProxy alias without synonyms")
    func testItemProxyAliasWithoutSynonyms() async throws {
        // Given
        let item = Item(
            id: "sword",
            .name("sharp sword"),
            .adjectives("sharp", "gleaming", "shining", "steel"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: item
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let sword = try await engine.item("sword")

        let adjectives = await sword.adjectives
        expectNoDifference(adjectives, ["gleaming", "sharp", "shining", "steel"])

        let synonyms = await sword.synonyms
        #expect(synonyms.isEmpty)

        // Test alias generation (should combine adjective + synonym)
        let alias1 = try await sword.alias()
        expectNoDifference(alias1, "sharp sword")

        let alias2 = try await sword.alias(.withDefiniteArticle)
        expectNoDifference(alias2, "the sharp sword")

        let alias3 = try await sword.alias(.withIndefiniteArticle)
        expectNoDifference(alias3, "a sharp sword")

        let alias4 = try await sword.alias(.withPossessiveAdjective)
        expectNoDifference(alias4, "your sharp sword")
    }

    @Test("ItemProxy size, health, strength, and value properties")
    func testNumericProperties() async throws {
        // Given
        let item = Item(
            id: "artifact",
            .name("magic artifact"),
            .size(5),
            .characterSheet(
                .init(strength: 15, health: 75)
            ),
            .value(100),
            .in(.startRoom)
        )

        let defaultItem = Item(
            id: "basic",
            .name("basic item"),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: item, defaultItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then - Test explicit values
        let artifactProxy = try await engine.item("artifact")
        #expect(await artifactProxy.size == 5)
        #expect(try await artifactProxy.health == 75)
        #expect(try await artifactProxy.strength == 15)
        #expect(await artifactProxy.value == 100)

        // Test default values
        let basicProxy = try await engine.item("basic")
        #expect(await basicProxy.size == 1)  // Default size
        #expect(try await basicProxy.health == 50)  // Default health
        #expect(try await basicProxy.strength == 10)  // Default strength
        #expect(await basicProxy.value == 0)  // Default value
    }

    @Test("ItemProxy visibility and description flags")
    func testVisibilityAndDescriptionFlags() async throws {
        // Given
        let visibleItem = Item(
            id: "visible",
            .name("visible item"),
            .in(.startRoom)
        )

        let invisibleItem = Item(
            id: "invisible",
            .name("invisible item"),
            .isInvisible,
            .in(.startRoom)
        )

        let omitDescriptionItem = Item(
            id: "omit",
            .name("omit item"),
            .omitDescription,
            .isTakable,
            .in(.startRoom)
        )

        let touchedItem = Item(
            id: "touched",
            .name("touched item"),
            .isTouched,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: visibleItem, invisibleItem, omitDescriptionItem, touchedItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let visibleProxy = try await engine.item("visible")
        #expect(await visibleProxy.isVisible == true)
        #expect(await visibleProxy.shouldDescribe == true)
        #expect(await visibleProxy.isTouched == false)

        let invisibleProxy = try await engine.item("invisible")
        #expect(await invisibleProxy.isVisible == false)
        #expect(await invisibleProxy.shouldDescribe == false)

        let omitProxy = try await engine.item("omit")
        #expect(await omitProxy.shouldDescribe == false)
        #expect(await omitProxy.isIncludableInAllCommands == false)  // Not includable due to omitDescription

        let touchedProxy = try await engine.item("touched")
        #expect(await touchedProxy.isTouched == true)
    }

    @Test("ItemProxy door properties")
    func testDoorProperties() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("wooden door"),
            .isOpenable,
            .isLockable,
            .in(.startRoom)
        )

        let regularItem = Item(
            id: "book",
            .name("book"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: door, regularItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let doorProxy = try await engine.item("door")
        #expect(await doorProxy.isDoor == true)

        let bookProxy = try await engine.item("book")
        #expect(await bookProxy.isDoor == false)
    }

    @Test("ItemProxy character life and death")
    func testCharacterLifeAndDeath() async throws {
        // Given
        let aliveCharacter = Item(
            id: "guard",
            .name("town guard"),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let deadCharacter = Item(
            id: "skeleton",
            .name("ancient skeleton"),
            .characterSheet(
                .init(consciousness: .dead)
            ),
            .in(.startRoom)
        )

        let hostileEnemy = Item(
            id: "orc",
            .name("fierce orc"),
            .characterSheet(
                .init(isFighting: true)
            ),
            .in(.startRoom)
        )

        let regularItem = Item(
            id: "rock",
            .name("rock"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: aliveCharacter, deadCharacter, hostileEnemy, regularItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let guardProxy = try await engine.item("guard")
        #expect(try await guardProxy.isAlive == true)
        #expect(try await guardProxy.isDead == false)
        #expect(try await guardProxy.isHostileEnemy == false)

        let skeletonProxy = try await engine.item("skeleton")
        #expect(try await skeletonProxy.isAlive == false)
        #expect(try await skeletonProxy.isDead == true)

        let orcProxy = try await engine.item("orc")
        #expect(try await orcProxy.isHostileEnemy == true)

        let rockProxy = try await engine.item("rock")
        await #expect(throws: ItemError.self) {
            _ = try await rockProxy.isAlive
        }
    }

    @Test("ItemProxy text content properties")
    func testTextContentProperties() async throws {
        // Given
        let readableItem = Item(
            id: "book",
            .name("magic book"),
            .description("A leather-bound tome."),
            .readText("Ancient secrets are revealed within."),
            .readWhileHeldText("The text glows when held closely."),
            .shortDescription("A tome"),
            .firstDescription("You notice an untouched book."),
            .in(.startRoom)
        )

        let unreadableItem = Item(
            id: "rock",
            .name("smooth rock"),
            .in(.startRoom)
        )

        let touchedItem = Item(
            id: "scroll",
            .name("old scroll"),
            .firstDescription("An ancient scroll lies here."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: readableItem, unreadableItem, touchedItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let bookProxy = try await engine.item("book")
        #expect(await bookProxy.readText == "Ancient secrets are revealed within.")
        #expect(await bookProxy.readWhileHeldText == "The text glows when held closely.")
        #expect(await bookProxy.shortDescription == "A tome")
        #expect(await bookProxy.firstDescription == "You notice an untouched book.")

        let rockProxy = try await engine.item("rock")
        let readText = await rockProxy.readText
        let readWhileHeldText = await rockProxy.readWhileHeldText
        expectNoDifference(
            readText,
            "The smooth rock bears no inscription, message, or literary content whatsoever."
        )
        expectNoDifference(
            readWhileHeldText,
            "The smooth rock keeps its mysteries, if any, well hidden from your grasp."
        )

        let scrollProxy = try await engine.item("scroll")
        #expect(await scrollProxy.firstDescription == "An ancient scroll lies here.")
        try await engine.apply(
            scrollProxy.setFlag(.isTouched)
        )
        #expect(await scrollProxy.firstDescription == nil)  // nil because item is touched
    }

    @Test("ItemProxy container visibility and contents")
    func testContainerVisibilityAndContents() async throws {
        // Given
        let openContainer = Item(
            id: "chest",
            .name("wooden chest"),
            .isContainer,
            .isOpen,
            .in(.startRoom)
        )

        let closedContainer = Item(
            id: "box",
            .name("metal box"),
            .isContainer,
            .in(.startRoom)
        )

        let transparentContainer = Item(
            id: "jar",
            .name("glass jar"),
            .isContainer,
            .isTransparent,
            .in(.startRoom)
        )

        let surface = Item(
            id: "table",
            .name("wooden table"),
            .isSurface,
            .in(.startRoom)
        )

        let itemInChest = Item(
            id: "gem",
            .name("ruby gem"),
            .in(.item("chest"))
        )

        let itemInBox = Item(
            id: "coin",
            .name("gold coin"),
            .in(.item("box"))
        )

        let itemInJar = Item(
            id: "beetle",
            .name("small beetle"),
            .in(.item("jar"))
        )

        let itemOnTable = Item(
            id: "book",
            .name("old book"),
            .in(.item("table"))
        )

        let hiddenItem = Item(
            id: "secret",
            .name("secret item"),
            .isInvisible,
            .in(.item("chest"))
        )

        let game = MinimalGame(
            items: openContainer, closedContainer, transparentContainer, surface,
            itemInChest, itemInBox, itemInJar, itemOnTable, hiddenItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let chestProxy = try await engine.item("chest")
        #expect(await chestProxy.contentsAreVisible == true)  // Open container
        let chestVisibleItems = try await chestProxy.visibleItems
        #expect(chestVisibleItems.count == 1)  // Only gem, not hidden item
        #expect(chestVisibleItems[0].id == "gem")

        let boxProxy = try await engine.item("box")
        #expect(await boxProxy.contentsAreVisible == false)  // Closed container

        let jarProxy = try await engine.item("jar")
        #expect(await jarProxy.contentsAreVisible == true)  // Transparent container

        let tableProxy = try await engine.item("table")
        #expect(await tableProxy.contentsAreVisible == true)  // Surface

        // Test allContents method
        let chestAllContents = try await chestProxy.allContents
        #expect(chestAllContents.count == 2)  // Both gem and hidden item
    }

    @Test("ItemProxy holding and reachability")
    func testHoldingAndReachability() async throws {
        // Given
        let container = Item(
            id: "bag",
            .name("leather bag"),
            .isContainer,
            .isOpen,
            .in(.player)
        )

        let itemInBag = Item(
            id: "coin",
            .name("gold coin"),
            .in(.item("bag"))
        )

        let roomItem = Item(
            id: "key",
            .name("brass key"),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: container, itemInBag, roomItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let bagProxy = try await engine.item("bag")
        let coinProxy = try await engine.item("coin")
        let keyProxy = try await engine.item("key")

        #expect(try await bagProxy.isHolding(coinProxy.id) == true)
        #expect(try await bagProxy.isHolding(keyProxy.id) == false)

        #expect(await coinProxy.playerCanReach == true)  // In bag held by player
        #expect(await keyProxy.playerCanReach == true)  // In same room
        #expect(try await keyProxy.shouldTakeFirst == true)  // Takable but not held
        #expect(try await bagProxy.shouldTakeFirst == false)  // Already held
    }

    @Test("ItemProxy possessive and article methods")
    func testPossessiveAndArticleMethods() async throws {
        // Given
        let item = Item(
            id: "sword",
            .name("steel sword"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: item
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = try await engine.item("sword")

        // When/Then
        let possessive = await proxy.withPossessiveAdjective
        #expect(possessive == "your steel sword")
    }

    @Test("ItemProxy array convenience methods")
    func testArrayConvenienceMethods() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("leather book"),
            .in(.startRoom)
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.startRoom)
        )

        let gem = Item(
            id: "gem",
            .name("sparkling gem"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: book, coin, gem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let bookProxy = try await engine.item("book")
        let coinProxy = try await engine.item("coin")
        let gemProxy = try await engine.item("gem")
        let itemArray = [bookProxy, coinProxy, gemProxy]

        // Then
        let definiteList = await itemArray.listWithDefiniteArticles()
        #expect(definiteList == "the leather book, the gold coin, and the sparkling gem")

        let indefiniteList = await itemArray.listWithIndefiniteArticles()
        #expect(indefiniteList == "a leather book, a gold coin, and a sparkling gem")

        let singleItem = [bookProxy]
        let singleDefinite = await singleItem.listWithDefiniteArticles()
        #expect(singleDefinite == "the leather book")

        let twoItems = [bookProxy, coinProxy]
        let twoDefinite = await twoItems.listWithDefiniteArticles()
        #expect(twoDefinite == "the leather book and the gold coin")

        let emptyArray: [ItemProxy] = []
        let emptyList = await emptyArray.listWithDefiniteArticles()
        #expect(emptyList == nil)
    }

    @Test("ItemProxy array allContents and visibleContents")
    func testArrayContentsAccessors() async throws {
        // Given
        let openChest = Item(
            id: "chest",
            .name("wooden chest"),
            .isContainer,
            .isOpen,
            .in(.startRoom)
        )

        let closedBox = Item(
            id: "box",
            .name("metal box"),
            .isContainer,
            .in(.startRoom)
        )

        let transparentJar = Item(
            id: "jar",
            .name("glass jar"),
            .isContainer,
            .isTransparent,
            .in(.startRoom)
        )

        let gemInChest = Item(
            id: "gem",
            .name("ruby gem"),
            .in(.item("chest"))
        )

        let coinInBox = Item(
            id: "coin",
            .name("gold coin"),
            .in(.item("box"))
        )

        let beetleInJar = Item(
            id: "beetle",
            .name("small beetle"),
            .in(.item("jar"))
        )

        let nestedContainer = Item(
            id: "pouch",
            .name("small pouch"),
            .isContainer,
            .isOpen,
            .in(.item("chest"))
        )

        let ringInPouch = Item(
            id: "ring",
            .name("gold ring"),
            .in(.item("pouch"))
        )

        let hiddenItem = Item(
            id: "secret",
            .name("secret item"),
            .isInvisible,
            .in(.item("chest"))
        )

        let game = MinimalGame(
            items: openChest, closedBox, transparentJar, gemInChest, coinInBox,
            beetleInJar, nestedContainer, ringInPouch, hiddenItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let chestProxy = try await engine.item("chest")
        let boxProxy = try await engine.item("box")
        let jarProxy = try await engine.item("jar")
        let containerArray = [chestProxy, boxProxy, jarProxy]

        // Then - Test allContents (includes everything recursively)
        let allContents = try await containerArray.allContents
        #expect(allContents.count == 6)  // gem, coin, beetle, pouch, ring, secret
        let allContentIDs = allContents.map(\.id).sorted()
        #expect(allContentIDs == ["beetle", "coin", "gem", "pouch", "ring", "secret"])

        // Test visibleContents (only visible items in open/transparent containers)
        let visibleContents = await containerArray.visibleContents
        let visibleContentIDs = visibleContents.map(\.id).sorted()
        // Should include: gem (chest is open), beetle (jar is transparent), pouch (chest is open), ring (pouch is open)
        // Should NOT include: coin (box is closed), secret (invisible)
        #expect(visibleContentIDs == ["beetle", "gem", "pouch", "ring"])
    }

    @Test("ItemProxy array sortedByValue")
    func testArraySortedByValue() async throws {
        // Given
        let cheapItem = Item(
            id: "copper",
            .name("copper coin"),
            .value(1),
            .in(.startRoom)
        )

        let expensiveItem = Item(
            id: "diamond",
            .name("precious diamond"),
            .value(100),
            .in(.startRoom)
        )

        let mediumItem = Item(
            id: "silver",
            .name("silver coin"),
            .value(10),
            .in(.startRoom)
        )

        let noValueItem = Item(
            id: "rock",
            .name("worthless rock"),
            .in(.startRoom)
        )

        let tempValueItem = Item(
            id: "special",
            .name("special item"),
            .value(50),
            .tmpValue(5),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: cheapItem, expensiveItem, mediumItem, noValueItem, tempValueItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let copperProxy = try await engine.item("copper")
        let diamondProxy = try await engine.item("diamond")
        let silverProxy = try await engine.item("silver")
        let rockProxy = try await engine.item("rock")
        let specialProxy = try await engine.item("special")

        let itemArray = [diamondProxy, copperProxy, silverProxy, rockProxy, specialProxy]

        // Then - Sort by regular value (highest to lowest)
        let sortedByValue = await itemArray.sortedByValue
        let sortedValueIds = sortedByValue.map(\.id)
        #expect(sortedValueIds == ["diamond", "special", "silver", "copper", "rock"])

        // Sort by temporary value (highest to lowest)
        let sortedByTempValue = await itemArray.sortedByTempValue
        let sortedTempValueIds = sortedByTempValue.map(\.id)
        // Items without tmpValue should use regular value: rock=0, copper=1, silver=10, diamond=100, special=5
        #expect(sortedTempValueIds == ["special", "diamond", "copper", "silver", "rock"])
    }
}
