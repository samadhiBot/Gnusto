import CustomDump
import Testing

@testable import GnustoEngine

@Suite("WaveActionHandler Tests")
struct WaveActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("WAVE DIRECTOBJECT syntax works")
    func testWaveDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let wand = Item(
            id: "wand",
            .name("magic wand"),
            .description("A mystical magic wand."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: wand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave wand")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave wand
            You wave the magic wand.
            """)

        let finalState = try await engine.item("wand")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("WAVE AT DIRECTOBJECT syntax works")
    func testWaveAtDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let flag = Item(
            id: "flag",
            .name("colorful flag"),
            .description("A bright colorful flag."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: flag
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave at flag")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave at flag
            You wave the colorful flag.
            """)
    }

    @Test("WAVE TO DIRECTOBJECT syntax works")
    func testWaveToDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let handkerchief = Item(
            id: "handkerchief",
            .name("silk handkerchief"),
            .description("A delicate silk handkerchief."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: handkerchief
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave to handkerchief")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave to handkerchief
            You wave the silk handkerchief.
            """)
    }

    @Test("WAVE DIRECTOBJECT AT INDIRECTOBJECT syntax works")
    func testWaveDirectObjectAtIndirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let torch = Item(
            id: "torch",
            .name("burning torch"),
            .description("A brightly burning torch."),
            .isTakable,
            .isLightSource,
            .in(.player)
        )

        let troll = Item(
            id: "troll",
            .name("cave troll"),
            .description("A menacing cave troll."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: torch, troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave torch at troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave torch at troll
            You wave the burning torch.
            """)

        let finalTorch = try await engine.item("torch")
        #expect(finalTorch.hasFlag(.isTouched) == true)
    }

    @Test("BRANDISH syntax works")
    func testBrandishSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A sharp steel sword."),
            .isTakable,
            .isWeapon,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("brandish sword")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > brandish sword
            You brandish the steel sword menacingly.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot wave without specifying what")
    func testCannotWaveWithoutTarget() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave
            Wave what?
            """)
    }

    @Test("Cannot wave non-existent item")
    func testCannotWaveNonExistentItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave nonexistent
            You can’t see any such thing.
            """)
    }

    @Test("Cannot wave item not in reach")
    func testCannotWaveItemNotInReach() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let distantItem = Item(
            id: "distantItem",
            .name("distant banner"),
            .description("A banner in another room."),
            .isTakable,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: distantItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave banner")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave banner
            You can’t see any such thing.
            """)
    }

    @Test("Cannot wave non-item")
    func testCannotWaveNonItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave me
            You can’t wave that.
            """)
    }

    @Test("Requires light to wave")
    func testRequiresLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let wand = Item(
            id: "wand",
            .name("magic wand"),
            .description("A mystical magic wand."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: wand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave wand")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave wand
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Wave fixed object gives appropriate message")
    func testWaveFixedObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let pillar = Item(
            id: "pillar",
            .name("stone pillar"),
            .description("A massive stone pillar."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: pillar
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave pillar")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave pillar
            You can’t wave the stone pillar.
            """)

        let finalState = try await engine.item("pillar")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Wave weapon gives special message")
    func testWaveWeapon() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let dagger = Item(
            id: "dagger",
            .name("sharp dagger"),
            .description("A wickedly sharp dagger."),
            .isTakable,
            .isWeapon,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: dagger
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave dagger")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave dagger
            You brandish the sharp dagger menacingly.
            """)

        let finalState = try await engine.item("dagger")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Wave generic takable object")
    func testWaveGenericTakableObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let ribbon = Item(
            id: "ribbon",
            .name("blue ribbon"),
            .description("A silky blue ribbon."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: ribbon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave ribbon")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave ribbon
            You wave the blue ribbon.
            """)

        let finalState = try await engine.item("ribbon")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Wave item not held")
    func testWaveItemNotHeld() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let flag = Item(
            id: "flag",
            .name("red flag"),
            .description("A bright red flag."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: flag
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave flag")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave flag
            You wave the red flag.
            """)

        let finalState = try await engine.item("flag")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Wave light source")
    func testWaveLightSource() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lantern = Item(
            id: "lantern",
            .name("glowing lantern"),
            .description("A brightly glowing lantern."),
            .isTakable,
            .isLightSource,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lantern
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave lantern")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave lantern
            You wave the glowing lantern.
            """)

        let finalState = try await engine.item("lantern")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Wave multiple items sequentially")
    func testWaveMultipleItemsSequentially() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let wand1 = Item(
            id: "wand1",
            .name("oak wand"),
            .description("A wand made of oak wood."),
            .isTakable,
            .in(.player)
        )

        let wand2 = Item(
            id: "wand2",
            .name("pine wand"),
            .description("A wand made of pine wood."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: wand1, wand2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - wave first wand
        try await engine.execute("wave oak wand")

        // Then - verify first wand was waved
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > wave oak wand
            You wave the oak wand.
            """)

        let finalWand1 = try await engine.item("wand1")
        #expect(finalWand1.hasFlag(.isTouched) == true)

        // When - wave second wand
        try await engine.execute("wave pine wand")

        // Then - verify second wand was waved
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > wave pine wand
            You wave the pine wand.
            """)

        let finalWand2 = try await engine.item("wand2")
        #expect(finalWand2.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = WaveActionHandler()
        // WaveActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = WaveActionHandler()
        #expect(handler.verbs.contains(.wave))
        #expect(handler.verbs.contains(.brandish))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = WaveActionHandler()
        #expect(handler.requiresLight == true)
    }
}
