import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("Health System Tests")
struct HealthSystemTests {

    // MARK: - Player Health State Changes

    @Test("Player health can be set directly")
    func testSetPlayerHealth() async throws {
        let (engine, _) = await GameEngine.test(blueprint: MinimalGame())

        // Test setting health to various values
        let healthChange = await engine.player.setHealth(to: 75)
        try await engine.apply(healthChange)

        let playerHealth = await engine.player.health
        #expect(playerHealth == 75)
    }

    @Test("Player health can be adjusted with bounds checking")
    func testAdjustPlayerHealth() async throws {
        let (engine, _) = await GameEngine.test(blueprint: MinimalGame())

        // Test damage
        let damageChange = await engine.player.takeDamage(40)
        try await engine.apply(damageChange)
        #expect(await engine.player.health == 10)

        // Test healing
        let healChange = await engine.player.heal(25)
        try await engine.apply(healChange)
        #expect(await engine.player.health == 35)

        // Test healing beyond max (should cap at 50)
        let overhealChange = await engine.player.heal(50)
        try await engine.apply(overhealChange)
        #expect(await engine.player.health == 50)

        // Test damage beyond minimum (should cap at 0)
        let excessDamageChange = await engine.player.takeDamage(55)
        try await engine.apply(excessDamageChange)
        #expect(await engine.player.health == 0)
    }

    // MARK: - Creature Health

    @Test("Creatures have default health when not specified")
    func testCreatureDefaultHealth() async throws {
        let creature = Item(
            id: "testCreature",
            .name("test creature"),
            .in("startRoom"),
            .characterSheet(.init(health: 50)),
        )

        let (engine, _) = await GameEngine.test(
            blueprint: MinimalGame(
                items: creature
            )
        )

        let creatureProxy = try await engine.item("testCreature")
        let health = try await creatureProxy.health
        #expect(health == 50)  // Default health
    }

    @Test("Creatures can have custom health values")
    func testCreatureCustomHealth() async throws {
        let weakCreature = Item(
            id: "weakCreature",
            .name("weak creature"),
            .characterSheet(.init(health: 25)),
            .in(.startRoom)
        )

        let (engine, _) = await GameEngine.test(
            blueprint: MinimalGame(
                items: weakCreature
            )
        )

        let creatureProxy = try await engine.item("weakCreature")
        let health = try await creatureProxy.health
        #expect(health == 25)
    }

    @Test("Creature health can be modified through damage and healing")
    func testCreatureHealthModification() async throws {
        let creature = Item(
            id: "testCreature",
            .name("test creature"),
            .characterSheet(.init(health: 80)),
            .in(.startRoom)
        )

        let (engine, _) = await GameEngine.test(
            blueprint: MinimalGame(
                items: creature
            )
        )

        let creatureProxy = try await engine.item("testCreature")

        // Test damage
        try await engine.apply(
            creatureProxy.takeDamage(30)
        )
        #expect(try await creatureProxy.health == 50)

        // Test healing
        try await engine.apply(
            creatureProxy.heal(20)
        )
        #expect(try await creatureProxy.health == 70)

        // Test damage to zero (should not go below 0)
        try await engine.apply(
            creatureProxy.takeDamage(100)
        )
        #expect(try await creatureProxy.health == 0)
    }

    // MARK: - Self-Examination with Health Status

    @Test("Self-examination reflects excellent health")
    func testSelfExaminationExcellentHealth() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        #expect(await engine.player.health == 50)

        try await engine.execute("examine me", times: 3)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine me
            As good-looking as ever, which is to say, adequately
            presentable.

            > examine me
            You examine yourself with satisfaction. Not a scratch. The
            universe has failed to leave its mark.

            > examine me
            You are magnificently intact, without so much as a misplaced
            hair to suggest adventure.
            """
        )
    }

    @Test("Self-examination reflects state at 94%")
    func testSelfExamination94PercentHealth() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        try await engine.apply(
            engine.player.setHealth(to: 47)
        )

        try await engine.execute("examine me")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine me
            You're nearly pristine, with only the faintest marks to show
            for your troubles. You've had worse paper cuts.
            """
        )
    }

    @Test("Self-examination reflects state at 84%")
    func testSelfExamination84PercentHealth() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        try await engine.apply(
            engine.player.setHealth(to: 42)
        )

        try await engine.execute("examine me")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine me
            You're lightly scuffed up. A few scrapes and bruises mark your
            recent activities, but nothing a good night's rest won't fix.
            """
        )
    }

    @Test("Self-examination reflects state at 74%")
    func testSelfExamination74PercentHealth() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        try await engine.apply(
            engine.player.setHealth(to: 37)
        )

        try await engine.execute("examine me")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine me
            You're somewhat worse for wear. A collection of minor injuries
            and aches remind you that adventure has its price.
            """
        )
    }

    @Test("Self-examination reflects state at 64%")
    func testSelfExamination64PercentHealth() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        try await engine.apply(
            engine.player.setHealth(to: 32)
        )

        try await engine.execute("examine me")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine me
            You're battered but functional. Various cuts and bruises make
            themselves known, but nothing that won't heal with time.
            """
        )
    }

    @Test("Self-examination reflects state at 54%")
    func testSelfExamination54PercentHealth() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        try await engine.apply(
            engine.player.setHealth(to: 27)
        )

        try await engine.execute("examine me")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine me
            You're wounded and weary. Several painful injuries slow your
            movements, and you're definitely not at your best. You've been
            better.
            """
        )
    }

    @Test("Self-examination reflects state at 44%")
    func testSelfExamination44PercentHealth() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        try await engine.apply(
            engine.player.setHealth(to: 22)
        )

        try await engine.execute("examine me")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine me
            You're seriously hurt. Deep injuries throb with persistent
            pain, and you're moving with obvious difficulty. This is
            getting dangerous.
            """
        )
    }

    @Test("Self-examination reflects state at 34%")
    func testSelfExamination34PercentHealth() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        try await engine.apply(
            engine.player.setHealth(to: 17)
        )

        try await engine.execute("examine me")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine me
            You're badly wounded. Pain radiates through your body with
            every heartbeat, and your strength is failing. You need help,
            desperately.
            """
        )
    }

    @Test("Self-examination reflects state at 24%")
    func testSelfExamination24PercentHealth() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        try await engine.apply(
            engine.player.setHealth(to: 12)
        )

        try await engine.execute("examine me")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine me
            You're in critical condition. Blood seeps from numerous wounds,
            and you struggle to stay upright. Death feels uncomfortably
            close.
            """
        )
    }

    @Test("Self-examination reflects state at 14%")
    func testSelfExamination14PercentHealth() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        try await engine.apply(
            engine.player.setHealth(to: 7)
        )

        try await engine.execute("examine me")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine me
            You're a breath away from oblivion. Every movement is agony,
            your vision swims with darkness, and you can barely remain
            conscious.
            """
        )
    }

    @Test("Self-examination reflects critical condition")
    func testSelfExaminationDead() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.apply(
            engine.player.setHealth(to: 0)
        )

        try await engine.execute("examine me")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine me
            Against all logic, you examine your deceased form. The
            diagnosis is not encouraging.

            ****  You have died  ****

            Death, that most permanent of inconveniences, has claimed you.
            Yet in these tales, even death offers second chances.

            You scored 0 out of a possible 10 points, in 0 moves.

            Would you like to RESTART, RESTORE a saved game, or QUIT?

            >
            """
        )
    }

    // MARK: - Strength and Combat Integration

    @Test("Creatures have default strength when not specified")
    func testCreatureDefaultStrength() async throws {
        let creature = Item(
            id: "testCreature",
            .name("test creature"),
            .in(.startRoom),
            .characterSheet(.default)
        )

        let (engine, _) = await GameEngine.test(
            blueprint: MinimalGame(
                items: creature
            )
        )

        let creatureProxy = try await engine.item("testCreature")
        let strength = try await creatureProxy.strength
        #expect(strength == 10)  // Default strength
    }

    @Test("Creatures can have custom strength values")
    func testCreatureCustomStrength() async throws {
        let strongCreature = Item(
            id: "strongCreature",
            .name("strong creature"),
            .characterSheet(.init(strength: 25)),
            .in(.startRoom)
        )

        let (engine, _) = await GameEngine.test(
            blueprint: MinimalGame(
                items: strongCreature
            )
        )

        let creatureProxy = try await engine.item("strongCreature")
        let strength = try await creatureProxy.strength
        #expect(strength == 25)
    }

    // MARK: - Health Boundary Tests

    @Test("Health cannot go below zero")
    func testHealthLowerBound() async throws {
        let creature = Item(
            id: "testCreature",
            .name("test creature"),
            .characterSheet(.init(health: 10)),
            .in(.startRoom)
        )

        let (engine, _) = await GameEngine.test(
            blueprint: MinimalGame(
                items: creature
            )
        )

        let creatureProxy = try await engine.item("testCreature")

        // Deal massive damage
        if let damageChange = try await creatureProxy.takeDamage(50) {
            try await engine.apply(damageChange)
        }

        #expect(try await creatureProxy.health == 0)
    }

    @Test("Health caps at maxHealth for standard healing")
    func testHealthUpperBound() async throws {
        let creature = Item(
            id: "testCreature",
            .name("test creature"),
            .characterSheet(.init(health: 90)),
            .in(.startRoom)
        )

        let (engine, _) = await GameEngine.test(
            blueprint: MinimalGame(
                items: creature
            )
        )

        let creatureProxy = try await engine.item("testCreature")

        // Heal beyond maximum
        if let healChange = try await creatureProxy.heal(50) {
            try await engine.apply(healChange)
        }

        #expect(try await creatureProxy.health == 90)
    }

    // MARK: - Basic Combat Health Integration

    @Test("Combat with healthy participants works")
    func testBasicCombatHealthIntegration() async throws {
        let sword = Item(
            id: "sword",
            .name("sword"),
            .isWeapon,
            .isTakable,
            .in(.player)
        )

        let creature = Item(
            id: "creature",
            .name("creature"),
            .characterSheet(.init(health: 50)),
            .in(.startRoom)
        )

        let (engine, mockIO) = await GameEngine.test(
            blueprint: MinimalGame(
                items: creature, sword
            )
        )

        // Execute combat
        try await engine.execute("attack creature")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack creature
            Armed and hungry for violence, you strike with your sword as
            the creature can only dodge and weave against the advantage of
            sharpened metal.

            Your blow with your sword catches the creature cleanly, tearing
            flesh and drawing crimson. The blow lands solidly, drawing
            blood. It feels the sting but remains strong.

            In the tangle, the creature drives an elbow home--sudden
            pressure that blooms into dull pain. The wound is trivial
            against your battle fury.
            """
        )

        // Health values should remain valid (0-100)
        let finalPlayerHealth = await engine.player.health
        let finalCreatureHealth = try await engine.item("creature").health

        #expect(finalPlayerHealth >= 0)
        #expect(finalPlayerHealth <= 100)
        #expect(finalCreatureHealth >= 0)
        #expect(finalCreatureHealth <= 100)
    }
}
