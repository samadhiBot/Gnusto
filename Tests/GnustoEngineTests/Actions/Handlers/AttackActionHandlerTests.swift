import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("AttackActionHandler Tests")
struct AttackActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("ATTACK DIRECTOBJECT syntax works")
    func testAttackDirectObjectSyntax() async throws {
        // Given
        let game = MinimalGame(
            items: Lab.troll, Lab.axe
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack the troll", times: 5)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack the troll
            With nothing but rage you rush the fearsome beast as his
            gruesome ax gleams cold and ready for the blood you're
            offering.

            Perfect opportunity appears! The angry beast is off-balance and
            defenseless, a sitting target for your next move.

            The terrible beast swings his bloody axe in response but you
            weave away, leaving the weapon to bite empty air.

            > attack the troll
            You swing and miss entirely! The monster sidesteps your clumsy
            punch, his nicked ax still threatening.

            The riposte comes fast, his bloody axe flicking out to trace a
            shallow arc of red across your guard. Pain flickers and dies.
            Your body has more important work.

            > attack the troll
            Impact! The creature reels from your strike, feet shuffling
            frantically to stay upright.

            The beast strikes back with his nicked ax, sending you
            staggering and unable to keep the ground where it belongs.

            > attack the troll
            You slip inside the reach of his axe and drive your knuckles
            hard into the creature's body. The wound is real but
            manageable.

            Then the grotesque creature breaks through with his ax in a
            move that leaves you defenseless, your body a map of
            unprotected targets.

            > attack the troll
            You land the decisive hit! The beast wavers for a heartbeat,
            then collapses into permanent silence.
            """
        )
    }

    @Test("ATTACK DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testAttackWithWeaponSyntax() async throws {
        // Given
        let dragon = Item(
            id: "dragon",
            .name("red dragon"),
            .adjectives("terrible", "awesome", "fierce"),
            .synonyms("creature", "wyrm"),
            .description("A fearsome red dragon."),
            .characterSheet(.boss),
            .in(.startRoom)
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A sharp steel sword."),
            .isWeapon,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: dragon, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack dragon with sword", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack dragon with sword
            You press forward with your steel sword leading the way toward
            flesh while the fierce creature backs away, unarmed but still
            dangerous as any cornered thing.

            Your steel sword misses completely--the wyrm wasn't even near
            where you struck.

            The awesome creature shatters your defense with bare hands,
            leaving you wide open and unable to protect yourself.

            > attack dragon with sword
            You strike the creature with your steel sword, opening a wound
            that bleeds steadily. The wound is real but manageable.

            The counterblow drives deep. The wyrm buries knuckles in your
            ribs, and breath becomes agony. The shock of injury hits hard.
            Your unmarked flesh now torn and bleeding.

            > attack dragon with sword
            You nick the wyrm with your steel sword, the weapon barely
            breaking skin. It feels it connect, adding to the bruises but
            not breaking rhythm.

            Then the wyrm's strike meets you solidly and the world lurches
            sideways, as balance becomes a memory rather than a fact.
            """
        )
    }

    @Test("FIGHT syntax works")
    func testFightSyntax() async throws {
        // Given
        let orc = Item(
            id: "orc",
            .name("angry orc"),
            .description("A mighty orc warrior."),
            .characterSheet(.strong),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: orc
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fight the orc", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fight the orc
            You close the distance fast with fists ready as the warrior
            mirrors your stance, both of you committed to finding out who
            breaks first.

            You land a light punch that it barely feels. It notes the minor
            damage and dismisses it.

            The angry warrior shatters your defense with bare hands,
            leaving you wide open and unable to protect yourself.

            > fight the orc
            You land a light punch that it barely feels. It notes the minor
            damage and dismisses it.

            The counterstrike comes heavy. The warrior's fist finds ribs,
            and pain blooms like fire through your chest. First blood to
            them. The wound is real but manageable.

            > fight the orc
            Impact! The warrior reels from your strike, feet shuffling
            frantically to stay upright.

            The mighty warrior shatters your defense with bare hands,
            leaving you wide open and unable to protect yourself.
            """
        )
    }

    @Test("HIT syntax works")
    func testHitSyntax() async throws {
        // Given
        let goblin = Item(
            id: "goblin",
            .name("sneaky goblin"),
            .description("A sneaky goblin."),
            .characterSheet(.weak),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: goblin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("hit the goblin", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > hit the goblin
            You close the distance fast with fists ready as the sneaky
            goblin mirrors your stance, both of you committed to finding
            out who breaks first.

            You drive your bare hands into the sneaky goblin, feeling the
            satisfying thud of impact. The wound is real but manageable.

            The counterstrike comes wild--the sneaky goblin's fist clips
            you without finding purchase. No real damage. More of a touch
            than a strike.

            > hit the goblin
            You land the decisive hit! The sneaky goblin wavers for a
            heartbeat, then collapses into permanent silence.

            > hit the goblin
            You close the distance fast with fists ready as the sneaky
            goblin mirrors your stance, both of you committed to finding
            out who breaks first.

            Death has already claimed the sneaky goblin.
            """
        )
    }

    @Test("KILL syntax works")
    func testKillSyntax() async throws {
        // Given
        let spider = Item(
            id: "spider",
            .name("giant spider"),
            .description("A giant spider."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(items: spider)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kill the giant spider", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kill the giant spider
            You close the distance fast with fists ready as the giant
            spider mirrors your stance, both of you committed to finding
            out who breaks first.

            You land a light punch that it barely feels. It notes the minor
            damage and dismisses it.

            The counterblow comes wild and desperate, the giant spider
            hammering through your guard to bruise rather than break. Pain
            flickers and dies. Your body has more important work.

            > kill the giant spider
            You land a light punch that it barely feels. It feels it
            connect, adding to the bruises but not breaking rhythm.

            The counterblow comes wild and desperate, the giant spider
            hammering through your guard to bruise rather than break. You
            feel it connect, adding to the bruises but not breaking your
            rhythm.

            > kill the giant spider
            You land a light punch that it barely feels. It feels the hit,
            another note in the symphony of damage.

            The counterstrike comes wild--the giant spider's fist clips you
            without finding purchase. You feel it dimly through the haze of
            other pains.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot attack without specifying target")
    func testCannotAttackWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack
            Attack what?
            """
        )
    }

    @Test("Cannot attack target not in scope")
    func testCannotAttackTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteTroll = Item(
            id: "remoteTroll",
            .name("remote troll"),
            .description("A troll in another room."),
            .characterSheet(.default),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteTroll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack troll
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot attack with weapon not held")
    func testCannotAttackWithWeaponNotHeld() async throws {
        // Given
        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A sharp steel sword."),
            .isWeapon,
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: Lab.troll, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack troll with sword")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack troll with sword
            You aren't holding the steel sword.
            """
        )
    }

    @Test("Requires light to attack")
    func testRequiresLight() async throws {
        // Given: Dark room with character
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack troll
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Attack non-character gives appropriate message")
    func testAttackNonCharacter() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack rock
            Attacking the large rock would accomplish nothing productive.
            """
        )

        let finalState = await engine.item("rock")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Attack boss character bare-handed is denied")
    func testAttackBossCharacterBareHandedDenied() async throws {
        // Given
        let dragon = Item(
            id: "dragon",
            .name("red dragon"),
            .adjectives("terrible", "awesome", "fierce"),
            .synonyms("creature", "wyrm"),
            .description("A fearsome red dragon."),
            .characterSheet(.boss),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: dragon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack the dragon")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack the dragon
            You close the distance fast with fists ready as the fierce
            creature mirrors your stance, both of you committed to finding
            out who breaks first.

            The wyrm bobs and weaves, avoiding your strike entirely.

            The awesome creature shatters your defense with bare hands,
            leaving you wide open and unable to protect yourself.
            """
        )
    }

    @Test("Attack character with non-weapon")
    func testAttackCharacterWithNonWeapon() async throws {
        // Given
        let bandit = Item(
            id: "bandit",
            .name("dangerous bandit"),
            .description("A dangerous bandit."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let stick = Item(
            id: "stick",
            .name("wooden stick"),
            .description("A simple wooden stick."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: bandit, stick
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack the bandit with a stick")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack the bandit with a stick
            You press forward with your wooden stick leading the way toward
            flesh while the dangerous bandit backs away, unarmed but still
            dangerous as any cornered thing.

            You attack with the wooden stick! The dangerous bandit dodges,
            more puzzled than threatened by your choice of weapon.

            The counterblow comes wild and desperate, the dangerous bandit
            hammering through your guard to bruise rather than break. Pain
            flickers and dies. Your body has more important work.
            """
        )
    }

    @Test("Attack character with weapon")
    func testAttackCharacterWithWeapon() async throws {
        // Given
        let monster = Item(
            id: "monster",
            .name("evil monster"),
            .description("An evil monster."),
            .characterSheet(.agile),
            .in(.startRoom)
        )

        let dagger = Item(
            id: "dagger",
            .name("sharp dagger"),
            .description("A sharp dagger."),
            .isWeapon,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: monster, dagger
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack the monster with my dagger", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack the monster with my dagger
            You press forward with your sharp dagger leading the way toward
            flesh while the evil monster backs away, unarmed but still
            dangerous as any cornered thing.

            You nick the evil monster with your sharp dagger, the weapon
            barely breaking skin. It notes the minor damage and dismisses
            it.

            The counterstrike comes heavy. The evil monster's fist finds
            ribs, and pain blooms like fire through your chest. First blood
            to them. The wound is real but manageable.

            > attack the monster with my dagger
            You nick the evil monster with your sharp dagger, the weapon
            barely breaking skin. It notes the minor damage and dismisses
            it.

            The evil monster retaliates with expert technique, disarming
            you barehanded and sending your sharp dagger clattering away.

            > attack the monster with my dagger
            You aren't holding the sharp dagger.

            You nick the evil monster with your sharp dagger, the weapon
            barely breaking skin. It feels it connect, adding to the
            bruises but not breaking rhythm.

            Then the evil monster's strike meets you solidly and the world
            lurches sideways, as balance becomes a memory rather than a
            fact.
            """
        )
    }

    @Test("Attack enemy with weapon")
    func testAttackEnemyWithWeapon() async throws {
        // Given
        let monster = Item(
            id: "monster",
            .name("evil monster"),
            .description("An evil monster."),
            .characterSheet(.init(isFighting: true)),
            .in(.startRoom)
        )

        let dagger = Item(
            id: "dagger",
            .name("sharp dagger"),
            .description("A sharp dagger."),
            .isWeapon,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: monster, dagger
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "look",
            "attack the monster with my dagger"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            You can see an evil monster here.

            The evil monster comes at you unarmed but fearless! You level
            your sharp dagger at its approach--will your weapon stop such
            determination?

            > attack the monster with my dagger
            You strike the evil monster with your sharp dagger, opening a
            wound that bleeds steadily. The wound is real but manageable.

            The counterblow comes wild and desperate, the evil monster
            hammering through your guard to bruise rather than break. Pain
            flickers and dies. Your body has more important work.
            """
        )
    }

    @Test("Attack character with unspecified weapon")
    func testAttackCharacterWithUnspecifiedWeapon() async throws {
        // Given
        let monster = Item(
            id: "monster",
            .name("evil monster"),
            .description("An evil monster."),
            .characterSheet(.agile),
            .in(.startRoom)
        )

        let dagger = Item(
            id: "dagger",
            .name("sharp dagger"),
            .description("A sharp dagger."),
            .isWeapon,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: monster, dagger
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("stab the monster", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > stab the monster
            You press forward with your sharp dagger leading the way toward
            flesh while the evil monster backs away, unarmed but still
            dangerous as any cornered thing.

            You nick the evil monster with your sharp dagger, the weapon
            barely breaking skin. It notes the minor damage and dismisses
            it.

            The counterstrike comes heavy. The evil monster's fist finds
            ribs, and pain blooms like fire through your chest. First blood
            to them. The wound is real but manageable.

            > stab the monster
            You nick the evil monster with your sharp dagger, the weapon
            barely breaking skin. It notes the minor damage and dismisses
            it.

            The evil monster retaliates with expert technique, disarming
            you barehanded and sending your sharp dagger clattering away.

            > stab the monster
            You aren't holding the sharp dagger.

            The evil monster bobs and weaves, avoiding your strike
            entirely.

            Then the evil monster's strike meets you solidly and the world
            lurches sideways, as balance becomes a memory rather than a
            fact.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = AttackActionHandler()
        expectNoDifference(
            handler.synonyms,
            [
                .attack, .break, .destroy, .fight, .hit, .kill, .rip,
                .ruin, .shatter, .slay, .smash, .stab, .tear,
            ])
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = AttackActionHandler()
        #expect(handler.requiresLight == true)
    }
}
