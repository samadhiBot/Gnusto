import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ThrowActionHandler Tests")
struct ThrowActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("THROW DIRECTOBJECT syntax works")
    func testThrowDirectObjectSyntax() async throws {
        // Given
        let ball = Item("ball")
            .name("rubber ball")
            .description("A bouncy rubber ball.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: ball
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw ball")

        // Then
        await mockIO.expectOutput(
            """
            > throw ball
            You throw the rubber ball in a lazy arc. It lands nearby with
            little fanfare.
            """
        )

        let finalState = await engine.item("ball")
        let startRoom = await engine.location(.startRoom)
        #expect(await finalState.hasFlag(.isTouched) == true)
        #expect(await finalState.parent == .location(startRoom))
    }

    @Test("THROW DIRECTOBJECT AT INDIRECTOBJECT syntax works")
    func testThrowAtIndirectObjectSyntax() async throws {
        // Given
        let rock = Item("rock")
            .name("small rock")
            .description("A small throwing rock.")
            .isTakable
            .in(.player)

        let target = Item("target")
            .name("wooden target")
            .description("A wooden archery target.")
            .in(.startRoom)

        let game = MinimalGame(
            items: rock, target
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw rock at target")

        // Then
        await mockIO.expectOutput(
            """
            > throw rock at target
            You throw the small rock at the wooden target. It bounces off
            and falls to the ground with an unimpressive thud.
            """
        )

        let finalRock = await engine.item("rock")
        let finalTarget = await engine.item("target")
        let startRoom = await engine.location(.startRoom)

        #expect(await finalRock.hasFlag(.isTouched) == true)
        #expect(await finalRock.parent == .location(startRoom))
        #expect(await finalTarget.hasFlag(.isTouched) == true)
    }

    @Test("THROW DIRECTOBJECT TO INDIRECTOBJECT syntax works")
    func testThrowToIndirectObjectSyntax() async throws {
        // Given
        let key = Item("key")
            .name("brass key")
            .description("A shiny brass key.")
            .isTakable
            .in(.player)

        let castleGuard = Item("guard")
            .name("castle guard")
            .description("A stern castle guard.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: key, castleGuard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw key to guard")

        // Then
        await mockIO.expectOutput(
            """
            > throw key to guard
            You throw the brass key to the castle guard, who catches it
            deftly and nods with appreciation before pocketing it.
            """
        )

        let finalKey = await engine.item("key")
        let finalGuard = await engine.item("guard")
        #expect(await finalKey.hasFlag(.isTouched) == true)
        #expect(await finalKey.parent == .item(castleGuard.proxy(engine)))
        #expect(await finalGuard.hasFlag(.isTouched) == true)
    }

    @Test("HURL syntax works")
    func testHurlSyntax() async throws {
        // Given
        let spear = Item("spear")
            .name("wooden spear")
            .description("A sharp wooden spear.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: spear
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("hurl spear")

        // Then
        await mockIO.expectOutput(
            """
            > hurl spear
            You hurl the wooden spear in a lazy arc. It lands nearby with
            little fanfare.
            """
        )
    }

    @Test("TOSS syntax works")
    func testTossSyntax() async throws {
        // Given
        let coin = Item("coin")
            .name("gold coin")
            .description("A shiny gold coin.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("toss coin")

        // Then
        await mockIO.expectOutput(
            """
            > toss coin
            You toss the gold coin in a lazy arc. It lands nearby with
            little fanfare.
            """
        )
    }

    @Test("CHUCK syntax works")
    func testChuckSyntax() async throws {
        // Given
        let stone = Item("stone")
            .name("heavy stone")
            .description("A heavy throwing stone.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: stone
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("chuck stone")

        // Then
        await mockIO.expectOutput(
            """
            > chuck stone
            You chuck the heavy stone in a lazy arc. It lands nearby with
            little fanfare.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot throw without specifying what")
    func testCannotThrowWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw")

        // Then
        await mockIO.expectOutput(
            """
            > throw
            Throw what?
            """
        )
    }

    @Test("Cannot throw item not held")
    func testCannotThrowItemNotHeld() async throws {
        // Given
        let ball = Item("ball")
            .name("rubber ball")
            .description("A bouncy rubber ball.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: ball
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw ball")

        // Then
        await mockIO.expectOutput(
            """
            > throw ball
            You aren't holding the rubber ball.
            """
        )
    }

    @Test("Cannot throw non-existent item")
    func testCannotThrowNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw nonexistent")

        // Then
        await mockIO.expectOutput(
            """
            > throw nonexistent
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot throw at non-existent target")
    func testCannotThrowAtNonExistentTarget() async throws {
        // Given
        let ball = Item("ball")
            .name("rubber ball")
            .description("A bouncy rubber ball.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: ball
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw ball at nonexistent")

        // Then
        await mockIO.expectOutput(
            """
            > throw ball at nonexistent
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot throw at target not in reach")
    func testCannotThrowAtTargetNotInReach() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let ball = Item("ball")
            .name("rubber ball")
            .description("A bouncy rubber ball.")
            .isTakable
            .in(.player)

        let distantTarget = Item("distantTarget")
            .name("distant target")
            .description("A target in another room.")
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: ball, distantTarget
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw ball at target")

        // Then
        await mockIO.expectOutput(
            """
            > throw ball at target
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Requires light to throw")
    func testRequiresLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
        // Note: No .inherentlyLit property

        let ball = Item("ball")
            .name("rubber ball")
            .description("A bouncy rubber ball.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: ball
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw ball")

        // Then
        await mockIO.expectOutput(
            """
            > throw ball
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Throw item generally")
    func testThrowItemGenerally() async throws {
        // Given
        let bottle = Item("bottle")
            .name("glass bottle")
            .description("A fragile glass bottle.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: bottle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw bottle", times: 2)

        // Then
        await mockIO.expectOutput(
            """
            > throw bottle
            You throw the glass bottle in a lazy arc. It lands nearby with
            little fanfare.

            > throw bottle
            You aren't holding the glass bottle.
            """
        )

        // Verify state changes
        let finalState = await engine.item("bottle")
        let startRoom = await engine.location(.startRoom)

        #expect(await finalState.hasFlag(.isTouched) == true)
        #expect(await finalState.parent == .location(startRoom))
    }

    @Test("Throw item at character")
    func testThrowItemAtCharacter() async throws {
        // Given
        let apple = Item("apple")
            .name("red apple")
            .description("A juicy red apple.")
            .isTakable
            .in(.player)

        let wizard = Item("wizard")
            .name("old wizard")
            .description("A wise old wizard.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: apple, wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw apple at wizard", times: 2)

        // Then
        await mockIO.expectOutput(
            """
            > throw apple at wizard
            You throw the red apple at the old wizard, who dodges aside
            with an indignant look. The the red apple clatters to the
            ground.

            > throw apple at wizard
            You aren't holding the red apple.
            """
        )

        // Verify state changes
        let finalApple = await engine.item("apple")
        let finalWizard = await engine.item("wizard")
        let startRoom = await engine.location(.startRoom)

        #expect(await finalApple.hasFlag(.isTouched) == true)
        #expect(await finalApple.parent == .location(startRoom))
        #expect(await finalWizard.hasFlag(.isTouched) == true)
    }

    @Test("Throw item at enemy")
    func testThrowItemAtEnemy() async throws {
        // Given
        let apple = Item("apple")
            .name("red apple")
            .description("A juicy red apple.")
            .isTakable
            .in(.player)

        let wizard = Item("wizard")
            .name("old wizard")
            .description("A wise old wizard.")
            .characterSheet(.init(isFighting: true))
            .in(.startRoom)

        let game = MinimalGame(
            items: apple, wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw apple at wizard", times: 2)

        // Then
        await mockIO.expectOutput(
            """
            > throw apple at wizard
            You throw the red apple at the old wizard, but your aim falls
            short. The the red apple tumbles uselessly to the ground.

            In a moment of raw violence, the old wizard comes at you with
            nothing but fury! You raise your fists, knowing this will hurt
            regardless of who wins.

            > throw apple at wizard
            You aren't holding the red apple.

            In the tangle, the old wizard drives an elbow home -- sudden
            pressure that blooms into dull pain. Pain flickers and dies.
            Your body has more important work.
            """
        )

        // Verify state changes
        let finalApple = await engine.item("apple")
        let finalWizard = await engine.item("wizard")
        let startRoom = await engine.location(.startRoom)

        #expect(await finalApple.hasFlag(.isTouched) == true)
        #expect(await finalApple.parent == .location(startRoom))
        #expect(await finalWizard.hasFlag(.isTouched) == true)
    }

    @Test("Throw item at object")
    func testThrowItemAtObject() async throws {
        // Given
        let dart = Item("dart")
            .name("sharp dart")
            .description("A sharp throwing dart.")
            .isTakable
            .in(.player)

        let board = Item("board")
            .name("dartboard")
            .description("A standard dartboard.")
            .in(.startRoom)

        let game = MinimalGame(
            items: dart, board
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw dart at board", times: 2)

        // Then
        await mockIO.expectOutput(
            """
            > throw dart at board
            You throw the sharp dart at the dartboard. It bounces off and
            falls to the ground with an unimpressive thud.

            > throw dart at board
            You aren't holding the sharp dart.
            """
        )

        // Verify state changes
        let finalDart = await engine.item("dart")
        let finalBoard = await engine.item("board")
        let startRoom = await engine.location(.startRoom)

        #expect(await finalDart.hasFlag(.isTouched) == true)
        #expect(await finalDart.parent == .location(startRoom))
        #expect(await finalBoard.hasFlag(.isTouched) == true)
    }

    @Test("Throw item to character")
    func testThrowItemToCharacter() async throws {
        // Given
        let coin = Item("coin")
            .name("gold coin")
            .description("A shiny gold coin.")
            .isTakable
            .in(.player)

        let merchant = Item("merchant")
            .name("traveling merchant")
            .description("A friendly traveling merchant.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: coin, merchant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw coin to merchant", times: 2)

        // Then
        await mockIO.expectOutput(
            """
            > throw coin to merchant
            You throw the gold coin to the traveling merchant, who catches
            it deftly and nods with appreciation before pocketing it.

            > throw coin to merchant
            You aren't holding the gold coin.
            """
        )

        // Verify state changes
        let finalCoin = await engine.item("coin")
        let finalMerchant = await engine.item("merchant")
        #expect(await finalCoin.hasFlag(.isTouched) == true)
        #expect(await finalCoin.parent == .item(merchant.proxy(engine)))
        #expect(await finalMerchant.hasFlag(.isTouched) == true)
    }

    @Test("Throw item to enemy")
    func testThrowItemToEnemy() async throws {
        // Given
        let coin = Item("coin")
            .name("gold coin")
            .description("A shiny gold coin.")
            .isTakable
            .in(.player)

        let merchant = Item("merchant")
            .name("traveling merchant")
            .description("A friendly traveling merchant.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: coin, merchant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw coin to merchant", times: 2)

        // Then
        await mockIO.expectOutput(
            """
            > throw coin to merchant
            You throw the gold coin to the traveling merchant, who catches
            it deftly and nods with appreciation before pocketing it.

            > throw coin to merchant
            You aren't holding the gold coin.
            """
        )

        // Verify state changes
        let finalCoin = await engine.item("coin")
        let finalMerchant = await engine.item("merchant")
        #expect(await finalCoin.hasFlag(.isTouched) == true)
        #expect(await finalCoin.parent == .item(merchant.proxy(engine)))
        #expect(await finalMerchant.hasFlag(.isTouched) == true)
    }

    @Test("Throw item to object")
    func testThrowItemToObject() async throws {
        // Given
        let ball = Item("ball")
            .name("tennis ball")
            .description("A bright yellow tennis ball.")
            .isTakable
            .in(.player)

        let basket = Item("basket")
            .name("wicker basket")
            .description("A large wicker basket.")
            .in(.startRoom)

        let game = MinimalGame(
            items: ball, basket
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw ball to basket", times: 2)

        // Then
        await mockIO.expectOutput(
            """
            > throw ball to basket
            You throw the tennis ball toward the wicker basket, but
            inanimate objects make poor catchers. The the tennis ball drops
            to the ground.

            > throw ball to basket
            You aren't holding the tennis ball.
            """
        )

        // Verify state changes
        let finalBall = await engine.item("ball")
        let finalBasket = await engine.item("basket")
        let startRoom = await engine.location(.startRoom)

        #expect(await finalBall.hasFlag(.isTouched) == true)
        #expect(await finalBall.parent == .location(startRoom))
        #expect(await finalBasket.hasFlag(.isTouched) == true)
    }

    @Test("Throw multiple items")
    func testThrowMultipleItems() async throws {
        // Given
        let ball1 = Item("ball1")
            .name("red ball")
            .description("A red rubber ball.")
            .isTakable
            .in(.player)

        let ball2 = Item("ball2")
            .name("blue ball")
            .description("A blue rubber ball.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: ball1, ball2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - throw first ball
        try await engine.execute(
            "throw red ball",
            "throw blue ball"
        )

        // Then - verify first ball was thrown
        await mockIO.expectOutput(
            """
            > throw red ball
            You throw the red ball in a lazy arc. It lands nearby with
            little fanfare.

            > throw blue ball
            You throw the blue ball in a lazy arc. It lands nearby with
            little fanfare.
            """
        )

        let startRoom = await engine.location(.startRoom)

        let finalBall1 = await engine.item("ball1")
        #expect(await finalBall1.parent == .location(startRoom))

        let finalBall2 = await engine.item("ball2")
        #expect(await finalBall2.parent == .location(startRoom))
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = ThrowActionHandler()
        #expect(handler.synonyms.contains(.throw))
        #expect(handler.synonyms.contains(.hurl))
        #expect(handler.synonyms.contains(.toss))
        #expect(handler.synonyms.contains(.chuck))
        #expect(handler.synonyms.count == 4)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ThrowActionHandler()
        #expect(handler.requiresLight == true)
    }
}
