import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

/// Tests for commands with conjunctions like "DROP SWORD AND LANTERN"
@Suite("Conjunction Command Tests")
struct ConjunctionCommandTests {

    // MARK: - Test Helpers

    /// Creates a test engine with basic items for conjunction testing
    private func createTestEngine() async -> (GameEngine, MockIOHandler) {
        // Create items for testing
        let sword = Item("sword")
            .name("sword")
            .in(.player)
            .isTakable
            .size(3)

        let lantern = Item("lantern")
            .name("lantern")
            .in(.player)
            .isTakable
            .size(2)

        let book = Item("book")
            .name("book")
            .in(.player)
            .isTakable
            .size(1)

        let coin = Item("coin")
            .name("coin")
            .in(.startRoom)
            .isTakable
            .size(1)

        let gem = Item(.startItem)
            .name("gem")
            .in(.startRoom)
            .isTakable
            .size(1)

        let player = Player(in: .startRoom, characterSheet: .weak)
        let game = MinimalGame(
            player: player,
            items: sword, lantern, book, coin, gem
        )
        return await GameEngine.test(blueprint: game)
    }

    // MARK: - DROP Conjunction Tests

    @Test("DROP SWORD AND LANTERN drops both items")
    func testDropSwordAndLantern() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act: Execute the conjunction command
        try await engine.execute("drop sword and lantern")

        // Assert: Both items should be dropped
        let swordItem = await engine.item("sword")
        let lanternItem = await engine.item("lantern")

        #expect(await swordItem.parent == .location(engine.location(.startRoom)))
        #expect(await lanternItem.parent == .location(engine.location(.startRoom)))

        // Assert: Appropriate message
        await mockIO.expect(
            """
            > drop sword and lantern
            You drop the lantern and the sword.
            """
        )
    }

    @Test("DROP SWORD, LANTERN AND BOOK drops all three items")
    func testDropThreeItemsWithCommaAndConjunction() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act: Execute the conjunction command with comma
        try await engine.execute("drop sword, lantern and book")

        // Assert: All three items should be dropped
        let swordItem = await engine.item("sword")
        let lanternItem = await engine.item("lantern")
        let bookItem = await engine.item("book")

        #expect(await swordItem.parent == .location(engine.location(.startRoom)))
        #expect(await lanternItem.parent == .location(engine.location(.startRoom)))
        #expect(await bookItem.parent == .location(engine.location(.startRoom)))

        // Assert: Appropriate message
        await mockIO.expect(
            """
            > drop sword, lantern and book
            You drop the book, the lantern, and the sword.
            """
        )

    }

    // MARK: - TAKE Conjunction Tests

    @Test("TAKE COIN AND GEM takes both items")
    func testTakeCoinAndGem() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act: Execute the conjunction command
        try await engine.execute("take coin and gem")

        // Assert: Both items should be taken
        let coinItem = await engine.item("coin")
        let gemItem = await engine.item(.startItem)

        #expect(await coinItem.playerIsHolding)
        #expect(await gemItem.playerIsHolding)

        // Assert: Appropriate message
        await mockIO.expect(
            """
            > take coin and gem
            You take the coin and the gem.
            """
        )
    }

    // MARK: - Error Handling Tests

    @Test("Conjunction with verb that doesn't support multiple objects fails")
    func testConjunctionWithUnsupportedVerb() async throws {
        // Create test setup directly
        let sword = Item("sword")
            .name("sword")
            .in(.player)
            .isTakable

        let lantern = Item("lantern")
            .name("lantern")
            .in(.player)
            .isTakable


        let (engine, mockIO) = await GameEngine.test(
            blueprint: MinimalGame(items: sword, lantern)
        )

        // Act: Try to parse "open sword and lantern" (OPEN doesn't support multiple objects)
        try await engine.execute("open sword and lantern")

        // Assert: Should get an error about multiple objects not being supported
        await mockIO.expect(
            """
            > open sword and lantern
            The verb 'open' doesn't support multiple objects.
            """
        )
    }

    @Test("Conjunction with non-existent item handles gracefully")
    func testConjunctionWithNonExistentItem() async throws {
        // Create test setup directly
        let sword = Item("sword")
            .name("sword")
            .in(.player)
            .isTakable


        let (engine, mockIO) = await GameEngine.test(
            blueprint: MinimalGame(items: sword)
        )

        // Act: Try to parse "drop sword and nonexistent" (nonexistent item should cause error)
        try await engine.execute("drop sword and nonexistent")

        // Assert: Should get a parse error about the non-existent item
        await mockIO.expect(
            """
            > drop sword and nonexistent
            You drop the sword.
            """
        )
    }

    // MARK: - Mixed Conjunction Tests

    @Test("DROP with one held and one not held item")
    func testDropMixedHeldStatus() async throws {
        // Create items with one held and one not held
        let sword = Item("sword")
            .name("sword")
            .in(.player)
            .isTakable
            .size(3)

        let statue = Item("statue")
            .name("statue")
            .in(.startRoom)
            .size(10)

        let player = Player(in: .startRoom, characterSheet: .weak)
        let game = MinimalGame(player: player, items: sword, statue)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Try to drop a held item and a non-held item
        try await engine.execute("drop sword and statue")

        // Assert: Should drop the sword but handle the statue appropriately
        let swordItem = await engine.item("sword")
        let statueItem = await engine.item("statue")

        #expect(await swordItem.parent == .location(engine.location(.startRoom)))
        #expect(await statueItem.parent == .location(engine.location(.startRoom)))  // Should remain in location

        // Check output for appropriate error or success message
        await mockIO.expect(
            """
            > drop sword and statue
            You drop the sword.
            """
        )
    }

    // MARK: - Parser Integration Tests

    @Test("Parser correctly parses DROP SWORD AND LANTERN")
    func testParserParsesDropSwordAndLantern() async throws {
        // Create test setup directly
        let sword = Item("sword")
            .name("sword")
            .in(.player)
            .isTakable

        let lantern = Item("lantern")
            .name("lantern")
            .in(.player)
            .isTakable


        let (engine, mockIO) = await GameEngine.test(
            blueprint: MinimalGame(items: sword, lantern)
        )

        // Act: Parse and execute "drop sword and lantern"
        try await engine.execute("drop sword and lantern")

        // Assert: Should successfully execute with multiple objects
        let swordItem = await engine.item("sword")
        let lanternItem = await engine.item("lantern")
        #expect(await swordItem.parent == .location(engine.location(.startRoom)))
        #expect(await lanternItem.parent == .location(engine.location(.startRoom)))

        await mockIO.expect(
            """
            > drop sword and lantern
            You drop the lantern and the sword.
            """
        )
    }

    @Test("Parser correctly parses TAKE COIN, GEM AND BOOK")
    func testParserParsesTakeWithCommaAndConjunction() async throws {
        // Create test setup directly
        let coin = Item("coin")
            .name("coin")
            .in(.startRoom)
            .isTakable

        let gem = Item(.startItem)
            .name("gem")
            .in(.startRoom)
            .isTakable

        let book = Item("book")
            .name("book")
            .in(.startRoom)
            .isTakable


        let (engine, mockIO) = await GameEngine.test(
            blueprint: MinimalGame(items: coin, gem, book)
        )

        // Act: Parse and execute "take coin, gem and book"
        try await engine.execute("take coin, gem and book")

        // Assert: Should successfully execute with multiple objects
        let coinItem = await engine.item("coin")
        let gemItem = await engine.item(.startItem)
        let bookItem = await engine.item("book")
        #expect(await coinItem.playerIsHolding)
        #expect(await gemItem.playerIsHolding)
        #expect(await bookItem.playerIsHolding)

        await mockIO.expect(
            """
            > take coin, gem and book
            You take the book, the coin, and the gem.
            """
        )
    }
}
