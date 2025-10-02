import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ItemProxy Accessor Tests")
struct ItemProxyAccessorTests {
    @Test("ItemProxy name and description accessors")
    func testNameAndDescriptionAccessors() async throws {
        // Given
        let itemWithDescription = Item("book")
            .name("leather book")
            .description("A worn leather-bound tome.")
            .in(.startRoom)

        let itemWithoutDescription = Item("coin")
            .name("gold coin")
            .in(.startRoom)

        let game = MinimalGame(
            items: itemWithDescription, itemWithoutDescription
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let bookProxy = await engine.item("book")
        let name = await bookProxy.name
        #expect(name == "leather book")

        let description = await bookProxy.description
        #expect(description == "A worn leather-bound tome.")

        let coinProxy = await engine.item("coin")
        let coinDescription = await coinProxy.description
        #expect(
            coinDescription
                == "The gold coin reveals itself to be exactly what it appears--nothing more, nothing less."
        )
    }

    @Test("ItemProxy flag checking methods")
    func testFlagCheckingMethods() async throws {
        // Given
        let container = Item("container")
            .name("wooden box")
            .isContainer
            .isOpenable
            .isOpen
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: container
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("container")

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
        let container = Item("container")
            .name("wooden box")
            .isContainer
            .isOpenable
            .isOpen
            .isTakable
            .capacity(10)
            .in(.startRoom)

        let weapon = Item("sword")
            .name("sharp sword")
            .isWeapon
            .isTakable
            .in(.startRoom)

        let character = Item("guard")
            .name("town guard")
            .characterSheet(.default)
            .in(.startRoom)

        let fightingCharacter = Item("monster")
            .name("angry monster")
            .characterSheet(
                .init(isFighting: true)
            )
            .in(.startRoom)

        let surface = Item("table")
            .name("wooden table")
            .isSurface
            .in(.startRoom)

        let lightSource = Item("lamp")
            .name("brass lamp")
            .isLightSource
            .isDevice
            .isOn
            .in(.startRoom)

        let game = MinimalGame(
            items: container, weapon, character, fightingCharacter, surface, lightSource
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let containerProxy = await engine.item("container")
        #expect(await containerProxy.isContainer == true)
        #expect(await containerProxy.isOpenable == true)
        #expect(await containerProxy.isOpen == true)
        #expect(await containerProxy.isTakable == true)
        #expect(await containerProxy.isEmpty == true)
        #expect(await containerProxy.isNotEmpty == false)
        #expect(await containerProxy.isVisible == true)

        let weaponProxy = await engine.item("sword")
        #expect(await weaponProxy.isWeapon == true)
        #expect(await weaponProxy.isContainer == false)

        let characterProxy = await engine.item("guard")
        #expect(await characterProxy.isCharacter == true)
        #expect(await characterProxy.isFighting == false)

        let fightingProxy = await engine.item("monster")
        #expect(await fightingProxy.isCharacter == true)
        #expect(await fightingProxy.isFighting == true)

        let surfaceProxy = await engine.item("table")
        #expect(await surfaceProxy.isSurface == true)

        let lampProxy = await engine.item("lamp")
        #expect(await lampProxy.isProvidingLight == true)
    }

    @Test("ItemProxy container and capacity methods")
    func testContainerAndCapacityMethods() async throws {
        // Given
        let container = Item("container")
            .name("small box")
            .isContainer
            .isOpen
            .capacity(5)
            .in(.startRoom)

        let smallItem = Item("coin")
            .name("gold coin")
            .size(1)
            .isTakable
            .in(.item("container"))

        let largeItem = Item("boulder")
            .name("heavy boulder")
            .size(10)
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: container, smallItem, largeItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let containerProxy = await engine.item("container")
        #expect(await containerProxy.capacity == 5)
        #expect(await containerProxy.currentLoad == 1)  // coin has size 1
        #expect(await containerProxy.canHold("coin") == true)  // can hold another coin
        #expect(await containerProxy.canHold("boulder") == false)  // boulder is size 10

        let contents = await containerProxy.contents
        #expect(contents.count == 1)
        #expect(contents[0].id == "coin")

        #expect(await containerProxy.isEmpty == false)
        #expect(await containerProxy.isNotEmpty == true)
    }

    @Test("ItemProxy parent and location methods")
    func testParentAndLocationMethods() async throws {
        // Given
        let container = Item("container")
            .name("wooden box")
            .isContainer
            .isOpen
            .in(.startRoom)

        let itemInRoom = Item("roomItem")
            .name("room item")
            .isTakable
            .in(.startRoom)

        let itemInContainer = Item("containerItem")
            .name("container item")
            .isTakable
            .in(.item("container"))

        let itemWithPlayer = Item("playerItem")
            .name("player item")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: container, itemInRoom, itemInContainer, itemWithPlayer
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let roomItemProxy = await engine.item("roomItem")
        let roomItemParent = await roomItemProxy.parent
        if case .location(let locationProxy) = roomItemParent {
            #expect(locationProxy.id == .startRoom)
        } else {
            #expect(Bool(false), "Expected location parent")
        }
        #expect(await roomItemProxy.playerIsHolding == false)
        #expect(await roomItemProxy.playerCanCarry == true)

        let containerItemProxy = await engine.item("containerItem")
        let containerItemParent = await containerItemProxy.parent
        if case .item(let itemProxy) = containerItemParent {
            #expect(itemProxy.id == "container")
        } else {
            #expect(Bool(false), "Expected item parent")
        }

        let playerItemProxy = await engine.item("playerItem")
        let playerItemParent = await playerItemProxy.parent
        #expect(playerItemParent == .player)
        #expect(await playerItemProxy.playerIsHolding == true)
    }

    @Test("ItemProxy article methods")
    func testArticleMethods() async throws {
        // Given
        let regularItem = Item("book")
            .name("leather book")
            .in(.startRoom)

        let pluralItem = Item("coins")
            .name("gold coins")
            .isPlural
            .in(.startRoom)

        let noArticleItem = Item("water")
            .name("water")
            .omitArticle
            .in(.startRoom)

        let vowelItem = Item("apple")
            .name("apple")
            .in(.startRoom)

        let game = MinimalGame(
            items: regularItem, pluralItem, noArticleItem, vowelItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let bookProxy = await engine.item("book")
        #expect(await bookProxy.withDefiniteArticle == "the leather book")
        #expect(await bookProxy.withIndefiniteArticle == "a leather book")

        let coinsProxy = await engine.item("coins")
        #expect(await coinsProxy.withDefiniteArticle == "the gold coins")
        #expect(await coinsProxy.withIndefiniteArticle == "some gold coins")

        let waterProxy = await engine.item("water")
        #expect(await waterProxy.withDefiniteArticle == "water")
        #expect(await waterProxy.withIndefiniteArticle == "water")

        let appleProxy = await engine.item("apple")
        #expect(await appleProxy.withDefiniteArticle == "the apple")
        #expect(await appleProxy.withIndefiniteArticle == "an apple")
    }

    @Test("ItemProxy response method")
    func testResponseMethod() async throws {
        // Given
        let object = Item("book")
            .name("leather book")
            .in(.startRoom)

        let character = Item("guard")
            .name("town guard")
            .characterSheet(.default)
            .in(.startRoom)

        let enemy = Item("monster")
            .name("angry monster")
            .characterSheet(
                .init(isFighting: true)
            )
            .in(.startRoom)

        let game = MinimalGame(
            items: object, character, enemy
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let objectProxy = await engine.item("book")
        let objectResponse = await objectProxy.response(
            object: { "object: \($0)" },
            character: { "character: \($0)" },
            enemy: { "enemy: \($0)" }
        )
        #expect(objectResponse == "object: the leather book")

        let characterProxy = await engine.item("guard")
        let characterResponse = await characterProxy.response(
            object: { "object: \($0)" },
            character: { "character: \($0)" },
            enemy: { "enemy: \($0)" }
        )
        #expect(characterResponse == "character: the town guard")

        let enemyProxy = await engine.item("monster")
        let enemyResponse = await enemyProxy.response(
            object: { "object: \($0)" },
            character: { "character: \($0)" },
            enemy: { "enemy: \($0)" }
        )
        #expect(enemyResponse == "enemy: the angry monster")
    }

    @Test("ItemProxy alias")
    func testItemProxyAlias() async throws {
        // Given
        let item = Item("sword")
            .name("sharp sword")
            .adjectives("sharp", "gleaming", "shining", "steel")
            .synonyms("blade", "weapon", "sabre")
            .in(.startRoom)

        let game = MinimalGame(
            items: item
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let sword = await engine.item("sword")

        let adjectives = await sword.adjectives
        expectNoDifference(adjectives, ["gleaming", "sharp", "shining", "steel"])

        let synonyms = await sword.synonyms
        expectNoDifference(synonyms, ["blade", "sabre", "weapon"])

        // Test alias generation (should combine adjective + synonym)
        let alias1 = await sword.alias()
        expectNoDifference(alias1, "sharp blade")

        let alias2 = await sword.alias(.withDefiniteArticle)
        expectNoDifference(alias2, "the sharp blade")

        let alias3 = await sword.alias(.withIndefiniteArticle)
        expectNoDifference(alias3, "a weapon")

        let alias4 = await sword.alias(.withPossessiveAdjective)
        expectNoDifference(alias4, "your sabre")
    }

    @Test("ItemProxy alias without adjectives")
    func testItemProxyAliasWithoutAdjectives() async throws {
        // Given
        let item = Item("sword")
            .name("sharp sword")
            .synonyms("blade", "weapon", "sabre")
            .in(.startRoom)

        let game = MinimalGame(
            items: item
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let sword = await engine.item("sword")

        let adjectives = await sword.adjectives
        expectNoDifference(adjectives, ["sharp"])

        let synonyms = await sword.synonyms
        expectNoDifference(synonyms, ["blade", "sabre", "weapon"])

        // Test alias generation (should combine adjective + synonym)
        let alias1 = await sword.alias()
        expectNoDifference(alias1, "sabre")

        let alias2 = await sword.alias(.withDefiniteArticle)
        expectNoDifference(alias2, "the weapon")

        let alias3 = await sword.alias(.withIndefiniteArticle)
        expectNoDifference(alias3, "a sharp blade")

        let alias4 = await sword.alias(.withPossessiveAdjective)
        expectNoDifference(alias4, "your weapon")
    }

    @Test("ItemProxy alias without synonyms")
    func testItemProxyAliasWithoutSynonyms() async throws {
        // Given
        let item = Item("sword")
            .name("sharp sword")
            .adjectives("sharp", "gleaming", "shining", "steel")
            .in(.startRoom)

        let game = MinimalGame(
            items: item
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let sword = await engine.item("sword")

        let adjectives = await sword.adjectives
        expectNoDifference(adjectives, ["gleaming", "sharp", "shining", "steel"])

        let synonyms = await sword.synonyms
        #expect(synonyms.isEmpty)

        // Test alias generation (should combine adjective + synonym)
        let alias1 = await sword.alias()
        expectNoDifference(alias1, "sharp sword")

        let alias2 = await sword.alias(.withDefiniteArticle)
        expectNoDifference(alias2, "the sharp sword")

        let alias3 = await sword.alias(.withIndefiniteArticle)
        expectNoDifference(alias3, "a sharp sword")

        let alias4 = await sword.alias(.withPossessiveAdjective)
        expectNoDifference(alias4, "your sharp sword")
    }

    @Test("ItemProxy size, health, strength, and value properties")
    func testNumericProperties() async throws {
        // Given
        let item = Item("artifact")
            .name("magic artifact")
            .size(5)
            .characterSheet(
                .init(strength: 15, health: 75)
            )
            .value(100)
            .in(.startRoom)

        let defaultItem = Item("basic")
            .name("basic item")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: item, defaultItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then - Test explicit values
        let artifactProxy = await engine.item("artifact")
        #expect(await artifactProxy.size == 5)
        #expect(await artifactProxy.health == 75)
        #expect(await artifactProxy.strength == 15)
        #expect(await artifactProxy.value == 100)

        // Test default values
        let basicProxy = await engine.item("basic")
        #expect(await basicProxy.size == 1)  // Default size
        #expect(await basicProxy.health == 50)  // Default health
        #expect(await basicProxy.strength == 10)  // Default strength
        #expect(await basicProxy.value == 0)  // Default value
    }

    @Test("ItemProxy visibility and description flags")
    func testVisibilityAndDescriptionFlags() async throws {
        // Given
        let visibleItem = Item("visible")
            .name("visible item")
            .in(.startRoom)

        let invisibleItem = Item("invisible")
            .name("invisible item")
            .isInvisible
            .in(.startRoom)

        let omitDescriptionItem = Item("omit")
            .name("omit item")
            .omitDescription
            .isTakable
            .in(.startRoom)

        let touchedItem = Item("touched")
            .name("touched item")
            .isTouched
            .in(.startRoom)

        let game = MinimalGame(
            items: visibleItem, invisibleItem, omitDescriptionItem, touchedItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let visibleProxy = await engine.item("visible")
        #expect(await visibleProxy.isVisible == true)
        #expect(await visibleProxy.shouldDescribe == true)
        #expect(await visibleProxy.isTouched == false)

        let invisibleProxy = await engine.item("invisible")
        #expect(await invisibleProxy.isVisible == false)
        #expect(await invisibleProxy.shouldDescribe == false)

        let omitProxy = await engine.item("omit")
        #expect(await omitProxy.shouldDescribe == false)
        #expect(await omitProxy.isIncludableInAllCommands == false)  // Not includable due to omitDescription

        let touchedProxy = await engine.item("touched")
        #expect(await touchedProxy.isTouched == true)
    }

    @Test("ItemProxy door properties")
    func testDoorProperties() async throws {
        // Given
        let door = Item("door")
            .name("wooden door")
            .isOpenable
            .isLockable
            .in(.startRoom)

        let regularItem = Item("book")
            .name("book")
            .in(.startRoom)

        let game = MinimalGame(
            items: door, regularItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let doorProxy = await engine.item("door")
        #expect(await doorProxy.isDoor == true)

        let bookProxy = await engine.item("book")
        #expect(await bookProxy.isDoor == false)
    }

    @Test("ItemProxy character life and death")
    func testCharacterLifeAndDeath() async throws {
        // Given
        let aliveCharacter = Item("guard")
            .name("town guard")
            .characterSheet(.default)
            .in(.startRoom)

        let deadCharacter = Item("skeleton")
            .name("ancient skeleton")
            .characterSheet(
                .init(consciousness: .dead)
            )
            .in(.startRoom)

        let hostileEnemy = Item("orc")
            .name("fierce orc")
            .characterSheet(
                .init(isFighting: true)
            )
            .in(.startRoom)

        let regularItem = Item("rock")
            .name("rock")
            .in(.startRoom)

        let game = MinimalGame(
            items: aliveCharacter, deadCharacter, hostileEnemy, regularItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let guardProxy = await engine.item("guard")
        #expect(await guardProxy.isAlive == true)
        #expect(await guardProxy.isDead == false)
        #expect(await guardProxy.isHostileEnemy == false)

        let skeletonProxy = await engine.item("skeleton")
        #expect(await skeletonProxy.isAlive == false)
        #expect(await skeletonProxy.isDead == true)

        let orcProxy = await engine.item("orc")
        #expect(await orcProxy.isHostileEnemy == true)

        let rockProxy = await engine.item("rock")
        #expect(await rockProxy.isAlive == false)
    }

    @Test("ItemProxy text content properties")
    func testTextContentProperties() async throws {
        // Given
        let readableItem = Item("book")
            .name("magic book")
            .description("A leather-bound tome.")
            .readText("Ancient secrets are revealed within.")
            .readWhileHeldText("The text glows when held closely.")
            .shortDescription("A tome")
            .firstDescription("You notice an untouched book.")
            .in(.startRoom)

        let unreadableItem = Item("rock")
            .name("smooth rock")
            .in(.startRoom)

        let touchedItem = Item("scroll")
            .name("old scroll")
            .firstDescription("An ancient scroll lies here.")
            .in(.startRoom)

        let game = MinimalGame(
            items: readableItem, unreadableItem, touchedItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let bookProxy = await engine.item("book")
        #expect(await bookProxy.readText == "Ancient secrets are revealed within.")
        #expect(await bookProxy.readWhileHeldText == "The text glows when held closely.")
        #expect(await bookProxy.shortDescription == "A tome")
        #expect(await bookProxy.firstDescription == "You notice an untouched book.")

        let rockProxy = await engine.item("rock")
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

        let scrollProxy = await engine.item("scroll")
        #expect(await scrollProxy.firstDescription == "An ancient scroll lies here.")
        try await engine.apply(
            scrollProxy.setFlag(.isTouched)
        )
        #expect(await scrollProxy.firstDescription == nil)  // nil because item is touched
    }

    @Test("ItemProxy container visibility and contents")
    func testContainerVisibilityAndContents() async throws {
        // Given
        let openContainer = Item("chest")
            .name("wooden chest")
            .isContainer
            .isOpen
            .in(.startRoom)

        let closedContainer = Item("box")
            .name("metal box")
            .isContainer
            .in(.startRoom)

        let transparentContainer = Item("jar")
            .name("glass jar")
            .isContainer
            .isTransparent
            .in(.startRoom)

        let surface = Item("table")
            .name("wooden table")
            .isSurface
            .in(.startRoom)

        let itemInChest = Item("gem")
            .name("ruby gem")
            .in(.item("chest"))

        let itemInBox = Item("coin")
            .name("gold coin")
            .in(.item("box"))

        let itemInJar = Item("beetle")
            .name("small beetle")
            .in(.item("jar"))

        let itemOnTable = Item("book")
            .name("old book")
            .in(.item("table"))

        let hiddenItem = Item("secret")
            .name("secret item")
            .isInvisible
            .in(.item("chest"))

        let game = MinimalGame(
            items: openContainer, closedContainer, transparentContainer, surface,
            itemInChest, itemInBox, itemInJar, itemOnTable, hiddenItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let chestProxy = await engine.item("chest")
        #expect(await chestProxy.contentsAreVisible == true)  // Open container
        let chestVisibleItems = await chestProxy.visibleItems
        #expect(chestVisibleItems.count == 1)  // Only gem, not hidden item
        #expect(chestVisibleItems[0].id == "gem")

        let boxProxy = await engine.item("box")
        #expect(await boxProxy.contentsAreVisible == false)  // Closed container

        let jarProxy = await engine.item("jar")
        #expect(await jarProxy.contentsAreVisible == true)  // Transparent container

        let tableProxy = await engine.item("table")
        #expect(await tableProxy.contentsAreVisible == true)  // Surface

        // Test allContents method
        let chestAllContents = await chestProxy.allContents
        #expect(chestAllContents.count == 2)  // Both gem and hidden item
    }

    @Test("ItemProxy holding and reachability")
    func testHoldingAndReachability() async throws {
        // Given
        let container = Item("bag")
            .name("leather bag")
            .isContainer
            .isOpen
            .in(.player)

        let itemInBag = Item("coin")
            .name("gold coin")
            .in(.item("bag"))

        let roomItem = Item("key")
            .name("brass key")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: container, itemInBag, roomItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let bagProxy = await engine.item("bag")
        let coinProxy = await engine.item("coin")
        let keyProxy = await engine.item("key")

        #expect(await bagProxy.isHolding(coinProxy.id) == true)
        #expect(await bagProxy.isHolding(keyProxy.id) == false)

        #expect(await coinProxy.playerCanReach == true)  // In bag held by player
        #expect(await keyProxy.playerCanReach == true)  // In same room
        #expect(await keyProxy.shouldTakeFirst == true)  // Takable but not held
        #expect(await bagProxy.shouldTakeFirst == false)  // Already held
    }

    @Test("ItemProxy possessive and article methods")
    func testPossessiveAndArticleMethods() async throws {
        // Given
        let item = Item("sword")
            .name("steel sword")
            .in(.startRoom)

        let game = MinimalGame(
            items: item
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.item("sword")

        // When/Then
        let possessive = await proxy.withPossessiveAdjective
        #expect(possessive == "your steel sword")
    }

    @Test("ItemProxy array convenience methods")
    func testArrayConvenienceMethods() async throws {
        // Given
        let book = Item("book")
            .name("leather book")
            .in(.startRoom)

        let coin = Item("coin")
            .name("gold coin")
            .in(.startRoom)

        let gem = Item("gem")
            .name("sparkling gem")
            .in(.startRoom)

        let game = MinimalGame(
            items: book, coin, gem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let bookProxy = await engine.item("book")
        let coinProxy = await engine.item("coin")
        let gemProxy = await engine.item("gem")
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
        let openChest = Item("chest")
            .name("wooden chest")
            .isContainer
            .isOpen
            .in(.startRoom)

        let closedBox = Item("box")
            .name("metal box")
            .isContainer
            .in(.startRoom)

        let transparentJar = Item("jar")
            .name("glass jar")
            .isContainer
            .isTransparent
            .in(.startRoom)

        let gemInChest = Item("gem")
            .name("ruby gem")
            .in(.item("chest"))

        let coinInBox = Item("coin")
            .name("gold coin")
            .in(.item("box"))

        let beetleInJar = Item("beetle")
            .name("small beetle")
            .in(.item("jar"))

        let nestedContainer = Item("pouch")
            .name("small pouch")
            .isContainer
            .isOpen
            .in(.item("chest"))

        let ringInPouch = Item("ring")
            .name("gold ring")
            .in(.item("pouch"))

        let hiddenItem = Item("secret")
            .name("secret item")
            .isInvisible
            .in(.item("chest"))

        let game = MinimalGame(
            items: openChest, closedBox, transparentJar, gemInChest, coinInBox,
            beetleInJar, nestedContainer, ringInPouch, hiddenItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let chestProxy = await engine.item("chest")
        let boxProxy = await engine.item("box")
        let jarProxy = await engine.item("jar")
        let containerArray = [chestProxy, boxProxy, jarProxy]

        // Then - Test allContents (includes everything recursively)
        let allContents = await containerArray.allContents
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
        let cheapItem = Item("copper")
            .name("copper coin")
            .value(1)
            .in(.startRoom)

        let expensiveItem = Item("diamond")
            .name("precious diamond")
            .value(100)
            .in(.startRoom)

        let mediumItem = Item("silver")
            .name("silver coin")
            .value(10)
            .in(.startRoom)

        let noValueItem = Item("rock")
            .name("worthless rock")
            .in(.startRoom)

        let tempValueItem = Item("special")
            .name("special item")
            .value(50)
            .tmpValue(5)
            .in(.startRoom)

        let game = MinimalGame(
            items: cheapItem, expensiveItem, mediumItem, noValueItem, tempValueItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let copperProxy = await engine.item("copper")
        let diamondProxy = await engine.item("diamond")
        let silverProxy = await engine.item("silver")
        let rockProxy = await engine.item("rock")
        let specialProxy = await engine.item("special")

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
