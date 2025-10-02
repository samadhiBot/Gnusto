import GnustoEngine

/*
 TODO: update eventHandler processing in auto-wiring tool now that the item id is specified
 */

/// The notorious thief of Zork 1, a sophisticated character with stealth, theft, and
/// combat abilities.
///
/// Based on the original ZIL `ROBBER-FUNCTION` and `THIEF-VS-ADVENTURER` routines, this
/// implementation captures the thief's complex behaviors:
///
/// - Movement throughout the dungeon via daemon
/// - Sophisticated theft mechanics for valuable items
/// - Combat abilities with his deadly stiletto
/// - Treasure interactions and enhanced AI
struct Thief {
    // MARK: - Core Items

    let thief = Item(.thief)
        .name("thief")
        .synonyms("thief", "robber", "man", "person")
        .adjectives("shady", "suspicious", "seedy", "suspicious-looking", "sneaky")
        .firstDescription(
            """
            There is a suspicious-looking individual, holding a large bag,
            leaning against one wall. He is armed with a deadly stiletto.
            """
        )
        .characterSheet(  // Stronger than the troll
            CharacterSheet(
                strength: 14,
                dexterity: 18,
                intelligence: 13,
                charisma: 7,
                bravery: 9,
                perception: 16,
                accuracy: 15,
                intimidation: 15,
                stealth: 17,
                level: 2,
                classification: .masculine,
                alignment: .neutralEvil
            )
        )
        .validLocations(
            .cellar, .damRoom, .deepCanyon, .egyptRoom, .gallery, .maze1, .maze2, .maze3, .maze4,
            .maze5, .mirrorRoomSouth, .northSouthPassage, .reservoir, .reservoirSouth, .roundRoom,
            .streamView, .tinyCave, .windingPassage,
        )

    let stiletto = Item(.stiletto)
        .name("stiletto")
        .synonyms("stiletto", "knife", "blade")
        .adjectives("vicious", "deadly", "sharp")
        .isWeapon
        .requiresTryTake
        .isTakable
        .omitDescription
        .size(10)
        .in(.item(.thief))

    let largeBag = Item(.largeBag)
        .name("large bag")
        .synonyms("bag", "sack")
        .adjectives("large")
        .requiresTryTake
        .omitDescription
        .isContainer
        .capacity(1_000)  // Large capacity for stolen treasures
        .in(.item(.thief))
}

// MARK: - Event Handlers

extension Thief {
    /// Main thief character handler with sophisticated AI behavior
    static let thiefHandler = ItemEventHandler(for: .thief) {
        before(.examine) { _, _ in
            ActionResult(
                """
                The thief is a slippery character with beady eyes that flit back
                and forth. He carries, along with an unmistakable arrogance, a large bag
                over his shoulder and a vicious stiletto, whose blade is aimed
                menacingly in your direction. I'd watch out if I were you.
                """
            )
        }

        before(.give) { _, command in
            // Get the item being given from the direct object
            guard case .item(let giftProxy) = command.directObject else {
                return nil
            }
            return await handleGiveToThief(item: giftProxy)
        }

        before(.listen) { _, _ in
            ActionResult("The thief says nothing, as you have not been formally introduced.")
        }

        before(.take) { _, _ in
            ActionResult("Once you got him, what would you do with him?")
        }

        before(.tell) { _, _ in
            ActionResult("The thief is a strong, silent type.")
        }

        before(.throw) { context, command in
            if command.directObject?.itemProxy?.id == .knife {
                await throwNastyKnifeAtThief(in: context)
            } else {
                nil
            }
        }

    }

    /// Stiletto weapon handler with thief protection
    static let stilettoHandler = ItemEventHandler(for: .stiletto) {
        before(.examine) { context, _ in
            guard await isThiefHoldingStiletto(context.engine) else { return nil }
            return ActionResult(
                """
                It's a vicious-looking stiletto with a razor-sharp blade. The thief
                grips it expertly, clearly experienced in its use.
                """
            )
        }

        before(.take) { context, _ in
            // Stiletto is protected while thief is alive and present
            guard await isThiefHoldingStiletto(context.engine) else { return nil }
            return ActionResult(
                """
                The thief is armed and dangerous. You'd have to defeat him first
                before attempting to take his stiletto.
                """
            )
        }
    }

    /// Large bag handler with treasure integration
    static let largeBagHandler = ItemEventHandler(for: .largeBag) {
        before(.examine) { context, _ in
            if await isThiefHoldingLargeBag(context.engine) {
                return ActionResult(
                    """
                    The thief's large bag bulges with what are obviously stolen goods.
                    He watches you carefully, ready to defend his ill-gotten gains.
                    """
                )
            }

            let contents = await context.item.contents
            if contents.isEmpty {
                return ActionResult("The thief's bag lies empty on the ground.")
            } else {
                return await ActionResult(
                    """
                    The thief's bag lies open, spilling its stolen contents:
                    \(contents.listWithIndefiniteArticles() ?? "nothing").
                    """
                )
            }
        }

        before(.take, .open) { context, _ in
            guard await isThiefHoldingLargeBag(context.engine) else { return nil }
            return ActionResult(
                """
                The thief clutches his bag protectively. You'd need to defeat him
                first before you could get at his stolen treasures.
                """
            )
        }
    }

    // MARK: - Thief Daemon

    /// The `thiefDaemon` controls the thief's movement and tendency to steal.
    ///
    /// Based on Zork's `THIEF-VS-ADVENTURER` routine.
    static let thiefDaemon = Daemon(frequency: 1) { engine, _ in
        let playerLocation = await engine.player.location
        let thief = await engine.item(.thief)
        let thiefLargeBag = await engine.item(.largeBag)
        let thiefLocation = await thief.location

        // Thief must be alive, awake, not engaged in combat, and allowed in the current location
        guard
            await thief.isAwake,
            await !thief.isFighting,
            await thief.isAllowed(in: playerLocation.id)
        else {
            return .yield
        }

        if await thief.parent == .nowhere {
            // Thief is not here, has 30% chance to spawn into the current location
            if await engine.randomPercentage(chance: 30) {
                if await thief.isHolding(.stiletto) {
                    return ActionResult(
                        """
                        Someone carrying a large bag is casually leaning against one of the
                        walls here. He does not speak, but it is clear from his aspect that
                        the bag will be taken only over his dead body.
                        """,
                        thief.move(to: playerLocation.id)
                    )
                }
                if await engine.player.isHolding(.stiletto) {
                    return await ActionResult(
                        """
                        You feel a light finger-touch, and turning, notice a grinning figure
                        holding a large bag in one hand and a stiletto in the other.
                        """,
                        thief.move(to: playerLocation.id),
                        engine.item(.stiletto).move(to: .item(.thief))
                    )
                }
            }

        } else if thiefLocation == playerLocation {
            // Thief is in the same room as the player, 30% chance to steal
            if await engine.randomPercentage(chance: 30) {
                // Thief steals everything he can from the player and the room
                var changes = [StateChange?]()
                let roomItems = await playerLocation.items.eligibleForTheft
                for item in roomItems {
                    changes.append(
                        item.move(to: thiefLargeBag.id)
                    )
                }
                let playerItems = await engine.player.inventory.eligibleForTheft
                for item in playerItems {
                    changes
                        .append(
                            item.move(to: thiefLargeBag.id)
                        )
                }
                let message =
                    if playerItems.isNotEmpty {
                        """
                        The thief just left, still carrying his large bag. You may not
                        have noticed that he robbed you blind first.
                        """
                    } else if roomItems.isNotEmpty {
                        """
                        The thief just left, still carrying his large bag. You may not
                        have noticed that he appropriated the valuables in the room.
                        """
                    } else {
                        "The thief, finding nothing of value, left disgusted."
                    }
                return ActionResult(
                    message: message,
                    changes: changes
                )
            }

            // Thief didn't steal anything; 30% chance that he now leaves
            if await engine.randomPercentage(chance: 30) {
                return ActionResult(
                    """
                    The holder of the large bag just left, looking disgusted.
                    Fortunately, he took nothing.
                    """,
                    thief.remove()
                )
            }
        }

        // Otherwise, thief is no longer in the same room as the player, therefore remove.
        return .yield
    }
}

// MARK: - Combat System

extension Thief {
    static let thiefCombatSystem = StandardCombatSystem(
        versus: .thief
    ) { event, context async throws -> ActionResult? in
        switch event {

        case .playerSlain:
            await ActionResult(
                context.combatMsg.oneOf(
                    "The thief, forgetting his essentially genteel upbringing, cuts your throat.",
                    "The thief, a pragmatist, dispatches you as a threat to his livelihood.",
                    "Finishing you off, the thief inserts his blade into your heart.",
                    "The thief comes in from the side, feints, and inserts the blade into your ribs.",
                    """
                    The thief bows formally, raises his stiletto,
                    and with a wry grin, ends the battle and your life.
                    """
                )
            )

        case .playerUnconscious:
            await ActionResult(
                context.combatMsg.oneOf(
                    """
                    Shifting in the midst of a thrust, the thief knocks you unconscious
                    with the haft of his stiletto.
                    """,
                    "The thief knocks you out."
                )
            )

        case .playerDisarmed(_, let playerWeapon, _, _):
            await playerDisarmedResult(playerWeapon, context)

        case .playerCriticallyWounded:
            await ActionResult(
                context.combatMsg.oneOf(
                    "The butt of his stiletto cracks you on the skull, and you stagger back.",
                    """
                    The thief rams the haft of his blade into your stomach,
                    leaving you out of breath.
                    """,
                    "The thief attacks, and you fall back desperately."
                )
            )

        case .playerGravelyInjured:
            await ActionResult(
                context.combatMsg.oneOf(
                    "The thief strikes like a snake! The resulting wound is serious.",
                    "The thief stabs a deep cut in your upper arm.",
                    "The stiletto touches your forehead, and the blood obscures your vision.",
                    "The thief strikes at your wrist, and suddenly your grip is slippery with blood."
                )
            )

        case .playerLightlyInjured:
            await ActionResult(
                context.combatMsg.oneOf(
                    "A quick thrust pinks your left arm, and blood starts to trickle down.",
                    "The thief draws blood, raking his stiletto across your arm.",
                    "The stiletto flashes faster than you can follow, and blood wells from your leg.",
                    "The thief slowly approaches, strikes like a snake, and leaves you wounded."
                )
            )

        case .playerMissed:
            await ActionResult(
                context.combatMsg.oneOf(
                    "The thief stabs nonchalantly with his stiletto and misses.",
                    "You dodge as the thief comes in low."
                )
            )

        case .playerDodged:
            await ActionResult(
                context.combatMsg.oneOf(
                    "You parry a lightning thrust, and the thief salutes you with a grim nod.",
                    "The thief tries to sneak past your guard, but you twist away."
                )
            )

        case .enemyFlees:
            await ActionResult(
                context.combatMsg.output(
                    """
                    Your opponent, determining discretion to be the better part of
                    valor, decides to terminate this little contretemps. With a rueful
                    nod of his head, he steps backward into the gloom and disappears.
                    """
                )
            )

        case .enemySpecialAction:
            await ActionResult(
                context.combatMsg.oneOf(
                    """
                    The thief, a man of superior breeding, pauses for a moment
                    to consider the propriety of finishing you off.
                    """,
                    "The thief amuses himself by searching your pockets.",
                    "The thief entertains himself by rifling your pack."
                )
            )

        case .enemySlain(let enemy, _, _, let damage):
            await thiefSlainResult(context, enemy, damage)

        default:
            nil
        }
    }

    static func thiefSlainResult(
        _ context: ActionContext,
        _ enemy: ItemProxy,
        _ damage: Int
    ) async -> ActionResult? {
        let currentLocation = await context.player.location
        let thief = await context.engine.item(.thief)
        let largeBag = await context.engine.item(.largeBag)
        let stiletto = await context.engine.item(.stiletto)

        var changes: [StateChange] = [
            thief.remove()
        ]
        var treasuresDeposited = false

        // Drop the stiletto at current location if thief is holding it
        if await thief.isHolding(stiletto.id) {
            changes.append(
                stiletto.move(to: currentLocation.id)
            )
        }

        // Move valuable contents from bag to current location
        if await thief.isHolding(largeBag.id) {
            for item in await largeBag.contents {
                let itemId = item.id
                if itemId == .stiletto || itemId == .largeBag {
                    continue
                }

                if await item.value > 0 {
                    changes.append(
                        item.move(to: currentLocation.id)
                    )
                    treasuresDeposited = true

                    // Special handling for the egg - open it when deposited
                    if itemId == .egg {
                        changes.append(
                            await item.setFlag(.isOpen)
                        )
                    }
                }
            }

            // Move the empty bag to current location
            changes.append(
                largeBag.move(to: currentLocation.id)
            )
        }

        // Add standard death changes
        //        changes.append(await enemy.takeDamage(damage))
        //        changes.append(await context.engine.endCombat())
        //        changes.append(
        //            await enemy.setCharacterAttributes(
        //                consciousness: .dead,
        //                isFighting: false
        //            )
        //        )

        print("🎾 changes:", changes)

        let bootyStatus = treasuresDeposited ? " His booty remains." : ""

        await print("🎾 roundRoom.items:", context.location(.roundRoom).items.map(\.id))

        return ActionResult(
            message: """
                Almost as soon as the thief breathes his last breath, a cloud
                of sinister black fog envelops him, and when the fog lifts, the
                carcass has disappeared.\(bootyStatus)
                """,
            changes: changes
                //            executionFlow: treasuresDeposited ? .yield : .override
        )
    }

    static func playerDisarmedResult(
        _ playerWeapon: ItemProxy,
        _ context: ActionContext
    ) async -> ActionResult? {
        let weapon = await playerWeapon.alias(.withPossessiveAdjective)
        let weaponAlt = await playerWeapon.alias(.withPossessiveAdjective)
        return await ActionResult(
            context.combatMsg.oneOf(
                """
                A long, theatrical slash. You catch it on \(weapon),
                but the thief twists his knife, and \(weaponAlt) goes flying.
                """,
                "The thief neatly flips \(weapon) out of your hands, and it drops to the floor.",
                "You parry a low thrust, and \(weapon) slips out of your hand."
            )
        )
    }

}

// MARK: - Helper functions

extension Thief {

    static func handleGiveToThief(item: ItemProxy) async -> ActionResult? {
        if await item.value > 0 {
            await ActionResult(
                """
                The thief examines the \(item.name) with obvious delight and
                carefully places it in his bag, giving you a grudging nod of
                acknowledgment.
                """,
                item.move(to: .item(.largeBag))
            )
        } else {
            await ActionResult(
                """
                The thief examines the \(item.name) briefly, then shakes his head
                with obvious disdain. "I only deal in quality merchandise," he mutters.
                """
            )
        }
    }

    static func isThiefHoldingLargeBag(_ engine: GameEngine) async -> Bool {
        let thief = await engine.item(.thief)
        let largeBag = await engine.item(.largeBag)
        return await thief.isHolding(largeBag.id)
    }

    static func isThiefHoldingStiletto(_ engine: GameEngine) async -> Bool {
        let thief = await engine.item(.thief)
        let stiletto = await engine.item(.stiletto)
        return await thief.isHolding(stiletto.id)
    }

    static func throwNastyKnifeAtThief(
        in context: ItemEventContext
    ) async -> ActionResult? {
        let nastyKnife = await context.item(.knife)

        guard await context.player.isHolding(nastyKnife.id) else { return nil }

        let thief = await context.item(.thief)
        let largeBag = await context.item(.largeBag)
        let playerLocation = await context.player.location

        if await context.engine.rollD10(rollsAtLeast: 10) {
            return ActionResult(
                """
                You evidently frightened the robber, though you didn't hit him.
                He flees, but the contents of his bag fall on the floor.
                """,
                context.item.move(to: .location(playerLocation.id)),
                largeBag.move(to: .location(playerLocation.id)),
                thief.remove()
            )
        } else {
            return ActionResult(
                """
                You missed. The thief makes no attempt to take the knife, though it
                would be a fine addition to the collection in his bag. He does seem
                angered by your attempt.
                """
            )
            .appending(
                await context.engine.enemyAttacks(enemy: thief)
            )
        }
    }
}

extension Array where Element == ItemProxy {
    var eligibleForTheft: [ItemProxy] {
        get async {
            await asyncFilter {
                if await $0.value > 0, await $0.hasFlags(none: .isSacred, .isInvisible) {
                    true
                } else {
                    false
                }
            }
        }
    }
}
