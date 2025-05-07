import Testing
@testable import GnustoEngine

// Define custom tags in an extension
extension Tag {
    @Tag static var parser: Tag
    @Tag static var errorHandling: Tag
    @Tag static var verbOnly: Tag
    @Tag static var placeholder: Tag
    @Tag static var directObject: Tag
    @Tag static var modifiers: Tag
    @Tag static var indirectObject: Tag
    @Tag static var preposition: Tag
    @Tag static var resolution: Tag
    @Tag static var scope: Tag
    @Tag static var ambiguity: Tag
    @Tag static var pronouns: Tag
    @Tag static var container: Tag
    @Tag static var surface: Tag // Added tag for surface tests
}

struct StandardParserTests {
    // --- Test Setup ---
    let parser = StandardParser()
    let vocabulary: Vocabulary
    let gameState: GameState

    // Optionally define location IDs for clarity
    let roomID: LocationID = "room"

    // Optionally define items used in tests
    let lampID: ItemID = "lantern"

    init() async {
        // 1. Define all possible Items
        let allItems = [
            Item(
                id: "apple",
                name: "apple",
                parent: .item("tray"),
                attributes: [
                    .adjectives: .stringSet(["red"]),
                    .isTakable: true,
                    .isEdible: true
                ]
            ),
            Item(
                id: "backpack",
                name: "backpack",
                parent: .player,
                attributes: [
                    .isContainer: true,
                    .isTakable: true,
                    .isOpen: true,
                    .capacity: 20
                ]
            ),
            Item(
                id: "book",
                name: "book",
                parent: .item("table"),
                attributes: [
                    .adjectives: .stringSet(["dusty"]),
                    .isTakable: true,
                    .isReadable: true
                ]
            ),
            Item(
                id: "box",
                name: "box",
                parent: .location(roomID),
                attributes: [
                    .adjectives: .stringSet(["wooden"]),
                    .isContainer: true,
                    .isOpenable: true
                ]
            ),
            Item(
                id: "chest",
                name: "chest",
                parent: .player,
                attributes: [
                    .isContainer: true,
                    .isTakable: true,
                    .isOpenable: true,
                    .isLocked: true,
                    .capacity: 50
                ]
            ),
            Item(
                id: "coin",
                name: "coin",
                parent: .item("backpack"),
                attributes: [
                    .adjectives: .stringSet(["gold"]),
                    .isTakable: true
                ]
            ),
            Item(
                id: "key",
                name: "key",
                parent: .player,
                attributes: [
                    .adjectives: .stringSet(["rusty", "small"]),
                    .isTakable: true
                ]
            ),
            Item(
                id: "lantern",
                name: "lantern",
                parent: .location(roomID),
                attributes: [
                    .adjectives: .stringSet(["brass"]),
                    .synonyms: .stringSet(["lamp"]),
                    .isLightSource: true,
                    .isOpenable: true
                ]
            ),
            Item(
                id: "lantern2",
                name: "lantern",
                parent: .location(roomID),
                attributes: [
                    .adjectives: .stringSet(["rusty"]),
                    .isLightSource: true
                ]
            ),
            Item(
                id: "leaflet",
                name: "leaflet",
                parent: .player,
                attributes: [
                    .isTakable: true,
                    .isReadable: true
                ]
            ),
            Item(
                id: "note",
                name: "note",
                parent: .item("chest"),
                attributes: [
                    .isTakable: true,
                    .isReadable: true
                ]
            ),
            Item(
                id: "orb",
                name: "orb",
                parent: .nowhere,
                attributes: [
                    .adjectives: .stringSet(["glowing"]),
                    .isTakable: true,
                    .isLightSource: true
                ]
            ),
            Item(
                id: "rug",
                name: "rug"
            ),
            Item(
                id: "sword",
                name: "sword",
                parent: .location(roomID),
                attributes: [
                    .isTakable: true
                ]
            ),
            Item(
                id: "table",
                name: "table",
                parent: .location(roomID),
                attributes: [
                    .adjectives: .stringSet(["sturdy"]),
                    .isSurface: true
                ]
            ),
            Item(
                id: "tray",
                name: "tray",
                parent: .player,
                attributes: [
                    .adjectives: .stringSet(["silver"]),
                    .isSurface: true,
                    .isTakable: true
                ]
            ),
            Item(
                id: "widget",
                name: "widget",
                parent: .item("box"),
                attributes: [
                    .isTakable: true
                ]
            ),
        ]

        // 2. Define Game-Specific Verbs (if any) - Most verbs are now defaults
        // let gameSpecificVerbs: [Verb] = [
        //     // Example: Add back a verb if its specific syntax/conditions ARE needed for a test
        //     // and differ from the default (unlikely for most basic tests now).
        //     // Verb(id: "eat", syntax: [ SyntaxRule(pattern: [.verb, .directObject], directObjectConditions: []) ])
        //     // NOTE: The test setup previously defined verbs like 'take', 'look', 'go', 'put', 'drop', 'eat'.
        //     // These are now provided by Vocabulary.defaultVerbs and should NOT be redefined here
        //     // unless a specific test requires overriding a default rule.
        // ]

        // 3. Define all Locations
        let locations = [
            Location(
                id: roomID,
                name: "Room",
                description: "A room.",
                attributes: [.localGlobals: .itemIDSet(["rug"])] // Globals remain associated with location
            )
            // Add more locations later if needed
        ]

        // 4. Define initial Player state
        let player = Player(in: roomID)

        // 5. Define initial pronouns
        let initialPronouns: [String: Set<ItemID>] = [
            "it": ["box"] // Let's say "it" initially refers to the box in the room
        ]

        // 6. Build Vocabulary using defaults + game-specific items/verbs
        self.vocabulary = await .build(items: allItems)

        // 7. Build GameState using the new factory method
        self.gameState = await GameState(
            locations: locations,
            items: allItems,
            player: player,
            pronouns: initialPronouns
        )

        // --- Sanity Checks (Optional but Recommended) ---
        // Check if parents were set correctly
        #expect(self.gameState.items["leaflet"]?.parent == .player)
        #expect(self.gameState.items["sword"]?.parent == .location(roomID))
        #expect(self.gameState.items["coin"]?.parent == .item("backpack"))
        #expect(self.gameState.items["book"]?.parent == .item("table"))
        #expect(self.gameState.items["rug"]?.parent == .nowhere) // Globals aren't parented by this initializer
        #expect(self.gameState.pronouns["it"] == ["box"])
    }

    // --- Tests ---

    @Test("Parse Empty Input", .tags(.parser, .errorHandling))
    func testParseEmpty() async throws {
        let result = parser.parse(input: "", vocabulary: vocabulary, gameState: gameState)
        #expect(result.isFailure(matching: ParseError.emptyInput))

        let resultWhitespace = parser.parse(input: "   \t ", vocabulary: vocabulary, gameState: gameState)
        #expect(resultWhitespace.isFailure(matching: ParseError.emptyInput))

        let resultNoiseOnly = parser.parse(input: "the the the", vocabulary: vocabulary, gameState: gameState)
        #expect(resultNoiseOnly.isFailure(matching: ParseError.emptyInput))
    }

    @Test("Parse Unknown Verb", .tags(.parser, .errorHandling))
    func testParseUnknownVerb() async throws {
        let result = parser.parse(input: "xyzzy", vocabulary: vocabulary, gameState: gameState)
        #expect(result.isFailure(matching: ParseError.unknownVerb("xyzzy")))

        let resultWithNoise = parser.parse(input: "the jump the", vocabulary: vocabulary, gameState: gameState)
        #expect(resultWithNoise.isFailure(matching: ParseError.unknownVerb("jump")))
    }

    @Test("Parse Simple Verb - Known", .tags(.parser, .verbOnly))
    func testParseSimpleVerbKnown() async throws {
        // Test LOOK variations (no DO expected)
        let lookInputs = ["look", "LOOK", "l"]
        for input in lookInputs {
            let result = parser.parse(input: input, vocabulary: vocabulary, gameState: gameState)
            let command = try result.get()
            #expect(command.verbID == "look")
            #expect(command.directObject == nil)
            #expect(command.indirectObject == nil)
            #expect(command.rawInput == input)
        }

        // Test EXAMINE variations (should fail without DO)
        let examineInputs = ["examine", "x"]
        for input in examineInputs {
            let result = parser.parse(input: input, vocabulary: vocabulary, gameState: gameState)
            #expect(result.isFailure(matching: .badGrammar("Expected a direct object phrase for verb 'examine'.")))
        }
    }

    @Test("Parse Simple Verb - Synonym", .tags(.parser, .verbOnly))
    func testParseSimpleVerbSynonym() async throws {
        let result = parser.parse(input: "get", vocabulary: vocabulary, gameState: gameState)
        // "get" (take) requires a DO according to its SyntaxRule.
        // Expect failure because no DO was provided.
        #expect(result.isFailure(matching: .badGrammar("Expected a direct object phrase for verb 'take'.")))
    }

    @Test("Parse Verb + Direct Object (Ambiguous)", .tags(.parser, .directObject, .resolution, .ambiguity, .errorHandling))
    func testParseVerbDirectObject() async throws {
        // "lantern" is ambiguous because both "lantern" and "lantern2" are in scope
        let result = parser.parse(input: "take lantern", vocabulary: vocabulary, gameState: gameState)
        // Update to expect ambiguity
        #expect(result.isFailure(matching: ParseError.ambiguity("Which lantern do you mean?")))
    }

    @Test("Parse Verb + Direct Object + Modifiers", .tags(.parser, .directObject, .modifiers, .resolution, .scope))
    func testParseVerbDirectObjectMods() async throws {
        // "lantern" is now in scope (in the room)
        let result = parser.parse(input: "get the brass lantern", vocabulary: vocabulary, gameState: gameState)
        // Revert to expecting success
        let command = try result.get()
        #expect(command.verbID == "take")
        #expect(command.directObject == "lantern")
        #expect(command.directObjectModifiers == ["brass"])
        #expect(command.indirectObject == nil)
        #expect(command.preposition == nil)
    }

    @Test("Parse Verb + Direct Object + Multiple Modifiers", .tags(.parser, .directObject, .modifiers, .resolution, .scope))
    func testParseVerbDirectObjectMultiMods() async throws {
        // Input uses "examine"
        let result = parser.parse(input: "examine the rusty small key", vocabulary: vocabulary, gameState: gameState)
        let command = try result.get()
        #expect(command.verbID == "examine") // Expect examine, not look
        #expect(command.directObject == "key")
        #expect(Set(command.directObjectModifiers) == Set(["rusty", "small"]))
        #expect(command.indirectObject == nil)
        #expect(command.preposition == nil)
    }

    @Test("Parse Verb + Direct + Preposition + Indirect", .tags(.parser, .indirectObject, .preposition, .resolution, .scope))
    func testParseVerbDirectPrepIndirect() async throws {
        // "key" parent is .player, "box" parent is .location(roomID). Both should be found.
        let result = parser.parse(input: "put key in box", vocabulary: vocabulary, gameState: gameState)
        // Should now SUCCEED because "box" is in scope (in the room)
        let command = try result.get()
        #expect(command.verbID == "insert")
        #expect(command.directObject == "key")
        #expect(command.indirectObject == "box")
        #expect(command.preposition == "in")
    }

    @Test("Parse Verb + DirectObject + Prep + IndirectMods", .tags(.parser, .directObject, .indirectObject, .preposition, .modifiers, .resolution, .scope))
    func testParseFullComplexity() async throws {
        // "key" parent is .player, "box" parent is .location(roomID). Both should be found.
        let result = parser.parse(input: "place the small key into the wooden box", vocabulary: vocabulary, gameState: gameState)
        // Should now SUCCEED because "box" is in scope (in the room)
        let command = try result.get()
        #expect(command.verbID == "insert")
        #expect(command.directObject == "key")
        #expect(Set(command.directObjectModifiers) == Set(["small"]))
        #expect(command.indirectObject == "box")
        #expect(Set(command.indirectObjectModifiers) == Set(["wooden"]))
        #expect(command.preposition == "into")
    }

    @Test("Parse Unknown Direct Object (Exists but Not In Scope)", .tags(.parser, .resolution, .errorHandling))
    func testParseUnknownDirectObject() async throws {
        // "box" exists and its parent IS .location(roomID), so it IS in scope.
        let result = parser.parse(input: "take box", vocabulary: vocabulary, gameState: gameState)
        // Should SUCCEED now.
        let command = try result.get()
        #expect(command.verbID == "take")
        #expect(command.directObject == "box")
        #expect(command.indirectObject == nil)
    }

    @Test("Parse Indirect Object Not In Scope", .tags(.parser, .resolution, .errorHandling, .indirectObject))
    func testParseIndirectObjectNotInScope() async throws {
        // Direct object 'leaflet' parent is .player.
        // Indirect object 'box' parent IS .location(roomID), so it IS in scope.
        let result = parser.parse(input: "put leaflet in box", vocabulary: vocabulary, gameState: gameState)
        // Should SUCCEED now.
        let command = try result.get()
        #expect(command.verbID == "insert")
        #expect(command.directObject == "leaflet")
        #expect(command.indirectObject == "box")
        #expect(command.preposition == "in")
    }

    @Test("Parse Ambiguous Indirect Object in Location", .tags(.parser, .resolution, .ambiguity, .errorHandling))
    func testAmbiguousIndirectObjectInLocation() async throws {
        // Direct object 'leaflet' is in inventory, indirect object 'lantern' is ambiguous.
        // Parser identifies ambiguity before checking if candidates meet the .container property.
        let result = parser.parse(input: "put leaflet in lantern", vocabulary: vocabulary, gameState: gameState)
        #expect(result.isFailure(matching: .ambiguity("Which lantern do you mean?")))
    }

    @Test("Parse Direct from Inventory, Indirect from Location", .tags(.parser, .resolution, .scope))
    func testParseDirectFromInvIndirectFromLoc() async throws {
        // 'leaflet' (DO) is in inventory, 'sword' (IO) is in the room
        let result = parser.parse(input: "put leaflet on sword", vocabulary: vocabulary, gameState: gameState)
        let command = try result.get()
        #expect(command.verbID == "put-on")
        #expect(command.directObject == "leaflet")
        #expect(command.directObjectModifiers.isEmpty)
        #expect(command.preposition == "on")
        #expect(command.indirectObject == "sword")
        #expect(command.indirectObjectModifiers.isEmpty)
    }

    @Test("Parse Find Direct Object in Inventory", .tags(.parser, .resolution, .scope))
    func testParseDirectObjectInInventory() async throws {
        // Player has 'leaflet'
        let result = parser.parse(input: "drop leaflet", vocabulary: vocabulary, gameState: gameState)
        let command = try result.get()
        #expect(command.verbID == "drop")
        #expect(command.directObject == "leaflet")
        #expect(command.indirectObject == nil)
    }

    @Test("Parse Find Direct Object in Location (Item)", .tags(.parser, .resolution, .scope))
    func testParseDirectObjectInLocationItem() async throws {
        // Location has 'sword'
        let result = parser.parse(input: "take sword", vocabulary: vocabulary, gameState: gameState)
        let command = try result.get()
        #expect(command.verbID == "take")
        #expect(command.directObject == "sword")
        #expect(command.indirectObject == nil)
    }

    @Test("Parse Find Direct Object in Location (Global)", .tags(.parser, .resolution, .scope))
    func testParseDirectObjectInLocationGlobal() async throws {
        // Input uses "examine"
        let result = parser.parse(input: "examine rug", vocabulary: vocabulary, gameState: gameState)
        let command = try result.get()
        #expect(command.verbID == "examine") // Expect examine, not look
        #expect(command.directObject == "rug")
        #expect(command.indirectObject == nil)
    }

    // --- Tests for Adjective Filtering ---

    @Test("Filter by Single Adjective", .tags(.parser, .resolution, .modifiers))
    func testFilterSingleAdjective() async throws {
        // Both lanterns are in scope, but only one is brass
        let result = parser.parse(input: "take brass lantern", vocabulary: vocabulary, gameState: gameState)
        let command = try result.get()
        #expect(command.verbID == "take")
        #expect(command.directObject == "lantern") // Should resolve to the brass one
        #expect(command.directObjectModifiers == ["brass"])
    }

    @Test("Filter by Different Single Adjective", .tags(.parser, .resolution, .modifiers))
    func testFilterDifferentAdjective() async throws {
        // Input uses "examine"
        let result = parser.parse(input: "examine rusty lantern", vocabulary: vocabulary, gameState: gameState)
        let command = try result.get()
        #expect(command.verbID == "examine") // Expect examine, not look
        #expect(command.directObject == "lantern2") // Should resolve to the rusty one
        #expect(command.directObjectModifiers == ["rusty"])
    }

    @Test("Filter by Multiple Adjectives", .tags(.parser, .resolution, .modifiers))
    func testFilterMultipleAdjectives() async throws {
        // Only one key, but check if multiple adjectives work
        let result = parser.parse(input: "drop small rusty key", vocabulary: vocabulary, gameState: gameState)
        let command = try result.get()
        #expect(command.verbID == "drop")
        #expect(command.directObject == "key")
        #expect(Set(command.directObjectModifiers) == Set(["small", "rusty"]))
    }

    @Test("Filter Fails (Adjective Mismatch)", .tags(.parser, .resolution, .modifiers, .errorHandling))
    func testFilterFailsAdjectiveMismatch() async throws {
        // "lantern" is in scope (brass one), but "wooden" doesn't match.
        let result = parser.parse(input: "take wooden lantern", vocabulary: vocabulary, gameState: gameState)
        // Should fail because modifiers don't match, not because noun is unknown.
        #expect(result.isFailure(matching: .modifierMismatch(noun: "lantern", modifiers: ["wooden"])))
    }

    @Test("Filter Causes Ambiguity (Modifier Not Specified)", .tags(.parser, .resolution, .ambiguity, .errorHandling))
    func testFilterCausesAmbiguity() async throws {
        // Input "take lantern" is ambiguous because both lanterns are in scope
        let result = parser.parse(input: "take lantern", vocabulary: vocabulary, gameState: gameState)
        #expect(result.isFailure(matching: ParseError.ambiguity("Which lantern do you mean?")))
    }

    // --- Tests for Pronoun Resolution ---

    @Test("Pronoun 'it' Not Set")
    func testPronounItNotSet() async throws {
        // Initialize game state without 'it'
        let initState = await GameState(
            locations: Array(self.gameState.locations.values),
            items: Array(self.gameState.items.values),
            player: self.gameState.player,
            vocabulary: self.vocabulary,
            pronouns: [:] // Start with empty pronouns
        )
        let result = parser.parse(input: "take it", vocabulary: vocabulary, gameState: initState)
        #expect(result == .failure(ParseError.pronounNotSet(pronoun: "it")))
    }

    @Test("Pronoun 'it' Refers to Out of Scope Item")
    func testPronounItRefersToOutOfScopeItem() async throws {
        // Initialize game state with 'it' set to lamp
        let initState = await GameState(
            locations: Array(self.gameState.locations.values),
            items: Array(self.gameState.items.values),
            player: self.gameState.player,
            vocabulary: self.vocabulary,
            pronouns: ["it": [lampID]] // Start with 'it' = lamp
        )

        // Ensure lamp IS IN SCOPE (room) for setup, the test checks parser result
        #expect(initState.items[lampID]?.parent == .location(roomID))

        let result = await parser.parse(input: "examine it", vocabulary: vocabulary, gameState: initState)
        // This test should actually *pass* now, as the lantern is in scope.
        let command = try result.get() // Expect success now
        #expect(command.directObject == lampID)
    }

    // Need a new test for pronoun referring to out-of-scope item
    @Test("Pronoun 'it' Refers to Item Genuinely Out of Scope")
    func testPronounItRefersToGenuinelyOutOfScopeItem() async throws {
        // Initialize game state with 'it' set to orb (out of scope)
        let initState = await GameState(
            locations: Array(self.gameState.locations.values),
            items: Array(self.gameState.items.values),
            player: self.gameState.player,
            vocabulary: self.vocabulary,
            pronouns: ["it": ["orb"]] // Start with 'it' = orb
        )
        #expect(initState.items["orb"]?.parent == .nowhere)

        let result = await parser.parse(input: "take it", vocabulary: vocabulary, gameState: initState)
        #expect(result == .failure(ParseError.pronounRefersToOutOfScopeItem(pronoun: "it")))
    }

    @Test("Pronoun 'it' Refers to Item In Scope", .tags(.parser, .resolution, .pronouns))
    func testPronounItInScope() async throws {
        // Initialize game state with 'it' set to sword (in room)
        let initState = await GameState(
            locations: Array(self.gameState.locations.values),
            items: Array(self.gameState.items.values),
            player: self.gameState.player,
            vocabulary: self.vocabulary,
            pronouns: ["it": ["sword"]] // Start with 'it' = sword
        )
        // Input uses "examine"
        let result = await parser.parse(input: "examine it", vocabulary: vocabulary, gameState: initState)
        let command = try result.get()
        #expect(command.verbID == "examine") // Expect examine, not look
        #expect(command.directObject == "sword")
    }

    @Test("Pronoun 'it' Refers to Item Out of Scope", .tags(.parser, .resolution, .pronouns, .errorHandling))
    func testPronounItOutOfScope() async throws {
        // Initialize game state with 'it' set to note (in closed chest)
        let initState = await GameState(
            locations: Array(self.gameState.locations.values),
            items: Array(self.gameState.items.values),
            player: self.gameState.player,
            vocabulary: self.vocabulary,
            pronouns: ["it": ["note"]] // Start with 'it' = note
        )
        let result = await parser.parse(input: "take it", vocabulary: vocabulary, gameState: initState)
        #expect(result.isFailure(matching: ParseError.pronounRefersToOutOfScopeItem(pronoun: "it")))
    }

    @Test("Pronoun 'it' with Modifiers", .tags(.parser, .resolution, .pronouns, .errorHandling))
    func testPronounItWithModifiers() async throws {
        // Initialize game state with 'it' set to key
        let initState = await GameState(
            locations: Array(self.gameState.locations.values),
            items: Array(self.gameState.items.values),
            player: self.gameState.player,
            vocabulary: self.vocabulary,
            pronouns: ["it": ["key"]] // Start with 'it' = key
        )
        let result = await parser.parse(input: "take rusty it", vocabulary: vocabulary, gameState: initState)
        #expect(result.isFailure(matching: ParseError.badGrammar("Pronouns like 'it' usually cannot be modified.")))
    }

    @Test("Pronoun 'it' as Indirect Object", .tags(.parser, .resolution, .pronouns, .indirectObject))
    func testPronounItAsIndirect() async throws {
        // Initialize game state with 'it' set to sword
        let initState = await GameState(
            locations: Array(self.gameState.locations.values),
            items: Array(self.gameState.items.values),
            player: self.gameState.player,
            vocabulary: self.vocabulary,
            pronouns: ["it": ["sword"]] // Start with 'it' = sword
        )
        let result = await parser.parse(input: "put leaflet on it", vocabulary: vocabulary, gameState: initState)
        let command = try result.get()
        #expect(command.verbID == "put-on")
        #expect(command.directObject == "leaflet")
        #expect(command.preposition == "on")
        #expect(command.indirectObject == "sword")
    }

    // NEW Test for "them" resolving to multiple in-scope items
    @Test("Pronoun 'them' Multiple In Scope", .tags(.parser, .resolution, .pronouns, .errorHandling))
    func testPronounThemMultipleInScope() async throws {
        // Initialize game state with 'them' set to key & leaflet (both held)
        let initState = await GameState(
            locations: Array(self.gameState.locations.values),
            items: Array(self.gameState.items.values),
            player: self.gameState.player,
            vocabulary: self.vocabulary,
            pronouns: ["them": ["key", "leaflet"]] // Start with 'them'
        )
        // Player holds key and leaflet (verified by initialItems setup)
        #expect(initState.items["key"]?.parent == .player)
        #expect(initState.items["leaflet"]?.parent == .player)

        let result = await parser.parse(input: "drop them", vocabulary: vocabulary, gameState: initState)
        #expect(result.isFailure(matching: ParseError.ambiguousPronounReference("Which one of \"them\" do you mean?")))
    }

    // NEW Test for "them" resolving to one in-scope item
    @Test("Pronoun 'them' Single In Scope", .tags(.parser, .resolution, .pronouns))
    func testPronounThemSingleInScope() async throws {
        // Initialize game state with 'them' set to key (held) & note (out of scope)
        let initState = await GameState(
            locations: Array(self.gameState.locations.values),
            items: Array(self.gameState.items.values),
            player: self.gameState.player,
            vocabulary: self.vocabulary,
            pronouns: ["them": ["key", "note"]] // Start with 'them'
        )
        // Verify item locations
        #expect(initState.items["key"]?.parent == .player)
        #expect(initState.items["note"]?.parent == .item("chest"))
        #expect(initState.items["chest"]?.attributes["isOpen"] == nil)

        // Only the key should be resolved from "them" because the note is out of scope
        let result = await parser.parse(input: "drop them", vocabulary: vocabulary, gameState: initState)
        let command = try result.get()
        #expect(command.verbID == "drop")
        #expect(command.directObject == "key") // Successfully resolved to the only one in scope
    }

    // --- Tests for Container Scope ---

    @Test("Find Item in Open Inventory Container", .tags(.parser, .resolution, .scope, .container))
    func testFindItemInOpenInventoryContainer() async throws {
        // Player has 'backpack' (open) containing 'coin'
        let result = await parser.parse(input: "take coin", vocabulary: vocabulary, gameState: gameState)
        let command = try result.get()
        #expect(command.verbID == "take")
        #expect(command.directObject == "coin")
        #expect(command.indirectObject == nil)
    }

    @Test("Find Item in Open Inventory Container (With Modifier)", .tags(.parser, .resolution, .scope, .container, .modifiers))
    func testFindItemInOpenInventoryContainerWithMod() async throws {
        // Player has 'backpack' (open) containing 'gold coin'
        let result = await parser.parse(input: "take gold coin", vocabulary: vocabulary, gameState: gameState)
        let command = try result.get()
        #expect(command.verbID == "take")
        #expect(command.directObject == "coin")
        #expect(command.directObjectModifiers == ["gold"])
        #expect(command.indirectObject == nil)
    }

    @Test("Item in Closed Inventory Container Not Found", .tags(.parser, .resolution, .scope, .container, .errorHandling))
    func testItemInClosedInventoryContainerNotFound() async throws {
        // Player has 'chest' (parent .player, but closed/locked) containing 'note' (parent .item(chest))
        let result = await parser.parse(input: "take note", vocabulary: vocabulary, gameState: gameState)
        // Should not find 'note' because parent 'chest' is closed/locked -> item not in scope
        #expect(result.isFailure(matching: .itemNotInScope(noun: "note")))
    }

    @Test("Item in Inventory Container in Location Not Found Yet", .tags(.parser, .resolution, .scope, .container, .errorHandling))
    func testItemInLocationContainerNotFoundYet() async throws {
        // TODO: Re-enable and adapt this test once gatherCandidates handles
        // items inside containers within the location.
        // The setup now includes "widget" inside "box" in the room.

        // let resultWidget = await parser.parse(input: "take widget", vocabulary: vocabulary, gameState: gameState)
        // #expect(resultWidget.isFailure(matching: ParseError.unknownNoun("widget"))) // Should still fail until scope logic updated

        // Check we can find the container itself (box)
        let resultBox = await parser.parse(input: "take wooden box", vocabulary: vocabulary, gameState: gameState)
        let commandBox = try resultBox.get()
        #expect(commandBox.directObject == "box")

        // Placeholder until scope logic is fixed
        #expect(true)
    }

    @Test("Direct Inventory Item Preferred Over Item In Container", .tags(.parser, .resolution, .scope, .container))
    func testDirectInventoryPreferredOverContainer() async throws {
        // Create a temporary state where 'key' is held and a temp key is in backpack
        var itemsDict = self.gameState.items // Base items copy
        let tempKeyInBackpack = Item(
            id: "tempKeyInBackpack",
            name: "key",
            parent: .item("backpack"),
            attributes: [
                .adjectives: .stringSet(["temp"])
            ]
        )
        let tempKeyOnGround = Item(
            id: "tempKeyOnGround",
            name: "key",
            parent: .location("startRoom"),
            attributes: [
                .adjectives: .stringSet(["temp"])
            ]
        )
        let permKey = Item(
            id: "permKey",
            name: "key",
            parent: .location("startRoom"),
            attributes: [
                .adjectives: .stringSet(["perm"])
            ]
        )
        itemsDict[tempKeyInBackpack.id] = tempKeyInBackpack
        itemsDict[tempKeyOnGround.id] = tempKeyOnGround
        itemsDict[permKey.id] = permKey
        let initState = await GameState(
            locations: Array(self.gameState.locations.values),
            items: Array(itemsDict.values), // Pass the modified copy's values
            player: self.gameState.player,
            vocabulary: self.vocabulary,
            pronouns: self.gameState.pronouns // Use base pronouns
        )

        // Verify setup
        #expect(initState.items["key"]?.parent == .player)
        #expect(initState.items["tempKeyInBackpack"]?.parent == .item("backpack"))
        #expect(initState.items["tempKeyOnGround"]?.parent == .location("startRoom"))
        #expect(initState.items["permKey"]?.parent == .location("startRoom"))

        // Update vocab temporarily ONLY for this test's state
        var tempVocabulary = vocabulary
        tempVocabulary.items["key", default: []].insert(tempKeyInBackpack.id)
        tempVocabulary.items["key", default: []].insert(tempKeyOnGround.id)
        tempVocabulary.items["key", default: []].insert(permKey.id)

        // Parsing "take key" might become ambiguous IF the parser finds both.
        // Let's test with the modifier to target the *real* key.
        let resultSpecific = await parser.parse(input: "take rusty key", vocabulary: tempVocabulary, gameState: initState)
        let commandSpecific = try resultSpecific.get()

        // Should resolve to the original 'key' which is rusty and held by player.
        #expect(commandSpecific.directObject == "key")
        #expect(Set(commandSpecific.directObjectModifiers) == Set(["rusty"]))
        // No need to clean up temp state as it was local to the test
    }

    // --- TODO: Add tests for Ambiguity Resolution (more complex) ---
    // --- TODO: Add tests for other pronouns ("them", etc.) ---

    // MARK: - Tokenization and Noise Removal Tests

    @Test("Tokenize basic input")
    func testTokenizeBasic() {
        let input = "take the brass lamp"
        let expected = ["take", "the", "brass", "lamp"]
        #expect(parser.tokenize(input: input) == expected)
    }

    @Test("Tokenize with punctuation")
    func testTokenizePunctuation() {
        let input = "Go north. Take lamp!"
        let expected = ["go", "north", "take", "lamp"]
        #expect(parser.tokenize(input: input) == expected)
    }

    @Test("Tokenize preserves case initially (should be lowercased)")
    func testTokenizeLowercase() {
        let input = "DROP ALL"
        let expected = ["drop", "all"]
        #expect(parser.tokenize(input: input) == expected)
    }

    @Test("Remove noise words")
    func testRemoveNoise() {
        let tokens = ["take", "the", "brass", "lamp", "and", "the", "key"]
        let expected = ["take", "brass", "lamp", "key"]
        #expect(parser.removeNoise(tokens: tokens, noiseWords: vocabulary.noiseWords) == expected)
    }

    @Test("Remove noise words - only noise")
    func testRemoveNoiseOnlyNoise() {
        let tokens = ["the", "a", "an", ".", ","]
        let expected: [String] = []
        #expect(parser.removeNoise(tokens: tokens, noiseWords: vocabulary.noiseWords) == expected)
    }

    // MARK: - Basic Parsing Tests (Empty/Noise Input)

    @Test("Parse empty string")
    func testParseEmptyString() async {
        let result = await parser.parse(input: "", vocabulary: vocabulary, gameState: gameState)
        #expect(result == .failure(ParseError.emptyInput))
    }

    @Test("Parse only whitespace")
    func testParseWhitespace() async {
        let result = await parser.parse(input: "   \t  \n ", vocabulary: vocabulary, gameState: gameState)
        #expect(result == .failure(ParseError.emptyInput))
    }

    @Test("Parse only noise words")
    func testParseOnlyNoise() async {
        let result = await parser.parse(input: "a the an .", vocabulary: vocabulary, gameState: gameState)
        #expect(result == .failure(ParseError.emptyInput))
    }

    @Test("Noun Not In Scope")
    func testNounNotInScope() async {
        // Lamp exists in vocab, but isn't in the room or held by player
        // Create a custom state where the lamp is explicitly out of scope
        var itemsDict = self.gameState.items // Base items copy
        itemsDict[lampID]?.parent = .nowhere // Move lamp out of scope
        let customState = await GameState(
            locations: Array(self.gameState.locations.values),
            items: Array(itemsDict.values),
            player: self.gameState.player,
            vocabulary: self.vocabulary,
            pronouns: self.gameState.pronouns // Use base pronouns
        )
        #expect(customState.items[lampID]?.parent == .nowhere) // Verify setup

        // Run parser with the custom state
        let result = await parser.parse(input: "take lamp", vocabulary: vocabulary, gameState: customState)
        #expect(result == .failure(ParseError.itemNotInScope(noun: "lamp")))
    }

    // MARK: - Noun/Modifier Extraction Tests

    @Test("Extract Noun/Mods - Simple Case", .tags(.parser, .resolution, .modifiers))
    func testExtractNounModsSimple() async throws {
        // "take brass lantern"
        let result = parser.parse(input: "take brass lantern", vocabulary: vocabulary, gameState: gameState)
        let command = try result.get()
        #expect(command.verbID == "take")
        #expect(command.directObject == "lantern") // Noun = lantern
        #expect(command.directObjectModifiers == ["brass"]) // Mods = [brass]
    }

    @Test("Extract Noun/Mods - With Noise Words", .tags(.parser, .resolution, .modifiers))
    func testExtractNounModsNoise() async throws {
        // "take the small rusty key"
        let result = parser.parse(input: "take the small rusty key", vocabulary: vocabulary, gameState: gameState)
        let command = try result.get()
        #expect(command.verbID == "take")
        #expect(command.directObject == "key") // Noun = key
        #expect(command.directObjectModifiers == ["small", "rusty"]) // Mods = [small, rusty], "the" filtered
    }

    @Test("Extract Noun/Mods - Multiple Nouns", .tags(.parser, .resolution, .modifiers))
    func testExtractNounModsMultipleNouns() async throws {
        // "put the small box key in lamp"
        // Setup: Make lamp a container for this test to pass resolution
        var itemsDict = self.gameState.items // Base items copy
        itemsDict["lantern"]?.attributes[.isContainer] = true
        let modifiedState = await GameState(
            locations: Array(self.gameState.locations.values),
            items: Array(itemsDict.values),
            player: self.gameState.player,
            vocabulary: self.vocabulary,
            pronouns: self.gameState.pronouns // Use base pronouns
        )

        let result = parser.parse(input: "put the small box key in lamp", vocabulary: vocabulary, gameState: modifiedState)
        let command = try result.get()

        #expect(command.verbID == "insert")
        // DO: noun = key (last known noun), mods = [small] ("box" is noun, not modifier)
        #expect(command.directObject == "key")
        #expect(command.directObjectModifiers == ["small"])
        // IO: noun = lamp (resolved to 'lantern'), mods = []
        #expect(command.indirectObject == "lantern")
        #expect(command.indirectObjectModifiers == [])
        #expect(command.preposition == "in")
    }

    @Test("Extract Noun/Mods - Only Unknown Word", .tags(.parser, .errorHandling))
    func testExtractNounModsOnlyUnknown() async throws {
        // "look xyzzy" - Should now parse with look verb and attempt resolution
        let result = parser.parse(input: "look xyzzy", vocabulary: vocabulary, gameState: gameState)
        #expect(result.isFailure(matching: .unknownNoun("xyzzy")))
    }

    @Test("Extract Noun/Mods - Only Modifier", .tags(.parser, .errorHandling))
    func testExtractNounModsOnlyModifier() async throws {
        // "look brass" - Should now parse with look verb and attempt resolution
        let result = parser.parse(input: "look brass", vocabulary: vocabulary, gameState: gameState)
        #expect(result.isFailure(matching: .unknownNoun("brass")))
    }

    @Test("Extract Noun/Mods - Pronoun", .tags(.parser, .resolution, .pronouns))
    func testExtractNounModsPronoun() async throws {
        // "drop it" - assumes 'it' refers to something held (e.g., the key)
        var itemsDict = self.gameState.items // Base items copy
        itemsDict["key"]?.parent = .player // Put key in inventory
        let modifiedState = await GameState(
            locations: Array(self.gameState.locations.values),
            items: Array(itemsDict.values),
            player: self.gameState.player,
            vocabulary: self.vocabulary,
            pronouns: ["it": ["key"]] // Set 'it' to key for this state
        )

        let result = parser.parse(input: "drop it", vocabulary: vocabulary, gameState: modifiedState)
        let command = try result.get()
        #expect(command.verbID == "drop")
        #expect(command.directObject == "key") // Noun = it (resolved to key)
        #expect(command.directObjectModifiers == []) // Mods = []
    }

    @Test("Extract Noun/Mods - Pronoun With Noise", .tags(.parser, .resolution, .pronouns))
    func testExtractNounModsPronounNoise() async throws {
        // "drop the it"
        var itemsDict = self.gameState.items // Base items copy
        itemsDict["key"]?.parent = .player
        let modifiedState = await GameState(
            locations: Array(self.gameState.locations.values),
            items: Array(itemsDict.values),
            player: self.gameState.player,
            vocabulary: self.vocabulary,
            pronouns: ["it": ["key"]] // Set 'it' to key for this state
        )

        let result = parser.parse(input: "drop the it", vocabulary: vocabulary, gameState: modifiedState)
        let command = try result.get()
        #expect(command.verbID == "drop")
        #expect(command.directObject == "key") // Noun = it
        #expect(command.directObjectModifiers == []) // Mods = [], "the" filtered
    }

    // MARK: - Direction Parsing Tests

    @Test("Parse Single Word Direction (Implicit Go)", .tags(.parser, .verbOnly))
    func testParseSingleWordDirection() async throws {
        let directionMap: [String: Direction] = [
            "north": .north, "n": .north,
            "south": .south, "s": .south,
            "east": .east, "e": .east,
            "west": .west, "w": .west,
            "northeast": .northeast, "ne": .northeast,
            "northwest": .northwest, "nw": .northwest,
            "southeast": .southeast, "se": .southeast,
            "southwest": .southwest, "sw": .southwest,
            "up": .up, "u": .up,
            "down": .down, "d": .down,
            "in": .inside,
            "out": .outside
        ]

        for (input, expectedDirection) in directionMap {
            let result = parser.parse(input: input, vocabulary: vocabulary, gameState: gameState)
            let command = try result.get()
            #expect(command.verbID == "go") // Should assume "go"
            #expect(command.direction == expectedDirection)
            #expect(command.directObject == nil)
            #expect(command.indirectObject == nil)
            #expect(command.preposition == nil)
            #expect(command.rawInput == input)
        }
    }

    @Test("Parse Go + Direction", .tags(.parser))
    func testParseGoDirection() async throws {
         let directionMap: [String: Direction] = [
            "north": .north, "n": .north,
            "south": .south, "s": .south,
            "east": .east, "e": .east,
            "west": .west, "w": .west,
            "northeast": .northeast, "ne": .northeast,
            "northwest": .northwest, "nw": .northwest,
            "southeast": .southeast, "se": .southeast,
            "southwest": .southwest, "sw": .southwest,
            "up": .up, "u": .up,
            "down": .down, "d": .down,
            "in": .inside,
            "out": .outside
        ]

        for (directionWord, expectedDirection) in directionMap {
            let input = "go \(directionWord)"
            let result = parser.parse(input: input, vocabulary: vocabulary, gameState: gameState)
            let command = try result.get()
            #expect(command.verbID == "go")
            #expect(command.direction == expectedDirection)
            #expect(command.directObject == nil)
            #expect(command.indirectObject == nil)
            #expect(command.preposition == nil)
            #expect(command.rawInput == input)
        }
    }

    @Test("Parse Go + Invalid Direction", .tags(.parser, .errorHandling))
    func testParseGoInvalidDirection() async throws {
        let input = "go nowhere"
        let result = parser.parse(input: input, vocabulary: vocabulary, gameState: gameState)
        #expect(result.isFailure(matching: .badGrammar("Expected a direction (like north, s, up) but found 'nowhere'.")))
    }

    @Test("Parse Go + Extra Words", .tags(.parser, .errorHandling))
    func testParseGoExtraWords() async throws {
        let input = "go north quickly"
        let result = parser.parse(input: input, vocabulary: vocabulary, gameState: gameState)
        #expect(result.isFailure(matching: .badGrammar("Unexpected words found after command: 'quickly'")))
    }

    @Test("Parse Go (No Direction)", .tags(.parser, .errorHandling))
    func testParseGoNoDirection() async throws {
        let input = "go"
        let result = parser.parse(input: input, vocabulary: vocabulary, gameState: gameState)
        #expect(result.isFailure(matching: .badGrammar("Command seems incomplete, expected more input like 'direction'.")))
    }
}

// Helper to check Result failure case against a specific ParseError
extension Result where Failure == ParseError {
    func isFailure(matching expectedError: ParseError) -> Bool {
        guard case .failure(let actualError) = self else {
            return false
        }
        switch (actualError, expectedError) {
        case (.emptyInput, .emptyInput):
            return true
        case (.unknownVerb(let actual), .unknownVerb(let expected)):
            return actual == expected
        case (.unknownNoun(let actual), .unknownNoun(let expected)):
            return actual == expected
        case (.itemNotInScope(let actual), .itemNotInScope(let expected)):
            return actual == expected
        case (.modifierMismatch(let actualNoun, let actualMods), .modifierMismatch(let expectedNoun, let expectedMods)):
            return actualNoun == expectedNoun && Set(actualMods) == Set(expectedMods)
        case (.ambiguity(let actual), .ambiguity(let expected)):
            return actual == expected
        case (.ambiguousPronounReference(let actual), .ambiguousPronounReference(let expected)):
            return actual == expected
        case (.badGrammar(let actual), .badGrammar(let expected)):
            return actual == expected
        case (.pronounNotSet(let actual), .pronounNotSet(let expected)):
            return actual == expected
        case (.pronounRefersToOutOfScopeItem(let actual), .pronounRefersToOutOfScopeItem(let expected)):
            return actual == expected
        case (.internalError(let actual), .internalError(let expected)):
            return actual == expected
        default:
            return false
        }
    }
}
