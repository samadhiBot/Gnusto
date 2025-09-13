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
            You attack barehanded against his axe in what might be suicide
            but the violence is already chosen.

            The monster has left himself wide open and completely
            vulnerable to your attack.

            The fearsome beast's retaliatory strike with his axe cuts
            toward you but your body knows how to flow around death.

            > attack the troll
            Your fist finds nothing but air! The creature watches with
            amusement, his ax at the ready.

            In the exchange, his ax slips through to mark you--a stinging
            reminder that the angry beast still has teeth. The wound is
            trivial against your battle fury.

            > attack the troll
            The blow rocks the grotesque monster backward! He stumbles and
            sways fighting desperately for balance.

            The fearsome monster's retaliation with his axe sends you
            stumbling like a drunk, with the world tilting at impossible
            angles.

            > attack the troll
            Your blow bypasses his axe and lands true, the force driving
            breath from the creature's lungs. The blow lands solidly,
            drawing blood. He feels the sting but remains strong.

            The monster's retaliation with his ax tears through your guard,
            and in an instant you're completely exposed.

            > attack the troll
            The brutal exchange ends with your killing blow! The terrible
            monster goes limp and crashes down, utterly still.
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
            Armed and hungry for violence, you strike with your steel sword
            as the wyrm can only dodge and weave against the advantage of
            sharpened metal.

            A disastrous miss--your steel sword cuts through empty air and
            the terrible wyrm effortlessly evades your mistimed attack.

            The wyrm's brutal retaliation breaks through your defenses
            completely, rendering you vulnerable as an opened shell.

            > attack dragon with sword
            Your blow with your steel sword catches the wyrm cleanly,
            tearing flesh and drawing crimson. The blow lands solidly,
            drawing blood. It feels the sting but remains strong.

            Then the wyrm recovers and strikes true. Your jaw takes the
            full force. Blood and fragments of teeth spray the air. First
            blood draws a gasp. You touch the wound, fingers coming away
            red.

            > attack dragon with sword
            Your strike with your steel sword grazes the fierce wyrm,
            drawing minimal blood. The strike lands, but doesn't slow it.

            The wyrm retaliates with raw force that rocks you hard, leaving
            you stumbling through space that won't hold still.
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
            No weapons needed as you attack with pure violence while the
            warrior braces for the inevitable collision of flesh and bone.

            You catch the angry warrior with minimal force, the blow almost
            gentle. The light wound barely seems to register.

            The warrior's brutal retaliation breaks through your defenses
            completely, rendering you vulnerable as an opened shell.

            > fight the orc
            You catch the warrior with minimal force, the blow almost
            gentle. The light wound barely seems to register.

            In the exchange, the warrior lands clean. The world lurches as
            your body absorbs punishment it won't soon forget. The blow
            lands solidly, drawing blood. You feel the sting but remain
            strong.

            > fight the orc
            The blow rocks the warrior backward! It stumbles and sways
            fighting desperately for balance.

            The warrior's brutal retaliation breaks through your defenses
            completely, rendering you vulnerable as an opened shell.
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
            No weapons needed as you attack with pure violence while the
            sneaky goblin braces for the inevitable collision of flesh and
            bone.

            You land a punishing blow to the sneaky goblin, and it grunts
            from the force. The blow lands solidly, drawing blood. It feels
            the sting but remains strong.

            In the scramble, the sneaky goblin throws a desperate hook that
            barely connects, all motion and no mass. The graze is utterly
            trivial. You barely register it happened.

            > hit the goblin
            The brutal exchange ends with your killing blow! The sneaky
            goblin goes limp and crashes down, utterly still.

            > hit the goblin
            No weapons needed as you attack with pure violence while the
            sneaky goblin braces for the inevitable collision of flesh and
            bone.

            You're too late--the sneaky goblin is already deceased.
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

        let game = MinimalGame(
            items: spider
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kill the giant spider", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kill the giant spider
            No weapons needed as you attack with pure violence while the
            giant spider braces for the inevitable collision of flesh and
            bone.

            You catch the giant spider with minimal force, the blow almost
            gentle. The light wound barely seems to register.

            The giant spider's counter-punch goes wide, rage making the
            strike clumsy and predictable.

            > kill the giant spider
            You catch the giant spider with minimal force, the blow almost
            gentle. The light wound barely seems to register.

            The giant spider's retaliatory strike comes fast but you're
            faster, sidestepping the violence with practiced grace.

            > kill the giant spider
            You land a punishing blow to the giant spider, and it grunts
            from the force. You see the ripple of pain, but its body
            absorbs it. It remains dangerous.

            In the tangle, the giant spider drives an elbow home--sudden
            pressure that blooms into dull pain. The wound is trivial
            against your battle fury.
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
            You cannot reach any such thing from here.
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
            The darkness here is absolute, consuming all light and hope of
            sight.
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
            The large rock is immune to your hostility.
            """
        )

        let finalState = try await engine.item("rock")
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
            No weapons needed as you attack with pure violence while the
            wyrm braces for the inevitable collision of flesh and bone.

            The terrible wyrm catches your fist, stopping your attack cold.

            The creature's brutal retaliation breaks through your defenses
            completely, rendering you vulnerable as an opened shell.
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
            Armed and hungry for violence, you strike with your wooden
            stick as the dangerous bandit can only dodge and weave against
            the advantage of sharpened metal.

            The wooden stick wasn't designed for combat, but you wield it
            against the dangerous bandit regardless!

            In the tangle, the dangerous bandit drives an elbow
            home--sudden pressure that blooms into dull pain. The wound is
            trivial against your battle fury.
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
            Armed and hungry for violence, you strike with your sharp
            dagger as the evil monster can only dodge and weave against the
            advantage of sharpened metal.

            Your strike with your sharp dagger grazes the evil monster,
            drawing minimal blood. The light wound barely seems to
            register.

            In the exchange, the evil monster lands clean. The world
            lurches as your body absorbs punishment it won't soon forget.
            The blow lands solidly, drawing blood. You feel the sting but
            remain strong.

            > attack the monster with my dagger
            Your strike with your sharp dagger grazes the evil monster,
            drawing minimal blood. The light wound barely seems to
            register.

            The evil monster's lightning-fast counter strikes your wrist,
            causing your sharp dagger to drop from shocked fingers.

            > attack the monster with my dagger
            You aren't holding the sharp dagger.

            Your strike with your sharp dagger grazes the evil monster,
            drawing minimal blood. The strike lands, but doesn't slow it.

            The evil monster retaliates with raw force that rocks you hard,
            leaving you stumbling through space that won't hold still.
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

            There is an evil monster here.

            Despite having no weapon, the evil monster charges with
            terrifying resolve! You grip your sharp dagger tighter, knowing
            you'd better use this advantage.

            > attack the monster with my dagger
            Your blow with your sharp dagger catches the evil monster
            cleanly, tearing flesh and drawing crimson. The blow lands
            solidly, drawing blood. It feels the sting but remains strong.

            In the tangle, the evil monster drives an elbow home--sudden
            pressure that blooms into dull pain. The wound is trivial
            against your battle fury.
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
            Armed and hungry for violence, you strike with your sharp
            dagger as the evil monster can only dodge and weave against the
            advantage of sharpened metal.

            Your strike with your sharp dagger grazes the evil monster,
            drawing minimal blood. The light wound barely seems to
            register.

            In the exchange, the evil monster lands clean. The world
            lurches as your body absorbs punishment it won't soon forget.
            The blow lands solidly, drawing blood. You feel the sting but
            remain strong.

            > stab the monster
            Your strike with your sharp dagger grazes the evil monster,
            drawing minimal blood. The light wound barely seems to
            register.

            The evil monster's lightning-fast counter strikes your wrist,
            causing your sharp dagger to drop from shocked fingers.

            > stab the monster
            You aren't holding the sharp dagger.

            The evil monster catches your fist, stopping your attack cold.

            The evil monster retaliates with raw force that rocks you hard,
            leaving you stumbling through space that won't hold still.
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
