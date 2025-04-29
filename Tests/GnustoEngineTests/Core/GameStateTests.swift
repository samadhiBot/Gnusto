import Testing
import Foundation // For JSONEncoder/Decoder
@testable import GnustoEngine

@MainActor
@Suite("GameState Struct Tests")
struct GameStateTests {
    // Define IDs for clarity
    static let locWOH: LocationID = "westOfHouse"
    static let locNorth: LocationID = "northOfHouse"
    static let locClearing: LocationID = "clearing"

    static let itemLantern: ItemID = "lantern"
    static let itemMailbox: ItemID = "mailbox"
    static let itemLeaflet: ItemID = "leaflet"
    static let itemSword: ItemID = "sword"

    // 1. Define all potential Items
    func createSampleItems() -> [Item] {
        [
            Item(
                id: Self.itemLantern,
                name: "lantern",
                properties: .takable, .lightSource
            ),
            Item(
                id: Self.itemMailbox,
                name: "mailbox",
                properties: .container, .openable,
                parent: .location(Self.locWOH)
            ),
            Item(
                id: Self.itemLeaflet,
                name: "leaflet",
                properties: .takable, .read,
                parent: .item(Self.itemMailbox)
            ),
            Item(
                id: Self.itemSword,
                name: "sword",
                properties: .takable,
                parent: .player
            )
        ]
    }

    // 2. Define all Locations (without items initially)
    func createSampleLocations() -> [Location] {
        return [
            Location(
                id: Self.locWOH,
                name: "West of House",
                longDescription: "You are standing west of a white house.",
                exits: [.north: Exit(destination: Self.locNorth)]
                // items: // Removed
            ),
            Location(
                id: Self.locNorth,
                name: "North of House",
                longDescription: "You are north of the house.",
                exits: [.south: Exit(destination: Self.locWOH)]
            )
        ]
    }

    // 3. Define initial Player
    func createSamplePlayer() -> Player {
        Player(in: Self.locWOH)
    }

    // 4. Helper to create the GameState with defined placements
    func createSampleGameState() async -> GameState {
        let items = createSampleItems()
        let locations = createSampleLocations()
        let player = createSamplePlayer()
        let flags = ["gameStarted": true]
        let pronouns: [String: Set<ItemID>] = ["it": [Self.itemMailbox]]

        return GameState(
            locations: locations,
            items: items,
            player: player,
            flags: flags,
            pronouns: pronouns
        )
    }

    // --- Tests ---

    @Test("GameState Initial Factory and Parent Setting")
    func testGameStateInitialFactory() async throws {
        let state = await createSampleGameState()

        // Check locations exist
        #expect(state.locations.count == 2)
        #expect(state.locations[Self.locWOH] != nil)
        #expect(state.locations[Self.locNorth] != nil)
        // #expect(state.locations[locWOH]?.items == [itemMailbox]) // Removed: Location no longer stores items directly

        // Check items exist
        #expect(state.items.count == 4) // Now 4 items
        #expect(state.items[Self.itemLantern] != nil) // Exists but parent is .nowhere
        #expect(state.items[Self.itemMailbox] != nil)
        #expect(state.items[Self.itemLeaflet] != nil)
        #expect(state.items[Self.itemSword] != nil)

        // Check item parents were set correctly by GameState.initial
        #expect(state.items[Self.itemLantern]?.parent == .nowhere) // Default
        #expect(state.items[Self.itemMailbox]?.parent == .location(Self.locWOH))
        #expect(state.items[Self.itemLeaflet]?.parent == .item(Self.itemMailbox))
        #expect(state.items[Self.itemSword]?.parent == .player)

        // Check player state
        #expect(state.player.currentLocationID == Self.locWOH)

        // Check other state properties
        #expect(state.flags == ["gameStarted": true])
        #expect(state.pronouns == ["it": [Self.itemMailbox]])

        // Check derived inventory
        #expect(Set(state.itemsInInventory()) == [Self.itemSword])
    }

    @Test("GameState Property Modification")
    func testGameStatePropertyModification() async throws {
        let state = await createSampleGameState() // Use let, as direct mutation of struct props is removed

        // Valid: Modify properties of reference types (Location, Item)
        state.locations[Self.locWOH]?.longDescription = "A new description."
        state.items[Self.itemLantern]?.name = "Magic Lantern"

        // Valid: Simulate state changes by modifying Item parents (reference type)
        state.items[Self.itemLantern]?.parent = .player
        state.items[Self.itemSword]?.parent = .location(state.player.currentLocationID)

        // Assertions for the valid modifications:
        #expect(
            state.locations[Self.locWOH]?.longDescription?
                .rawStaticDescription == "A new description."
        )
        #expect(state.items[Self.itemLantern]?.name == "Magic Lantern")

        // Check derived inventory reflects parent changes
        #expect(Set(state.itemsInInventory()) == [Self.itemLantern]) // Sword dropped, Lantern taken

        // Check sword is now in the location
        #expect(state.items[Self.itemSword]?.parent == .location(Self.locWOH))

        // Removed assertions for disallowed mutations:
        // #expect(state.player.score == 10)
        // #expect(state.flags["lightSeen"] == true)
        // #expect(state.pronouns["it"] == [Self.itemLantern])
    }

    @Test("GameState Codable Conformance")
    func testGameStateCodable() async throws {
        let originalState = await createSampleGameState()

        // Modify an item *before* encoding to check reference persistence & parent encoding
        originalState.items[Self.itemLantern]?.addProperty(.on)
        originalState.items[Self.itemLantern]?.parent = .player // Put lantern in inventory

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys] // Easier debugging
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalState)
        let decodedState = try decoder.decode(GameState.self, from: jsonData)

        // Basic properties
        #expect(decodedState.flags == originalState.flags)
        #expect(decodedState.pronouns == originalState.pronouns)
        #expect(decodedState.player == originalState.player)

        // Check dictionaries counts
        #expect(decodedState.locations.count == originalState.locations.count)
        #expect(decodedState.items.count == originalState.items.count)

        // Check content of locations (comparing key properties)
        #expect(decodedState.locations[Self.locWOH]?.name == originalState.locations[Self.locWOH]?.name)
        // #expect(decodedState.locations[locWOH]?.items == originalState.locations[locWOH]?.items) // Removed
        #expect(decodedState.locations[Self.locNorth]?.longDescription == originalState.locations[Self.locNorth]?.longDescription)

        // Check content of items (comparing key properties, including parent)
        #expect(decodedState.items[Self.itemLantern]?.name == originalState.items[Self.itemLantern]?.name)
        #expect(decodedState.items[Self.itemLantern]?.properties == originalState.items[Self.itemLantern]?.properties)
        #expect(decodedState.items[Self.itemLantern]?.parent == originalState.items[Self.itemLantern]?.parent) // Should be .player
        #expect(decodedState.items[Self.itemMailbox]?.parent == originalState.items[Self.itemMailbox]?.parent) // Should be .location
        #expect(decodedState.items[Self.itemLeaflet]?.parent == originalState.items[Self.itemLeaflet]?.parent) // Should be .item

        // IMPORTANT: Check that decoded objects are NEW instances
        #expect(decodedState.locations[Self.locWOH] !== originalState.locations[Self.locWOH])
        #expect(decodedState.items[Self.itemLantern] !== originalState.items[Self.itemLantern])
    }

    @Test("GameState Value Semantics (Mixed with Reference)")
    func testGameStateValueSemantics() async throws {
        let state1 = await createSampleGameState()
        let state2 = state1 // Creates a copy of the struct

        // Check initial equality of value types
        #expect(state1.player == state2.player)
        #expect(state1.flags == state2.flags)
        #expect(state1.pronouns == state2.pronouns)

        // Modify reference type (Item) *through* state2
        state2.items[Self.itemLantern]?.name = "Shiny Lantern"
        state2.items[Self.itemLantern]?.parent = .player // Also move it for state2

        // Verify state1's value types remain equal to state2's initial values (confirming copy)
        let initialPlayer = state1.player // Capture initial player state from state1
        #expect(state1.player == initialPlayer) // state1 player unchanged
        #expect(state2.player == initialPlayer) // state2 player also initially unchanged
        let initialFlags = state1.flags
        #expect(state1.flags == initialFlags)
        #expect(state2.flags == initialFlags)
        let initialPronouns = state1.pronouns
        #expect(state1.pronouns == initialPronouns)
        #expect(state2.pronouns == initialPronouns)

        // Verify state1's reference type *is* CHANGED (because Item is a class)
        #expect(state1.items[Self.itemLantern]?.name == "Shiny Lantern")
        // Also verify parent change propagated
        #expect(state1.items[Self.itemLantern]?.parent == .player)

        // Check derived inventories reflect the change in both states (due to shared Item instance)
        #expect(Set(state1.itemsInInventory()) == [Self.itemSword, Self.itemLantern]) // Sword was initial, lantern got moved
        #expect(Set(state2.itemsInInventory()) == [Self.itemSword, Self.itemLantern]) // Same items, parent change propagated

        // Further check: state1 and state2 are distinct structs
        // Check their internal dictionaries point to the same item objects initially
        #expect(state1.items[Self.itemLantern] === state2.items[Self.itemLantern])

        // Removed disallowed mutations from state2:
        // state2.player.moves = 5
        // state2.flags["mailboxOpened"] = true
        // state2.pronouns["it"] = [Self.itemLantern]
    }
}
