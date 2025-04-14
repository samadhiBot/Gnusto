//import CustomDump
//import NaturalLanguage
//import Testing
//
//@testable import Gnusto
//
//struct NLParserTests {
//    let parser = NLParser()
//
//    @Test("Parse empty command")
//    func parseEmptyCommand() {
//        expectNoDifference(parser.parseCommand(""), .empty)
//    }
//
//    @Test("Parse simple command")
//    func parseSimpleCommand() {
//        expectNoDifference(
//            parser.parseCommand("examine chest"),
//            NLParser.ProtoCommand(
//                verb: ["examine"],
//                directObject: ["chest"]
//            )
//        )
//
//        expectNoDifference(
//            parser.parseCommand("take the red book"),
//            NLParser.ProtoCommand(
//                verb: ["take"],
//                directObject: ["book"],
//                directObjectModifiers: ["red"]
//            )
//        )
//    }
//
//    @Test("Parse abbreviated command")
//    func parseAbbreviatedCommand() {
//        expectNoDifference(
//            parser.parseCommand("x wooden chest"),
//            NLParser.ProtoCommand(
//                verb: ["x"],
//                directObject: ["chest"],
//                directObjectModifiers: ["wooden"]
//            )
//        )
//    }
//
//    @Test("Parse command with preposition")
//    func parseCommandWithPreposition() {
//        expectNoDifference(
//            parser.parseCommand("put the red book in the dark corner"),
//            NLParser.ProtoCommand(
//                verb: ["put"],
//                directObject: ["book"],
//                directObjectModifiers: ["red"],
//                indirectObject: ["corner"],
//                indirectObjectModifiers: ["dark"],
//                prepositions: "in"
//            )
//        )
//    }
//
//    @Test("Parse command single word look")
//    func parseCommandSingleWordLook() {
//        expectNoDifference(
//            parser.parseCommand("look"),
//            NLParser.ProtoCommand(
//                verb: ["look"]
//            )
//        )
//
//        expectNoDifference(
//            parser.parseCommand("l"),
//            NLParser.ProtoCommand(
//                verb: ["l"]
//            )
//        )
//    }
//
//    @Test("Parse command single word inventory")
//    func parseCommandSingleInventory() {
//        expectNoDifference(
//            parser.parseCommand("inventory"),
//            NLParser.ProtoCommand(
//                verb: ["inventory"]
//            )
//        )
//
//        expectNoDifference(
//            parser.parseCommand("i"),
//            NLParser.ProtoCommand(
//                verb: ["i"]
//            )
//        )
//    }
//
//    @Test("Parse command single word quit")
//    func parseCommandSingleQuit() {
//        expectNoDifference(
//            parser.parseCommand("quit"),
//            NLParser.ProtoCommand(
//                verb: ["quit"]
//            )
//        )
//    }
//
//    @Test("Parse command move direction")
//    func parseCommandMoveDirection() {
//        expectNoDifference(
//            parser.parseCommand("north"),
//            NLParser.ProtoCommand(
//                direction: "north"
//            )
//        )
//
//        expectNoDifference(
//            parser.parseCommand("up"),
//            NLParser.ProtoCommand(
//                direction: "up"
//            )
//        )
//
//        expectNoDifference(
//            parser.parseCommand("down"),
//            NLParser.ProtoCommand(
//                direction: "down"
//            )
//        )
//
//        expectNoDifference(
//            parser.parseCommand("move north"),
//            NLParser.ProtoCommand(
//                verb: ["move"],
//                direction: "north"
//            )
//        )
//
//        expectNoDifference(
//            parser.parseCommand("go north"),
//            NLParser.ProtoCommand(
//                verb: ["go"],
//                direction: "north"
//            )
//        )
//    }
//
//    @Test("Parse entering and exiting")
//    func parseEnteringAndExiting() {
//        expectNoDifference(
//            parser.parseCommand("in"),
//            NLParser.ProtoCommand(
//                direction: "in"
//            )
//        )
//
//        expectNoDifference(
//            parser.parseCommand("out"),
//            NLParser.ProtoCommand(
//                direction: "out"
//            )
//        )
//
//        expectNoDifference(
//            parser.parseCommand("go inside"),
//            NLParser.ProtoCommand(
//                    verb: ["go"],
//                    direction: "inside"
//                )
//        )
//
//        expectNoDifference(
//            parser.parseCommand("climb inside the pod"),
//            NLParser.ProtoCommand(
//                verb: ["climb"],
//                directObject: ["pod"],
//                prepositions: "inside"
//            )
//        )
//
//        expectNoDifference(
//            parser.parseCommand("go in"),
//            NLParser.ProtoCommand(
//                verb: ["go"],
//                direction: "in"
//            )
//        )
//    }
//
//    @Test("Parse command verb phrase")
//    func parseCommandVerbPhrase() {
//        expectNoDifference(
//            parser.parseCommand("pick up the red book"),
//            NLParser.ProtoCommand(
//                verb: ["pick", "up"],
//                directObject: ["book"],
//                directObjectModifiers: ["red"]
//            )
//        )
//
//        expectNoDifference(
//            parser.parseCommand("pick up the glowing blob with the rusty old pliers"),
//            NLParser.ProtoCommand(
//                verb: ["pick", "up"],
//                directObject: ["blob"],
//                directObjectModifiers: ["glowing"],
//                indirectObject: ["pliers"],
//                indirectObjectModifiers: ["rusty", "old"],
//                prepositions: "with"
//            )
//        )
//    }
//
//    @Test("Parse command split verb phrase")
//    func parseCommandSplitVerbPhrase() {
//        expectNoDifference(
//            parser.parseCommand("pick the red book up"),
//            NLParser.ProtoCommand(
//                verb: ["pick"],
//                directObject: ["book"],
//                directObjectModifiers: ["red"],
//                prepositions: "up"
//            )
//        )
//    }
//
//    @Test("Parse command putting things on")
//    func parseCommandPuttingThingsOn() {
//        expectNoDifference(
//            parser.parseCommand("put on the dark cloak"),
//            NLParser.ProtoCommand(
//                verb: ["put"],
//                directObject: ["cloak"],
//                directObjectModifiers: ["dark"],
//                prepositions: "on"
//            )
//        )
//
//        expectNoDifference(
//            parser.parseCommand("put the dark cloak on"),
//            NLParser.ProtoCommand(
//                verb: ["put"],
//                directObject: ["cloak"],
//                directObjectModifiers: ["dark"],
//                prepositions: "on"
//            )
//        )
//
//        expectNoDifference(
//            parser.parseCommand("put the dark cloak on the large wooden table"),
//            NLParser.ProtoCommand(
//                verb: ["put"],
//                directObject: ["cloak"],
//                directObjectModifiers: ["dark"],
//                indirectObject: ["table"],
//                indirectObjectModifiers: ["large", "wooden"],
//                prepositions: "on"
//            )
//        )
//    }
//}
//
//// MARK: - Additional Hardening Tests
//
//extension NLParserTests {
//    @Test("Mis-tagged words: 'using' as Verb, 'iron' as Noun")
//    func parseMistaggedUsingIron() {
//        // Simulate NLTagger potentially mis-tagging 'using' as Verb and 'iron' as Noun
//        // The current parser logic might put 'using' in modifiers and 'iron'/'sword' in IO.
//        // Depending on desired behavior, the parser or CommandParser might need adjustment.
//        // For now, we test the current logic's likely output.
//        expectNoDifference(
//            parser.parseCommand("attack troll using iron sword"),
//            NLParser.ProtoCommand(
//                verb: ["attack"], // Assuming 'attack' is tagged Noun, caught as first verb
//                directObject: ["troll"], // Assuming 'troll' is tagged Noun
//                // Assuming 'using' (tagged Verb) goes to DO Modifiers because DO is filled
////                directObjectModifiers: ["using"],
//                indirectObject: ["iron", "sword"], // Assuming 'sword' is Noun
//                // Assuming 'iron' (tagged Noun) goes to IO Modifiers because IO is empty
//                indirectObjectModifiers: ["using"],
//                preposition: nil // Preposition slot not filled if 'using' tagged as Verb
//            ),
//            "Test assumes NLTagger tags: attack(Noun), troll(Noun), using(Verb), iron(Noun), sword(Noun)"
//        )
//
//        // Let's also test the ideal case where 'using' is correctly tagged as Preposition
//        // (Requires modifying the simulated tagger output if testing NLParser directly,
//        // or just asserting the desired outcome if testing CommandParser later)
//        // Desired ProtoCommand (if tags are correct):
//        // ProtoCommand(
//        //     verb: ["attack"], directObject: ["troll"],
//        //     indirectObject: ["sword"], indirectObjectModifiers: ["iron"], prepositions: "using"
//        // )
//    }
//
//    @Test("Mis-tagged words: 'velvet' as Noun")
//    func parseMistaggedVelvet() {
//        // Simulate NLTagger mis-tagging 'velvet' as Noun
//        expectNoDifference(
//            parser.parseCommand("wear velvet cloak"),
//            NLParser.ProtoCommand(
//                verb: ["wear"], // Assuming 'wear' is Verb
//                directObject: ["cloak"], // Assuming 'cloak' is Noun
//                // 'velvet' (tagged Noun) should become a modifier as DO is empty when it's processed
//                directObjectModifiers: ["velvet"]
//            ),
//            "Test assumes NLTagger tags: wear(Verb), velvet(Noun), cloak(Noun)"
//        )
//    }
//
//    @Test("Ambiguity/Order: Give without preposition")
//    func parseGiveNoPreposition() {
//        // How does the parser handle DO vs IO without a preposition hint?
//        expectNoDifference(
//            parser.parseCommand("give troll sword"),
//            NLParser.ProtoCommand(
//                verb: ["give"],
//                directObject: ["troll"], // First noun becomes DO
//                indirectObject: ["sword"] // Second noun becomes IO
//            )
//        )
//    }
//
//    @Test("Ambiguity/Order: Give with preposition")
//    func parseGiveWithPreposition() {
//        expectNoDifference(
//            parser.parseCommand("give sword to troll"),
//            NLParser.ProtoCommand(
//                verb: ["give"],
//                directObject: ["sword"],
//                indirectObject: ["troll"],
//                prepositions: "to"
//            )
//        )
//    }
//
//    @Test("Complex Modifiers: Multiple adjectives")
//    func parseComplexModifiers() {
//        expectNoDifference(
//            parser.parseCommand("take the small rusty key"),
//            NLParser.ProtoCommand(
//                verb: ["take"],
//                directObject: ["key"],
//                directObjectModifiers: ["small", "rusty"] // Determiner 'the' is ignored
//            )
//        )
//    }
//
//    @Test("Complex Modifiers: Intervening Adverb (Expected to be Ignored)")
//    func parseComplexModifiersWithAdverb() {
//        // Assuming adverbs that aren't directions are currently ignored or mis-assigned
//        expectNoDifference(
//            parser.parseCommand("examine the intricately carved wooden box"),
//            NLParser.ProtoCommand(
//                verb: ["examine"],
//                directObject: ["box"],
//                directObjectModifiers: ["intricately", "carved", "wooden"]
//            )
//        )
//    }
//
//    @Test("Pronouns: Indirect Object")
//    func parsePronounIO() {
//        expectNoDifference(
//            parser.parseCommand("give sword to me"),
//            NLParser.ProtoCommand(
//                verb: ["give"],
//                directObject: ["sword"],
//                indirectObject: ["me"], // Pronoun treated like Noun for IO
//                prepositions: "to"
//            )
//        )
//    }
//
//    @Test("Pronouns: Prepositional Object")
//    func parsePronounPrepObj() {
//        expectNoDifference(
//            parser.parseCommand("put cloak on myself"),
//            NLParser.ProtoCommand(
//                verb: ["put"],
//                directObject: ["cloak"],
//                indirectObject: ["myself"], // Pronoun treated like Noun for IO
//                prepositions: "on"
//            )
//        )
//    }
//
//    @Test("Pronouns: Direct Object")
//    func parsePronounDO() {
//        expectNoDifference(
//            parser.parseCommand("take it"),
//            NLParser.ProtoCommand(
//                verb: ["take"],
//                directObject: ["it"] // Pronoun treated like Noun for DO
//            )
//        )
//    }
//
//    @Test("More Directions: Verb + Direction Word")
//    func parseMoreDirections() {
//        // 'inside' is often tagged Preposition. Check 2-token rule.
//        expectNoDifference(
//            parser.parseCommand("move inside"),
//            NLParser.ProtoCommand(
//                verb: ["move"],
//                direction: "inside" // Expect 'inside' preposition becomes direction in 2-token command
//            )
//        )
//    }
//
//    @Test("More Directions: Ambiguous verb/object")
//    func parseAmbiguousDirectionObject() {
//        // Is 'ladder' a direction or an object here? Current logic likely treats it as DO.
//        expectNoDifference(
//            parser.parseCommand("climb ladder"),
//            NLParser.ProtoCommand(
//                verb: ["climb"],
//                directObject: ["ladder"]
//            )
//        )
//    }
//
//    @Test("More Prepositions: Look Under")
//    func parseMorePrepositionsLookUnder() {
//        // How is IO handled when there is no DO?
//        expectNoDifference(
//            parser.parseCommand("look under rock"),
//            NLParser.ProtoCommand(
//                verb: ["look"],
//                // Current logic puts first Noun after Prep into IO if DO is empty/missing
//                indirectObject: ["rock"],
//                prepositions: "under"
//            )
//        )
//    }
//
//    @Test("More Prepositions: Hit With")
//    func parseMorePrepositionsHitWith() {
//        expectNoDifference(
//            parser.parseCommand("hit troll with sword"),
//            NLParser.ProtoCommand(
//                verb: ["hit"],
//                directObject: ["troll"],
//                indirectObject: ["sword"],
//                prepositions: "with"
//            )
//        )
//    }
//
//    @Test("Edge Cases: Only Stop Words")
//    func parseEdgeStopWords() {
//        // Assuming determiners are ignored, resulting in empty command
//        expectNoDifference(
//            parser.parseCommand("the the the"),
//            .empty
//        )
//    }
//
//    @Test("Edge Cases: Verb Only")
//    func parseEdgeVerbOnly() {
//        expectNoDifference(
//            parser.parseCommand("go"),
//            NLParser.ProtoCommand(verb: ["go"])
//        )
//        expectNoDifference(
//            parser.parseCommand("move"),
//            NLParser.ProtoCommand(verb: ["move"])
//        )
//    }
//
//    @Test("Edge Cases: Unknown Verb")
//    func parseEdgeUnknownVerb() {
//        expectNoDifference(
//            parser.parseCommand("xyzzy book"),
//            NLParser.ProtoCommand(
//                verb: ["xyzzy"], // First non-tag word assumed verb
//                directObject: ["book"]
//            )
//        )
//    }
//}
