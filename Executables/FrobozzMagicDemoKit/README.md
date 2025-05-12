# Frobozz Magic Demo Kit

Welcome, aspiring Implementor! This folder contains the genuine Frobozz Magic Demo Kit, guaranteed\* to demonstrate the wondrous capabilities of the Gnusto Interactive Fiction Engine. Its goal is to provide a clear, approachable reference implementation to help new developers understand how to create magical interactive adventures with Gnusto.

\*Guarantee void if used near grues, volcanoes, or during Implementor Incantations.

## Design Philosophy

The `FrobozzMagicDemoKit` class (the heart of the Demo Kit) demonstrates:

1. Setting up a complete game with the engine (some assembly required)
2. Defining magical game content (locations, items, verbs)
3. Implementing custom spell-like behavior through game hooks
4. Managing time-based enchantments with fuses and daemons
5. Testing the user-friendliness (ergonomics) of the engine for client games

### Adding More Magic to the Demo Kit

- Everything in the Demo Kit should be intentional, serving to demonstrate some piece of engine functionality (or "magic").
- The Demo Kit is the proving ground for engine functionality and ease-of-use.
- The Gnusto Interactive Fiction Engine is still under active development (pre 0.0.1!), so feel free to enhance and improve the engine whenever you find missing functionality or awkward enchantments.

## Demonstrated Features

The Demo Kit showcases several important engine features:

### Location and Item Setup

```swift
// Creating locations with descriptions and exits
Location(
    id: "treasureRoom",
    name: "Treasure Room",
    description: """
        This small chamber sparkles with reflections from numerous precious gems \
        embedded in the walls. A stone pedestal in the center of the room holds \
        what appears to be a golden crown.
        """,
    exits: [
        .south: Exit(destination: "darkChamber")
    ]
)

// Creating items with properties
Item(
    id: "brassLantern",
    name: "lantern",
    adjectives: "brass",
    synonyms: "lamp", "light",
    description: "A sturdy brass lantern, useful for exploring dark places.",
    properties: .takable, .lightSource,
    .in(.location(.startRoom))
)
```

### Game Hooks (Incantations)

The Demo Kit demonstrates how to implement custom behavior for specific game events:

```swift
// Custom logic when player enters a room
private static func onEnterRoom(engine: GameEngine, locationID: LocationID) async {
    if locationID == "treasureRoom" {
        let flag = "visited_treasure_room"
        let hasVisited = await engine.getCurrentGameState().flags[flag] ?? false

        if !hasVisited {
            // First-time discovery behavior
            // ...
        }
    }
}

// Custom logic at the start of each turn
private static func beforeEachTurn(engine: GameEngine) async {
    // Atmospheric messages based on location and turn count
    // ...
}

// Custom item examination behavior
private static func onExamineItem(engine: GameEngine, itemID: ItemID) async -> Bool {
    // Special behavior for certain items
    // ...
}
```

### Time-Based Events (Fuses & Daemons)

The Demo Kit includes a complete implementation of a lantern timer system similar to Zork's:

```swift
// Create a daemon that runs every turn
private static func createLanternTimerDaemon() -> DaemonDefinition {
    return DaemonDefinition(
        id: LanternConstants.timerDaemonID,
        frequency: 1 // Run every turn
    ) { engine in
        // Track battery life, trigger warnings, etc.
        // ...
    }
}

// Create a fuse that triggers after a certain number of turns
private static func createLanternWarningFuse() -> FuseDefinition {
    return FuseDefinition(
        id: LanternConstants.lowBatteryWarningFuseID,
        initialTurns: LanternConstants.lowBatteryThreshold / 2
    ) { engine in
        // Provide a warning message
        // ...
    }
}
```

## Running the Demo Kit

To run the Demo Kit, simply build and execute the `FrobozzMagicDemoKit` target. The demonstration will start in the console and guide you through exploring a small cave system with a lantern and treasure (standard adventuring gear).

## Using This as a Template

You can use `FrobozzMagicDemoKit.swift` as a starting point for your own magical creations. Key points to understand:

1. The `createGameData()` method sets up your game world
2. The game hooks (`onEnterRoom`, etc.) provide custom behavior
3. The main `run()` method starts the game

Feel free to modify and extend this Demo Kit to create your own interactive fiction adventures!
