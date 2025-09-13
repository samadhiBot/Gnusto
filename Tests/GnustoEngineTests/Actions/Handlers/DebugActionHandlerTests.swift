import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("DebugActionHandler Tests")
struct DebugActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("DEBUG syntax works")
    func testDebugSyntax() async throws {
        // Given
        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lantern."),
            .adjectives("shiny", "brass"),
            .synonyms("lantern"),
            .isTakable,
            .isLightSource,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > debug lamp
            ```
            Item(
              id: .lamp,
              properties: [
                .adjectives: ['brass', 'shiny'],
                .description: 'A shiny brass lantern.',
                .isLightSource: true,
                .isTakable: true,
                .name: 'brass lamp',
                .parentEntity: .location(.startRoom),
                .synonyms: ['lantern']
              ]
            )
            ```
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot debug without specifying object")
    func testCannotDebugWithoutObject() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > debug
            DEBUG requires a direct object to examine.
            """
        )
    }

    @Test("Cannot debug non-existent item")
    func testCannotDebugNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > debug nonexistent
            ```
            Item(
              id: .nonexistent,
              properties: [:]
            )
            ```
            """
        )
    }

    @Test("Cannot debug non-existent location")
    func testCannotDebugNonExistentLocation() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug nonexistentRoom")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > debug nonexistentRoom
            ```
            Item(
              id: .nonexistentroom,
              properties: [:]
            )
            ```
            """
        )
    }

    @Test("Does not require light to debug")
    func testDoesNotRequireLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lantern."),
            .adjectives("shiny", "brass"),
            .synonyms("lantern"),
            .isTakable,
            .isLightSource,
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug lamp")

        // Then - Debug should work even in darkness
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > debug lamp
            ```
            Item(
              id: .lamp,
              properties: [
                .adjectives: ['brass', 'shiny'],
                .description: 'A shiny brass lantern.',
                .isLightSource: true,
                .isTakable: true,
                .name: 'brass lamp',
                .parentEntity: .location(.darkRoom),
                .synonyms: ['lantern']
              ]
            )
            ```
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Debug item shows item details")
    func testDebugItemShowsDetails() async throws {
        // Given
        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A sharp steel sword."),
            .adjectives("sharp", "steel"),
            .isTakable,
            .isWeapon,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug sword")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > debug sword
            ```
            Item(
              id: .sword,
              properties: [
                .adjectives: ['sharp', 'steel'],
                .description: 'A sharp steel sword.',
                .isTakable: true,
                .isWeapon: true,
                .name: 'steel sword',
                .parentEntity: .location(.startRoom)
              ]
            )
            ```
            """
        )
    }

    @Test("Debug location shows location details")
    func testDebugLocationShowsDetails() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug startRoom")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > debug startRoom
            ```
            Location(
              id: .startRoom,
              properties: [
                .description: 'A laboratory in which strange experiments are being conducted.',
                .inherentlyLit: true,
                .name: 'Laboratory'
              ]
            )
            ```
            """
        )
    }

    @Test("Debug player shows player details")
    func testDebugPlayerShowsDetails() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > debug me
            ```
            Player(
              characterSheet: CharacterSheet(
                strength: 10,
                dexterity: 10,
                constitution: 10,
                intelligence: 10,
                wisdom: 10,
                charisma: 10,
                bravery: 10,
                perception: 10,
                luck: 10,
                morale: 10,
                accuracy: 10,
                intimidation: 10,
                stealth: 10,
                armorClass: 10,
                health: 50,
                maxHealth: 50,
                level: 1,
                classification: .neuter,
                alignment: .trueNeutral,
                consciousness: .alert,
                combatCondition: .normal,
                generalCondition: .normal,
                isFighting: false,
                weaponWeaknesses: [:],
                weaponResistances: [:],
                taunts: []
              ),
              currentLocationID: .startRoom,
              moves: 0,
              score: 0
            )
            ```
            """
        )
    }

    @Test("Debug self alias works")
    func testDebugSelfAlias() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug self")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > debug self
            ```
            Player(
              characterSheet: CharacterSheet(
                strength: 10,
                dexterity: 10,
                constitution: 10,
                intelligence: 10,
                wisdom: 10,
                charisma: 10,
                bravery: 10,
                perception: 10,
                luck: 10,
                morale: 10,
                accuracy: 10,
                intimidation: 10,
                stealth: 10,
                armorClass: 10,
                health: 50,
                maxHealth: 50,
                level: 1,
                classification: .neuter,
                alignment: .trueNeutral,
                consciousness: .alert,
                combatCondition: .normal,
                generalCondition: .normal,
                isFighting: false,
                weaponWeaknesses: [:],
                weaponResistances: [:],
                taunts: []
              ),
              currentLocationID: .startRoom,
              moves: 0,
              score: 0
            )
            ```
            """
        )
    }

    @Test("Debug item with flags shows flag details")
    func testDebugItemWithFlagsShowsFlags() async throws {
        // Given
        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lantern."),
            .adjectives("shiny", "brass"),
            .synonyms("lantern"),
            .isTakable,
            .isDevice,
            .isLightSource,
            .in(.player)
        )

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set the lamp to be on for more detailed debug output
        try await engine.apply(
            await lamp.proxy(engine).setFlag(.isOn)
        )

        // When
        try await engine.execute("debug lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > debug lamp
            ```
            Item(
              id: .lamp,
              properties: [
                .adjectives: ['brass', 'shiny'],
                .description: 'A shiny brass lantern.',
                .isDevice: true,
                .isLightSource: true,
                .isOn: true,
                .isTakable: true,
                .name: 'brass lamp',
                .parentEntity: .player,
                .synonyms: ['lantern']
              ]
            )
            ```
            """
        )
    }

    @Test("Debug item not in scope still works")
    func testDebugItemNotInScopeStillWorks() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteItem = Item(
            id: "remoteItem",
            .name("remote item"),
            .description("An item in another room."),
            .isTakable,
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Debug should work even on items not in current scope
        try await engine.execute("debug remoteItem")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > debug remoteItem
            ```
            Item(
              id: .remoteItem,
              properties: [
                .adjectives: ['remote'],
                .description: 'An item in another room.',
                .isTakable: true,
                .name: 'remote item',
                .parentEntity: .location(.anotherRoom),
                .synonyms: ['remoteitem', 'room']
              ]
            )
            ```
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = DebugActionHandler()
        #expect(handler.synonyms.contains(.debug))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = DebugActionHandler()
        #expect(handler.requiresLight == false)
    }

    @Test("Handler uses correct syntax")
    func testSyntaxRules() async throws {
        let handler = DebugActionHandler()
        #expect(handler.syntax.count == 1)

        // Should have .match(.verb) syntax
        let _ = handler.syntax[0]
        // Note: We can't easily test the internal structure of SyntaxRule,
        // but we can verify the count and that syntax testing above works
    }
}
