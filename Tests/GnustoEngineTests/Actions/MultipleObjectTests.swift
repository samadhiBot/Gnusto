import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

/// Tests for verbs that support multiple objects (ALL and AND keywords).
struct MultipleObjectTests {

    // MARK: - EXAMINE Multiple Objects Tests

    @Test("EXAMINE ALL works correctly")
    func testExamineAll() async throws {
        let sword = Item("sword")
            .name("sword")
            .in(.startRoom)
            .description("A sharp blade.")

        let lantern = Item("lantern")
            .name("lantern")
            .in(.startRoom)
            .description("A bright light.")

        let game = MinimalGame(items: sword, lantern)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Execute "examine all"
        try await engine.execute("examine all")

        // Assert: Should examine both items
        await mockIO.expectOutput(
            """
            > examine all
            - Lantern: A bright light.
            - Sword: A sharp blade.
            """
        )
    }

    @Test("EXAMINE SWORD AND LANTERN works correctly")
    func testExamineSwordAndLantern() async throws {
        let sword = Item("sword")
            .name("sword")
            .in(.startRoom)
            .description("A sharp blade.")

        let lantern = Item("lantern")
            .name("lantern")
            .in(.startRoom)
            .description("A bright light.")

        let game = MinimalGame(items: sword, lantern)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Execute "examine sword and lantern"
        try await engine.execute("examine sword and lantern")

        // Assert: Should examine both items
        await mockIO.expectOutput(
            """
            > examine sword and lantern
            - Lantern: A bright light.
            - Sword: A sharp blade.
            """
        )
    }

    // MARK: - GIVE Multiple Objects Tests

    @Test("GIVE ALL TO MERCHANT works correctly")
    func testGiveAllToMerchant() async throws {
        let coin = Item("coin")
            .name("coin")
            .in(.player)

        let gem = Item("gem")
            .name("gem")
            .in(.player)

        let merchant = Item("merchant")
            .name("merchant")
            .in(.startRoom)
            .characterSheet(.default)

        let game = MinimalGame(
            items: coin, gem, merchant
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Execute "give all to merchant"
        try await engine.execute("give all to merchant")

        // Assert: Should give both items
        await mockIO.expectOutput(
            """
            > give all to merchant
            You give the coin and the gem to the merchant.
            """
        )

        // Verify items moved to merchant
        let updatedCoin = await engine.item("coin")
        let updatedGem = await engine.item("gem")
        #expect(await updatedCoin.parent == .item(merchant.proxy(engine)))
        #expect(await updatedGem.parent == .item(merchant.proxy(engine)))
    }

    @Test("GIVE COIN AND GEM TO MERCHANT works correctly")
    func testGiveCoinAndGemToMerchant() async throws {
        let coin = Item("coin")
            .name("coin")
            .in(.player)
        let gem = Item("gem")
            .name("gem")
            .in(.player)
        let merchant = Item("merchant")
            .name("merchant")
            .in(.startRoom)
            .characterSheet(.default)

        let game = MinimalGame(
            items: coin, gem, merchant
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Execute "give coin and gem to merchant"
        try await engine.execute("give coin and gem to merchant")

        // Assert: Should give both items
        await mockIO.expectOutput(
            """
            > give coin and gem to merchant
            You give the coin and the gem to the merchant.
            """
        )

        // Verify items moved to merchant
        let updatedCoin = await engine.item("coin")
        let updatedGem = await engine.item("gem")
        #expect(await updatedCoin.parent == .item(merchant.proxy(engine)))
        #expect(await updatedGem.parent == .item(merchant.proxy(engine)))
    }

    // MARK: - PUT Multiple Objects Tests

    @Test("PUT ALL IN BOX works correctly")
    func testPutAllInBox() async throws {
        let coin = Item("coin")
            .name("coin")
            .in(.player)
        let gem = Item("gem")
            .name("gem")
            .in(.player)
        let box = Item("box")
            .name("box")
            .in(.startRoom)
            .isContainer
            .isOpen

        let game = MinimalGame(items: coin, gem, box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Execute "put all in box"
        try await engine.execute("put all in box")

        // Assert: Should put both items in box
        await mockIO.expectOutput(
            """
            > put all in box
            You carefully place the coin and the gem within the box.
            """
        )

        // Verify items moved to box
        let updatedCoin = await engine.item("coin")
        let updatedGem = await engine.item("gem")
        #expect(await updatedCoin.parent == .item(box.proxy(engine)))
        #expect(await updatedGem.parent == .item(box.proxy(engine)))
    }

    @Test("PUT COIN AND GEM IN BOX works correctly")
    func testPutCoinAndGemInBox() async throws {
        let coin = Item("coin")
            .name("coin")
            .in(.player)
        let gem = Item("gem")
            .name("gem")
            .in(.player)
        let box = Item("box")
            .name("box")
            .in(.startRoom)
            .isContainer
            .isOpen

        let game = MinimalGame(items: coin, gem, box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Execute "put coin and gem in box"
        try await engine.execute("put coin and gem in box")

        // Assert: Should put both items in box
        await mockIO.expectOutput(
            """
            > put coin and gem in box
            You carefully place the coin and the gem within the box.
            """
        )

        // Verify items moved to box
        let updatedCoin = await engine.item("coin")
        let updatedGem = await engine.item("gem")
        #expect(await updatedCoin.parent == .item(box.proxy(engine)))
        #expect(await updatedGem.parent == .item(box.proxy(engine)))
    }

    // MARK: - TAKE Multiple Objects Tests

    @Test("TAKE ALL works correctly")
    func testTakeAll() async throws {
        let goblet = Item("goblet")
            .name("goblet")
            .in(.startRoom)
            .isTakable
        let scepter = Item("scepter")
            .name("scepter")
            .in(.startRoom)
            .isTakable

        let game = MinimalGame(
            items: goblet, scepter
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Execute "take all"
        try await engine.execute("take all")

        // Assert: Should take both items
        await mockIO.expectOutput(
            """
            > take all
            You take the goblet and the scepter.
            """
        )
    }

    @Test("TAKE BUTTON AND LEVER works correctly")
    func testTakeButtonAndLever() async throws {
        let goblet = Item("goblet")
            .name("goblet")
            .in(.startRoom)
            .isTakable
        let scepter = Item("scepter")
            .name("scepter")
            .in(.startRoom)
            .isTakable

        let game = MinimalGame(
            items: goblet, scepter
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Execute "take goblet and scepter"
        try await engine.execute("take goblet and scepter")

        // Assert: Should take both items
        await mockIO.expectOutput(
            """
            > take goblet and scepter
            You take the goblet and the scepter.
            """
        )
    }

    // MARK: - Error Handling Tests

    @Test("Multiple objects with unsupported verb fails gracefully")
    func testMultipleObjectsWithUnsupportedVerb() async throws {
        let sword = Item("sword")
            .name("sword")
            .in(.startRoom)
        let lantern = Item("lantern")
            .name("lantern")
            .in(.startRoom)

        let game = MinimalGame(items: sword, lantern)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Try "open sword and lantern" (OPEN doesn't support multiple objects)
        try await engine.execute("open sword and lantern")

        // Assert: Should get an error about multiple objects not being supported
        await mockIO.expectOutput(
            """
            > open sword and lantern
            The verb 'open' doesn't support multiple objects.
            """
        )
    }

    @Test("ALL with no applicable items handles gracefully")
    func testAllWithNoApplicableItems() async throws {
        let fountain = Item(.startItem)
            .name("fountain")
            .in(.startRoom)

        let game = MinimalGame(items: fountain)

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Execute "take all" when there's nothing to take
        try await engine.execute("take all")

        // Assert: Should get appropriate message
        await mockIO.expectOutput(
            """
            > take all
            Take what?
            """
        )
    }
}
