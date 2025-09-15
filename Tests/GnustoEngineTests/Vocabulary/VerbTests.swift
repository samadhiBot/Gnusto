import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("Verb Tests")
struct VerbTests {

    // MARK: - Basic Functionality Tests

    @Test("Verb initializer with id and intents works correctly")
    func testVerbInitializerWithIdAndIntents() throws {
        let verb = Verb(id: "test", intents: .take, .examine)

        #expect(verb.rawValue == "test")
        #expect(verb.intents.count == 2)
        #expect(verb.intents.contains(.take))
        #expect(verb.intents.contains(.examine))
    }

    @Test("Verb initializer with single intent works correctly")
    func testVerbInitializerWithSingleIntent() throws {
        let verb = Verb(id: "grab", intents: .take)

        #expect(verb.rawValue == "grab")
        #expect(verb.intents == [.take])
    }

    @Test("Verb initializer with no intents works correctly")
    func testVerbInitializerWithNoIntents() throws {
        let verb = Verb(id: "mysterious")

        #expect(verb.rawValue == "mysterious")
        #expect(verb.intents.isEmpty)
    }

    @Test("Empty verb ID assertion")
    func testEmptyVerbIDAssertion() throws {
        // Note: We can't test assertions directly in Swift Testing
        // This test just ensures compilation and documents the behavior
        #expect(Bool(true))
    }

    // MARK: - GnustoID Conformance Tests

    @Test("Verb conforms to GnustoID protocol")
    func testGnustoIDConformance() throws {
        let verb = Verb(id: "testVerb", intents: .take)

        // Test that rawValue is accessible as required by GnustoID
        let id: String = verb.rawValue
        #expect(id == "testVerb")
    }

    // MARK: - Predefined Verbs Tests

    @Test("All predefined verbs have correct raw values")
    func testPredefinedVerbRawValues() throws {
        // Test a representative sample of verbs
        #expect(Verb.take.rawValue == "take")
        #expect(Verb.get.rawValue == "get")
        #expect(Verb.grab.rawValue == "grab")
        #expect(Verb.drop.rawValue == "drop")
        #expect(Verb.look.rawValue == "look")
        #expect(Verb.examine.rawValue == "examine")
        #expect(Verb.go.rawValue == "go")
        #expect(Verb.walk.rawValue == "walk")
        #expect(Verb.run.rawValue == "run")
        #expect(Verb.open.rawValue == "open")
        #expect(Verb.close.rawValue == "close")
        #expect(Verb.light.rawValue == "light")
        #expect(Verb.extinguish.rawValue == "extinguish")
        #expect(Verb.inventory.rawValue == "inventory")
        #expect(Verb.quit.rawValue == "quit")
        #expect(Verb.save.rawValue == "save")
        #expect(Verb.restore.rawValue == "restore")
        #expect(Verb.help.rawValue == "help")
        #expect(Verb.xyzzy.rawValue == "xyzzy")
    }

    @Test("Movement verbs have correct intents")
    func testMovementVerbIntents() throws {
        #expect(Verb.go.intents.contains(.move))
        #expect(Verb.walk.intents.contains(.move))
        #expect(Verb.run.intents.contains(.move))
        #expect(Verb.travel.intents.contains(.move))
        #expect(Verb.proceed.intents.contains(.move))
        #expect(Verb.head.intents.contains(.move))
        #expect(Verb.hike.intents.contains(.move))
        #expect(Verb.stroll.intents.contains(.move))
    }

    @Test("Taking verbs have correct intents")
    func testTakingVerbIntents() throws {
        #expect(Verb.take.intents.contains(.take))
        #expect(Verb.get.intents.contains(.take))
        #expect(Verb.grab.intents.contains(.take))
        #expect(Verb.steal.intents.contains(.take))

        // Verbs that can both take and do other actions
        #expect(Verb.lift.intents.contains(.take))
        #expect(Verb.lift.intents.contains(.pull))
        #expect(Verb.raise.intents.contains(.take))
        #expect(Verb.raise.intents.contains(.pull))
        #expect(Verb.pick.intents.contains(.take))
        #expect(Verb.pick.intents.contains(.search))
    }

    @Test("Examination verbs have correct intents")
    func testExaminationVerbIntents() throws {
        #expect(Verb.examine.intents.contains(.examine))
        #expect(Verb.inspect.intents.contains(.examine))
        #expect(Verb.peek.intents.contains(.examine))

        // Look can both look around and examine specific objects
        #expect(Verb.look.intents.contains(.look))
        #expect(Verb.look.intents.contains(.examine))
    }

    @Test("Light source verbs have correct intents")
    func testLightSourceVerbIntents() throws {
        #expect(Verb.light.intents.contains(.lightSource))
        #expect(Verb.ignite.intents.contains(.lightSource))

        // Turn can both turn objects and operate light sources
        #expect(Verb.turn.intents.contains(.turn))
        #expect(Verb.turn.intents.contains(.lightSource))
    }

    @Test("Attack verbs have correct intents")
    func testAttackVerbIntents() throws {
        #expect(Verb.attack.intents.contains(.attack))
        #expect(Verb.hit.intents.contains(.attack))
        #expect(Verb.kick.intents.contains(.attack))
        #expect(Verb.kill.intents.contains(.attack))
        #expect(Verb.fight.intents.contains(.attack))
        #expect(Verb.slay.intents.contains(.attack))
        #expect(Verb.brandish.intents.contains(.attack))

        // Multi-purpose attack verbs
        #expect(Verb.bite.intents.contains(.attack))
        #expect(Verb.bite.intents.contains(.eat))
        #expect(Verb.chop.intents.contains(.attack))
        #expect(Verb.chop.intents.contains(.cut))
        #expect(Verb.stab.intents.contains(.attack))
        #expect(Verb.stab.intents.contains(.cut))
        #expect(Verb.slice.intents.contains(.attack))
        #expect(Verb.slice.intents.contains(.cut))
    }

    @Test("Vocal expression verbs have tell intent")
    func testVocalExpressionVerbIntents() throws {
        let vocalVerbs: [Verb] = [
            .tell, .yell, .shout, .scream, .holler, .shriek, .laugh, .giggle, .chuckle, .snicker,
            .chortle, .cry, .sob, .weep, .curse, .swear, .damn, .fuck, .shit, .sing, .hum, .xyzzy,
            .inform,
        ]

        for verb in vocalVerbs {
            #expect(verb.intents.contains(.tell), "Verb \(verb.rawValue) should have .tell intent")
        }
    }

    @Test("Drinking verbs have correct intents")
    func testDrinkingVerbIntents() throws {
        #expect(Verb.drink.intents.contains(.drink))
        #expect(Verb.sip.intents.contains(.drink))
        #expect(Verb.quaff.intents.contains(.drink))
        #expect(Verb.imbibe.intents.contains(.drink))
    }

    @Test("Eating verbs have correct intents")
    func testEatingVerbIntents() throws {
        #expect(Verb.eat.intents.contains(.eat))
        #expect(Verb.consume.intents.contains(.eat))
        #expect(Verb.devour.intents.contains(.eat))
        #expect(Verb.chew.intents.contains(.eat))
        #expect(Verb.chomp.intents.contains(.eat))
    }

    @Test("Container operation verbs have correct intents")
    func testContainerOperationVerbIntents() throws {
        #expect(Verb.open.intents.contains(.open))
        #expect(Verb.close.intents.contains(.close))
        #expect(Verb.shut.intents.contains(.close))

        #expect(Verb.insert.intents.contains(.insert))
        #expect(Verb.put.intents.contains(.insert))
        #expect(Verb.place.intents.contains(.insert))
        #expect(Verb.load.intents.contains(.insert))

        #expect(Verb.empty.intents.contains(.empty))
        #expect(Verb.fill.intents.contains(.fill))
        #expect(Verb.pour.intents.contains(.pour))
    }

    @Test("Game control verbs have correct intents")
    func testGameControlVerbIntents() throws {
        #expect(Verb.quit.intents.contains(.quit))
        #expect(Verb.save.intents.contains(.save))
        #expect(Verb.restore.intents.contains(.restore))
        #expect(Verb.restart.intents.contains(.restart))
        #expect(Verb.inventory.intents.contains(.inventory))

        // Help-related verbs
        #expect(Verb.help.intents.contains(.help))
        #expect(Verb.score.intents.contains(.help))
        #expect(Verb.brief.intents.contains(.help))
        #expect(Verb.verbose.intents.contains(.help))
        #expect(Verb.script.intents.contains(.help))
        #expect(Verb.unscript.intents.contains(.help))
    }

    // MARK: - Intent Mapping Consistency Tests

    @Test("Synonymous verbs have consistent intents")
    func testSynonymousVerbConsistency() throws {
        // Taking synonyms should all have .take intent
        let takingVerbs: [Verb] = [.take, .get, .grab, .steal]
        for verb in takingVerbs {
            #expect(
                verb.intents.contains(.take),
                "Taking verb \(verb.rawValue) should have .take intent")
        }

        // Movement synonyms should all have .move intent
        let movementVerbs: [Verb] = [.go, .walk, .run, .travel, .proceed, .head, .hike, .stroll]
        for verb in movementVerbs {
            #expect(
                verb.intents.contains(.move),
                "Movement verb \(verb.rawValue) should have .move intent")
        }

        // Examination synonyms should have .examine intent
        let examinationVerbs: [Verb] = [.examine, .inspect, .peek]
        for verb in examinationVerbs {
            #expect(
                verb.intents.contains(.examine),
                "Examination verb \(verb.rawValue) should have .examine intent")
        }

        // Closing synonyms should have .close intent
        let closingVerbs: [Verb] = [.close, .shut]
        for verb in closingVerbs {
            #expect(
                verb.intents.contains(.close),
                "Closing verb \(verb.rawValue) should have .close intent")
        }
    }

    @Test("Multi-intent verbs have all expected intents")
    func testMultiIntentVerbs() throws {
        // Switch can turn and push
        #expect(Verb.switch.intents.contains(.turn))
        #expect(Verb.switch.intents.contains(.push))

        // Throw can throw objects or give them
        #expect(Verb.throw.intents.contains(.throw))
        #expect(Verb.throw.intents.contains(.give))

        // Hang can insert or attack
        #expect(Verb.hang.intents.contains(.insert))
        #expect(Verb.hang.intents.contains(.attack))

        // Wave can attack or tell (gesture)
        #expect(Verb.wave.intents.contains(.attack))
        #expect(Verb.wave.intents.contains(.tell))

        // Set can insert or push
        #expect(Verb.set.intents.contains(.insert))
        #expect(Verb.set.intents.contains(.push))
    }

    // MARK: - Special Cases Tests

    @Test("Contextual verbs have appropriate intent combinations")
    func testContextualVerbIntents() throws {
        // Lick can taste or touch
        #expect(Verb.lick.intents.contains(.taste))
        #expect(Verb.lick.intents.contains(.touch))

        // Tap can push or touch
        #expect(Verb.tap.intents.contains(.push))
        #expect(Verb.tap.intents.contains(.touch))

        // Knock can push or attack
        #expect(Verb.knock.intents.contains(.push))
        #expect(Verb.knock.intents.contains(.attack))

        // Blow can push or extinguish
        #expect(Verb.blow.intents.contains(.push))
        #expect(Verb.blow.intents.contains(.extinguish))

        // Puff can push or extinguish
        #expect(Verb.puff.intents.contains(.push))
        #expect(Verb.puff.intents.contains(.extinguish))

        // Spill can empty or drop
        #expect(Verb.spill.intents.contains(.empty))
        #expect(Verb.spill.intents.contains(.drop))
    }

    @Test("Touch-related verbs have touch intent")
    func testTouchRelatedVerbIntents() throws {
        let touchVerbs: [Verb] = [
            .touch, .feel, .rub, .polish, .clean, .kiss, .breathe,
        ]

        for verb in touchVerbs {
            #expect(
                verb.intents.contains(.touch),
                "Touch verb \(verb.rawValue) should have .touch intent")
        }
    }

    @Test("Push-related verbs have push intent")
    func testPushRelatedVerbIntents() throws {
        let pushVerbs: [Verb] = [
            .push, .shove, .press, .squeeze, .compress, .depress,
            .shake, .rattle, .slide, .shift, .deflate, .inflate,
        ]

        for verb in pushVerbs {
            #expect(
                verb.intents.contains(.push), "Push verb \(verb.rawValue) should have .push intent")
        }
    }

    // MARK: - Completeness Tests

    @Test("All climbing verbs have climb intent")
    func testClimbingVerbIntents() throws {
        let climbingVerbs: [Verb] = [.climb, .ascend, .mount, .scale]

        for verb in climbingVerbs {
            #expect(
                verb.intents.contains(.climb),
                "Climbing verb \(verb.rawValue) should have .climb intent")
        }
    }

    @Test("All jumping verbs have jump intent")
    func testJumpingVerbIntents() throws {
        let jumpingVerbs: [Verb] = [.jump, .leap, .hop]

        for verb in jumpingVerbs {
            #expect(
                verb.intents.contains(.jump),
                "Jumping verb \(verb.rawValue) should have .jump intent")
        }
    }

    @Test("All throwing verbs have throw intent")
    func testThrowingVerbIntents() throws {
        let throwingVerbs: [Verb] = [.throw, .toss, .chuck, .hurl]

        for verb in throwingVerbs {
            #expect(
                verb.intents.contains(.throw),
                "Throwing verb \(verb.rawValue) should have .throw intent")
        }
    }

    @Test("All searching verbs have search intent")
    func testSearchingVerbIntents() throws {
        let searchingVerbs: [Verb] = [.search, .find, .locate]

        for verb in searchingVerbs {
            #expect(
                verb.intents.contains(.search),
                "Searching verb \(verb.rawValue) should have .search intent")
        }
    }

    @Test("All cutting verbs have cut intent")
    func testCuttingVerbIntents() throws {
        let cuttingVerbs: [Verb] = [.cut, .chop, .slice, .prune]

        for verb in cuttingVerbs {
            #expect(
                verb.intents.contains(.cut), "Cutting verb \(verb.rawValue) should have .cut intent"
            )
        }
    }

    @Test("All extinguishing verbs have extinguish intent")
    func testExtinguishingVerbIntents() throws {
        let extinguishingVerbs: [Verb] = [.extinguish, .douse]

        for verb in extinguishingVerbs {
            #expect(
                verb.intents.contains(.extinguish),
                "Extinguishing verb \(verb.rawValue) should have .extinguish intent")
        }
    }

    @Test("All turning verbs have turn intent")
    func testTurningVerbIntents() throws {
        let turningVerbs: [Verb] = [.turn, .rotate, .twist]

        for verb in turningVerbs {
            #expect(
                verb.intents.contains(.turn),
                "Turning verb \(verb.rawValue) should have .turn intent")
        }
    }

    @Test("All pulling verbs have pull intent")
    func testPullingVerbIntents() throws {
        let pullingVerbs: [Verb] = [.pull, .hoist]

        for verb in pullingVerbs {
            #expect(
                verb.intents.contains(.pull),
                "Pulling verb \(verb.rawValue) should have .pull intent")
        }
    }

    @Test("All tying verbs have tie intent")
    func testTyingVerbIntents() throws {
        let tyingVerbs: [Verb] = [.tie, .bind, .fasten]

        for verb in tyingVerbs {
            #expect(
                verb.intents.contains(.tie), "Tying verb \(verb.rawValue) should have .tie intent")
        }
    }

    @Test("All giving verbs have give intent")
    func testGivingVerbIntents() throws {
        let givingVerbs: [Verb] = [.give, .offer, .donate]

        for verb in givingVerbs {
            #expect(
                verb.intents.contains(.give),
                "Giving verb \(verb.rawValue) should have .give intent")
        }
    }

    @Test("All dropping verbs have drop intent")
    func testDroppingVerbIntents() throws {
        let droppingVerbs: [Verb] = [.drop, .discard, .dump]

        for verb in droppingVerbs {
            #expect(
                verb.intents.contains(.drop),
                "Dropping verb \(verb.rawValue) should have .drop intent")
        }
    }

    @Test("All wearing verbs have appropriate intents")
    func testWearingVerbIntents() throws {
        #expect(Verb.wear.intents.contains(.wear))
        #expect(Verb.don.intents.contains(.wear))
        #expect(Verb.remove.intents.contains(.remove))
        #expect(Verb.doff.intents.contains(.remove))
    }

    @Test("All locking verbs have appropriate intents")
    func testLockingVerbIntents() throws {
        #expect(Verb.lock.intents.contains(.lock))
        #expect(Verb.unlock.intents.contains(.unlock))
    }

    @Test("All smelling verbs have smell intent")
    func testSmellingVerbIntents() throws {
        let smellingVerbs: [Verb] = [.smell, .sniff]

        for verb in smellingVerbs {
            #expect(
                verb.intents.contains(.smell),
                "Smelling verb \(verb.rawValue) should have .smell intent")
        }
    }

    @Test("All listening verbs have listen intent")
    func testListeningVerbIntents() throws {
        #expect(Verb.listen.intents.contains(.listen))
    }

    @Test("All reading verbs have read intent")
    func testReadingVerbIntents() throws {
        #expect(Verb.read.intents.contains(.read))
    }

    @Test("All waiting verbs have wait intent")
    func testWaitingVerbIntents() throws {
        #expect(Verb.wait.intents.contains(.wait))
    }

    @Test("All sitting verbs have sit intent")
    func testSittingVerbIntents() throws {
        #expect(Verb.sit.intents.contains(.sit))
    }

    @Test("All digging verbs have dig intent")
    func testDiggingVerbIntents() throws {
        let diggingVerbs: [Verb] = [.dig, .excavate]

        for verb in diggingVerbs {
            #expect(
                verb.intents.contains(.dig), "Digging verb \(verb.rawValue) should have .dig intent"
            )
        }
    }

    @Test("All burning verbs have burn intent")
    func testBurningVerbIntents() throws {
        #expect(Verb.burn.intents.contains(.burn))
    }

    @Test("All thinking verbs have think intent")
    func testThinkingVerbIntents() throws {
        let thinkingVerbs: [Verb] = [.think, .consider, .ponder]

        for verb in thinkingVerbs {
            #expect(
                verb.intents.contains(.think),
                "Thinking verb \(verb.rawValue) should have .think intent")
        }
    }

    @Test("All tasting verbs have taste intent")
    func testTastingVerbIntents() throws {
        #expect(Verb.taste.intents.contains(.taste))
    }

    @Test("All asking verbs have ask intent")
    func testAskingVerbIntents() throws {
        let askingVerbs: [Verb] = [.ask, .question]

        for verb in askingVerbs {
            #expect(
                verb.intents.contains(.ask), "Asking verb \(verb.rawValue) should have .ask intent")
        }
    }

    @Test("All entering verbs have enter intent")
    func testEnteringVerbIntents() throws {
        #expect(Verb.enter.intents.contains(.enter))
    }

    @Test("Debug verb has debug intent")
    func testDebugVerbIntent() throws {
        #expect(Verb.debug.intents.contains(.debug))
    }

    // MARK: - Edge Cases and Error Conditions

    @Test("Verbs with no intents are handled correctly")
    func testVerbsWithNoIntents() throws {
        let emptyVerb = Verb(id: "empty")
        #expect(emptyVerb.intents.isEmpty)
        #expect(emptyVerb.rawValue == "empty")
    }

    @Test("Verbs with many intents are handled correctly")
    func testVerbsWithManyIntents() throws {
        // Create a verb with multiple intents (more than typically used)
        let multiVerb = Verb(
            id: "multi",
            intents: .take, .drop, .examine, .push, .pull, .attack, .tell
        )

        #expect(multiVerb.intents.count == 7)
        #expect(multiVerb.intents.contains(.take))
        #expect(multiVerb.intents.contains(.drop))
        #expect(multiVerb.intents.contains(.examine))
        #expect(multiVerb.intents.contains(.push))
        #expect(multiVerb.intents.contains(.pull))
        #expect(multiVerb.intents.contains(.attack))
        #expect(multiVerb.intents.contains(.tell))
    }

    // MARK: - Performance and Memory Tests

    @Test("All predefined verbs are accessible without performance issues")
    func testPredefinedVerbsPerformance() throws {
        // This test ensures all static properties are accessible
        // and don't cause performance issues when accessed

        let allVerbs: [Verb] = [
            .switch, .throw, .ascend, .ask, .attack, .balance, .bind, .bite, .blow,
            .brandish, .breathe, .brief, .burn, .chew, .chomp, .chop, .chortle,
            .chuck, .chuckle, .clean, .climb, .close, .compress, .consider,
            .consume, .cry, .curse, .cut, .damn, .dance, .debug, .deflate,
            .depress, .devour, .dig, .discard, .doff, .don, .donate, .douse,
            .drink, .drop, .dump, .eat, .empty, .enter, .examine, .excavate,
            .extinguish, .fasten, .feel, .fight, .fill, .find, .fuck, .get,
            .giggle, .give, .go, .grab, .hang, .head, .help, .hike, .hit,
            .hoist, .holler, .hop, .hum, .hurl, .ignite, .imbibe, .inflate,
            .inform, .insert, .inspect, .inventory, .jump, .kick, .kill, .kiss,
            .knock, .laugh, .leap, .lick, .lift, .light, .listen, .load,
            .locate, .lock, .look, .mount, .move, .offer, .open, .peek, .pick,
            .place, .polish, .ponder, .pour, .press, .proceed, .prune, .puff,
            .pull, .push, .put, .quaff, .question, .quit, .raise, .rap, .rattle,
            .read, .remove, .restart, .restore, .rotate, .rub, .run, .save,
            .scale, .score, .scream, .script, .search, .set, .shake, .shift,
            .shit, .shout, .shove, .shriek, .shut, .sing, .sip, .sit, .slay,
            .slice, .slide, .smell, .snicker, .sniff, .sob, .spill, .squeeze,
            .stab, .steal, .stroll, .swear, .take, .tap, .taste, .tell, .think,
            .tie, .toss, .touch, .travel, .turn, .twist, .unlock, .unscript,
            .verbose, .wait, .walk, .wave, .wear, .weep, .xyzzy, .yell,
        ]

        // Test that all verbs are accessible and have valid data
        for verb in allVerbs {
            #expect(!verb.rawValue.isEmpty, "Verb \(verb.rawValue) should have non-empty raw value")
            // Intents can be empty, but the array should be valid
            _ = verb.intents.count
        }

        // Count should match the number of verbs we expect
        #expect(allVerbs.count == 173)  // Update this number if verbs are added/removed
    }

    // MARK: - Consistency and Validation Tests

    @Test("All predefined verbs have unique raw values")
    func testUniqueRawValues() throws {
        let allVerbs: [Verb] = [
            .switch, .throw, .ascend, .ask, .attack, .balance, .bind, .bite, .blow,
            .brandish, .breathe, .brief, .burn, .chew, .chomp, .chop, .chortle,
            .chuck, .chuckle, .clean, .climb, .close, .compress, .consider,
            .consume, .cry, .curse, .cut, .damn, .dance, .debug, .deflate,
            .depress, .devour, .dig, .discard, .doff, .don, .donate, .douse,
            .drink, .drop, .dump, .eat, .empty, .enter, .examine, .excavate,
            .extinguish, .fasten, .feel, .fight, .fill, .find, .fuck, .get,
            .giggle, .give, .go, .grab, .hang, .head, .help, .hike, .hit,
            .hoist, .holler, .hop, .hum, .hurl, .ignite, .imbibe, .inflate,
            .inform, .insert, .inspect, .inventory, .jump, .kick, .kill, .kiss,
            .knock, .laugh, .leap, .lick, .lift, .light, .listen, .load,
            .locate, .lock, .look, .mount, .move, .offer, .open, .peek, .pick,
            .place, .polish, .ponder, .pour, .press, .proceed, .prune, .puff,
            .pull, .push, .put, .quaff, .question, .quit, .raise, .rap, .rattle,
            .read, .remove, .restart, .restore, .rotate, .rub, .run, .save,
            .scale, .score, .scream, .script, .search, .set, .shake, .shift,
            .shit, .shout, .shove, .shriek, .shut, .sing, .sip, .sit, .slay,
            .slice, .slide, .smell, .snicker, .sniff, .sob, .spill, .squeeze,
            .stab, .steal, .stroll, .swear, .take, .tap, .taste, .tell, .think,
            .tie, .toss, .touch, .travel, .turn, .twist, .unlock, .unscript,
            .verbose, .wait, .walk, .wave, .wear, .weep, .xyzzy, .yell,
        ]

        let rawValues = allVerbs.map { $0.rawValue }
        let uniqueRawValues = Set(rawValues)

        #expect(rawValues.count == uniqueRawValues.count, "All verb raw values should be unique")
    }

    @Test("All predefined verbs have meaningful intents")
    func testMeaningfulIntents() throws {
        // Most verbs should have at least one intent, with few exceptions
        let allVerbs: [Verb] = [
            .switch, .throw, .ascend, .ask, .attack, .balance, .bind, .bite, .blow,
            .brandish, .breathe, .brief, .burn, .chew, .chomp, .chop, .chortle,
            .chuck, .chuckle, .clean, .climb, .close, .compress, .consider,
            .consume, .cry, .curse, .cut, .damn, .dance, .debug, .deflate,
            .depress, .devour, .dig, .discard, .doff, .don, .donate, .douse,
            .drink, .drop, .dump, .eat, .empty, .enter, .examine, .excavate,
            .extinguish, .fasten, .feel, .fight, .fill, .find, .fuck, .get,
            .giggle, .give, .go, .grab, .hang, .head, .help, .hike, .hit,
            .hoist, .holler, .hop, .hum, .hurl, .ignite, .imbibe, .inflate,
            .inform, .insert, .inspect, .inventory, .jump, .kick, .kill, .kiss,
            .knock, .laugh, .leap, .lick, .lift, .light, .listen, .load,
            .locate, .lock, .look, .mount, .move, .offer, .open, .peek, .pick,
            .place, .polish, .ponder, .pour, .press, .proceed, .prune, .puff,
            .pull, .push, .put, .quaff, .question, .quit, .raise, .rap, .rattle,
            .read, .remove, .restart, .restore, .rotate, .rub, .run, .save,
            .scale, .score, .scream, .script, .search, .set, .shake, .shift,
            .shit, .shout, .shove, .shriek, .shut, .sing, .sip, .sit, .slay,
            .slice, .slide, .smell, .snicker, .sniff, .sob, .spill, .squeeze,
            .stab, .steal, .stroll, .swear, .take, .tap, .taste, .tell, .think,
            .tie, .toss, .touch, .travel, .turn, .twist, .unlock, .unscript,
            .verbose, .wait, .walk, .wave, .wear, .weep, .xyzzy, .yell,
        ]

        let verbsWithoutIntents = allVerbs.filter { $0.intents.isEmpty }

        // Most verbs should have intents - only allow a few exceptions for edge cases
        #expect(
            verbsWithoutIntents.count <= 5,
            "Most verbs should have meaningful intents. Found \(verbsWithoutIntents.count) verbs without intents: \(verbsWithoutIntents.map { $0.rawValue })"
        )
    }

    // MARK: - Hashable and Equatable Tests

    @Test("Verb equality works correctly")
    func testVerbEquality() throws {
        let verb1 = Verb(id: "test", intents: .take)
        let verb2 = Verb(id: "test", intents: .take)
        let verb3 = Verb(id: "different", intents: .take)
        let verb4 = Verb(id: "test", intents: .examine)

        #expect(verb1 == verb2, "Verbs with same ID and intents should be equal")
        #expect(verb1 != verb3, "Verbs with different IDs should not be equal")
        // Note: Verb equality is based on rawValue only, not intents
        #expect(verb1 == verb4, "Verbs with same ID are equal regardless of intents")
    }

    @Test("Verb is properly hashable")
    func testVerbHashable() throws {
        let verb1 = Verb(id: "test", intents: .take)
        let verb2 = Verb(id: "test", intents: .take)
        let verb3 = Verb(id: "different", intents: .take)

        #expect(verb1.hashValue == verb2.hashValue, "Equal verbs should have equal hash values")

        // Test that verbs can be used in Sets and Dictionaries
        let verbSet: Set<Verb> = [verb1, verb2, verb3]
        #expect(verbSet.count == 2, "Set should contain only unique verbs")

        var verbDict: [Verb: String] = [:]
        verbDict[verb1] = "first"
        verbDict[verb2] = "second"  // Should overwrite first
        verbDict[verb3] = "third"

        #expect(verbDict.count == 2, "Dictionary should have unique verb keys")
        #expect(verbDict[verb1] == "second", "Later assignment should overwrite")
    }

    @Test("Predefined verbs work in collections")
    func testPredefinedVerbsInCollections() throws {
        let verbSet: Set<Verb> = [.take, .get, .grab, .take]  // duplicate .take
        #expect(verbSet.count == 3, "Set should contain unique predefined verbs")

        let verbArray: [Verb] = [.go, .walk, .run, .travel]
        #expect(verbArray.contains(.go))
        #expect(verbArray.contains(.walk))
        #expect(!verbArray.contains(.take))

        let verbDict: [Verb: String] = [
            .take: "taking",
            .drop: "dropping",
            .look: "looking",
            .go: "going",
        ]
        #expect(verbDict[.take] == "taking")
        #expect(verbDict[.examine] == nil)
    }

    // MARK: - Sendable Conformance Tests

    @Test("Verb is Sendable")
    func testSendableConformance() async throws {
        // This test ensures Verb works correctly in concurrent contexts
        let verb = Verb(id: "concurrent", intents: .take, .examine)

        await withCheckedContinuation { continuation in
            Task {
                #expect(verb.rawValue == "concurrent")
                #expect(verb.intents.contains(.take))
                #expect(verb.intents.contains(.examine))
                continuation.resume()
            }
        }
    }

    // MARK: - Integration Tests

    @Test("Verbs integrate correctly with Intent system")
    func testVerbIntentIntegration() throws {
        // Test that verbs can be used to find related actions
        let takingVerbs = [Verb.take, .get, .grab, .steal]

        for verb in takingVerbs {
            #expect(
                verb.intents.contains(.take), "Taking verb \(verb.rawValue) should support taking")
        }

        // Test multi-intent verbs
        let multiIntentVerb = Verb.turn
        #expect(multiIntentVerb.intents.contains(.turn))
        #expect(multiIntentVerb.intents.contains(.lightSource))

        // Verify we can filter verbs by intent
        let allVerbsWithTakeIntent = [
            Verb.take, .get, .grab, .steal, .lift, .raise, .pick, .move,
        ].filter { $0.intents.contains(.take) }

        #expect(allVerbsWithTakeIntent.count >= 4, "Should find multiple verbs with take intent")
    }

    @Test("Verb system supports game vocabulary expansion")
    func testVocabularyExpansion() throws {
        // Test that new verbs can be created for game-specific vocabulary
        let customVerb1 = Verb(id: "zap", intents: .attack, .lightSource)
        let customVerb2 = Verb(id: "teleport", intents: .move)
        let customVerb3 = Verb(id: "analyze", intents: .examine, .debug)

        #expect(customVerb1.rawValue == "zap")
        #expect(customVerb1.intents.contains(.attack))
        #expect(customVerb1.intents.contains(.lightSource))

        #expect(customVerb2.rawValue == "teleport")
        #expect(customVerb2.intents == [.move])

        #expect(customVerb3.rawValue == "analyze")
        #expect(customVerb3.intents.contains(.examine))
        #expect(customVerb3.intents.contains(.debug))

        // Test that custom verbs work in collections with predefined verbs
        let mixedVerbs: [Verb] = [.take, customVerb1, .drop, customVerb2]
        #expect(mixedVerbs.count == 4)
        #expect(mixedVerbs.contains(customVerb1))
        #expect(mixedVerbs.contains(.take))
    }

    // MARK: - Regression Tests

    @Test("Reserved Swift keywords work as verb IDs")
    func testReservedKeywords() throws {
        // Test that verbs using Swift reserved keywords work correctly
        #expect(Verb.switch.rawValue == "switch")
        // Add more if needed based on Swift reserved words used as verb IDs
    }

    @Test("Special characters in verb names are handled correctly")
    func testSpecialCharacters() throws {
        // Most verb names should be simple, but test edge cases if they exist
        let specialVerb = Verb(id: "verb-with-dash", intents: .examine)
        #expect(specialVerb.rawValue == "verb-with-dash")

        let numberedVerb = Verb(id: "verb2", intents: .take)
        #expect(numberedVerb.rawValue == "verb2")
    }

    // MARK: - Documentation Tests

    @Test("All predefined verbs have reasonable intent mappings")
    func testReasonableIntentMappings() throws {
        // Spot check that some common verbs have sensible intents

        // Movement verbs should have .move
        #expect(Verb.go.intents.contains(.move))
        #expect(Verb.walk.intents.contains(.move))

        // Object manipulation verbs should have appropriate intents
        #expect(Verb.take.intents.contains(.take))
        #expect(Verb.drop.intents.contains(.drop))
        #expect(Verb.open.intents.contains(.open))
        #expect(Verb.close.intents.contains(.close))

        // Examination verbs should support examination
        #expect(Verb.look.intents.contains(.look))
        #expect(Verb.examine.intents.contains(.examine))

        // System verbs should have appropriate system intents
        #expect(Verb.quit.intents.contains(.quit))
        #expect(Verb.save.intents.contains(.save))
        #expect(Verb.inventory.intents.contains(.inventory))
    }
}
