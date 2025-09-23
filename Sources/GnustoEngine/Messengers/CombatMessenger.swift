import Foundation

// swiftlint:disable file_length function_body_length line_length type_body_length

/// A messenger class that provides combat-related narrative text generation.
///
/// `CombatMessenger` extends `StandardMessenger` to provide specialized messaging
/// for combat scenarios in a text-based game. It generates dynamic, contextual
/// descriptions for various combat situations including attacks, outcomes, and
/// status effects.
///
/// The class uses weapon state and combat context to generate appropriate narrative
/// text that varies based on whether participants are armed or unarmed, creating
/// immersive combat descriptions.
///
/// `StandardMessenger`, `CombatMessenger` and its subclasses are forced to declare
/// `@unchecked Sendable` because they are open classes.
open class CombatMessenger: StandardMessenger, @unchecked Sendable {

    // MARK: - Opening Attacks

    /// An enemy attacks the player.
    open func enemyAttacks(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let yourWeapon = await playerWeapon?.alias(.withPossessiveAdjective)

        return switch (yourWeapon, itsWeapon) {
        case (.some(let yourWeapon), .some(let itsWeapon)):
            // Player WITH weapon, Enemy WITH weapon
            oneOf(
                """
                \(theEnemy) lunges with \(itsWeapon) raised to kill! You barely raise
                \(yourWeapon) in time to block, and the collision sends shockwaves through
                your arms.
                """,
                """
                \(theEnemy) attacks! \(itsWeapon) cuts through the air toward your face!
                Desperately you parry with \(yourWeapon), and the impact jars every bone
                in your body.
                """,
                """
                \(theEnemy) explodes into motion, \(itsWeapon) seeking your heart! You raise
                \(yourWeapon) on pure instinct, and the clash reverberates through you.
                """,
                """
                Without warning \(theEnemy) lashes out with \(itsWeapon) in a blur of lethal
                intent! You desperately twist \(yourWeapon) into a guard that saves your life.
                """,
                """
                Without warning \(theEnemy) charges! The world narrows to this moment--
                \(yourWeapon) against \(itsWeapon), with everything hanging in the balance.
                """
            )
        case (.none, .some(let itsWeapon)):
            // Player WITHOUT weapon, Enemy WITH weapon
            oneOf(
                """
                \(theEnemy) attacks with \(itsWeapon) while you stand defenseless! You throw
                yourself sideways as death whispers past your ribs.
                """,
                """
                \(theEnemy) cuts the air with \(itsWeapon)! \(enemyRef.subjectPronoun) presses
                the assault while you scramble backward, weaponless and terrified.
                """,
                """
                To your horror, \(theEnemy) swings \(itsWeapon) at your exposed form! You duck
                and weave with nothing but desperate speed keeping you alive.
                """,
                """
                \(theEnemy) drives forward with \(itsWeapon), and you have nothing! Pure
                adrenaline fuels your dodge as the weapon passes close enough to feel.
                """,
                """
                \(itsWeapon) flashes as \(theEnemy) attacks! Unarmed, you can only twist
                away and pray your reflexes hold out.
                """
            )
        case (.some(let yourWeapon), .none):
            // Player WITH weapon, Enemy WITHOUT weapon
            oneOf(
                """
                \(theEnemy) rushes you with savage fury! You swing \(yourWeapon) up as
                \(enemyRef.subjectPronoun) \(enemyRef.verb("barrels")) in, desperately
                hoping your reach can blunt \(enemyRef.possessiveAdjective) raw aggression.
                """,
                """
                Despite having no weapon, \(theEnemy) charges with terrifying resolve! You
                grip \(yourWeapon) tighter, knowing you'd better use this advantage.
                """,
                """
                \(theEnemy) comes at you unarmed but fearless! You level \(yourWeapon) at
                \(enemyRef.possessiveAdjective) approach--will your weapon stop such
                determination?
                """,
                """
                Weaponless, \(theEnemy) attacks with primal violence! You raise \(yourWeapon)
                to meet \(enemyRef.subjectPronoun), but in a heartbeat the gap is gone and
                \(enemyRef.subjectPronoun) is upon you.
                """,
                """
                \(theEnemy) abandons caution and lunges straight at you! \(yourWeapon)
                suddenly feels less reassuring as the distance vanishes.
                """
            )
        case (.none, .none):
            // Player WITHOUT weapon, Enemy WITHOUT weapon
            oneOf(
                """
                \(theEnemy) charges with violent intent! You meet \(enemyRef.objectPronoun)
                halfway--no weapons, no mercy, just the brutal arithmetic of survival.
                """,
                """
                In a moment of raw violence, \(theEnemy) comes at you with nothing but fury!
                You raise your fists, knowing this will hurt regardless of who wins.
                """,
                """
                \(theEnemy) attacks with pure murderous intent! You brace yourself for
                the impact, guard up, ready for the worst kind of fight.
                """,
                """
                No weapons between you--just \(theEnemy.possessive) aggression and your
                desperation! You collide in a tangle of strikes and blocks.
                """,
                """
                \(theEnemy) rushes in for close combat! With only your bare hands, you meet
                \(enemyRef.possessiveAdjective) assault head-on--this will be messy.
                """
            )
        }
    }

    /// The player attacks an enemy.
    open func playerAttacks(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let yourWeapon = await playerWeapon?.alias(.withPossessiveAdjective)

        return switch (yourWeapon, itsWeapon) {
        case (.some(let yourWeapon), .some(let itsWeapon)):
            // Player WITH weapon, Enemy WITH weapon
            oneOf(
                "You surge forward with \(yourWeapon) seeking blood as \(theEnemy) brings \(itsWeapon) up to meet the violence you've chosen.",
                "No more waiting as you attack with \(yourWeapon) raised and \(theEnemy) responds with \(itsWeapon), two weapons now committed to drawing blood.",
                "You drive in hard with \(yourWeapon) while \(theEnemy) pivots with \(itsWeapon) ready, both of you past the point of retreat.",
                "Your blood sings as \(yourWeapon) cuts toward \(theEnemy) who barely gets \(itsWeapon) into position before impact.",
                "You explode into motion with \(yourWeapon) hunting flesh as \(theEnemy) meets your charge with \(itsWeapon), the dance of death begun."
            )
        case (.none, .some(let itsWeapon)):
            // Player WITHOUT weapon, Enemy WITH weapon
            oneOf(
                "Desperate and weaponless, you charge at \(theEnemy) with only fists while \(enemyRef.subjectPronoun) raises \(itsWeapon) almost lazily to meet your futile assault.",
                "You attack barehanded against \(itsWeapon) in what might be suicide but the violence is already chosen.",
                "With nothing but rage you rush \(theEnemy) as \(itsWeapon) gleams cold and ready for the blood you're offering.",
                "You throw yourself at \(theEnemy) despite \(itsWeapon) because sometimes fury must answer steel even when flesh cannot win.",
                "Weaponless, you advance on \(theEnemy) who grips \(itsWeapon) tighter, ready to teach you what violence really means."
            )
        case (.some(let yourWeapon), .none):
            // Player WITH weapon, Enemy WITHOUT weapon
            oneOf(
                "You advance with \(yourWeapon) ready to taste blood while \(theEnemy) has nothing but rage to meet steel.",
                "Armed and hungry for violence, you strike with \(yourWeapon) as \(theEnemy) can only dodge and weave against the advantage of sharpened metal.",
                "You press forward with \(yourWeapon) leading the way toward flesh while \(theEnemy) backs away, unarmed but still dangerous as any cornered thing.",
                "\(yourWeapon) cuts through air toward \(theEnemy) who has no steel to answer yours, only the speed of desperation.",
                "You drive forward with \(yourWeapon) seeking its purpose as \(theEnemy) meets you barehanded, flesh against steel in the oldest gamble."
            )
        case (.none, .none):
            // Player WITHOUT weapon, Enemy WITHOUT weapon
            oneOf(
                "You charge with fists raised as \(theEnemy) meets you halfway in what will be brutal and personal.",
                "No weapons needed as you attack with pure violence while \(theEnemy) braces for the inevitable collision of flesh and bone.",
                "You close the distance fast with fists ready as \(theEnemy) mirrors your stance, both of you committed to finding out who breaks first.",
                "Barehanded, you commit to the assault as \(theEnemy) accepts the challenge with equal violence promised.",
                "You attack with nothing but will and bone as \(theEnemy) meets your charge head-on, no weapons, no rules, no mercy."
            )
        }
    }

    // MARK: - Player Attack Outcomes

    /// Player kills the enemy outright.
    open func enemySlain(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?,
        damage: Int
    ) async -> String {
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let yourWeapon = await playerWeapon?.alias(.withPossessiveAdjective)

        return switch (yourWeapon, itsWeapon) {
        case (.some(let yourWeapon), .some(let itsWeapon)):
            // Player WITH weapon, Enemy WITH weapon
            oneOf(
                """
                \(yourWeapon) finds the fatal opening! \(theEnemy) drops \(itsWeapon)
                and crumples, all fight extinguished forever.
                """,
                """
                You drive \(yourWeapon) home with lethal precision! \(itsWeapon) falls
                from \(theEnemy.possessive) grasp as life leaves \(enemyRef.objectPronoun).
                """,
                """
                The final strike--\(yourWeapon) defeats \(theEnemy) decisively!
                \(enemyRef.objectPronoun) drops \(itsWeapon), collapses, and moves no more.
                """,
                """
                \(yourWeapon) breaks through \(theEnemy.possessive) defense!
                \(enemyRef.subjectPronoun) \(enemyRef.verb("staggers")), \(itsWeapon)
                clattering away as \(enemyRef.subjectPronoun) \(enemyRef.verb("falls"))
                to the ground lifeless.
                """,
                """
                One perfect moment--\(yourWeapon) slips past \(itsWeapon)! \(theEnemy)
                goes rigid, then topples forward into stillness.
                """
            )
        case (.none, .some(let itsWeapon)):
            // Player WITHOUT weapon, Enemy WITH weapon
            oneOf(
                """
                Against all odds, your desperate strike proves fatal! \(theEnemy)
                drops \(itsWeapon) in shock, then follows it to the ground.
                """,
                """
                Your bare hands find the impossible opening! \(itsWeapon) slips
                from \(theEnemy.possessive) grasp as \(enemyRef.subjectPronoun)
                \(enemyRef.verb("falls")), defeated.
                """,
                """
                Weaponless but victorious--your final blow lands! \(theEnemy) releases
                \(itsWeapon) and collapses into stillness.
                """,
                """
                You overcome \(enemyRef.possessiveAdjective) armed advantage with one perfect strike! \(theEnemy)
                and \(itsWeapon) both crash to the ground.
                """,
                """
                Your unarmed assault proves lethal! \(theEnemy) staggers, \(itsWeapon)
                forgotten, before dropping lifeless.
                """
            )
        case (.some(let yourWeapon), .none):
            // Player WITH weapon, Enemy WITHOUT weapon
            oneOf(
                """
                \(yourWeapon) delivers the killing blow! \(theEnemy) falls backward,
                \(enemyRef.possessiveAdjective) unarmed defense finally overwhelmed.
                """,
                """
                You strike true with \(yourWeapon)! \(theEnemy) drops without a sound,
                weaponless to the end.
                """,
                """
                Your armed advantage proves decisive--\(yourWeapon) ends it! \(theEnemy)
                crumples, having fought barehanded and lost.
                """,
                """
                The final thrust of \(yourWeapon) is devastating! \(theEnemy) collapses,
                unable to defend without a weapon.
                """,
                """
                \(yourWeapon) finds its mark at last! \(theEnemy) staggers once,
                then falls forever silent.
                """
            )
        case (.none, .none):
            // Player WITHOUT weapon, Enemy WITHOUT weapon
            oneOf(
                """
                Your final strike lands with devastating force! \(theEnemy) drops to \(enemyRef.possessiveAdjective)
                knees, then pitches forward into death.
                """,
                """
                The brutal exchange ends with your killing blow! \(theEnemy) goes limp
                and crashes down, utterly still.
                """,
                """
                You land the decisive hit! \(theEnemy) wavers for a heartbeat, then
                collapses into permanent silence.
                """,
                """
                Your bare hands deliver death! \(theEnemy) crumples without ceremony,
                the fight conclusively ended.
                """,
                """
                The last blow is yours! \(theEnemy) staggers back, eyes going vacant,
                before falling motionless.
                """
            )
        }
    }

    /// Player knocks enemy unconscious.
    open func enemyUnconscious(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let yourWeapon = await playerWeapon?.alias(.withPossessiveAdjective)

        return switch (yourWeapon, itsWeapon) {
        case (.some(let yourWeapon), .some(let itsWeapon)):
            // Player WITH weapon, Enemy WITH weapon
            oneOf(
                """
                \(yourWeapon) connects with stunning force! \(itsWeapon) drops from
                nerveless fingers as \(theEnemy) collapses senseless.
                """,
                """
                You bring \(yourWeapon) down hard! \(theEnemy) releases \(itsWeapon) and
                crumples, consciousness extinguished.
                """,
                """
                A perfect knockout blow with \(yourWeapon)! \(theEnemy.possessive) eyes roll back,
                \(itsWeapon) clattering away as \(enemyRef.subjectPronoun)
                \(enemyRef.verb("falls")).
                """,
                """
                \(yourWeapon) delivers crushing impact! \(theEnemy) sways drunkenly,
                drops \(itsWeapon), then crashes down unconscious.
                """,
                """
                You strike with \(yourWeapon) at just the right angle! \(itsWeapon) slips
                from \(theEnemy.possessive) grasp as darkness takes \(enemyRef.objectPronoun).
                """
            )
        case (.none, .some(let itsWeapon)):
            // Player WITHOUT weapon, Enemy WITH weapon
            oneOf(
                """
                Your desperate strike finds the sweet spot! \(theEnemy) drops \(itsWeapon)
                and follows it down, out cold.
                """,
                """
                Against the odds, you knock \(enemyRef.objectPronoun) senseless! \(itsWeapon) falls from limp
                fingers as \(theEnemy) collapses.
                """,
                """
                Your bare-handed blow is devastating! \(theEnemy) releases \(itsWeapon)
                and crumples, lights out.
                """,
                """
                You land the perfect knockout despite being unarmed! \(theEnemy) and
                \(itsWeapon) both hit the ground hard.
                """,
                """
                Your fist finds its mark! \(theEnemy) loses grip on \(itsWeapon) as
                unconsciousness claims \(enemyRef.objectPronoun) completely.
                """
            )
        case (.some(let yourWeapon), .none):
            // Player WITH weapon, Enemy WITHOUT weapon
            oneOf(
                """
                \(yourWeapon) knocks \(theEnemy) cold! \(enemyRef.subjectPronoun) drop like a stone,
                out before \(enemyRef.subjectPronoun) \(enemyRef.verb("hits")) the ground.
                """,
                """
                You swing \(yourWeapon) with knockout power! \(theEnemy) staggers once,
                then collapses into oblivion.
                """,
                """
                The blow from \(yourWeapon) is perfectly placed! \(theEnemy.possessive)
                legs buckle as consciousness abandons \(enemyRef.objectPronoun).
                """,
                """
                \(yourWeapon) connects solidly! \(theEnemy) goes limp and crashes
                down, thoroughly unconscious.
                """,
                """
                You deliver a crushing strike with \(yourWeapon)! \(theEnemy) wavers,
                then topples senseless to the ground.
                """
            )
        case (.none, .none):
            // Player WITHOUT weapon, Enemy WITHOUT weapon
            oneOf(
                """
                Your strike lands with knockout precision! \(theEnemy) drops instantly,
                consciousness snuffed like a candle.
                """,
                """
                You deliver the perfect blow! \(theEnemy) staggers drunkenly, then
                crashes down in a senseless heap.
                """,
                """
                Your fist connects with devastating effect! \(theEnemy.possessive) eyes glaze
                before \(enemyRef.subjectPronoun) \(enemyRef.verb("crumples")) unconscious.
                """,
                """
                The impact is decisive! \(theEnemy) goes rigid, then collapses bonelessly
                to the ground, out cold.
                """,
                """
                You land a crushing blow! \(theEnemy) sways for a moment, then topples
                backward into complete oblivion.
                """
            )
        }
    }

    /// Enemy drop \(enemyRef.possessiveAdjective) weapon, either disarmed by the player, or by fumbling on a critical miss
    /// and dropping \(enemyRef.possessiveAdjective) weapon.
    open func enemyDisarmed(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy,
        wasFumble: Bool
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon.withPossessiveAdjective(for: enemy)
        let yourWeapon = await playerWeapon?.alias(.withPossessiveAdjective)

        return switch (yourWeapon, wasFumble) {
        case (.some(let yourWeapon), true):
            // Enemy fumbles (with player weapon)
            oneOf(
                """
                \(theEnemy) swings wild and loses \(enemyRef.possessiveAdjective) grip!
                \(itsWeapon) flies from clumsy fingers as you press with \(yourWeapon).
                """,
                """
                Overextending badly, \(theEnemy) fumbles \(itsWeapon)! It clatters away
                as you advance with \(yourWeapon) ready.
                """,
                """
                \(theEnemy) mistimes the attack completely! \(itsWeapon) slips free and
                bounces away while you hold \(yourWeapon) steady.
                """,
                """
                In a critical error, \(theEnemy) loses control of \(itsWeapon)! You watch it
                spin away as you grip \(yourWeapon) tighter.
                """,
                """
                \(theEnemy) commits too hard and \(itsWeapon) goes flying! You shift
                \(yourWeapon) to capitalize on \(enemyRef.possessiveAdjective) mistake.
                """
            )
        case (.some(let yourWeapon), false):
            // Player WITH weapon, Enemy disarmed by player
            oneOf(
                """
                \(yourWeapon) strikes perfectly! \(itsWeapon) flies from \(theEnemy.possessive)
                grasp, spinning away into darkness.
                """,
                """
                You hook \(itsWeapon) with \(yourWeapon) and wrench it free! \(theEnemy)
                stumbles back, suddenly defenseless.
                """,
                """
                A decisive blow from \(yourWeapon) sends \(itsWeapon) clattering away!
                \(theEnemy) stares at empty hands in shock.
                """,
                """
                \(yourWeapon) connects with brutal precision! \(theEnemy.possessive) grip fails
                and \(itsWeapon) skitters across the ground.
                """,
                """
                You strike \(itsWeapon) from \(theEnemy.possessive) control with \(yourWeapon)!
                Panic flashes as \(enemyRef.subjectPronoun) \(enemyRef.verb("realizes")) \(enemyRef.subjectPronoun)'re disarmed.
                """
            )
        case (.none, true):
            // Enemy fumbles (without player weapon)
            oneOf(
                """
                \(theEnemy) swings wild and loses grip! \(itsWeapon) flies from clumsy
                fingers as you dodge aside.
                """,
                """
                Overextending badly, \(theEnemy) fumbles \(itsWeapon)! It clatters away
                while you circle for advantage.
                """,
                """
                \(theEnemy) mistimes the attack completely! \(itsWeapon) slips free and
                bounces out of reach.
                """,
                """
                In a critical error, \(theEnemy) loses control of \(itsWeapon)!
                You watch it tumble away, suddenly hopeful.
                """,
                """
                \(theEnemy) commits too hard and \(itsWeapon) goes flying! The battlefield
                just shifted in your favor.
                """
            )
        case (.none, false):
            // Player WITHOUT weapon, Enemy disarmed by player
            oneOf(
                """
                Your desperate grab succeeds! You tear \(itsWeapon) from \(theEnemy.possessive)
                grip and it tumbles away.
                """,
                """
                With surprising strength, you wrench \(itsWeapon) free! \(theEnemy)
                recoils, suddenly weaponless.
                """,
                """
                You strike at \(enemyRef.possessiveAdjective) grip with perfect timing!
                \(itsWeapon) drops from \(theEnemy.possessive) shocked grasp.
                """,
                """
                Your bare hands find the pressure point! \(theEnemy) loses hold of
                \(itsWeapon) as it tumbles away.
                """,
                """
                Against all odds, you knock \(itsWeapon) from \(enemyRef.possessiveAdjective)
                control! \(theEnemy) backs away, dangerously exposed.
                """
            )
        }
    }

    /// Player's attack causes enemy to stagger, reducing \(enemyRef.possessiveAdjective)
    /// combat effectiveness.
    open func enemyStaggers(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let yourWeapon = await playerWeapon?.alias(.withPossessiveAdjective)

        return switch (yourWeapon, itsWeapon) {
        case (.some(let yourWeapon), .some(let itsWeapon)):
            // Player WITH weapon, Enemy WITH weapon
            oneOf(
                """
                \(yourWeapon) finds its mark! \(theEnemy) staggers back, \(itsWeapon) wavering as
                \(enemyRef.subjectPronoun) \(enemyRef.verb("struggles")) to maintain balance.
                """,
                """
                The impact sends \(theEnemy) reeling! \(enemyRef.subjectPronoun)
                \(enemyRef.verb("clutches", "clutch")) \(itsWeapon) desperately
                while fighting to stay upright.
                """,
                """
                \(theEnemy) stumbles from your strike! \(enemyRef.possessiveAdjective) grip
                on \(itsWeapon) loosens as \(enemyRef.subjectPronoun) \(enemyRef.verb("fights"))
                to regain \(enemyRef.possessiveAdjective) footing.
                """,
                """
                \(yourWeapon) connects hard! \(theEnemy) sways dangerously, \(itsWeapon)
                dropping low as \(enemyRef.subjectPronoun) \(enemyRef.verb("reels")) from the blow.
                """,
                """
                A direct hit! \(theEnemy) staggers sideways, barely keeping hold of \(itsWeapon)
                as the world spins around \(enemyRef.objectPronoun).
                """
            )

        case (.none, .some(let itsWeapon)):
            // Player WITHOUT weapon, Enemy WITH weapon
            oneOf(
                """
                Your bare fist connects! \(theEnemy) staggers back, \(itsWeapon) swaying
                wildly as \(enemyRef.subjectPronoun) \(enemyRef.verb("tries", "try"))
                to stay standing.
                """,
                """
                The unarmed strike lands true! \(theEnemy) reels backward, nearly dropping
                \(itsWeapon) in \(enemyRef.possessiveAdjective) disorientation.
                """,
                """
                Your blow sends \(theEnemy) stumbling! \(enemyRef.subjectPronoun) struggle
                to raise \(itsWeapon) while fighting for balance.
                """,
                """
                Impact! \(theEnemy) sways drunkenly, \(itsWeapon) hanging loose as
                \(enemyRef.subjectPronoun) \(enemyRef.verb("fights")) to stay upright.
                """,
                """
                \(theEnemy) staggers from your strike! \(enemyRef.possessiveAdjective)
                \(itsWeapon) wavers dangerously as \(enemyRef.subjectPronoun)
                \(enemyRef.verb("struggles")) to recover.
                """
            )

        case (.some(let yourWeapon), .none):
            // Player WITH weapon, Enemy WITHOUT weapon
            oneOf(
                """
                \(yourWeapon) strikes true! \(theEnemy) staggers backward, arms
                windmilling as \(enemyRef.subjectPronoun) \(enemyRef.verb("fights")) for balance.
                """,
                """
                The blow lands hard! \(theEnemy) stumbles sideways, defenseless and
                struggling to stay on \(enemyRef.possessiveAdjective) feet.
                """,
                """
                \(theEnemy) reels from \(yourWeapon)! \(enemyRef.subjectPronoun)
                stagger drunkenly, completely off-balance.
                """,
                """
                Direct hit with \(yourWeapon)! \(theEnemy) sways dangerously, unable
                to mount any defense while fighting to stay upright.
                """,
                """
                Your strike sends \(theEnemy) stumbling! Unarmed and unsteady,
                \(enemyRef.subjectPronoun) can barely maintain
                \(enemyRef.possessiveAdjective) footing.
                """
            )

        case (.none, .none):
            // Player WITHOUT weapon, Enemy WITHOUT weapon
            oneOf(
                """
                Your fist connects solidly! \(theEnemy) staggers back, swaying like
                a tree in a storm.
                """,
                """
                The blow rocks \(theEnemy) backward! \(enemyRef.subjectPronoun)
                \(enemyRef.verb("stumbles and sways", "stumble and sway"))
                fighting desperately for balance.
                """,
                """
                Impact! \(theEnemy) reels from your strike, feet shuffling frantically
                to stay upright.
                """,
                """
                \(theEnemy) staggers from your hit! Arms flailing, \(enemyRef.subjectPronoun)
                \(enemyRef.verb("struggles")) to regain \(enemyRef.possessiveAdjective) equilibrium.
                """,
                """
                Your strike sends \(theEnemy) stumbling sideways! \(enemyRef.subjectPronoun)
                \(enemyRef.verb("sways")) precariously, barely maintaining
                \(enemyRef.possessiveAdjective) footing.
                """
            )
        }
    }

    /// Player's attack causes enemy to hesitate, creating an opening for follow-up actions.
    open func enemyHesitates(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let yourWeapon = await playerWeapon?.alias(.withPossessiveAdjective)

        return switch (yourWeapon, itsWeapon) {
        case (.some(let yourWeapon), .some(let itsWeapon)):
            // Player WITH weapon, Enemy WITH weapon
            oneOf(
                """
                Your ferocious assault with \(yourWeapon) causes \(theEnemy) to hesitate!
                \(itsWeapon) wavers as doubt creeps into \(enemyRef.possessiveAdjective) stance.
                """,
                """
                \(theEnemy) falters before \(yourWeapon)! For a crucial moment, \(itsWeapon) drops
                as \(enemyRef.subjectPronoun) \(enemyRef.verb("reconsiders")) the fight.
                """,
                """
                Your aggressive advance with \(yourWeapon) gives \(theEnemy) pause!
                \(enemyRef.subjectPronoun) \(enemyRef.verb("grips")) \(itsWeapon) uncertainly.
                """,
                """
                Uncertainty flashes in \(theEnemy.possessive) eyes! \(yourWeapon)
                has shaken \(enemyRef.possessiveAdjective) confidence.
                """,
                """
                \(theEnemy) pulls back, suddenly defensive! Your mastery of \(yourWeapon) makes
                \(enemyRef.objectPronoun) question \(enemyRef.possessiveAdjective) chances.
                """
            )

        case (.none, .some(let itsWeapon)):
            // Player WITHOUT weapon, Enemy WITH weapon
            oneOf(
                """
                Your fearless unarmed assault gives \(theEnemy) pause! Even with \(itsWeapon),
                \(enemyRef.subjectPronoun) \(enemyRef.verb("hesitates")) before such boldness.
                """,
                """
                \(theEnemy) falters, confused by your bare-handed aggression! \(itsWeapon) drops
                slightly in \(enemyRef.possessiveAdjective) uncertainty.
                """,
                """
                Your reckless courage gives \(theEnemy) pause! Despite holding \(itsWeapon),
                \(enemyRef.subjectPronoun) \(enemyRef.verb("pulls")) back warily.
                """,
                """
                Surprisingly, \(theEnemy) hesitates! Your weaponless fury raises some doubt
                in \(enemyRef.reflexivePronoun), even with \(itsWeapon) in hand.
                """,
                """
                \(theEnemy) wavers before your assault! The mad bravery of fighting
                unarmed against \(itsWeapon) gives \(enemyRef.objectPronoun) pause.
                """
            )

        case (.some(let yourWeapon), .none):
            // Player WITH weapon, Enemy WITHOUT weapon
            oneOf(
                """
                \(theEnemy) hesitates before \(yourWeapon)! The threat of armed
                violence makes \(enemyRef.objectPronoun) reconsider.
                """,
                """
                \(yourWeapon) gives \(theEnemy) serious pause! Unarmed,
                \(enemyRef.subjectPronoun) suddenly \(enemyRef.verb("questions"))
                this confrontation.
                """,
                """
                \(theEnemy) pulls back from \(yourWeapon)! Doubt replaces
                \(enemyRef.possessiveAdjective) earlier confidence.
                """,
                """
                Facing \(yourWeapon), \(theEnemy) falters! \(enemyRef.subjectPronoun)
                \(enemyRef.verb("takes")) an uncertain step backward.
                """,
                """
                \(theEnemy) wavers, intimidated by \(yourWeapon)! The armed advantage
                clearly shakes \(enemyRef.possessiveAdjective) resolve.
                """
            )

        case (.none, .none):
            // Player WITHOUT weapon, Enemy WITHOUT weapon
            oneOf(
                """
                Your fierce attack causes \(theEnemy) to hesitate! \(enemyRef.subjectPronoun)
                \(enemyRef.verb("pulls")) back, suddenly uncertain about continuing.
                """,
                """
                \(theEnemy) falters before your aggression! Doubt creeps into
                \(enemyRef.possessiveAdjective) fighting stance.
                """,
                """
                Your relentless assault gives \(theEnemy) pause! \(enemyRef.subjectPronoun)
                \(enemyRef.verb("steps")) back, reconsidering the wisdom of this fight.
                """,
                """
                \(theEnemy) wavers, thrown off by your intensity! The hesitation
                creates a perfect opening.
                """,
                """
                Uncertainty grips \(theEnemy)! Your savage determination makes
                \(enemyRef.objectPronoun) question this combat.
                """
            )
        }
    }

    /// Player's attack leaves enemy vulnerable to subsequent attacks.
    open func enemyVulnerable(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))

        return switch itsWeapon {
        case .some(let itsWeapon):
            // Enemy WITH weapon
            oneOf(
                """
                \(theEnemy.possessive) guard drops! \(itsWeapon) swings wide, leaving
                \(enemyRef.objectPronoun) completely exposed to your next move.
                """,
                """
                A perfect opening! \(theEnemy) overextends with \(itsWeapon), leaving
                \(enemyRef.reflexivePronoun) wide open for a counterstrike.
                """,
                """
                \(theEnemy) is off-balance! \(itsWeapon) is out of position, and
                \(enemyRef.subjectPronoun) cannot recover in time.
                """,
                """
                You've created an opening! \(itsWeapon) is too low,
                \(enemyRef.possessiveAdjective) defenses completely compromised.
                """,
                """
                \(theEnemy) leaves \(enemyRef.reflexivePronoun) exposed! A critical gap
                in \(enemyRef.possessiveAdjective) defense with \(itsWeapon)
                renders \(enemyRef.objectPronoun) vulnerable.
                """
            )
        case .none:
            // Enemy WITHOUT weapon
            oneOf(
                """
                \(theEnemy.possessive) defenses crumble! \(enemyRef.subjectPronoun)
                \(enemyRef.verb("stands")) exposed, unable to protect \(enemyRef.reflexivePronoun).
                """,
                """
                \(theEnemy) has left \(enemyRef.reflexivePronoun) wide open and completely
                vulnerable to your attack.
                """,
                """
                Perfect opportunity appears! \(theEnemy) is off-balance and defenseless,
                a sitting target for your next move.
                """,
                """
                \(theEnemy) drops \(enemyRef.possessiveAdjective) guard completely!
                \(enemyRef.subjectPronoun)\(enemyRef.verb("'s", "'re")) exposed and unable
                to defend against what comes next.
                """,
                """
                You've broken through! \(theEnemy) stands vulnerable, all
                \(enemyRef.possessiveAdjective) defenses shattered and useless.
                """
            )
        }
    }

    /// Player deals critical damage to enemy.
    open func enemyCriticallyWounded(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?,
        damage: Int
    ) async -> String {
        let enemyHealth = await enemy.characterSheet.healthCondition
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let yourWeapon = await playerWeapon?.alias(.withPossessiveAdjective)

        // Assess the enemy's overall condition after critical damage
        let conditionReport =
            switch enemyHealth {
            case .critical, .dead:
                oneOf(
                    """
                    \(enemyRef.possessiveAdjective) body is shutting down, organ by organ.
                    One more strike will end it.
                    """,
                    """
                    Death has \(enemyRef.objectPronoun) now. The body continues its motions
                    but the outcome is written.
                    """,
                    """
                    The light is leaving \(enemyRef.possessiveAdjective) eyes. Blood pools
                    beneath \(enemyRef.objectPronoun), too much to survive.
                    """,
                    """
                    \(enemyRef.subjectPronoun) stands only by habit. The next blow will drop
                    \(enemyRef.objectPronoun) forever.
                    """,
                    """
                    The damage is mortal. \(enemyRef.subjectPronoun) bleeds from places
                    that cannot be staunched.
                    """
                )
            case .badlyWounded:
                oneOf(
                    """
                    The new wounds join the old in a tapestry of ruin.
                    \(enemyRef.subjectPronoun) has minutes, not hours.
                    """,
                    """
                    \(enemyRef.possessiveAdjective) body is a collection of traumas now,
                    each wound feeding the others' hunger for blood.
                    """,
                    """
                    Fresh damage heaps atop old scars. The flesh remembers every blow,
                    and this one may be the last it records.
                    """,
                    """
                    Blood loss compounds upon blood loss. \(enemyRef.subjectPronoun)
                    sways like a tree ready to fall.
                    """,
                    """
                    The accumulation of wounds has reached critical mass.
                    \(enemyRef.possessiveAdjective) body is failing systematically.
                    """
                )
            case .wounded:
                oneOf(
                    """
                    What was manageable is now catastrophic. The wound changes everything.
                    """,
                    """
                    \(enemyRef.possessiveAdjective) earlier injuries pale beside
                    this fresh horror. The balance tips toward death.
                    """,
                    """
                    The new wound opens old ones. Blood flows from places that had begun to heal.
                    """,
                    """
                    This strike rewrites \(enemyRef.possessiveAdjective) fate.
                    What was survivable is now a death sentence.
                    """,
                    """
                    The damage cascades through \(enemyRef.possessiveAdjective)
                    weakened frame. Each breath comes harder than the last.
                    """
                )
            case .bruised:
                oneOf(
                    """
                    The minor hurts are forgotten now. This wound makes everything else irrelevant.
                    """,
                    """
                    From capable to dying in one strike. The body betrays its owner's confidence.
                    """,
                    """
                    \(enemyRef.subjectPronoun) looks down at the damage in disbelief.
                    The blood tells the truth.
                    """,
                    """
                    What were scratches are now preludes to this symphony of trauma.
                    """,
                    """
                    The devastating reversal shows in \(enemyRef.possessiveAdjective)
                    eyes--shock giving way to the knowledge of mortality.
                    """
                )
            case .healthy:
                oneOf(
                    """
                    The unblemished flesh is torn open, revealing the meat beneath.
                    First blood is the worst blood.
                    """,
                    """
                    From whole to broken in an instant. The body learns the meaning of
                    irreparable damage.
                    """,
                    """
                    \(enemyRef.possessiveAdjective) wound is a masterpiece of destruction.
                    """,
                    """
                    The shock is total--a body that knew no pain now drowns in it.
                    """,
                    """
                    Virgin flesh splits and bleeds. The wound is an education in mortality.
                    """
                )
            }

        let attackDescription =
            switch (yourWeapon, itsWeapon) {
            case (.some(let yourWeapon), .some(let itsWeapon)):
                // Player WITH weapon, enemy WITH weapon
                oneOf(
                    """
                    \(yourWeapon) slips past \(itsWeapon) and bites deep into \(theEnemy),
                    opening a wound that will not close. Blood follows blood in the ancient way.
                    """,
                    """
                    You drive \(yourWeapon) through \(theEnemy.possessive) guard,
                    past \(itsWeapon), tearing flesh and sinew in a spray of arterial
                    crimson. The wound gapes like a second mouth.
                    """,
                    """
                    \(yourWeapon) finds the gap past \(itsWeapon), plunging deep
                    into \(theEnemy). Dark blood wells and spills, staining everything
                    it touches.
                    """,
                    """
                    Your strike with \(yourWeapon) shatters \(theEnemy.possessive) defense,
                    \(itsWeapon) useless as you carve a terrible wound. The damage is profound
                    and irreversible.
                    """,
                    """
                    \(yourWeapon) cleaves through \(theEnemy.possessive) desperate parry
                    with \(itsWeapon), opening \(enemyRef.objectPronoun) from shoulder
                    to sternum. The wet sound of tearing meat fills the air.
                    """
                )
            case (.some(let yourWeapon), .none):
                // Player WITH weapon, enemy WITHOUT weapon
                oneOf(
                    """
                    \(yourWeapon) finds \(theEnemy) undefended and bites deep, tearing
                    through muscle and scraping bone. The wound bleeds freely, painting
                    the ground in spreading pools.
                    """,
                    """
                    You drive \(yourWeapon) into \(theEnemy.possessive) exposed flesh,
                    feeling it punch through resistance and emerge wet with gore.
                    The damage is catastrophic.
                    """,
                    """
                    \(yourWeapon) carves a ragged canyon through \(theEnemy), opening
                    veins and severing tendons. Blood comes in rhythmic spurts,
                    each weaker than the last.
                    """,
                    """
                    Your strike with \(yourWeapon) catches \(theEnemy) perfectly,
                    splitting flesh like overripe fruit. The wound yawns wide,
                    revealing things better left hidden.
                    """,
                    """
                    \(yourWeapon) tears into \(theEnemy) with mechanical precision,
                    inflicting damage that transforms a living thing into meat.
                    The blood comes dark and thick.
                    """
                )
            case (.none, .some(let itsWeapon)):
                // Player WITHOUT weapon, enemy WITH weapon
                oneOf(
                    """
                    Your bare fist crashes through \(theEnemy.possessive) guard,
                    past \(itsWeapon), connecting with bone-breaking force. Something inside
                    \(enemyRef.objectPronoun) ruptures with a wet pop.
                    """,
                    """
                    You slip inside \(itsWeapon.possessive) reach and drive your knuckles
                    into \(theEnemy), feeling ribs crack and organs shift. Internal bleeding
                    begins its slow, certain work.
                    """,
                    """
                    Your savage strike bypasses \(itsWeapon) entirely, hammering into
                    \(theEnemy.possessive) temple with the sound of a melon dropped on stone.
                    """,
                    """
                    Despite \(itsWeapon), you land a crushing blow to \(theEnemy.possessive)
                    throat. The cartilage sounds like stepping on wet kindling as it collapses.
                    """,
                    """
                    Your fist finds \(theEnemy) even as \(enemyRef.subjectPronoun)
                    raises \(itsWeapon), striking with a force that sends teeth scattering
                    like dice. The jaw hangs at an impossible angle.
                    """
                )
            case (.none, .none):
                // Player WITHOUT weapon, enemy WITHOUT weapon
                oneOf(
                    """
                    Your fist connects with \(theEnemy.possessive) skull in a spray of blood
                    and spittle. The bone gives way beneath your knuckles, soft as wet clay.
                    """,
                    """
                    You drive your bare hands into \(theEnemy), feeling the body break beneath
                    your assault. Ribs snap like dry branches, puncturing what lies beneath.
                    """,
                    """
                    Your strike hammers into \(theEnemy.possessive) solar plexus, driving all
                    breath away. Something ruptures deep inside, bleeding where no one can see.
                    """,
                    """
                    You catch \(theEnemy) with a blow that splits skin and crushes bone.
                    Blood wells from the ruined flesh, thick and dark as oil.
                    """,
                    """
                    Your bare-handed assault leaves \(theEnemy) broken in fundamental ways.
                    The damage shows in the unnatural angles, the blood that comes from
                    too many places.
                    """
                )
            }

        return "\(attackDescription) \(conditionReport)"
    }

    /// Player deals significant damage to enemy.
    open func enemyGravelyInjured(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?,
        damage: Int
    ) async -> String {
        let enemyHealth = await enemy.characterSheet.healthCondition
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let yourWeapon = await playerWeapon?.alias(.withPossessiveAdjective)

        // Assess the enemy's overall condition after grave damage
        let conditionReport =
            switch enemyHealth {
            case .critical:
                oneOf(
                    """
                    \(enemyRef.subjectPronoun) staggers, eyes unfocused.
                    The edge of the abyss is near.
                    """,
                    """
                    Shock sets in and \(enemyRef.possessiveAdjective) body shakes
                    uncontrollably, death circling.
                    """,
                    """
                    The wound pushes \(enemyRef.objectPronoun) past endurance.
                    \(enemyRef.subjectPronoun) may not rise again.
                    """
                )
            case .badlyWounded:
                oneOf(
                    """
                    Blood flows steadily from multiple wounds. \(enemyRef.subjectPronoun)
                    moves like a broken thing.
                    """,
                    """
                    \(enemyRef.possessiveAdjective) breathing comes ragged and wet.
                    The injuries mount beyond bearing.
                    """,
                    """
                    Each new wound weakens what little strength remains.
                    \(enemyRef.subjectPronoun) falters visibly.
                    """
                )
            case .wounded:
                oneOf(
                    """
                    The serious wound changes \(enemyRef.possessiveAdjective) stance.
                    Pain shows in every movement.
                    """,
                    """
                    \(enemyRef.subjectPronoun) clutches the wound, blood seeping
                    between fingers. The damage is real.
                    """,
                    """
                    Shock registers in \(enemyRef.possessiveAdjective) eyes.
                    The injury demands attention \(enemyRef.subjectPronoun) cannot give.
                    """
                )
            case .bruised:
                oneOf(
                    """
                    The wound steals \(enemyRef.possessiveAdjective) momentum.
                    \(enemyRef.subjectPronoun) staggers, trying to comprehend the damage.
                    """,
                    """
                    From confident to cautious in one blow. Blood runs freely
                    down \(enemyRef.possessiveAdjective) body.
                    """,
                    """
                    \(enemyRef.subjectPronoun) looks down at the wound in disbelief.
                    The pain hasn't fully registered yet.
                    """
                )
            case .healthy:
                oneOf(
                    """
                    First blood draws a gasp. \(enemyRef.subjectPronoun) touches
                    the wound, fingers coming away red.
                    """,
                    """
                    The shock of injury shows clearly. \(enemyRef.possessiveAdjective)
                    unmarked flesh now torn and bleeding.
                    """,
                    """
                    \(enemyRef.subjectPronoun) reels from the unexpected wound.
                    The reality of violence arrives.
                    """
                )
            case .dead:
                ""  // Shouldn't happen
            }

        let attackDescription =
            switch (yourWeapon, itsWeapon) {
            case (.some(let yourWeapon), .some(let itsWeapon)):
                // Player WITH weapon, enemy WITH weapon
                oneOf(
                    """
                    \(yourWeapon) slips past \(itsWeapon) and cuts deep into \(theEnemy),
                    drawing blood that flows too fast. The wound is serious but not mortal.
                    """,
                    """
                    You drive \(yourWeapon) through \(theEnemy.possessive) guard,
                    opening flesh that bleeds freely. \(enemyRef.subjectPronoun)
                    staggers back, \(itsWeapon) wavering.
                    """,
                    """
                    \(yourWeapon) finds its mark despite \(itsWeapon), tearing a ragged
                    wound in \(theEnemy). Blood soaks through clothing.
                    """,
                    """
                    Your strike with \(yourWeapon) overwhelms \(theEnemy.possessive)
                    defense with \(itsWeapon). The weapon bites deep, drawing a cry of pain.
                    """,
                    """
                    \(yourWeapon) beats aside \(itsWeapon) and opens a serious wound
                    in \(theEnemy.possessive) side. Blood flows steadily.
                    """
                )
            case (.some(let yourWeapon), .none):
                // Player WITH weapon, enemy WITHOUT weapon
                oneOf(
                    """
                    \(yourWeapon) cuts into \(theEnemy.possessive) unprotected flesh,
                    opening a wound that bleeds profusely. The damage is severe.
                    """,
                    """
                    You strike \(theEnemy) with \(yourWeapon), tearing through skin
                    and muscle. Blood wells immediately, dark and thick.
                    """,
                    """
                    \(yourWeapon) finds \(theEnemy) exposed, carving a serious wound
                    that will need tending--if there's time.
                    """,
                    """
                    Your blow with \(yourWeapon) catches \(theEnemy) cleanly, opening
                    flesh to the bone. The bleeding is immediate and concerning.
                    """,
                    """
                    \(yourWeapon) tears into \(theEnemy), inflicting damage that shows
                    in the sudden pallor of \(enemyRef.possessiveAdjective) face.
                    """
                )
            case (.none, .some(let itsWeapon)):
                // Player WITHOUT weapon, enemy WITH weapon
                oneOf(
                    """
                    Your bare fist crashes past \(itsWeapon) into \(theEnemy.possessive)
                    body with sickening force. Something gives way beneath the blow.
                    """,
                    """
                    You slip inside the reach of \(itsWeapon) and drive your knuckles hard
                    into \(theEnemy). The impact leaves \(enemyRef.objectPronoun) gasping.
                    """,
                    """
                    Despite \(itsWeapon), your strike hammers into \(theEnemy.possessive)
                    ribs, whose cracks are audible.
                    """,
                    """
                    Your fist bypasses \(itsWeapon) and connects solidly with
                    \(theEnemy.possessive) jaw. Blood and fragments of teeth go flying.
                    """,
                    """
                    You catch \(theEnemy) even as \(enemyRef.subjectPronoun)
                    \(enemyRef.verb("raises")) \(itsWeapon), your blow landing
                    with bone-jarring force.
                    """
                )
            case (.none, .none):
                // Player WITHOUT weapon, enemy WITHOUT weapon
                oneOf(
                    """
                    Your fist connects solidly with \(theEnemy.possessive) face,
                    splitting skin and drawing blood. The impact rocks
                    \(enemyRef.objectPronoun) backward.
                    """,
                    """
                    You drive your bare hands into \(theEnemy), feeling bone shift
                    beneath the blow. \(enemyRef.subjectPronoun) doubles over in pain.
                    """,
                    """
                    Your strike catches \(theEnemy) in the solar plexus, driving breath
                    and fight from \(enemyRef.possessiveAdjective) body.
                    """,
                    """
                    You land a crushing blow to \(theEnemy.possessive) temple.
                    \(enemyRef.subjectPronoun) \(enemyRef.verb("staggers")),
                    \(enemyRef.possessiveAdjective) vision swimming.
                    """,
                    """
                    Your bare-handed assault leaves \(theEnemy) bloodied and shaken.
                    The damage shows in \(enemyRef.possessiveAdjective) unsteady stance.
                    """
                )
            }

        return "\(attackDescription) \(conditionReport)"
    }

    /// Player deals moderate damage to enemy.
    open func enemyInjured(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?,
        damage: Int
    ) async -> String {
        let enemyHealth = await enemy.characterSheet.healthCondition
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let yourWeapon = await playerWeapon?.alias(.withPossessiveAdjective)

        // Assess the enemy's overall condition
        let conditionReport =
            switch enemyHealth {
            case .critical:
                oneOf(
                    """
                    \(enemyRef.possessiveAdjective) legs threaten to buckle. Even moderate
                    damage pushes \(enemyRef.objectPronoun) toward collapse.
                    """,
                    """
                    Blood loss has \(enemyRef.objectPronoun) swaying. This new wound
                    may be one too many.
                    """,
                    """
                    \(enemyRef.possessiveAdjective) body can barely process another injury.
                    Death circles closer.
                    """
                )
            case .badlyWounded:
                oneOf(
                    """
                    Fresh blood joins old. \(enemyRef.possessiveAdjective) strength
                    ebbs with each heartbeat.
                    """,
                    """
                    The wounds accumulate beyond \(enemyRef.possessiveAdjective) body's
                    ability to compensate.
                    """,
                    """
                    \(enemyRef.subjectPronoun) \(enemyRef.verb("weakens")) visibly, the damage
                    compounding relentlessly.
                    """
                )
            case .wounded:
                oneOf(
                    """
                    The blow lands hard, adding to \(enemyRef.possessiveAdjective)
                    growing collection of injuries.
                    """,
                    """
                    Pain shoots through \(enemyRef.objectPronoun), and
                    \(enemyRef.possessiveAdjective) movements grow sluggish.
                    """,
                    """
                    Blood seeps from the new wound.
                    """
                )
            case .bruised:
                oneOf(
                    """
                    You see the ripple of pain, but \(enemyRef.possessiveAdjective) body
                    absorbs it. \(enemyRef.subjectPronoun) remains dangerous.
                    """,
                    """
                    \(enemyRef.subjectPronoun) grunts from the impact but maintains stance.
                    """,
                    """
                    The wound stings sharply. \(enemyRef.subjectPronoun) can take more,
                    but not forever.
                    """
                )
            case .healthy:
                oneOf(
                    """
                    The blow lands solidly, drawing blood. \(enemyRef.subjectPronoun)
                    feels the sting but remains strong.
                    """,
                    """
                    The wound is real but manageable.
                    """,
                    """
                    \(enemyRef.subjectPronoun) absorbs the hit, flesh suffering
                    but endurance holding.
                    """
                )
            case .dead:
                ""  // Shouldn't happen
            }

        let attackDescription =
            switch (yourWeapon, itsWeapon) {
            case (.some(let yourWeapon), .some(let itsWeapon)):
                // Player WITH weapon, enemy WITH weapon
                oneOf(
                    """
                    \(yourWeapon) slips past \(itsWeapon) and cuts into \(theEnemy),
                    drawing blood that flows steadily.
                    """,
                    """
                    You drive \(yourWeapon) through \(theEnemy.possessive) guard,
                    slicing through skin and drawing a line of fire across
                    \(enemyRef.possessiveAdjective) body.
                    """,
                    """
                    \(yourWeapon) bites into \(theEnemy) despite \(itsWeapon),
                    opening flesh that will need attention.
                    """,
                    """
                    Your strike with \(yourWeapon) beats aside \(itsWeapon),
                    tearing through clothing and skin alike.
                    """,
                    """
                    \(yourWeapon) finds its mark past \(itsWeapon),
                    the impact jarring bone and bruising deep.
                    """
                )
            case (.some(let yourWeapon), .none):
                // Player WITH weapon, enemy WITHOUT weapon
                oneOf(
                    """
                    \(yourWeapon) cuts into \(theEnemy.possessive) unguarded flesh,
                    drawing blood that flows freely.
                    """,
                    """
                    You strike \(theEnemy) with \(yourWeapon), opening a wound
                    that bleeds steadily.
                    """,
                    """
                    \(yourWeapon) finds \(theEnemy) exposed, carving a solid wound
                    that draws a grunt of pain.
                    """,
                    """
                    Your blow with \(yourWeapon) catches \(theEnemy) cleanly,
                    tearing flesh and drawing crimson.
                    """,
                    """
                    \(yourWeapon) bites deep into \(theEnemy), inflicting damage
                    that shows immediately.
                    """
                )
            case (.none, .some(let itsWeapon)):
                // Player WITHOUT weapon, enemy WITH weapon
                oneOf(
                    """
                    Your fist hammers past \(itsWeapon) into \(theEnemy),
                    the impact jarring bone.
                    """,
                    """
                    You slip inside the reach of \(itsWeapon) and drive your knuckles
                    hard into \(theEnemy.possessive) body.
                    """,
                    """
                    Despite \(itsWeapon), your strike connects solidly with \(theEnemy),
                    sending \(enemyRef.objectPronoun) staggering.
                    """,
                    """
                    Your blow bypasses \(itsWeapon) and lands true, the force
                    driving breath from \(theEnemy.possessive) lungs.
                    """,
                    """
                    You catch \(theEnemy) even as \(enemyRef.subjectPronoun) wields
                    \(itsWeapon), your fist connecting with solid force.
                    """
                )
            case (.none, .none):
                // Player WITHOUT weapon, enemy WITHOUT weapon
                oneOf(
                    """
                    Your fist connects solidly with \(theEnemy.possessive) body,
                    the impact driving \(enemyRef.objectPronoun) back.
                    """,
                    """
                    You drive your bare hands into \(theEnemy), feeling
                    the satisfying thud of impact.
                    """,
                    """
                    Your strike catches \(theEnemy) hard, and you note the ripple of pain
                    shooting through \(enemyRef.possessiveAdjective) frame.
                    """,
                    """
                    You land a punishing blow to \(theEnemy), and
                    \(enemyRef.subjectPronoun) grunts from the force.
                    """,
                    """
                    Your bare-handed assault leaves \(theEnemy) momentarily stunned.
                    """
                )
            }

        return "\(attackDescription) \(conditionReport)"
    }

    /// Player deals light damage to enemy.
    open func enemyLightlyInjured(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?,
        damage: Int
    ) async -> String {
        let enemyHealth = await enemy.characterSheet.healthCondition
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let yourWeapon = await playerWeapon?.alias(.withPossessiveAdjective)

        // Assess the enemy's overall condition
        let conditionReport =
            switch enemyHealth {
            case .critical:
                oneOf(
                    """
                    \(enemyRef.possessiveAdjective) knees wobble. Even this light wound
                    threatens to topple \(enemyRef.objectPronoun).
                    """,
                    """
                    Vision blurring, \(enemyRef.subjectPronoun) struggles to focus.
                    Every scratch counts when death is so near.
                    """,
                    """
                    The minor cut wouldn't matter, except \(enemyRef.subjectPronoun)
                    bleeds from too many places already.
                    """
                )
            case .badlyWounded:
                oneOf(
                    """
                    Another trickle of blood joins the flow. \(enemyRef.possessiveAdjective)
                    reserves are nearly spent.
                    """,
                    """
                    The light wound is one more weight on a body already overburdened.
                    """,
                    """
                    \(enemyRef.subjectPronoun) winces. Even small injuries matter
                    when the body is this damaged.
                    """
                )
            case .wounded:
                oneOf(
                    """
                    The sting adds to \(enemyRef.possessiveAdjective) growing catalog of pain.
                    """,
                    """
                    \(enemyRef.subjectPronoun) feels the hit, another note
                    in the symphony of damage.
                    """,
                    """
                    The wound is light but unwelcome, \(enemyRef.possessiveAdjective)
                    body protesting the accumulation.
                    """
                )
            case .bruised:
                oneOf(
                    """
                    The strike lands, but doesn't slow \(enemyRef.objectPronoun).
                    """,
                    """
                    \(enemyRef.subjectPronoun) feels it connect, adding to the bruises
                    but not breaking rhythm.
                    """,
                    """
                    A flash of pain, quickly suppressed--\(enemyRef.subjectPronoun)
                    has taken worse.
                    """
                )
            case .healthy:
                oneOf(
                    "The light wound barely seems to register.",
                    "\(enemyRef.subjectPronoun) notes the minor damage and dismisses it.",
                    "\(enemyRef.subjectPronoun) registers the wound with annoyance."
                )
            case .dead:
                ""  // Shouldn't happen
            }

        let attackDescription =
            switch (yourWeapon, itsWeapon) {
            case (.some(let yourWeapon), .some(let itsWeapon)):
                // Player WITH weapon, Enemy WITH weapon
                oneOf(
                    """
                    \(yourWeapon) slips past \(itsWeapon) briefly, nicking \(theEnemy)
                    and drawing a thin line of blood.
                    """,
                    """
                    You manage to graze \(theEnemy) with \(yourWeapon) despite \(itsWeapon),
                    but barely break skin.
                    """,
                    """
                    \(yourWeapon) clips \(theEnemy), leaving a shallow cut.
                    """,
                    """
                    Your strike with \(yourWeapon) glances off \(itsWeapon),
                    still managing to catch \(theEnemy) lightly.
                    """,
                    """
                    \(yourWeapon) finds a brief opening beyond \(itsWeapon),
                    leaving a minor wound.
                    """
                )

            case (.some(let yourWeapon), .none):
                // Player WITH weapon, Enemy WITHOUT weapon
                oneOf(
                    """
                    \(yourWeapon) catches \(theEnemy) with a glancing blow,
                    drawing a thin line of blood.
                    """,
                    """
                    You nick \(theEnemy) with \(yourWeapon), the weapon barely breaking skin.
                    """,
                    """
                    \(yourWeapon) clips \(theEnemy.possessive) unguarded flesh,
                    leaving a shallow cut.
                    """,
                    """
                    Your strike with \(yourWeapon) grazes \(theEnemy), drawing minimal blood.
                    """,
                    """
                    \(yourWeapon) inflicts a light wound on \(theEnemy), more sting than damage.
                    """
                )

            case (.none, .some(let itsWeapon)):
                // Player WITHOUT weapon, Enemy WITH weapon
                oneOf(
                    """
                    Your fist clips \(theEnemy) despite \(itsWeapon),
                    causing more surprise than damage.
                    """,
                    """
                    You land a glancing blow past \(itsWeapon) that stings without truly hurting.
                    """,
                    """
                    Your strike catches \(theEnemy) off-guard even with \(itsWeapon),
                    though without much force.
                    """,
                    """
                    You manage to connect lightly despite \(itsWeapon),
                    the impact barely notable.
                    """,
                    """
                    Your blow grazes \(theEnemy) past \(itsWeapon.possessive) guard,
                    leaving a bruise at most.
                    """
                )

            case (.none, .none):
                // Player WITHOUT weapon, Enemy WITHOUT weapon
                oneOf(
                    "Your fist clips \(theEnemy), a glancing blow that stings briefly.",
                    "You land a light punch that \(enemyRef.subjectPronoun) barely feels.",
                    "Your strike grazes \(theEnemy), more push than punch.",
                    "You catch \(theEnemy) with minimal force, the blow almost gentle.",
                    "Your punch connects lightly, leaving perhaps a small bruise."
                )
            }

        return "\(attackDescription) \(conditionReport)"
    }

    /// Player barely damages enemy.
    open func enemyGrazed(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?,
        damage: Int
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let yourWeapon = await playerWeapon?.alias(.withPossessiveAdjective)
        let enemyHealth = await enemy.characterSheet.healthCondition

        // Assess the enemy's overall condition after a graze
        let conditionReport =
            switch enemyHealth {
            case .critical:
                oneOf(
                    """
                    \(enemyRef.possessiveAdjective) vision darkens at the edges. Even this graze
                    threatens \(enemyRef.possessiveAdjective) tenuous grip on consciousness.
                    """,
                    """
                    \(enemyRef.subjectPronoun) stumbles from the minor contact.
                    In this state, every touch could be the last.
                    """,
                    """
                    The graze wouldn't matter, but \(enemyRef.subjectPronoun) bleeds
                    from too many places already. Each hit brings the end closer.
                    """
                )
            case .badlyWounded:
                oneOf(
                    """
                    The scratch joins \(enemyRef.possessiveAdjective) collection of wounds,
                    toward a death by a thousand cuts.
                    """,
                    """
                    \(enemyRef.subjectPronoun) is so damaged that even this graze
                    registers as pain.
                    """,
                    """
                    Another small hurt atop the large ones. The accumulation
                    is killing \(enemyRef.objectPronoun).
                    """
                )
            case .wounded:
                oneOf(
                    """
                    The graze adds another small discomfort to \(enemyRef.possessiveAdjective)
                    growing list.
                    """,
                    """
                    \(enemyRef.subjectPronoun) feels it dimly through the haze of other pains.
                    """,
                    """
                    A minor addition to \(enemyRef.possessiveAdjective) catalog of injuries.
                    """
                )
            case .bruised:
                oneOf(
                    """
                    The graze is barely noticeable against \(enemyRef.possessiveAdjective)
                    existing bruises.
                    """,
                    """
                    \(enemyRef.subjectPronoun) registers the contact without concern.
                    """,
                    """
                    A fleeting sting, quickly forgotten.
                    """
                )
            case .healthy:
                oneOf(
                    """
                    The graze is utterly trivial. \(enemyRef.subjectPronoun)
                    barely registers that it happened.
                    """,
                    """
                    No real damage, it was more of a touch than a strike.
                    """,
                    """
                    \(enemyRef.subjectPronoun) notices the contact but registers no actual pain.
                    """
                )
            case .dead:
                ""  // Shouldn't happen
            }

        let attackDescription =
            switch (yourWeapon, itsWeapon) {
            case (.some(let yourWeapon), .some(let itsWeapon)):
                // Player WITH weapon, Enemy WITH weapon
                oneOf(
                    """
                    \(yourWeapon) barely grazes \(theEnemy.possessive) skin past \(itsWeapon),
                    leaving the faintest mark.
                    """,
                    """
                    You manage only to scratch \(theEnemy) with \(yourWeapon) despite
                    getting past \(itsWeapon), drawing a single drop of blood.
                    """,
                    """
                    \(yourWeapon) skims past \(theEnemy), your aim thrown off by \(itsWeapon).
                    """,
                    """
                    Your strike with \(yourWeapon) merely brushes \(theEnemy.possessive)
                    flesh as \(enemyRef.subjectPronoun) parries with \(itsWeapon).
                    """,
                    """
                    \(yourWeapon) achieves only the lightest touch against \(theEnemy),
                    deflected by \(itsWeapon).
                    """
                )

            case (.some(let yourWeapon), .none):
                // Player WITH weapon, Enemy WITHOUT weapon
                oneOf(
                    """
                    \(yourWeapon) barely grazes \(theEnemy.possessive) exposed skin,
                    leaving the faintest mark.
                    """,
                    """
                    You manage only to scratch \(theEnemy) with \(yourWeapon),
                    drawing a single drop of blood.
                    """,
                    """
                    \(yourWeapon) skims past \(theEnemy), your aim failing at the last moment.
                    """,
                    """
                    Your strike with \(yourWeapon) merely brushes \(theEnemy.possessive) flesh,
                    the contact almost gentle.
                    """,
                    """
                    \(yourWeapon) achieves only the lightest touch against \(theEnemy),
                    with no real damage done.
                    """
                )

            case (.none, .some(let itsWeapon)):
                // Player WITHOUT weapon, Enemy WITH weapon
                oneOf(
                    """
                    Your fist barely brushes \(theEnemy) as \(enemyRef.subjectPronoun)
                    deflects with \(itsWeapon).
                    """,
                    """
                    You only manage to graze \(theEnemy) with a weak swing,
                    \(itsWeapon) forcing you back.
                    """,
                    """
                    Your strike glances off \(theEnemy) harmlessly, impeded by \(itsWeapon).
                    """,
                    """
                    You connect despite \(theEnemy) wielding \(itsWeapon),
                    but there's no power behind it.
                    """,
                    """
                    Your blow barely makes contact with \(theEnemy),
                    who easily maintains guard with \(itsWeapon).
                    """
                )

            case (.none, .none):
                // Player WITHOUT weapon, Enemy WITHOUT weapon
                oneOf(
                    """
                    Your fist barely brushes \(theEnemy), more of a push than a punch.
                    """,
                    """
                    You only manage to graze \(theEnemy) with the weakest of swings.
                    """,
                    """
                    Your strike glances off \(theEnemy) harmlessly, lacking any force.
                    """,
                    """
                    You connect with only the lightest touch, with no power behind it.
                    """,
                    """
                    Your blow barely makes contact with \(theEnemy), a ghost of an attack.
                    """
                )
            }

        return "\(attackDescription) \(conditionReport)"
    }

    /// Player's attack is a critical miss.
    open func enemyMissed(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let yourWeapon = await playerWeapon?.alias(.withPossessiveAdjective)

        return switch (yourWeapon, itsWeapon) {
        case (.some(let yourWeapon), .some(let itsWeapon)):
            // Player WITH weapon, Enemy WITH weapon
            oneOf(
                """
                \(yourWeapon) swings wide, missing \(theEnemy) completely as
                \(enemyRef.subjectPronoun) \(enemyRef.verb("sidesteps")) your attack
                with \(itsWeapon) ready.
                """,
                """
                \(yourWeapon) finds only air where \(theEnemy) was standing,
                \(itsWeapon) gleaming in response.
                """,
                """
                \(yourWeapon) whistles past \(theEnemy)! Your timing was off,
                and \(enemyRef.subjectPronoun) easily \(enemyRef.verb("avoid"))
                your clumsy strike.
                """,
                """
                \(theEnemy) doesn't even need to block with \(itsWeapon) as
                \(yourWeapon) misses entirely.
                """,
                """
                \(yourWeapon) passes harmlessly past \(theEnemy),
                who readies \(itsWeapon) for a counter.
                """
            )

        case (.none, .some(let itsWeapon)):
            // Player WITHOUT weapon, Enemy WITH weapon
            oneOf(
                """
                Your punch swings wide! \(theEnemy) doesn't even bother to use
                \(itsWeapon) to defend against the miss.
                """,
                """
                Your fist finds nothing but air! \(theEnemy) watches with amusement,
                \(itsWeapon) at the ready.
                """,
                """
                You swing and miss entirely! \(theEnemy) sidesteps your clumsy punch,
                \(itsWeapon) still threatening.
                """,
                """
                Your fist passes through empty air while \(theEnemy) grips \(itsWeapon)
                more confidently.
                """,
                """
                Your unarmed attack goes nowhere near \(theEnemy), who hefts
                \(itsWeapon) meaningfully.
                """
            )

        case (.some(let yourWeapon), .none):
            // Player WITH weapon, Enemy WITHOUT weapon
            oneOf(
                """
                \(yourWeapon) misses completely, and \(theEnemy) dodges the
                wild swing with ease.
                """,
                """
                A disastrous miss--\(yourWeapon) cuts through empty air and
                \(theEnemy) effortlessly evades your mistimed attack.
                """,
                """
                \(yourWeapon) misses completely--\(theEnemy) wasn't even near
                where you struck.
                """,
                """
                A catastrophic failure--\(yourWeapon) finds nothing as \(theEnemy)
                sidesteps your clumsy attempt.
                """,
                """
                \(yourWeapon) swings wide, and \(theEnemy) avoids
                your poorly aimed strike with ease.
                """
            )

        case (.none, .none):
            // Player WITHOUT weapon, Enemy WITHOUT weapon
            oneOf(
                """
                Your clumsy punch misses completely! \(theEnemy) wasn't even
                close to where you swung.
                """,
                """
                Your fist encounters only air as \(theEnemy) effortlessly dodges.
                """,
                """
                You swing and miss entirely! \(theEnemy) sidesteps your wild punch
                with casual ease.
                """,
                """
                Your strike goes wide, missing \(theEnemy) by an embarrassing margin.
                """,
                """
                Your attack misses! Empty space is all you encounter while \(theEnemy)
                watches with amusement.
                """
            )
        }
    }

    /// Player's attack is blocked, dodged, or made ineffective by armor.
    open func enemyBlocked(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let yourWeapon = await playerWeapon?.alias(.withPossessiveAdjective)

        return switch (yourWeapon, itsWeapon) {
        case (.some(let yourWeapon), .some(let itsWeapon)):
            // Player WITH weapon, Enemy WITH weapon
            oneOf(
                """
                \(theEnemy) parries with \(itsWeapon), \(yourWeapon) rebounding harmlessly
                from \(enemyRef.possessiveAdjective) expert defense.
                """,
                """
                \(theEnemy) blocks and turns \(yourWeapon) aside with \(itsWeapon),
                denying your strike completely.
                """,
                """
                \(theEnemy) deflects your attack, \(itsWeapon) guiding \(yourWeapon) away
                from its intended target.
                """,
                """
                \(yourWeapon) clangs against \(itsWeapon), \(theEnemy) absorbing the
                impact and pushing you back.
                """,
                """
                \(theEnemy) uses \(itsWeapon) to expertly block and nullify \(yourWeapon),
                leaving you open.
                """
            )
        case (.none, .some(let itsWeapon)):
            // Player WITHOUT weapon, Enemy WITH weapon
            oneOf(
                """
                \(theEnemy) easily deflects your punch with \(itsWeapon),
                bouncing your fist away harmlessly.
                """,
                """
                \(theEnemy) weilds \(itsWeapon) to block your unarmed strike
                and turn it aside with casual efficiency.
                """,
                """
                \(theEnemy) meets your bare-handed attack with \(itsWeapon),
                redirecting your momentum and leaving you off-balance.
                """,
                """
                \(theEnemy) parries your fist with \(itsWeapon),
                leaving you momentarily exposed.
                """,
                """
                \(theEnemy) swats away your punch with \(itsWeapon), making
                your attack look feeble.
                """
            )
        case (.some(let yourWeapon), .none):
            // Player WITH weapon, Enemy WITHOUT weapon
            oneOf(
                """
                \(theEnemy) dodges gracefully, letting \(yourWeapon) slice through empty space
                where \(enemyRef.subjectPronoun) \(enemyRef.verb("was", "were")) just standing.
                """,
                """
                \(theEnemy) evades \(yourWeapon) with a fluid sidestep,
                managing to stay just out of reach.
                """,
                """
                \(theEnemy) ducks under \(yourWeapon)! \(enemyRef.possessiveAdjective)
                agility saves \(enemyRef.objectPronoun) from certain harm.
                """,
                """
                \(theEnemy) nimbly dodges and twists away from \(yourWeapon), using speed
                to compensate for being unarmed.
                """,
                """
                \(theEnemy) weaves past \(yourWeapon)! Pure reflexes keep
                \(enemyRef.objectPronoun) safe from your strike.
                """
            )
        case (.none, .none):
            // Player WITHOUT weapon, Enemy WITHOUT weapon
            oneOf(
                """
                \(theEnemy) blocks your punch, \(enemyRef.possessiveAdjective) forearm
                deflecting your strike and absorbinging the impact.
                """,
                """
                \(theEnemy) catches your fist, stopping your attack cold.
                """,
                """
                \(theEnemy) \(enemyRef.verb("bobs and weaves", "bob and weave")),
                avoiding your strike entirely.
                """,
                """
                \(theEnemy) manages to deflect \(enemyRef.possessiveAdjective) your blow.
                """,
                """
                \(theEnemy.possessive) quick footwork carries \(enemyRef.objectPronoun)
                away from your fist.
                """
            )
        }
    }

    // MARK: - Enemy Attack Outcomes

    /// Enemy kills the player.
    open func playerSlain(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        damage: Int
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))

        return switch itsWeapon {
        case .some(let itsWeapon):
            // Enemy WITH weapon
            oneOf(
                """
                \(theEnemy) retaliates with finality as \(itsWeapon) finds the last soft place
                in you and opens it to let the life pour out.
                """,
                """
                \(theEnemy.possessive) counter drives \(itsWeapon) through something vital
                and you feel yourself emptying onto the ground in warm, spreading pools.
                """,
                """
                \(theEnemy) ends the exchange with \(itsWeapon) buried deep,
                and you understand with perfect clarity that you will not rise again.
                """,
                """
                \(theEnemy.possessive) final retaliation sends \(itsWeapon) home to the hilt
                as your vision tunnels to a point and then to nothing.
                """,
                """
                \(theEnemy) finishes the battle, \(itsWeapon) doing its work
                with mechanical precision as the cold rushes in to replace everything warm.
                """
            )

        case .none:
            // Enemy WITHOUT weapon
            oneOf(
                """
                \(theEnemy) counters with lethal force, bare fists finding the places
                where life connects to body and severing each thread.
                """,
                """
                \(theEnemy.possessive) final retaliation breaks something essential
                inside you and you feel yourself folding inward like paper in rain.
                """,
                """
                \(theEnemy) delivers death with bare hands, crushing you windpipe
                with the indifference of stone.
                """,
                """
                \(theEnemy.possessive) counter-strike hits the off switch
                buried somewhere in your anatomy and everything simply stops.
                """,
                """
                \(theEnemy) finishes you with nothing but flesh and bone,
                proving that the oldest weapons still kill just as dead.
                """
            )
        }
    }

    /// Enemy knocks player unconscious.
    open func playerUnconscious(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        damage: Int
    ) async -> String {
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let theEnemy = await enemy.alias(.withDefiniteArticle)

        let combatEvent =
            switch itsWeapon {
            case .some(let itsWeapon):
                // Enemy WITH weapon
                oneOf(
                    """
                    \(theEnemy) swings back, \(itsWeapon) tracing a perfect arc
                    that connects with your skull, sending you into the black waters
                    of unconsciousness.
                    """,
                    """
                    \(theEnemy.possessive) counter with \(itsWeapon) finds your temple
                    and the world tilts sideways before disappearing entirely.
                    """,
                    """
                    Then \(theEnemy) brings \(itsWeapon) down on your head with calculated force,
                    enough to shut you down but not quite enough to kill.
                    """,
                    """
                    \(theEnemy.possessive) retaliation with \(itsWeapon) strikes your skull
                    and switches off your consciousness like snuffing a candle.
                    """,
                    """
                    Then \(theEnemy) brings the fight to an end when \(itsWeapon) meets your skull,
                    dropping you into the dreamless dark where violence cannot follow.
                    """
                )

            case .none:
                // Enemy WITHOUT weapon
                oneOf(
                    """
                    \(theEnemy) counters with a perfect strike that finds the sleep button
                    in your skull and presses it hard.
                    """,
                    """
                    Then \(theEnemy.possessive) strike connects with your jaw at exactly
                    the right angle to shut down your brain without breaking it.
                    """,
                    """
                    \(theEnemy) retaliates with precision, bare knuckles finding the spot
                    where consciousness lives and evicting it.
                    """,
                    """
                    \(theEnemy.possessive) counter-strike drops you into the black,
                    your body going slack as awareness flees.
                    """,
                    """
                    Then \(theEnemy) puts you down with scientific accuracy,
                    the blow calibrated to render you harmless but breathing.
                    """
                )
            }

        let returnToConsciousness = oneOf(
            """
            Consciousness returns like a cruel joke--every nerve screaming, head pounding with each
            heartbeat. \(theEnemy) is gone, apparently satisfied with your destruction. Best to move
            now before \(enemyRef.subjectPronoun) returns to verify the kill.
            """,

            """
            You wake to find yourself crumpled where you fell, dried blood crusting your face.
            \(theEnemy) must have left you for dead. Fighting waves of nausea, you need to leave
            immediately--\(enemyRef.subjectPronoun) could return at any moment.
            """,

            """
            Pain drags you back from the void--sharp, insistent, and very much proof you're alive.
            The battlefield is quiet now. \(theEnemy) has moved on to other business, but
            \(enemyRef.subjectPronoun) won't stay gone long. Get out while you can.
            """,

            """
            Your eyes crack open to an empty scene. How long were you out? Hours? Minutes?
            \(theEnemy) is nowhere to be seen--perhaps called away by urgent matters. Whatever
            the reason, this reprieve won't last. Move now or die here.
            """,

            """
            The world swims back into focus through a haze of hurt. You're alone now--\(theEnemy)
            either thought the job finished or had somewhere better to be. Every movement is agony,
            but staying means certain death when \(enemyRef.subjectPronoun) returns. Time to go.
            """
        )

        return """
            \(combatEvent)

            * * *

            \(returnToConsciousness)
            """
    }

    /// Player drop \(enemyRef.possessiveAdjective) weapon, either disarmed by the enemy, or by fumbling on a critical miss
    /// and dropping \(enemyRef.possessiveAdjective) weapon.
    open func playerDisarmed(
        enemy: ItemProxy,
        playerWeapon: ItemProxy,
        enemyWeapon: ItemProxy?,
        wasFumble: Bool
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let enemyRef = await enemy.classification
        let yourWeapon = await playerWeapon.withPossessiveAdjective
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))

        return switch (itsWeapon, wasFumble) {
        case (.some(let itsWeapon), true):
            // Enemy WITH weapon, player fumbles (drops own weapon)
            oneOf(
                """
                In the chaos of dodging \(itsWeapon), your grip betrays you--\(yourWeapon)
                spins away into darkness as \(theEnemy) presses the advantage.
                """,
                """
                Sweat and blood conspire--\(yourWeapon) tears free from slick fingers
                as \(theEnemy) drives in with \(itsWeapon), sensing victory.
                """,
                """
                A fatal miscalculation sends \(yourWeapon) tumbling as you reel back
                from \(theEnemy.possessive) strike with \(itsWeapon). Suddenly the odds shift hard.
                """,
                """
                Your parry goes wrong--\(yourWeapon) jolts loose and clatters away
                while \(theEnemy) advances with \(itsWeapon), death in \(enemyRef.possessivePronoun) eyes.
                """,
                """
                The impact jars \(yourWeapon) from nerveless fingers. It skitters into shadow
                as \(theEnemy) closes with \(itsWeapon), ready to finish this.
                """
            )

        case (.some(let itsWeapon), false):
            // Enemy WITH weapon, enemy disarms player
            oneOf(
                """
                \(theEnemy) counters by striking your weapon with \(itsWeapon),
                the impact sending \(yourWeapon) flying from numb fingers.
                """,
                """
                \(theEnemy.possessive) expert counter with \(itsWeapon) hooks
                \(yourWeapon) and tears it from your grasp.
                """,
                """
                \(theEnemy) retaliates by using \(itsWeapon) to snag \(yourWeapon),
                twisting it away with mechanical efficiency.
                """,
                """
                \(theEnemy.possessive) skillful response with \(itsWeapon)
                strikes your wrist, sending \(yourWeapon) clattering to the ground.
                """,
                """
                Then suddenly \(theEnemy) disarms you with \(itsWeapon) in a counter-move
                so smooth that it seems rehearsed, leaving you weaponless.
                """
            )

        case (.none, true):
            // Enemy WITHOUT weapon, player fumbles
            oneOf(
                """
                Your own momentum betrays you--\(yourWeapon) flies from your grasp,
                leaving you and \(theEnemy) to settle this with fists and fury.
                """,
                """
                A misstep costs everything. \(yourWeapon) spins away as \(theEnemy)
                rushes forward to exploit your sudden vulnerability.
                """,
                """
                Overextended, you lose \(yourWeapon) to gravity and bad timing.
                \(theEnemy) surges in, ready to make this personal.
                """,
                """
                The weapon tears free--\(yourWeapon) abandons you as \(theEnemy)
                closes the distance, violence written in every movement.
                """,
                """
                Your grip fails catastrophically. \(yourWeapon) clatters away
                as \(theEnemy) drives forward, sensing blood in the water.
                """
            )

        case (.none, false):
            // Enemy WITHOUT weapon, enemy disarms player
            oneOf(
                """
                \(theEnemy) counters by grabbing \(yourWeapon) with bare hands,
                and wrenches it away with surprising strength.
                """,
                """
                \(theEnemy.possessive) lightning-fast counter strikes your wrist,
                causing \(yourWeapon) to drop from shocked fingers.
                """,
                """
                \(theEnemy) retaliates with expert technique, disarming you barehanded
                and sending \(yourWeapon) clattering away.
                """,
                """
                The despite being unarmed, \(theEnemy) make an impressive counter
                that knocks \(yourWeapon) from your hands.
                """,
                """
                Then \(theEnemy) targets your weapon hand in response,
                and the precise strike sends \(yourWeapon) clattering to the ground.
                """
            )
        }
    }

    /// Enemy's attack causes player to stagger, reducing \(enemyRef.possessiveAdjective) combat effectiveness.
    open func playerStaggers(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))

        return switch itsWeapon {
        case .some(let itsWeapon):
            // Enemy WITH weapon
            oneOf(
                """
                \(theEnemy) counters with \(itsWeapon), and the blow rocks you backward
                as your legs struggle to remember their purpose.
                """,
                """
                \(theEnemy.possessive) retaliation with \(itsWeapon) sends you stumbling
                like a drunk, with the world tilting at impossible angles.
                """,
                """
                \(theEnemy) strikes back with \(itsWeapon), sending you staggering
                and unable to keep the ground where it belongs.
                """,
                """
                \(theEnemy.possessive) counter with \(itsWeapon) hits you hard in the ear,
                leaving you swaying like a tree in storm.
                """,
                """
                Then \(theEnemy) drives \(itsWeapon) into you with enough force
                to make standing a conscious effort rather than an assumption.
                """
            )
        case .none:
            // Enemy WITHOUT weapon
            oneOf(
                """
                \(theEnemy.possessive) counter-strike staggers you backward, your feet
                suddenly uncertain about their relationship with the ground.
                """,
                """
                \(theEnemy) retaliates with raw force that rocks you hard,
                leaving you stumbling through space that won't hold still.
                """,
                """
                Then \(theEnemy.possessive) strike meets you solidly and the world
                lurches sideways, as balance becomes a memory rather than a fact.
                """,
                """
                \(theEnemy) strikes back with enough impact to make your legs
                forget their job, sending you stumbling like a toddler.
                """,
                """
                \(theEnemy.possessive) counter connects true, and suddenly
                the act of standing requires all your concentration while the world spins.
                """
            )
        }
    }

    /// Enemy's attack causes player to hesitate, creating an opening for follow-up actions.
    open func playerHesitates(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))

        return switch itsWeapon {
        case .some(let itsWeapon):
            // Enemy WITH weapon
            oneOf(
                """
                \(theEnemy.possessive) vicious counter with \(itsWeapon) leaves you
                momentarily shocked, and your body hesitates when it should act.
                """,
                """
                \(theEnemy) strikes back with \(itsWeapon) so savagely that you falter,
                uncertainty freezing your muscles for one crucial heartbeat.
                """,
                """
                \(theEnemy.possessive) retaliation with \(itsWeapon) is fierce enough
                to break your rhythm, making you pull back when you should press forward.
                """,
                """
                \(theEnemy) counters with \(itsWeapon) with such violence that you flinch,
                in a moment of weakness \(enemyRef.subjectPronoun) immediately exploits.
                """,
                """
                \(theEnemy.possessive) brutal response with \(itsWeapon) shatters
                your confidence mid-strike, turning attack into retreat.
                """
            )
        case .none:
            // Enemy WITHOUT weapon
            oneOf(
                """
                \(theEnemy.possessive) savage counter-attack makes you hesitate,
                feet shuffling backward as doubt replaces certainty.
                """,
                """
                \(theEnemy) responds with such ferocity that you falter,
                your muscles locking as your brain recalculates the odds.
                """,
                """
                \(theEnemy.possessive) brutal retaliation stops you short,
                the raw violence of it shaking your confidence to its core.
                """,
                """
                \(theEnemy) strikes back with such primal intensity that you hesitate,
                your guard dropping as uncertainty takes hold.
                """,
                """
                \(theEnemy.possessive) vicious counter breaks your focus completely,
                turning your advance into uncertain retreat.
                """
            )
        }
    }

    /// Enemy's attack leaves player vulnerable to subsequent attacks.
    open func playerVulnerable(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))

        return switch itsWeapon {
        case .some(let itsWeapon):
            // Enemy WITH weapon
            oneOf(
                """
                \(theEnemy) perfectly counters with \(itsWeapon) and your defenses
                are shattered, leaving you exposed like a wound.
                """,
                """
                \(theEnemy.possessive) retaliation with \(itsWeapon) tears through your guard,
                and in an instant you're completely exposed.
                """,
                """
                Then \(theEnemy) breaks through with \(itsWeapon) in a move
                that leaves you defenseless, your body a map of unprotected targets.
                """,
                """
                Then \(theEnemy.possessive) skillful counter with \(itsWeapon) disrupts
                your stance completely, leaving you vulnerable as an overturned turtle.
                """,
                """
                Then \(theEnemy) uses \(itsWeapon) to dismantle your defense
                piece by piece, until nothing stands between you and what comes next.
                """
            )
        case .none:
            // Enemy WITHOUT weapon
            oneOf(
                """
                \(theEnemy) counters with a force that shatters your guard,
                leaving you exposed to whatever violence comes next.
                """,
                """
                \(theEnemy.possessive) brutal retaliation breaks through
                your defenses completely, rendering you vulnerable as an opened shell.
                """,
                """
                \(theEnemy) shatters your defense with bare hands, leaving you
                wide open and unable to protect yourself.
                """,
                """
                \(theEnemy.possessive) savage counter tears through your guard,
                creating the perfect opening for what comes next.
                """,
                """
                \(theEnemy) destroys your stance with raw force, leaving you
                vulnerable and defenseless against the coming assault.
                """
            )
        }
    }

    /// Enemy deals critical damage to player.
    open func playerCriticallyWounded(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        damage: Int
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let playerHealth = await enemy.engine.player.characterSheet.healthCondition

        // Assess the player's overall condition after critical damage
        let conditionReport =
            switch playerHealth {
            case .critical, .dead:
                oneOf(
                    "Your body is shutting down, system by system. One more strike and it ends.",
                    "Death has you now. Your body continues its motions but the outcome is written.",
                    "The light is leaving your eyes. Blood pools beneath you, too much to survive.",
                    "You stand only by habit. The next blow will drop you forever.",
                    "The damage is mortal. You bleed from places that cannot be staunched."
                )
            case .badlyWounded:
                oneOf(
                    "The new wounds join the old in a tapestry of ruin. You have minutes, not hours.",
                    "Your body is a collection of traumas now, each wound feeding the others' hunger for blood.",
                    "Fresh damage atop old scars. Your flesh remembers every blow, and this one may be the last it records.",
                    "Blood loss compounds upon blood loss. You sway like a tree ready to fall.",
                    "The accumulation of wounds has reached critical mass. Your body is failing systematically."
                )
            case .wounded:
                oneOf(
                    "What was manageable is now catastrophic. The wound changes everything.",
                    "Your earlier injuries pale beside this fresh horror. The balance tips toward death.",
                    "The new wound opens old ones. Blood flows from places that had begun to heal.",
                    "This strike rewrites your fate. What was survivable is now a death sentence.",
                    "The damage cascades through your weakened frame. Each breath comes harder than the last."
                )
            case .bruised:
                oneOf(
                    "The minor hurts are forgotten now. This wound makes everything else irrelevant.",
                    "From capable to dying in one strike. Your body betrays your confidence.",
                    "You look down at the damage in disbelief. The blood tells the truth.",
                    "What were scratches are now preludes to this symphony of trauma.",
                    "The devastating reversal shows in your vision--shock giving way to the knowledge of mortality."
                )
            case .healthy:
                oneOf(
                    "Your unblemished flesh is torn open, revealing the meat beneath. First blood is the worst blood.",
                    "From whole to broken in an instant. Your pristine body learns what damage means.",
                    "Your first wound is a masterpiece of destruction. Innocence dies with the skin.",
                    "The shock is total--a body that knew no pain now drowns in it.",
                    "Virgin flesh splits and bleeds. The wound is an education in mortality."
                )
            }

        let attackDescription =
            switch itsWeapon {
            case .some(let itsWeapon):
                // Enemy WITH weapon
                oneOf(
                    """
                    The counterstrike comes like a judgment, \(theEnemy) carving \(itsWeapon)
                    through meat and gristle, finding the soft places where life still pools.
                    Blood follows the weapon's path in thick ropes.
                    """,
                    """
                    Then \(theEnemy) exploits an opening in your guard, and surges through.
                    \(itsWeapon) opens you wide, parting flesh with obscene ease. The wound
                    yawns, revealing what should never see light.
                    """,
                    """
                    Then \(theEnemy) buries \(itsWeapon) deep, and turns it as it withdraws.
                    Your blood paints the ground in arterial spurts.
                    """,
                    """
                    The riposte is perfect and terrible: \(theEnemy) drives \(itsWeapon)
                    through your defenses, carving a canyon through your body. This sort of
                    damage will not heal.
                    """,
                    """
                    The \(theEnemy.possessive) weapon descends with the weight of ending.
                    From collarbone to sternum, \(itsWeapon) opens a red road through your chest
                    with the sound of wet butchery.
                    """
                )
            case .none:
                // Enemy WITHOUT weapon
                oneOf(
                    """
                    \(theEnemy) answers with devastating force--bone meets bone in wet percussion.
                    Your body folds wrong, organs shifting in ways they shouldn't.
                    """,
                    """
                    The counter comes brutal and precise. \(theEnemy.possessive) fist drives through
                    your guard like a piston, and something vital ruptures inside.
                    """,
                    """
                    \(theEnemy) strikes back with primal violence--knuckles find temple,
                    and the world fragments into red static and the taste of iron.
                    """,
                    """
                    In one fluid motion, \(theEnemy) destroys your defense. The impact
                    rearranges your insides while your vision splits into crimson doubles.
                    """,
                    """
                    \(theEnemy.possessive) response is immediate and catastrophic--a blow that
                    caves ribs inward, painting your lungs with your own blood.
                    """
                )
            }

        return "\(attackDescription) \(conditionReport)"
    }

    /// Enemy deals significant damage to player.
    open func playerGravelyInjured(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        damage: Int
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let playerHealth = await enemy.engine.player.characterSheet.healthCondition

        // Assess the player's overall condition after grave damage
        let conditionReport =
            switch playerHealth {
            case .critical:
                oneOf(
                    "You stagger, vision blurring. The edge of the abyss is near.",
                    "Shock sets in. Your body shakes uncontrollably, death circling.",
                    "The wound pushes you past endurance. You may not rise again."
                )
            case .badlyWounded:
                oneOf(
                    "Blood flows steadily from multiple wounds. You move like a broken thing.",
                    "Your breathing comes ragged and wet. The injuries mount beyond bearing.",
                    "Each new wound weakens what little strength remains. You falter visibly."
                )
            case .wounded:
                oneOf(
                    "The serious wound changes your stance. Pain shows in every movement.",
                    "You clutch the wound, blood seeping between your fingers. The damage is real.",
                    "Shock registers in your mind. The injury demands attention you cannot give."
                )
            case .bruised:
                oneOf(
                    "The wound steals your momentum. You stagger, trying to comprehend the damage.",
                    "From confident to cautious in one blow. Blood runs freely down your body.",
                    "You look down at the wound in disbelief. The pain hasn't fully registered yet."
                )
            case .healthy:
                oneOf(
                    "First blood draws a gasp. You touch the wound, fingers coming away red.",
                    "The shock of injury hits hard. Your unmarked flesh now torn and bleeding.",
                    "You reel from the unexpected wound. The reality of violence arrives."
                )
            case .dead:
                ""  // Shouldn't happen
            }

        let attackDescription =
            switch itsWeapon {
            case .some(let itsWeapon):
                // Enemy WITH weapon
                oneOf(
                    """
                    Then \(itsWeapon) answers your attack, slicing through guard and flesh alike.
                    Blood runs in steady streams, too much and too fast.
                    """,
                    """
                    The counter comes swift. \(theEnemy) drives \(itsWeapon) past
                    your defenses, opening meat that parts like overripe fruit. You stumble,
                    watching your blood spill out.
                    """,
                    """
                    Then \(itsWeapon) bites back hard, wielded with desperate fury. The weapon
                    tears rather than cuts, leaving wounds with ragged, weeping edges.
                    """,
                    """
                    Then \(theEnemy) finds the gap, and \(itsWeapon) punches through skin
                    and muscle, grating against the bone. Your body betrays you with a scream.
                    """,
                    """
                    The retaliation is vicious. \(itsWeapon) carves a crimson arc across your body,
                    your blood soaking cloth, then dripping steady to the ground.
                    """
                )
            case .none:
                // Enemy WITHOUT weapon
                oneOf(
                    """
                    Then \(theEnemy.possessive) strike hammers home with the sound of a mallet
                    on meat. Something structural fails inside you.
                    """,
                    """
                    The counterblow drives deep. \(theEnemy) buries knuckles in your ribs,
                    and breath becomes agony.
                    """,
                    """
                    \(theEnemy.possessive) answer is pure violence. Bone cracks
                    under the impact, the sound like kindling snapping.
                    """,
                    """
                    Then \(theEnemy) recovers and strikes true. Your jaw takes
                    the full force. Blood and fragments of teeth spray the air.
                    """,
                    """
                    Then flesh impacts flesh with terrible authority as
                    \(theEnemy.possessive) blow reverberates through your skeleton.
                    """
                )
            }

        return "\(attackDescription) \(conditionReport)"
    }

    /// Enemy deals moderate damage to player.
    open func playerInjured(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        damage: Int
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let playerHealth = await enemy.engine.player.characterSheet.healthCondition

        // Assess the player's overall condition
        let conditionReport =
            switch playerHealth {
            case .critical:
                oneOf(
                    "Your legs threaten to buckle. Even moderate damage pushes you toward collapse.",
                    "Blood loss has you swaying. This new wound may be one too many.",
                    "Your body can barely process another injury. Death circles closer."
                )
            case .badlyWounded:
                oneOf(
                    "Fresh blood joins old. Your strength ebbs with each heartbeat.",
                    "The wounds accumulate beyond your body's ability to compensate.",
                    "You feel yourself weakening, the damage compounding relentlessly."
                )
            case .wounded:
                oneOf(
                    "The blow lands hard, adding to your growing collection of injuries.",
                    "Pain shoots through you. Your movements grow sluggish.",
                    "Blood seeps from the new wound, joining streams from the old."
                )
            case .bruised:
                oneOf(
                    "The strike hurts, but your body absorbs it. You remain dangerous.",
                    "You grunt from the impact but maintain your stance.",
                    "The wound stings sharply. You can take more, but not forever."
                )
            case .healthy:
                oneOf(
                    "The blow lands solidly, drawing blood. You feel the sting but remain strong.",
                    "First blood to them. The wound is real but manageable.",
                    "You absorb the hit, feeling flesh tear but knowing you can endure."
                )
            case .dead:
                ""  // Shouldn't happen
            }

        let attackDescription =
            switch itsWeapon {
            case .some(let itsWeapon):
                // Enemy WITH weapon
                oneOf(
                    """
                    Then \(itsWeapon) finds purchase in your flesh. The wound opens clean,
                    blood welling dark and constant.
                    """,
                    """
                    \(theEnemy) strikes back, \(itsWeapon) parting skin like paper.
                    A line of fire traces across your body, followed by the warm rush of blood.
                    """,
                    """
                    Then \(itsWeapon) enters and exits your flesh,
                    leaving a hole that weeps crimson.
                    """,
                    """
                    Suddenly \(theEnemy) slips past your guard. \(itsWeapon) opens a wound
                    that will mark you, and your blood flows out steady and sure.
                    """,
                    """
                    The response is measured and brutal. \(itsWeapon) tears
                    through fabric and flesh, painting both red.
                    """
                )
            case .none:
                // Enemy WITHOUT weapon
                oneOf(
                    """
                    \(theEnemy) hammers back instantly--the blow lands solid,
                    driving air from lungs and thought from mind.
                    """,
                    """
                    The counterstrike comes heavy. \(theEnemy.possessive) fist
                    finds ribs, and pain blooms like fire through your chest.
                    """,
                    """
                    \(theEnemy) pivots and strikes true--impact ripples through
                    muscle and bone, stealing balance and breath together.
                    """,
                    """
                    In the exchange, \(theEnemy) lands clean. The world lurches
                    as your body absorbs punishment it won't soon forget.
                    """,
                    """
                    \(theEnemy.possessive) answer is swift and punishing--knuckles
                    meet flesh with the sound of meat hitting stone.
                    """
                )
            }

        return "\(attackDescription) \(conditionReport)"
    }

    /// Enemy deals light damage to player.
    open func playerLightlyInjured(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        damage: Int
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let playerHealth = await enemy.engine.player.characterSheet.healthCondition

        // Assess the player's overall condition
        let conditionReport =
            switch playerHealth {
            case .critical:
                oneOf(
                    "Your knees wobble. Even this light wound threatens to topple you.",
                    "Vision blurring, you struggle to focus. Every scratch counts when death is so near.",
                    "The minor cut wouldn't matter, except you're already bleeding from too many places."
                )
            case .badlyWounded:
                oneOf(
                    "Another trickle of blood joins the flow. Your reserves are nearly spent.",
                    "The light wound is one more weight on a body already overburdened.",
                    "You wince. Even small injuries matter when you're this damaged."
                )
            case .wounded:
                oneOf(
                    "The sting adds to your growing catalog of pain.",
                    "You feel the hit, another note in the symphony of damage.",
                    "The wound is light but unwelcome, your body protesting the accumulation."
                )
            case .bruised:
                oneOf(
                    "The strike lands but doesn't slow you. Not yet.",
                    "You feel it connect, adding to the bruises but not breaking your rhythm.",
                    "A flash of pain, quickly suppressed. You've taken worse."
                )
            case .healthy:
                oneOf(
                    "The wound is trivial against your battle fury.",
                    "Pain flickers and dies. Your body has more important work.",
                    "The cut registers dimly. Blood, but not enough to matter."
                )
            case .dead:
                ""  // Shouldn't happen
            }

        let attackDescription =
            switch itsWeapon {
            case .some(let itsWeapon):
                // Enemy WITH weapon
                oneOf(
                    "\(theEnemy) whips \(itsWeapon) across in answer--steel whispers against skin, leaving a thin signature of pain.",
                    "The riposte comes fast, \(itsWeapon) flicking out to trace a shallow arc of red across your guard.",
                    "\(theEnemy) pivots and \(itsWeapon) bites quick, a serpent's kiss that draws blood but finds no vein.",
                    "In the exchange, \(itsWeapon) slips through to mark you--a stinging reminder that \(theEnemy) still has teeth.",
                    "\(theEnemy) turns your momentum against you, \(itsWeapon) catching flesh in passing, painting a line of fire."
                )

            case .none:
                // Enemy WITHOUT weapon
                oneOf(
                    "\(theEnemy) surges back instantly, fist cracking against your ribs--more warning than wound.",
                    "The counterblow comes wild and desperate, \(theEnemy) hammering through your guard to bruise rather than break.",
                    "\(theEnemy) crashes forward in response, the impact jarring but glancing as you roll with it.",
                    "In the tangle, \(theEnemy) drives an elbow home--sudden pressure that blooms into dull pain.",
                    "\(theEnemy) answers with raw violence, a clubbing strike that finds you but lacks the angle to truly hurt."
                )
            }

        return "\(attackDescription) \(conditionReport)"
    }

    /// Enemy barely damages player.
    open func playerGrazed(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        damage: Int
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let playerHealth = await enemy.engine.player.characterSheet.healthCondition

        // Assess the player's overall condition after a graze
        let conditionReport =
            switch playerHealth {
            case .critical:
                oneOf(
                    "Your vision darkens at the edges. Even this graze threatens your tenuous grip on consciousness.",
                    "You stumble from the minor contact. In your state, every touch could be the last.",
                    "The graze wouldn't matter, but you're already dying. Each hit brings the end closer."
                )
            case .badlyWounded:
                oneOf(
                    "The scratch joins your collection of wounds. Death by a thousand cuts.",
                    "You're so damaged that even this graze registers as pain.",
                    "Another small hurt atop the large ones. The accumulation is killing you."
                )
            case .wounded:
                oneOf(
                    "The graze adds another small discomfort to your growing list.",
                    "You feel it dimly through the haze of other pains.",
                    "A minor addition to your catalog of injuries."
                )
            case .bruised:
                oneOf(
                    "The graze is barely noticeable against your existing bruises.",
                    "You register the contact without concern.",
                    "A fleeting sting, quickly forgotten."
                )
            case .healthy:
                oneOf(
                    "The graze is utterly trivial. You barely register it happened.",
                    "No real damage. More of a touch than a strike.",
                    "You notice the contact but feel no actual pain."
                )
            case .dead:
                ""  // Shouldn't happen
            }

        let attackDescription =
            switch itsWeapon {
            case .some(let itsWeapon):
                // Enemy WITH weapon
                oneOf(
                    "\(theEnemy) lashes out in response--\(itsWeapon) skims past, close enough to feel the wind of its passing.",
                    "The counter comes swift but shallow, \(itsWeapon) tracing air an inch from opening veins.",
                    "\(theEnemy) whips \(itsWeapon) through the space you just vacated, steel singing a near-miss song.",
                    "In the exchange, \(itsWeapon) flickers past--death's whisper without its bite.",
                    "\(theEnemy) strikes back instantly, but \(itsWeapon) finds only the ghost of where you were."
                )
            case .none:
                // Enemy WITHOUT weapon
                oneOf(
                    "\(theEnemy) swings back hard, knuckles grazing past as you twist away from impact.",
                    "The counterstrike comes wild--\(theEnemy.possessive) fist clips you without finding purchase.",
                    "\(theEnemy) lunges forward in answer, fingertips raking air where throat should be.",
                    "In the scramble, \(theEnemy) throws a desperate hook that barely connects, all motion and no mass.",
                    "\(theEnemy) surges back, but the blow slides off your moving form like water."
                )
            }

        return "\(attackDescription) \(conditionReport)"
    }

    /// Enemy's attack is a critical miss.
    open func playerMissed(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))

        return switch itsWeapon {
        case .some(let itsWeapon):
            // Enemy WITH weapon
            oneOf(
                "\(theEnemy) swings \(itsWeapon) in retaliation but finds only air where you were a heartbeat ago.",
                "\(theEnemy.possessive) counter with \(itsWeapon) misses completely, the weapon whistling through empty space.",
                "\(theEnemy) strikes back with \(itsWeapon) but misjudges badly, steel meeting nothing but its own momentum.",
                "\(theEnemy.possessive) retaliatory swing with \(itsWeapon) cuts through the space you've already vacated.",
                "\(theEnemy) counters viciously with \(itsWeapon) but rage makes the strike wild, missing you entirely."
            )
        case .none:
            // Enemy WITHOUT weapon
            oneOf(
                "\(theEnemy) swings back hard but \(enemyRef.possessiveAdjective) fist finds nothing but the memory of where you stood.",
                "\(theEnemy.possessive) counter-punch goes wide, rage making the strike clumsy and predictable.",
                "\(theEnemy) retaliates with violence but you're already elsewhere when the blow arrives.",
                "\(theEnemy.possessive) counter-strike punches through air, missing by the width of good instincts.",
                "\(theEnemy) strikes back but fury has made \(enemyRef.objectPronoun) blind, the attack failing to find flesh."
            )
        }
    }

    /// Enemy's attack is blocked, dodged, or made ineffective by armor.
    open func playerDodged(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))

        return switch itsWeapon {
        case .some(let itsWeapon):
            // Enemy WITH weapon
            oneOf(
                "\(theEnemy) counters with \(itsWeapon) but you slip aside, the weapon passing close enough to feel its wind.",
                "\(theEnemy.possessive) retaliatory strike with \(itsWeapon) cuts toward you but your body knows how to flow around death.",
                "\(theEnemy) swings \(itsWeapon) in response but you weave away, leaving the weapon to bite empty air.",
                "\(theEnemy.possessive) counter with \(itsWeapon) seeks your flesh but you duck and roll, making distance from the hungry steel.",
                "\(theEnemy) strikes back with \(itsWeapon) but you've already moved, a ghost that steel cannot touch."
            )
        case .none:
            // Enemy WITHOUT weapon
            oneOf(
                "\(theEnemy) counters with a vicious swing but you dodge aside, letting the fist pass through space you no longer occupy.",
                "\(theEnemy.possessive) retaliatory strike comes fast but you're faster, sidestepping the violence with practiced grace.",
                "\(theEnemy) strikes back hard but you duck away, the punch finding only the ghost of where you were.",
                "\(theEnemy.possessive) counter whistles past as you weave aside, your body remembering how to avoid pain.",
                "\(theEnemy) swings in retaliation but you slip the attack, flowing around the violence like water around stone."
            )
        }
    }

    // MARK: - Special Outcomes

    /// Enemy flees from combat.
    open func enemyFlees(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        direction: Direction?,
        destination: LocationID?
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let inSomeDirection = somethingDisappears(toward: direction)

        return switch itsWeapon {
        case .some(let itsWeapon):
            // Enemy WITH weapon
            oneOf(
                """
                \(theEnemy) breaks away from combat! Clutching \(itsWeapon),
                \(enemyRef.subjectPronoun) \(enemyRef.verb("vanishes", "vanish"))
                \(inSomeDirection) with desperate speed.
                """,
                """
                Suddenly \(theEnemy) turns and flees \(inSomeDirection)! \(enemyRef.possessiveAdjective) \(itsWeapon)
                glints as \(enemyRef.subjectPronoun) \(enemyRef.verb("abandons")) the fight entirely.
                """,
                """
                \(theEnemy) chooses survival over glory! With \(itsWeapon) still in hand,
                \(enemyRef.subjectPronoun) \(enemyRef.verb("sprints")) \(inSomeDirection) and out of sight.
                """,
                """
                The fight is over--\(theEnemy) retreats! \(enemyRef.subjectPronoun)
                take \(itsWeapon) and disappear \(inSomeDirection) without looking back.
                """,
                """
                \(theEnemy) has had enough! Gripping \(itsWeapon) tightly,
                \(enemyRef.subjectPronoun) \(enemyRef.verb("flees")) \(inSomeDirection) in full retreat.
                """
            )

        case .none:
            // Enemy WITHOUT weapon
            oneOf(
                """
                \(theEnemy) abandons the fight! Weaponless and beaten,
                \(enemyRef.subjectPronoun) \(enemyRef.verb("disappears")) \(inSomeDirection) at a dead run.
                """,
                """
                Suddenly \(theEnemy) breaks away! With nothing but fear driving
                \(enemyRef.objectPronoun), \(enemyRef.subjectPronoun) \(enemyRef.verb("vanishs")) \(inSomeDirection).
                """,
                """
                \(theEnemy) chooses flight over fight! Empty-handed,
                \(enemyRef.subjectPronoun) \(enemyRef.verb("sprints")) \(inSomeDirection) and out of reach.
                """,
                """
                The battle ends with \(theEnemy.possessive) retreat!
                \(enemyRef.subjectPronoun) flee \(inSomeDirection),
                leaving you victorious.
                """,
                """
                \(theEnemy) has seen enough! Without weapon or hope,
                \(enemyRef.subjectPronoun) \(enemyRef.verb("escapes")) \(inSomeDirection) in full flight.
                """
            )
        }
    }

    /// Enemy is pacified and stops fighting.
    open func enemyPacified(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))

        return switch itsWeapon {
        case .some(let itsWeapon):
            // Enemy WITH weapon
            oneOf(
                """
                \(theEnemy) lowers \(itsWeapon) slowly. The fight drains from
                \(enemyRef.possessiveAdjective) eyes, replaced by weary acceptance.
                """,
                """
                Something changes in \(theEnemy.possessive) stance. \(itsWeapon) drops
                to \(enemyRef.possessiveAdjective) side as aggression melts away.
                """,
                """
                \(theEnemy) steps back, \(itsWeapon) no longer threatening.
                Whatever drove \(enemyRef.objectPronoun) to violence has passed.
                """,
                """
                The hostility fades from \(theEnemy). Though still holding \(itsWeapon),
                \(enemyRef.subjectPronoun) \(enemyRef.verb("clearlys")) have no will to continue fighting.
                """,
                """
                \(theEnemy.possessive) grip on \(itsWeapon) relaxes. The murderous
                intent vanishes, leaving only cautious neutrality.
                """
            )
        case .none:
            // Enemy WITHOUT weapon
            oneOf(
                """
                \(theEnemy) unclenches \(enemyRef.possessiveAdjective) fists.
                The violence drains away, leaving only exhausted calm.
                """,
                """
                Something shifts in \(theEnemy.possessive) posture. The aggression
                dissipates like morning mist, replaced by wary peace.
                """,
                """
                \(theEnemy) steps back with open hands. Whatever fury drove
                \(enemyRef.objectPronoun) has burned itself out.
                """,
                """
                The fight leaves \(theEnemy) entirely. \(enemyRef.subjectPronoun)
                stand passive now, all hostility forgotten.
                """,
                """
                \(theEnemy.possessive) aggressive stance melts away. Though still
                watchful, \(enemyRef.subjectPronoun) \(enemyRef.verb("clearlys")) want no more violence.
                """
            )
        }
    }

    /// Enemy returns after knocking player unconscious and leaving them for dead.
    open func enemyReturns(enemy: ItemProxy) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let enemyRef = await enemy.classification

        return oneOf(
            """
            Your lingering proves catastrophic. \(theEnemy) returns to find you still here,
            upright and foolishly exploring instead of fleeing. \(enemyRef.possessivePronoun)
            posture shifts from surprise to deadly purpose. The rematch you didn't want has arrived.
            """,

            """
            Disaster. \(theEnemy) reappears just as you're examining your surroundings--clearly
            the wrong priority. \(enemyRef.subjectPronoun) takes in your recovered
            state with what reads as dark amusement. You should have run when you could.
            """,

            """
            \(theEnemy) walks back in to find you standing there like nothing happened.
            The momentary confusion gives way to focused aggression. All that time you wasted
            investigating instead of escaping--now the bill comes due.
            """,

            """
            Footsteps herald your doom. \(theEnemy) returns to discover you puttering about
            instead of being sensibly elsewhere. \(enemyRef.possessivePronoun) stance
            radiates disbelief, then hardens into lethal intent. Your curiosity has cost you dearly.
            """,

            """
            The worst possible timing: \(theEnemy) comes back to find you still present,
            apparently fascinated by your surroundings rather than your survival.
            \(enemyRef.subjectPronoun) doesn't hesitate--violence resumes immediately.
            You had your chance to leave.
            """
        )
    }

    /// Enemy surrenders.
    open func enemySurrenders(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))

        return switch itsWeapon {
        case .some(let itsWeapon):
            // Enemy WITH weapon
            oneOf(
                """
                \(theEnemy) drops \(itsWeapon) with a clatter! \(enemyRef.subjectPronoun)
                sink to the ground, all fight extinguished, clearly surrendering.
                """,
                """
                \(theEnemy) casts \(itsWeapon) aside and falls to \(enemyRef.possessiveAdjective)
                knees! The gesture of submission is unmistakable.
                """,
                """
                \(theEnemy) releases \(itsWeapon) and backs away with raised appendages,
                making every possible sign of surrender and submission.
                """,
                """
                With trembling movements, \(theEnemy) carefully sets down \(itsWeapon)
                and assumes a posture of complete defeat and surrender.
                """,
                """
                \(theEnemy) \(itsWeapon) far away! \(enemyRef.subjectPronoun)
                cower low, displaying absolute submission to your victory.
                """
            )
        case .none:
            // Enemy WITHOUT weapon
            oneOf(
                """
                \(theEnemy) makes gestures of surrender! \(enemyRef.subjectPronoun)
                drop low in submission, all aggression completely abandoned.
                """,
                """
                \(theEnemy) falls back with raised limbs, displaying the universal
                signs of defeat and surrender. The fight is over.
                """,
                """
                \(theEnemy) stops fighting entirely, assuming a posture of complete
                submission. \(enemyRef.possessiveAdjective) surrender is absolute.
                """,
                """
                With empty appendages raised high, \(theEnemy) backs away in clear
                surrender, making submissive gestures of defeat.
                """,
                """
                \(theEnemy) collapses in defeat! \(enemyRef.subjectPronoun)
                cower in unmistakable surrender, all resistance extinguished.
                """
            )
        }
    }

    /// Enemy performs a special ability or action.
    open func enemySpecialAction(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        message: String
    ) async -> String {
        output(message)
    }

    /// Enemy taunts or intimidates instead of attacking.
    open func enemyTaunts(
        enemy: ItemProxy,
        message: String
    ) async -> String {
        output(message)
    }

    /// Enemy wakes after being knocked unconscious for some time.
    open func enemyWakes(enemy: ItemProxy) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let enemyRef = await enemy.classification

        return oneOf(
            """
            \(theEnemy) stirs, then suddenly snaps to consciousness. \(enemyRef.subjectPronoun)
            rises unsteadily, taking in your continued presence with mounting rage. Whatever mercy
            stayed your hand, \(enemyRef.subjectPronoun) won't return the favor.
            """,

            """
            Movement from the fallen form--\(theEnemy) is coming around. \(enemyRef.subjectPronoun)
            pushes up from the ground, fury building with each labored breath. You should have finished
            this, or fled. Now you'll face the consequences.
            """,

            """
            A groan, then \(theEnemy) forces \(enemyRef.reflexivePronoun) upright, shaking off
            unconsciousness like a bad dream. Finding you still here transforms grogginess into
            focused hatred. The battle resumes, but now it's personal.
            """,

            """
            \(theEnemy) jolts awake with violent purpose, immediately scanning for you--and finding you.
            The humiliation of defeat burns in \(enemyRef.possessivePronoun) stance.
            \(enemyRef.subjectPronoun) won't underestimate you twice.
            """,

            """
            Your hesitation bears bitter fruit as \(theEnemy) regains consciousness.
            \(enemyRef.subjectPronoun) staggers upright, wounded pride mixing with
            murderous intent. Whatever advantage you had is gone--replaced by an enemy who knows
            your measure and wants revenge.
            """
        )

    }

    /// Player attempts to attack without required weapon.
    open func unarmedAttackDenied(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))

        return switch itsWeapon {
        case .some(let itsWeapon):
            // Enemy WITH weapon
            oneOf(
                """
                You'll need a weapon of your own to face \(theEnemy) while
                \(enemyRef.subjectPronoun) \(enemyRef.verb("wields")) \(itsWeapon)!
                """,
                """
                Attacking \(theEnemy) bare-handed while \(enemyRef.subjectPronoun)
                hold \(itsWeapon)? That would be suicidal.
                """,
                """
                Your fists against \(itsWeapon)?
                Find a weapon first, or find a grave soon after.
                """,
                """
                \(theEnemy) grips \(itsWeapon) confidently. You'll need more
                than courage to fight \(enemyRef.objectPronoun) unarmed.
                """,
                """
                Facing \(itsWeapon) with empty hands? \(theEnemy) almost
                pities your foolish bravery. Almost.
                """
            )
        case .none:
            // Enemy WITHOUT weapon
            oneOf(
                """
                You consider attacking \(theEnemy) but something stays your hand.
                Perhaps violence isn't the answer here.
                """,
                """
                Fighting \(theEnemy) bare-handed seems inadvisable.
                Find a proper weapon first.
                """,
                """
                \(theEnemy) may be unarmed, but so are you. This won't
                end well without a weapon.
                """,
                """
                Your empty hands won't suffice against \(theEnemy).
                Better to arm yourself properly first.
                """,
                """
                Attacking \(theEnemy) without a weapon? Your survival
                instincts strongly advise against it.
                """
            )
        }
    }

    /// Player attempts to attack with non-weapon item.
    open func nonWeaponAttack(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        item: ItemProxy
    ) async -> String {
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let theItem = await item.withDefiniteArticle

        return switch itsWeapon {
        case .some(let itsWeapon):
            // Enemy WITH weapon
            oneOf(
                """
                You wave \(theItem) at \(theEnemy) threateningly! \(enemyRef.subjectPronoun)
                seem more amused than intimidated, raising \(itsWeapon) in response.
                """,
                """
                \(theItem) makes a poor weapon against \(theEnemy.possessive)
                \(itsWeapon)! This might not end well.
                """,
                """
                You brandish \(theItem) aggressively! \(theEnemy) almost laughs,
                readying \(itsWeapon) for real combat.
                """,
                """
                Attacking with \(theItem)? \(theEnemy) grips \(itsWeapon)
                tighter, unimpressed by your improvised weaponry.
                """,
                """
                You swing \(theItem) with violent intent! Against \(itsWeapon),
                though, it seems rather inadequate.
                """
            )

        case .none:
            // Enemy WITHOUT weapon
            oneOf(
                """
                You threaten \(theEnemy) with \(theItem)! It's not much of
                a weapon, but \(enemyRef.subjectPronoun) \(enemyRef.verb("takes")) you seriously anyway.
                """,
                """
                \(theItem) wasn't designed for combat, but you wield it
                against \(theEnemy) regardless!
                """,
                """
                You attack with \(theItem)! \(theEnemy) dodges, more
                puzzled than threatened by your choice of weapon.
                """,
                """
                Brandishing \(theItem), you advance on \(theEnemy)!
                It's unconventional, but might just work.
                """,
                """
                You swing \(theItem) at \(theEnemy) with desperate creativity!
                \(enemyRef.subjectPronoun) prepare to defend against
                your improvised assault.
                """
            )
        }
    }

    /// Player is distracted by non-combat action, allowing enemy free attack.
    open func playerDistracted(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        command: Command
    ) async -> String {
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))
        let theEnemy = await enemy.alias(.withDefiniteArticle)

        return switch itsWeapon {
        case .some(let itsWeapon):
            // Enemy WITH weapon
            oneOf(
                "While you foolishly attempt to \(command.verbPhrase), \(theEnemy) seizes the opening and \(itsWeapon) swings toward your undefended flesh.",
                "You try to \(command.verbPhrase) mid-combat and \(theEnemy) punishes the distraction immediately, \(itsWeapon) finding you vulnerable.",
                "Your attempt to \(command.verbPhrase) in the middle of violence gives \(theEnemy) a gift, \(itsWeapon) striking while your attention wanders.",
                "Distracted by trying to \(command.verbPhrase), you leave yourself open as \(itsWeapon) teaches you about priorities.",
                "Your mind splits between \(command.verbPhrase) and survival, and \(theEnemy) exploits the division with \(itsWeapon) seeking flesh."
            )

        case .none:
            // Enemy WITHOUT weapon
            oneOf(
                "While you stupidly try to \(command.verbPhrase), \(theEnemy) attacks your distracted form with violent enthusiasm.",
                "You attempt to \(command.verbPhrase) during combat and \(theEnemy) makes you pay for the lapse in concentration.",
                "Your foolish attempt to \(command.verbPhrase) now gives \(theEnemy) an opening that \(enemyRef.subjectPronoun) exploits without hesitation.",
                "Trying to \(command.verbPhrase) in the middle of a fight proves costly as \(theEnemy) strikes your unguarded body.",
                "Your distraction with \(command.verbPhrase) drops your guard completely and \(theEnemy) strikes without mercy or pause."
            )
        }
    }

    /// Combat is interrupted by external event.
    open func combatInterrupted(
        reason: String
    ) async -> String {
        output(reason)
    }

    /// Stalemate: neither side can harm the other.
    open func stalemate(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    ) async -> String {
        let theEnemy = await enemy.alias(.withDefiniteArticle)
        let enemyRef = await enemy.classification
        let itsWeapon = await enemyWeapon?.alias(.withPossessiveAdjective(for: enemy))

        return switch itsWeapon {
        case .some(let itsWeapon):
            // Enemy WITH weapon
            oneOf(
                """
                You and \(theEnemy) circle endlessly. Neither \(itsWeapon) nor
                your defenses can break through. This could go on forever.
                """,
                """
                The combat reaches an impasse. \(itsWeapon)
                can't penetrate your guard, nor can you harm \(enemyRef.objectPronoun).
                """,
                """
                Round after round passes with neither advantage. \(theEnemy) with
                \(itsWeapon) proves your equal, nothing more, nothing less.
                """,
                """
                A perfect deadlock. Every strike from \(itsWeapon) meets perfect
                defense, every counter perfectly blocked. Futility incarnate.
                """,
                """
                You and \(theEnemy) are too evenly matched. \(itsWeapon) threatens
                but cannot connect, while you cannot break through either.
                """
            )
        case .none:
            // Enemy WITHOUT weapon
            oneOf(
                """
                You and \(theEnemy) trade blows to no effect. Neither can
                gain advantage over the other. Pure stalemate.
                """,
                """
                The fight goes nowhere. \(theEnemy) can't hurt you, you
                can't hurt \(enemyRef.objectPronoun). Endless, pointless combat.
                """,
                """
                Round after round of futile exchange. You and \(theEnemy)
                are perfectly matched, perfectly stuck.
                """,
                """
                Neither you nor \(theEnemy) can land a telling blow.
                The combat has reached complete equilibrium.
                """,
                """
                Deadlocked. Every attack meets defense, every defense meets
                attack. You and \(theEnemy) achieve nothing but exhaustion.
                """
            )
        }
    }
}

// swiftlint:enable file_length function_body_length line_length type_body_length
