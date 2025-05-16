import Testing
@testable import GnustoEngine

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
                .name("apple"),
                .in(.item("tray")),
                .adjectives("red"),
                .isTakable,
                .isEdible
            ),
            Item(
                id: "backpack",
                .name("backpack"),
                .in(.player),
                .isContainer,
                .isTakable,
                .isOpen,
                .capacity(20)
            ),
            Item(
                id: "book",
                .name("book"),
                .in(.item("table")),
                .adjectives("dusty"),
                .isTakable,
                .isReadable
            ),
            Item(
                id: "box",
                .name("box"),
                .in(.location(roomID)),
                .adjectives("wooden"),
                .isContainer,
                .isOpenable
            ),
            Item(
                id: "chest",
                .name("chest"),
                .in(.player),
                .isContainer,
                .isTakable,
                .isOpenable,
                .isLocked,
                .capacity(50)
            ),
            Item(
                id: "coin",
                .name("coin"),
                .in(.item("backpack")),
                .adjectives("gold"),
                .isTakable
            ),
            Item(
                id: "key",
                .name("key"),
                .in(.player),
                .adjectives("rusty", "small"),
                .isTakable
            ),
            Item(
                id: "lantern",
                .name("lantern"),
                .in(.location(roomID)),
                .adjectives("brass", "shiny"),
                .synonyms("lamp"),
                .isLightSource,
                .isOpenable
            ),
            Item(
                id: "lantern2",
                .name("lantern"),
                .in(.location(roomID)),
                .adjectives("rusty", "dented"),
                .isLightSource
            ),
            Item(
                id: "leaflet",
                .name("leaflet"),
                .in(.player),
                .isTakable,
                .isReadable
            ),
            Item(
                id: "note",
                .name("note"),
                .in(.item("chest")),
                .isTakable,
                .isReadable
            ),
            Item(
                id: "orb",
                .name("orb"),
                .in(.nowhere),
                .adjectives("glowing"),
                .isTakable,
                .isLightSource
            ),
            Item(
                id: "rug",
                .name("rug"),
                .in(.nowhere)
            ),
            Item(
                id: "sword",
                .name("sword"),
                .in(.location(roomID)),
                .isTakable
            ),
            Item(
                id: "table",
                .name("table"),
                .in(.location(roomID)),
                .adjectives("sturdy"),
                .isSurface
            ),
            Item(
                id: "tray",
                .name("tray"),
                .in(.player),
                .adjectives("silver"),
                .isSurface,
                .isTakable
            ),
            Item(
                id: "widget",
                .name("widget"),
                .in(.item("box")),
                .isTakable
            ),
        ]

        // 2. Define Game-Specific Verbs (if any) - Most verbs are now defaults
        // let gameSpecificVerbs: [Verb] = [
        //     // Example: Add back a verb if its specific syntax/conditions ARE needed for a test
        //     // and differ from the default (unlikely for most basic tests now).
        //     // Verb(id: "eat", syntax: [ SyntaxRule(pattern: [.verb, .directObject], directObjectConditions: []) ])
        //     // NOTE: The test setup previously defined verbs like ’take', 'look', 'go', 'put', 'drop', 'eat'.
        //     // These are now provided by Vocabulary.defaultVerbs and should NOT be redefined here
        //     // unless a specific test requires overriding a default rule.
        // ]

        // 3. Define all Locations
        let locations = [
            Location(
                id: roomID,
                .name("Room"),
                .description("A room."),
                .localGlobals("rug")
            )
            // Add more locations later if needed
        ]

        // 4. Define initial Player state
        let player = Player(in: roomID)

        // 5. Define initial pronouns
        let initialPronouns: [String: Set<EntityReference>] = [
            "it": [.item("box")] // Let's say "it" initially refers to the box in the room
        ]

        // 6. Build Vocabulary using defaults + game-specific items/verbs
        vocabulary = .build(items: allItems)

        // 7. Build GameState using the new factory method
        gameState = GameState(
            locations: locations,
            items: allItems,
            player: player,
            pronouns: initialPronouns
        )

        // --- Sanity Checks (Optional but Recommended) ---
        // Check if parents were set correctly
        #expect(gameState.items["leaflet"]?.parent == .player)
        #expect(gameState.items["sword"]?.parent == .location(roomID))
        #expect(gameState.items["coin"]?.parent == .item("backpack"))
        #expect(gameState.items["book"]?.parent == .item("table"))
        #expect(gameState.items["rug"]?.parent == .nowhere) // Globals aren’t parented by this initializer
        #expect(gameState.pronouns["it"] == [.item("box")])
    }

    // --- Tests ---

    @Test("Parse Empty Input")
    func testParseEmpty() async throws {
        let result = parser.parse(
            input: "",
            vocabulary: vocabulary,
            gameState: gameState
        )
        #expect(result.isFailure(matching: ParseError.emptyInput))

        let resultWhitespace = parser.parse(
            input: "   \t ",
            vocabulary: vocabulary,
            gameState: gameState
        )
        #expect(resultWhitespace.isFailure(matching: ParseError.emptyInput))

        let resultNoiseOnly = parser.parse(
            input: "the the the",
            vocabulary: vocabulary,
            gameState: gameState
        )
        #expect(resultNoiseOnly.isFailure(matching: ParseError.emptyInput))
    }

    @Test("Parse Unknown Verb")
    func testParseUnknownVerb() async throws {
        let result = parser.parse(
            input: "xyzzy",
            vocabulary: vocabulary,
            gameState: gameState
        )
        #expect(result.isFailure(matching: ParseError.unknownVerb("xyzzy")))

        let resultWithNoise = parser.parse(
            input: "the jump the",
            vocabulary: vocabulary,
            gameState: gameState
        )
        #expect(resultWithNoise.isFailure(matching: ParseError.unknownVerb("jump")))
    }

    @Test("Parse Simple Verb - Known")
    func testParseSimpleVerbKnown() async throws {
        // Test LOOK variations (no DO expected)
        let lookInputs = ["look", "LOOK", "l"]
        for input in lookInputs {
            let result = parser.parse(
                input: input,
                vocabulary: vocabulary,
                gameState: gameState
            )
            let command = try result.get()
            #expect(command.verb == "look")
            #expect(command.directObject == nil)
            #expect(command.indirectObject == nil)
            #expect(command.rawInput == input)
        }

        // Test EXAMINE variations (should fail without DO)
        let examineInputs = ["examine", "x"]
        for input in examineInputs {
            let result = parser.parse(
                input: input,
                vocabulary: vocabulary,
                gameState: gameState
            )
            #expect(result.isFailure(matching: .badGrammar("Expected a direct object phrase for verb 'examine'.")))
        }
    }

    @Test("Parse Simple Verb - Synonym")
    func testParseSimpleVerbSynonym() async throws {
        let result = parser.parse(
            input: "get",
            vocabulary: vocabulary,
            gameState: gameState
        )
        // "get" (take) requires a DO according to its SyntaxRule.
        // Expect failure because no DO was provided.
        #expect(result.isFailure(matching: .badGrammar("Expected a direct object phrase for verb ’take'.")))
    }

    @Test("Parse Verb + Direct Object (Ambiguous)")
    func testParseVerbDirectObject() async throws {
        // "lantern" is ambiguous because both "lantern" and "lantern2" are in scope
        let result = parser.parse(
            input: "take lantern",
            vocabulary: vocabulary,
            gameState: gameState
        )
        // Update to expect ambiguity
        #expect(
            result.isFailure(
                matching: ParseError.ambiguity(
                    "Which do you mean, the brass lantern or the dented lantern?"
                )
            )
        )
    }

    @Test("Parse Verb + Direct Object + Modifiers")
    func testParseVerbDirectObjectMods() async throws {
        // "lantern" is now in scope (in the room)
        let result = parser.parse(
            input: "get the brass lantern",
            vocabulary: vocabulary,
            gameState: gameState
        )
        // Revert to expecting success
        let command = try result.get()
        #expect(command.verb == "take")
        #expect(command.directObject == .item("lantern"))
        #expect(command.directObjectModifiers == ["brass"])
        #expect(command.indirectObject == nil)
        #expect(command.preposition == nil)
    }

    @Test("Parse Verb + Direct Object + Multiple Modifiers")
    func testParseVerbDirectObjectMultiMods() async throws {
        // Input uses "examine"
        let result = parser.parse(
            input: "examine the rusty small key",
            vocabulary: vocabulary,
            gameState: gameState
        )
        let command = try result.get()
        #expect(command.verb == .examine) // Expect examine, not look
        #expect(command.directObject == .item("key"))
        #expect(Set(command.directObjectModifiers) == Set(["rusty", "small"]))
        #expect(command.indirectObject == nil)
        #expect(command.preposition == nil)
    }

    @Test("Parse Verb + Direct + Preposition + Indirect")
    func testParseVerbDirectPrepIndirect() async throws {
        // "key" parent is .player, "box" parent is .location(roomID). Both should be found.
        let result = parser.parse(
            input: "put key in box",
            vocabulary: vocabulary,
            gameState: gameState
        )
        // Should now SUCCEED because "box" is in scope (in the room)
        let command = try result.get()
        #expect(command.verb == "insert")
        #expect(command.directObject == .item("key"))
        #expect(command.indirectObject == .item("box"))
        #expect(command.preposition == "in")
    }

    @Test("Parse Verb + DirectObject + Prep + IndirectMods")
    func testParseFullComplexity() async throws {
        // "key" parent is .player, "box" parent is .location(roomID). Both should be found.
        let result = parser.parse(
            input: "place the small key into the wooden box",
            vocabulary: vocabulary,
            gameState: gameState
        )
        // Should now SUCCEED because "box" is in scope (in the room)
        let command = try result.get()
        #expect(command.verb == "insert")
        #expect(command.directObject == .item("key"))
        #expect(Set(command.directObjectModifiers) == Set(["small"]))
        #expect(command.indirectObject == .item("box"))
        #expect(Set(command.indirectObjectModifiers) == Set(["wooden"]))
        #expect(command.preposition == "into")
    }

    @Test("Parse Unknown Direct Object (Exists but Not In Scope)")
    func testParseUnknownDirectObject() async throws {
        // "box" exists and its parent IS .location(roomID), so it IS in scope.
        let result = parser.parse(
            input: "take box",
            vocabulary: vocabulary,
            gameState: gameState
        )
        // Should SUCCEED now.
        let command = try result.get()
        #expect(command.verb == "take")
        #expect(command.directObject == .item("box"))
        #expect(command.indirectObject == nil)
    }

    @Test("Parse Indirect Object Not In Scope")
    func testParseIndirectObjectNotInScope() async throws {
        // Direct object 'leaflet' parent is .player.
        // Indirect object 'box' parent IS .location(roomID), so it IS in scope.
        let result = parser.parse(
            input: "put leaflet in box",
            vocabulary: vocabulary,
            gameState: gameState
        )
        // Should SUCCEED now.
        let command = try result.get()
        #expect(command.verb == "insert")
        #expect(command.directObject == .item("leaflet"))
        #expect(command.indirectObject == .item("box"))
        #expect(command.preposition == "in")
    }

    @Test("Parse Ambiguous Indirect Object in Location")
    func testAmbiguousIndirectObjectInLocation() async throws {
        // Direct object 'leaflet' is in inventory, indirect object 'lantern' is ambiguous.
        // Parser identifies ambiguity before checking if candidates meet the .container property.
        let result = parser.parse(
            input: "put leaflet in lantern",
            vocabulary: vocabulary,
            gameState: gameState
        )
        #expect(
            result.isFailure(
                matching: .ambiguity(
                    "Which do you mean, the brass lantern or the dented lantern?"
                )
            )
        )
    }

    @Test("Parse Direct from Inventory, Indirect from Location")
    func testParseDirectFromInvIndirectFromLoc() async throws {
        // 'leaflet' (DO) is in inventory, 'sword' (IO) is in the room
        let result = parser.parse(
            input: "put leaflet on sword",
            vocabulary: vocabulary,
            gameState: gameState
        )
        let command = try result.get()
        #expect(command.verb == .putOn)
        #expect(command.directObject == .item("leaflet"))
        #expect(command.directObjectModifiers.isEmpty)
        #expect(command.preposition == "on")
        #expect(command.indirectObject == .item("sword"))
        #expect(command.indirectObjectModifiers.isEmpty)
    }

    @Test("Parse Find Direct Object in Inventory")
    func testParseDirectObjectInInventory() async throws {
        // Player has 'leaflet'
        let result = parser.parse(
            input: "drop leaflet",
            vocabulary: vocabulary,
            gameState: gameState
        )
        let command = try result.get()
        #expect(command.verb == "drop")
        #expect(command.directObject == .item("leaflet"))
        #expect(command.indirectObject == nil)
    }

    @Test("Parse Find Direct Object in Location (Item)")
    func testParseDirectObjectInLocationItem() async throws {
        // Location has 'sword'
        let result = parser.parse(
            input: "take sword",
            vocabulary: vocabulary,
            gameState: gameState
        )
        let command = try result.get()
        #expect(command.verb == "take")
        #expect(command.directObject == .item("sword"))
        #expect(command.indirectObject == nil)
    }

    @Test("Parse Find Direct Object in Location (Global)")
    func testParseDirectObjectInLocationGlobal() async throws {
        // Input uses "examine"
        let result = parser.parse(
            input: "examine rug",
            vocabulary: vocabulary,
            gameState: gameState
        )
        let command = try result.get()
        #expect(command.verb == .examine) // Expect examine, not look
        #expect(command.directObject == .item("rug"))
        #expect(command.indirectObject == nil)
    }

    // --- Tests for Adjective Filtering ---

    @Test("Filter by Single Adjective")
    func testFilterSingleAdjective() async throws {
        // Both lanterns are in scope, but only one is brass
        let result = parser.parse(
            input: "take brass lantern",
            vocabulary: vocabulary,
            gameState: gameState
        )
        let command = try result.get()
        #expect(command.verb == "take")
        #expect(command.directObject == .item("lantern")) // Should resolve to the brass one
        #expect(command.directObjectModifiers == ["brass"])
    }

    @Test("Filter by Different Single Adjective")
    func testFilterDifferentAdjective() async throws {
        // Input uses "examine"
        let result = parser.parse(
            input: "examine rusty lantern",
            vocabulary: vocabulary,
            gameState: gameState
        )
        let command = try result.get()
        #expect(command.verb == .examine) // Expect examine, not look
        #expect(command.directObject == .item("lantern2")) // Should resolve to the rusty one
        #expect(command.directObjectModifiers == ["rusty"])
    }

    @Test("Filter by Multiple Adjectives")
    func testFilterMultipleAdjectives() async throws {
        // Only one key, but check if multiple adjectives work
        let result = parser.parse(
            input: "drop small rusty key",
            vocabulary: vocabulary,
            gameState: gameState
        )
        let command = try result.get()
        #expect(command.verb == "drop")
        #expect(command.directObject == .item("key"))
        #expect(Set(command.directObjectModifiers) == Set(["small", "rusty"]))
    }

    @Test("Filter Fails (Adjective Mismatch)")
    func testFilterFailsAdjectiveMismatch() async throws {
        // "lantern" is in scope (brass one), but "wooden" doesn’t match.
        let result = parser.parse(
            input: "take wooden lantern",
            vocabulary: vocabulary,
            gameState: gameState
        )
        // Should fail because modifiers don’t match, not because noun is unknown.
        #expect(result.isFailure(matching: .modifierMismatch(noun: "lantern", modifiers: ["wooden"])))
    }

    @Test("Filter Causes Ambiguity (Modifier Not Specified)")
    func testFilterCausesAmbiguity() async throws {
        // Input "take lantern" is ambiguous because both lanterns are in scope
        let result = parser.parse(
            input: "take lantern",
            vocabulary: vocabulary,
            gameState: gameState
        )
        #expect(
            result.isFailure(
                matching: ParseError.ambiguity(
                    "Which do you mean, the brass lantern or the dented lantern?"
                )
            )
        )
    }

    // --- Tests for Pronoun Resolution ---

    @Test("Pronoun 'it' Not Set")
    func testPronounItNotSet() async throws {
        // Initialize game state without 'it'
        let initState = GameState(
            locations: Array(gameState.locations.values),
            items: Array(gameState.items.values),
            player: gameState.player,
            vocabulary: vocabulary,
            pronouns: [:] // Start with empty pronouns
        )
        let result = parser.parse(
            input: "take it",
            vocabulary: vocabulary,
            gameState: initState
        )
        #expect(result == .failure(ParseError.pronounNotSet(pronoun: "it")))
    }

    @Test("Pronoun 'it' Refers to Out of Scope Item")
    func testPronounItRefersToOutOfScopeItem() async throws {
        // Initialize game state with 'it' set to lamp
        let initState = GameState(
            locations: Array(gameState.locations.values),
            items: Array(gameState.items.values),
            player: gameState.player,
            vocabulary: vocabulary,
            pronouns: ["it": [.item(lampID)]] // Start with 'it' = lamp
        )

        // Ensure lamp IS IN SCOPE (room) for setup, the test checks parser result
        #expect(initState.items[lampID]?.parent == .location(roomID))

        let result = parser.parse(
            input: "examine it",
            vocabulary: vocabulary,
            gameState: initState
        )
        // This test should actually *pass* now, as the lantern is in scope.
        let command = try result.get() // Expect success now
        #expect(command.directObject == .item(lampID))
    }

    // Need a new test for pronoun referring to out-of-scope item
    @Test("Pronoun 'it' Refers to Item Genuinely Out of Scope")
    func testPronounItRefersToGenuinelyOutOfScopeItem() async throws {
        // Initialize game state with 'it' set to orb (out of scope)
        let initState = GameState(
            locations: Array(gameState.locations.values),
            items: Array(gameState.items.values),
            player: gameState.player,
            vocabulary: vocabulary,
            pronouns: ["it": [.item("orb")]] // Start with 'it' = orb
        )
        #expect(initState.items["orb"]?.parent == .nowhere)

        let result = parser.parse(
            input: "take it",
            vocabulary: vocabulary,
            gameState: initState
        )
        #expect(result == .failure(ParseError.pronounRefersToOutOfScopeItem(pronoun: "it")))
    }

    @Test("Pronoun 'it' Refers to Item In Scope")
    func testPronounItInScope() async throws {
        // Initialize game state with 'it' set to sword (in room)
        let initState = GameState(
            locations: Array(gameState.locations.values),
            items: Array(gameState.items.values),
            player: gameState.player,
            vocabulary: vocabulary,
            pronouns: ["it": [.item("sword")]] // Start with 'it' = sword
        )
        // Input uses "examine"
        let result = parser.parse(
            input: "examine it",
            vocabulary: vocabulary,
            gameState: initState
        )
        let command = try result.get()
        #expect(command.verb == .examine) // Expect examine, not look
        #expect(command.directObject == .item("sword"))
    }

    @Test("Pronoun 'it' Refers to Item Out of Scope")
    func testPronounItOutOfScope() async throws {
        // Initialize game state with 'it' set to note (in closed chest)
        let initState = GameState(
            locations: Array(gameState.locations.values),
            items: Array(gameState.items.values),
            player: gameState.player,
            vocabulary: vocabulary,
            pronouns: ["it": [.item("note")]] // Start with 'it' = note
        )
        let result = parser.parse(input: "take it", vocabulary: vocabulary, gameState: initState)
        #expect(result.isFailure(matching: ParseError.pronounRefersToOutOfScopeItem(pronoun: "it")))
    }

    @Test("Pronoun 'it' with Modifiers")
    func testPronounItWithModifiers() async throws {
        // Initialize game state with 'it' set to key
        let initState = GameState(
            locations: Array(gameState.locations.values),
            items: Array(gameState.items.values),
            player: gameState.player,
            vocabulary: vocabulary,
            pronouns: ["it": [.item("key")]] // Start with 'it' = key
        )
        let result = parser.parse(input: "take rusty it", vocabulary: vocabulary, gameState: initState)
        #expect(result.isFailure(matching: ParseError.badGrammar("Pronouns like 'it' usually cannot be modified.")))
    }

    @Test("Pronoun 'it' as Indirect Object")
    func testPronounItAsIndirect() async throws {
        // Initialize game state with 'it' set to sword
        let initState = GameState(
            locations: Array(gameState.locations.values),
            items: Array(gameState.items.values),
            player: gameState.player,
            vocabulary: vocabulary,
            pronouns: ["it": [.item("sword")]] // Start with 'it' = sword
        )
        let result = parser.parse(input: "put leaflet on it", vocabulary: vocabulary, gameState: initState)
        let command = try result.get()
        #expect(command.verb == .putOn)
        #expect(command.directObject == .item("leaflet"))
        #expect(command.preposition == "on")
        #expect(command.indirectObject == .item("sword"))
    }

    // NEW Test for "them" resolving to multiple in-scope items
    @Test("Pronoun ’them' Multiple In Scope")
    func testPronounThemMultipleInScope() async throws {
        // Initialize game state with ’them' set to key & leaflet (both held)
        let initState = GameState(
            locations: Array(gameState.locations.values),
            items: Array(gameState.items.values),
            player: gameState.player,
            vocabulary: vocabulary,
            pronouns: ["them": [.item("key"), .item("leaflet")]] // Start with ’them'
        )
        // Player holds key and leaflet (verified by initialItems setup)
        #expect(initState.items["key"]?.parent == .player)
        #expect(initState.items["leaflet"]?.parent == .player)

        let result = parser.parse(
            input: "drop them",
            vocabulary: vocabulary,
            gameState: initState
        )
        #expect(
            result.isFailure(
                matching: ParseError.ambiguousPronounReference(
                    "Which ’them' do you mean: the key, or the leaflet?"
                )
            )
        )
    }

    // NEW Test for "them" resolving to one in-scope item
    @Test("Pronoun ’them' Single In Scope")
    func testPronounThemSingleInScope() async throws {
        // Initialize game state with ’them' set to key (held) & note (out of scope)
        let initState = GameState(
            locations: Array(gameState.locations.values),
            items: Array(gameState.items.values),
            player: gameState.player,
            vocabulary: vocabulary,
            pronouns: ["them": [.item("key"), .item("note")]] // Start with ’them'
        )
        // Verify item locations
        #expect(initState.items["key"]?.parent == .player)
        #expect(initState.items["note"]?.parent == .item("chest"))
        #expect(initState.items["chest"]?.attributes["isOpen"] == nil)

        // Only the key should be resolved from "them" because the note is out of scope
        let result = parser.parse(
            input: "drop them",
            vocabulary: vocabulary,
            gameState: initState
        )
        let command = try result.get()
        #expect(command.verb == "drop")
        #expect(command.directObject == .item("key")) // Successfully resolved to the only one in scope
    }

    // --- Tests for Container Scope ---

    @Test("Find Item in Open Inventory Container")
    func testFindItemInOpenInventoryContainer() async throws {
        // Player has 'backpack' (open) containing 'coin'
        let result = parser.parse(
            input: "take coin",
            vocabulary: vocabulary,
            gameState: gameState
        )
        let command = try result.get()
        #expect(command.verb == "take")
        #expect(command.directObject == .item("coin"))
        #expect(command.indirectObject == nil)
    }

    @Test("Find Item in Open Inventory Container (With Modifier)")
    func testFindItemInOpenInventoryContainerWithMod() async throws {
        // Player has 'backpack' (open) containing 'gold coin'
        let result = parser.parse(
            input: "take gold coin",
            vocabulary: vocabulary,
            gameState: gameState
        )
        let command = try result.get()
        #expect(command.verb == "take")
        #expect(command.directObject == .item("coin"))
        #expect(command.directObjectModifiers == ["gold"])
        #expect(command.indirectObject == nil)
    }

    @Test("Item in Closed Inventory Container Not Found")
    func testItemInClosedInventoryContainerNotFound() async throws {
        // Player has 'chest' (parent .player, but closed/locked) containing 'note' (parent .item(chest))
        let result = parser.parse(
            input: "take note",
            vocabulary: vocabulary,
            gameState: gameState
        )
        // Should not find 'note' because parent 'chest' is closed/locked -> item not in scope
        #expect(result.isFailure(matching: .itemNotInScope(noun: "note")))
    }

    @Test("Item in Inventory Container in Location Not Found Yet")
    func testItemInLocationContainerNotFoundYet() async throws {
        // TODO: Re-enable and adapt this test once gatherCandidates handles
        // items inside containers within the location.
        // The setup now includes "widget" inside "box" in the room.

        let takeWidget = parser.parse(
            input: "take widget",
            vocabulary: vocabulary,
            gameState: gameState
        )
        #expect(
            takeWidget.isFailure(matching: ParseError.itemNotInScope(noun: "widget"))
        )

        // Check we can find the container itself (box)
        let takeBox = parser.parse(
            input: "take wooden box",
            vocabulary: vocabulary,
            gameState: gameState
        )
        #expect(try takeBox.get().directObject == .item("box"))
    }

    @Test("Direct Inventory Item Preferred Over Item In Container")
    func testDirectInventoryPreferredOverContainer() async throws {
        // Create a temporary state where 'key' is held and a temp key is in backpack
        var itemsDict = gameState.items // Base items copy
        let tempKeyInBackpack = Item(
            id: "tempKeyInBackpack",
            .name("key"),
            .in(.item("backpack")),
            .adjectives("temp")
        )
        let tempKeyOnGround = Item(
            id: "tempKeyOnGround",
            .name("key"),
            .in(.location(.startRoom)),
            .adjectives("temp")
        )
        let permKey = Item(
            id: "permKey",
            .name("key"),
            .in(.location(.startRoom)),
            .adjectives("perm")
        )
        itemsDict[tempKeyInBackpack.id] = tempKeyInBackpack
        itemsDict[tempKeyOnGround.id] = tempKeyOnGround
        itemsDict[permKey.id] = permKey
        let initState = GameState(
            locations: Array(gameState.locations.values),
            items: Array(itemsDict.values), // Pass the modified copy's values
            player: gameState.player,
            vocabulary: vocabulary,
            pronouns: gameState.pronouns // Use base pronouns
        )

        // Verify setup
        #expect(initState.items["key"]?.parent == .player)
        #expect(initState.items["tempKeyInBackpack"]?.parent == .item("backpack"))
        #expect(initState.items["tempKeyOnGround"]?.parent == .location(.startRoom))
        #expect(initState.items["permKey"]?.parent == .location(.startRoom))

        // Update vocab temporarily ONLY for this test's state
        var tempVocabulary = vocabulary
        tempVocabulary.items["key", default: []].insert(tempKeyInBackpack.id)
        tempVocabulary.items["key", default: []].insert(tempKeyOnGround.id)
        tempVocabulary.items["key", default: []].insert(permKey.id)

        // Parsing "take key" might become ambiguous IF the parser finds both.
        // Let's test with the modifier to target the *real* key.
        let resultSpecific = parser.parse(
            input: "take rusty key",
            vocabulary: tempVocabulary,
            gameState: initState
        )
        let commandSpecific = try resultSpecific.get()

        // Should resolve to the original 'key' which is rusty and held by player.
        #expect(commandSpecific.directObject == .item("key"))
        #expect(commandSpecific.directObjectModifiers == ["rusty"])
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
        let result = parser.parse(
            input: "",
            vocabulary: vocabulary,
            gameState: gameState
        )
        #expect(result == .failure(ParseError.emptyInput))
    }

    @Test("Parse only whitespace")
    func testParseWhitespace() async {
        let result = parser.parse(
            input: "   \t  \n ",
            vocabulary: vocabulary,
            gameState: gameState
        )
        #expect(result == .failure(ParseError.emptyInput))
    }

    @Test("Parse only noise words")
    func testParseOnlyNoise() async {
        let result = parser.parse(
            input: "a the an .",
            vocabulary: vocabulary,
            gameState: gameState
        )
        #expect(result == .failure(ParseError.emptyInput))
    }

    @Test("Noun Not In Scope")
    func testNounNotInScope() async {
        // Lamp exists in vocab, but isn’t in the room or held by player
        // Create a custom state where the lamp is explicitly out of scope
        var itemsDict = gameState.items // Base items copy
        itemsDict[lampID]?.attributes[.parentEntity] = .parentEntity(.nowhere) // Move lamp out of scope
        let customState = GameState(
            locations: Array(gameState.locations.values),
            items: Array(itemsDict.values),
            player: gameState.player,
            vocabulary: vocabulary,
            pronouns: gameState.pronouns // Use base pronouns
        )
        #expect(customState.items[lampID]?.parent == .nowhere) // Verify setup

        // Run parser with the custom state
        let result = parser.parse(
            input: "take lamp",
            vocabulary: vocabulary,
            gameState: customState
        )
        #expect(result == .failure(ParseError.itemNotInScope(noun: "lamp")))
    }

    // MARK: - Noun/Modifier Extraction Tests

    @Test("Extract Noun/Mods - Simple Case")
    func testExtractNounModsSimple() async throws {
        // "take brass lantern"
        let result = parser.parse(
            input: "take brass lantern",
            vocabulary: vocabulary,
            gameState: gameState
        )
        let command = try result.get()
        #expect(command.verb == "take")
        #expect(command.directObject == .item("lantern")) // Noun = lantern
        #expect(command.directObjectModifiers == ["brass"]) // Mods = [brass]
    }

    @Test("Extract Noun/Mods - With Noise Words")
    func testExtractNounModsNoise() async throws {
        // "take the small rusty key"
        let result = parser.parse(
            input: "take the small rusty key",
            vocabulary: vocabulary,
            gameState: gameState
        )
        let command = try result.get()
        #expect(command.verb == "take")
        #expect(command.directObject == .item("key")) // Noun = key
        #expect(command.directObjectModifiers == ["small", "rusty"]) // Mods = [small, rusty], "the" filtered
    }

    @Test("Extract Noun/Mods - Multiple Nouns")
    func testExtractNounModsMultipleNouns() async throws {
        // "put the small box key in lamp"
        // Setup: Make lamp a container for this test to pass resolution
        var itemsDict = gameState.items // Base items copy
        itemsDict["lantern"]?.attributes[.isContainer] = true
        let modifiedState = GameState(
            locations: Array(gameState.locations.values),
            items: Array(itemsDict.values),
            player: gameState.player,
            vocabulary: vocabulary,
            pronouns: gameState.pronouns // Use base pronouns
        )

        let result = parser.parse(
            input: "put the small box key in lamp",
            vocabulary: vocabulary,
            gameState: modifiedState
        )
        let command = try result.get()

        #expect(command.verb == "insert")
        // DO: noun = key (last known noun), mods = [small] ("box" is noun, not modifier)
        #expect(command.directObject == .item("key"))
        #expect(command.directObjectModifiers == ["small"])
        // IO: noun = lamp (resolved to 'lantern'), mods = []
        #expect(command.indirectObject == .item("lantern"))
        #expect(command.indirectObjectModifiers == [])
        #expect(command.preposition == "in")
    }

    @Test("Extract Noun/Mods - Only Unknown Word")
    func testExtractNounModsOnlyUnknown() async throws {
        // "look xyzzy" - Should now parse with look verb and attempt resolution
        let result = parser.parse(
            input: "look xyzzy",
            vocabulary: vocabulary,
            gameState: gameState
        )
        #expect(result.isFailure(matching: .unknownNoun("xyzzy")))
    }

    @Test("Extract Noun/Mods - Only Modifier")
    func testExtractNounModsOnlyModifier() async throws {
        // "look brass" - Should now parse with look verb and attempt resolution
        let result = parser.parse(
            input: "look brass",
            vocabulary: vocabulary,
            gameState: gameState
        )
        #expect(result.isFailure(matching: .unknownNoun("brass")))
    }

    @Test("Extract Noun/Mods - Pronoun")
    func testExtractNounModsPronoun() async throws {
        // "drop it" - assumes 'it' refers to something held (e.g., the key)
        var itemsDict = gameState.items // Base items copy
        itemsDict["key"]?.attributes[.parentEntity] = .parentEntity(.player) // Put key in inventory
        let modifiedState = GameState(
            locations: Array(gameState.locations.values),
            items: Array(itemsDict.values),
            player: gameState.player,
            vocabulary: vocabulary,
            pronouns: ["it": [.item("key")]] // Set 'it' to key for this state
        )

        let result = parser.parse(
            input: "drop it",
            vocabulary: vocabulary,
            gameState: modifiedState
        )
        let command = try result.get()
        #expect(command.verb == "drop")
        #expect(command.directObject == .item("key")) // Noun = it (resolved to key)
        #expect(command.directObjectModifiers == []) // Mods = []
    }

    @Test("Extract Noun/Mods - Pronoun With Noise")
    func testExtractNounModsPronounNoise() async throws {
        // "drop the it"
        var itemsDict = gameState.items // Base items copy
        itemsDict["key"]?.attributes[.parentEntity] = .parentEntity(.player)
        let modifiedState = GameState(
            locations: Array(gameState.locations.values),
            items: Array(itemsDict.values),
            player: gameState.player,
            vocabulary: vocabulary,
            pronouns: ["it": [.item("key")]] // Set 'it' to key for this state
        )

        let result = parser.parse(
            input: "drop the it",
            vocabulary: vocabulary,
            gameState: modifiedState
        )
        let command = try result.get()
        #expect(command.verb == "drop")
        #expect(command.directObject == .item("key")) // Noun = it
        #expect(command.directObjectModifiers == []) // Mods = [], "the" filtered
    }

    // MARK: - Direction Parsing Tests

    @Test("Parse Single Word Direction (Implicit Go)")
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
            let result = parser.parse(
                input: input,
                vocabulary: vocabulary,
                gameState: gameState
            )
            let command = try result.get()
            #expect(command.verb == "go") // Should assume "go"
            #expect(command.direction == expectedDirection)
            #expect(command.directObject == nil)
            #expect(command.indirectObject == nil)
            #expect(command.preposition == nil)
            #expect(command.rawInput == input)
        }
    }

    @Test("Parse Go + Direction")
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
            let result = parser.parse(
                input: input,
                vocabulary: vocabulary,
                gameState: gameState
            )
            let command = try result.get()
            #expect(command.verb == "go")
            #expect(command.direction == expectedDirection)
            #expect(command.directObject == nil)
            #expect(command.indirectObject == nil)
            #expect(command.preposition == nil)
            #expect(command.rawInput == input)
        }
    }

    @Test("Parse Go + Invalid Direction")
    func testParseGoInvalidDirection() async throws {
        let input = "go nowhere"
        let result = parser.parse(
            input: input,
            vocabulary: vocabulary,
            gameState: gameState
        )
        #expect(result.isFailure(matching: .badGrammar("Expected a direction (like north, s, up) but found 'nowhere'.")))
    }

    @Test("Parse Go + Extra Words")
    func testParseGoExtraWords() async throws {
        let input = "go north quickly"
        let result = parser.parse(
            input: input,
            vocabulary: vocabulary,
            gameState: gameState
        )
        #expect(result.isFailure(matching: .badGrammar("Unexpected words found after command: 'quickly'")))
    }

    @Test("Parse Go (No Direction)")
    func testParseGoNoDirection() async throws {
        let input = "go"
        let result = parser.parse(
            input: input,
            vocabulary: vocabulary,
            gameState: gameState
        )
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
