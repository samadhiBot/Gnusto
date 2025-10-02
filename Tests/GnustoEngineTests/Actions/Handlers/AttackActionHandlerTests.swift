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
        await mockIO.expectOutput(
            """
            > attack the troll
            With nothing but rage you rush the fearsome beast as his
            gruesome ax gleams cold and ready for the blood you're
            offering.

            The angry beast's defenses crumble! He stands exposed, unable
            to protect himself.

            The angry monster strikes back with his axe but you've already
            moved, a ghost that steel cannot touch.

            > attack the troll
            Your blow bypasses his gruesome axe and lands true, the force
            driving breath from the beast's lungs. The wound is real but
            manageable.

            The grotesque monster whips his axe across in answer--steel
            whispers against skin, leaving a thin signature of pain. The
            cut registers dimly. Blood, but not enough to matter.

            The troll says something, probably uncomplimentary, in his
            guttural tongue.

            > attack the troll
            You slip inside the reach of his bloody axe and drive your
            knuckles hard into the angry monster's body. You see the ripple
            of pain, but his body absorbs it. He remains dangerous.

            The beast's counter with his axe misses completely, the weapon
            whistling through empty space.

            > attack the troll
            You land the decisive hit! The fearsome beast wavers for a
            heartbeat, then collapses into permanent silence.

            > attack the troll
            You throw yourself at the beast despite his nicked axe because
            sometimes fury must answer steel even when flesh cannot win.

            You're too late--the fierce troll is already deceased.
            """
        )
    }

    @Test("ATTACK DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testAttackWithWeaponSyntax() async throws {
        // Given
        let dragon = Item("dragon")
            .name("red dragon")
            .adjectives("terrible", "awesome", "fierce")
            .synonyms("creature", "wyrm")
            .description("A fearsome red dragon.")
            .characterSheet(.boss)
            .in(.startRoom)

        let sword = Item("sword")
            .name("steel sword")
            .description("A sharp steel sword.")
            .isWeapon
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: dragon, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack dragon with sword", times: 3)

        // Then
        await mockIO.expectOutput(
            """
            > attack dragon with sword
            You drive forward with your steel sword seeking its purpose as
            the fierce creature meets you barehanded, flesh against steel
            in the oldest gamble.

            Your steel sword swings wide, and the wyrm avoids your poorly
            aimed strike with ease.

            The awesome creature counters with a force that shatters your
            guard, leaving you exposed to whatever violence comes next.

            > attack dragon with sword
            Direct hit with your steel sword! The creature sways
            dangerously, unable to mount any defense while fighting to stay
            upright.

            The wyrm's lightning-fast counter strikes your wrist, causing
            your steel sword to drop from shocked fingers.

            > attack dragon with sword
            You aren't holding the steel sword.

            Your steel sword finds the fierce wyrm exposed, carving a solid
            wound that draws a grunt of pain. The wound is real but
            manageable.

            Then the wyrm's strike hammers home with the sound of a mallet
            on meat. Something structural fails inside you. First blood
            draws a gasp. You touch the wound, fingers coming away red.
            """
        )
    }

    @Test("FIGHT syntax works")
    func testFightSyntax() async throws {
        // Given
        let orc = Item("orc")
            .name("angry orc")
            .description("A mighty orc warrior.")
            .characterSheet(.strong)
            .in(.startRoom)

        let game = MinimalGame(
            items: orc
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fight the orc", times: 3)

        // Then
        await mockIO.expectOutput(
            """
            > fight the orc
            You close the distance fast with fists ready as the angry
            warrior mirrors your stance, both of you committed to finding
            out who breaks first.

            Your punch connects lightly, leaving perhaps a small bruise. It
            registers the wound with annoyance.

            Then the angry warrior's strike hammers home with the sound of
            a mallet on meat. Something structural fails inside you. First
            blood draws a gasp. You touch the wound, fingers coming away
            red.

            > fight the orc
            Your strike sends the warrior stumbling sideways! It sways
            precariously, barely maintaining its footing.

            The warrior finishes you with nothing but flesh and bone,
            proving that the oldest weapons still kill just as dead.

            ****  You have died  ****

            The curtain falls on this particular act of your existence. But
            all good stories deserve another telling...

            You scored 0 out of a possible 10 points, in 1 moves.

            Would you like to RESTART, RESTORE a saved game, or QUIT?

            >
            """
        )
    }

    @Test("HIT syntax works")
    func testHitSyntax() async throws {
        // Given
        let goblin = Item("goblin")
            .name("sneaky goblin")
            .description("A sneaky goblin.")
            .characterSheet(.weak)
            .in(.startRoom)

        let game = MinimalGame(
            items: goblin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("hit the goblin", times: 3)

        // Then
        await mockIO.expectOutput(
            """
            > hit the goblin
            No weapons needed as you attack with pure violence while the
            sneaky goblin braces for the inevitable collision of flesh and
            bone.

            You catch the sneaky goblin with minimal force, the blow almost
            gentle. It registers the wound with annoyance.

            The sneaky goblin's counter-punch goes wide, rage making the
            strike clumsy and predictable.

            > hit the goblin
            Your final strike lands with devastating force! The sneaky
            goblin drops to its knees, then pitches forward into death.

            > hit the goblin
            You charge with fists raised as the sneaky goblin meets you
            halfway in what will be brutal and personal.

            You're too late--the sneaky goblin is already deceased.
            """
        )
    }

    @Test("KILL syntax works")
    func testKillSyntax() async throws {
        // Given
        let spider = Item("spider")
            .name("giant spider")
            .description("A giant spider.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(items: spider)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kill the giant spider", times: 3)

        // Then
        await mockIO.expectOutput(
            """
            > kill the giant spider
            No weapons needed as you attack with pure violence while the
            giant spider braces for the inevitable collision of flesh and
            bone.

            You catch the giant spider with minimal force, the blow almost
            gentle. It registers the wound with annoyance.

            The giant spider's counter-punch goes wide, rage making the
            strike clumsy and predictable.

            > kill the giant spider
            You drive your bare hands into the giant spider, feeling the
            satisfying thud of impact. The wound is real but manageable.

            The giant spider swings in retaliation but you slip the attack,
            flowing around the violence like water around stone.

            > kill the giant spider
            Your bare-handed assault leaves the giant spider momentarily
            stunned. Blood seeps from the new wound.

            The giant spider crashes forward in response, the impact
            jarring but glancing as you roll with it. The cut registers
            dimly. Blood, but not enough to matter.
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
        await mockIO.expectOutput(
            """
            > attack
            Attack what?
            """
        )
    }

    @Test("Cannot attack target not in scope")
    func testCannotAttackTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteTroll = Item("remoteTroll")
            .name("remote troll")
            .description("A troll in another room.")
            .characterSheet(.default)
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteTroll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack troll")

        // Then
        await mockIO.expectOutput(
            """
            > attack troll
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Cannot attack with weapon not held")
    func testCannotAttackWithWeaponNotHeld() async throws {
        // Given
        let sword = Item("sword")
            .name("steel sword")
            .description("A sharp steel sword.")
            .isWeapon
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: Lab.troll, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack troll with sword")

        // Then
        await mockIO.expectOutput(
            """
            > attack troll with sword
            You aren't holding the steel sword.
            """
        )
    }

    @Test("Requires light to attack")
    func testRequiresLight() async throws {
        // Given: Dark room with character
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack troll")

        // Then
        await mockIO.expectOutput(
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
        let rock = Item("rock")
            .name("large rock")
            .description("A large boulder.")
            .in(.startRoom)

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack rock")

        // Then
        await mockIO.expectOutput(
            """
            > attack rock
            The large rock is immune to your hostility.
            """
        )

        let finalState = await engine.item("rock")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Attack boss character bare-handed is denied")
    func testAttackBossCharacterBareHandedDenied() async throws {
        // Given
        let dragon = Item("dragon")
            .name("red dragon")
            .adjectives("terrible", "awesome", "fierce")
            .synonyms("creature", "wyrm")
            .description("A fearsome red dragon.")
            .characterSheet(.boss)
            .in(.startRoom)

        let game = MinimalGame(
            items: dragon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack the dragon")

        // Then
        await mockIO.expectOutput(
            """
            > attack the dragon
            You attack with nothing but will and bone as the fierce
            creature meets your charge head-on, no weapons, no rules, no
            mercy.

            Your attack misses! Empty space is all you encounter while the
            wyrm watches with amusement.

            The awesome creature counters with a force that shatters your
            guard, leaving you exposed to whatever violence comes next.
            """
        )
    }

    @Test("Attack character with non-weapon")
    func testAttackCharacterWithNonWeapon() async throws {
        // Given
        let bandit = Item("bandit")
            .name("dangerous bandit")
            .description("A dangerous bandit.")
            .characterSheet(.default)
            .in(.startRoom)

        let stick = Item("stick")
            .name("wooden stick")
            .description("A simple wooden stick.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: bandit, stick
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack the bandit with a stick")

        // Then
        await mockIO.expectOutput(
            """
            > attack the bandit with a stick
            Your wooden stick cuts through air toward the dangerous bandit
            who has no steel to answer yours, only the speed of
            desperation.

            You attack with the wooden stick! The dangerous bandit dodges,
            more puzzled than threatened by your choice of weapon.

            In the tangle, the dangerous bandit drives an elbow
            home--sudden pressure that blooms into dull pain. The cut
            registers dimly. Blood, but not enough to matter.
            """
        )
    }

    @Test("Attack character with weapon")
    func testAttackCharacterWithWeapon() async throws {
        // Given
        let monster = Item("monster")
            .name("evil monster")
            .description("An evil monster.")
            .characterSheet(.agile)
            .in(.startRoom)

        let dagger = Item("dagger")
            .name("sharp dagger")
            .description("A sharp dagger.")
            .isWeapon
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: monster, dagger
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack the monster with my dagger", times: 3)

        // Then
        await mockIO.expectOutput(
            """
            > attack the monster with my dagger
            Armed and hungry for violence, you strike with your sharp
            dagger as the evil monster can only dodge and weave against the
            advantage of sharpened metal.

            The evil monster nimbly dodges and twists away from your sharp
            dagger, using speed to compensate for being unarmed.

            The evil monster's counter-strike punches through air, missing
            by the width of good instincts.

            > attack the monster with my dagger
            You nick the evil monster with your sharp dagger, the weapon
            barely breaking skin. It notes the minor damage and dismisses
            it.

            In the tangle, the evil monster drives an elbow home--sudden
            pressure that blooms into dull pain. The cut registers dimly.
            Blood, but not enough to matter.

            > attack the monster with my dagger
            Your sharp dagger swings wide, and the evil monster avoids your
            poorly aimed strike with ease.

            The evil monster pivots and strikes true--impact ripples
            through muscle and bone, stealing balance and breath together.
            You absorb the hit, feeling flesh tear but knowing you can
            endure.
            """
        )
    }

    @Test("Attack enemy with weapon")
    func testAttackEnemyWithWeapon() async throws {
        // Given
        let monster = Item("monster")
            .name("evil monster")
            .description("An evil monster.")
            .characterSheet(.init(isFighting: true))
            .in(.startRoom)

        let dagger = Item("dagger")
            .name("sharp dagger")
            .description("A sharp dagger.")
            .isWeapon
            .isTakable
            .in(.player)

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
        await mockIO.expectOutput(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There is an evil monster here.

            Despite having no weapon, the evil monster charges with
            terrifying resolve! You grip your sharp dagger tighter, knowing
            you'd better use this advantage.

            > attack the monster with my dagger
            Your strike with your sharp dagger grazes the evil monster,
            drawing minimal blood. It registers the wound with annoyance.

            The evil monster's counter-punch goes wide, rage making the
            strike clumsy and predictable.
            """
        )
    }

    @Test("Attack character with unspecified weapon")
    func testAttackCharacterWithUnspecifiedWeapon() async throws {
        // Given
        let monster = Item("monster")
            .name("evil monster")
            .description("An evil monster.")
            .characterSheet(.agile)
            .in(.startRoom)

        let dagger = Item("dagger")
            .name("sharp dagger")
            .description("A sharp dagger.")
            .isWeapon
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: monster, dagger
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("stab the monster", times: 3)

        // Then
        await mockIO.expectOutput(
            """
            > stab the monster
            Armed and hungry for violence, you strike with your sharp
            dagger as the evil monster can only dodge and weave against the
            advantage of sharpened metal.

            The evil monster nimbly dodges and twists away from your sharp
            dagger, using speed to compensate for being unarmed.

            The evil monster's counter-strike punches through air, missing
            by the width of good instincts.

            > stab the monster
            You nick the evil monster with your sharp dagger, the weapon
            barely breaking skin. It notes the minor damage and dismisses
            it.

            In the tangle, the evil monster drives an elbow home--sudden
            pressure that blooms into dull pain. The cut registers dimly.
            Blood, but not enough to matter.

            > stab the monster
            Your sharp dagger swings wide, and the evil monster avoids your
            poorly aimed strike with ease.

            The evil monster pivots and strikes true--impact ripples
            through muscle and bone, stealing balance and breath together.
            You absorb the hit, feeling flesh tear but knowing you can
            endure.
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
