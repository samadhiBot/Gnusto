# Gnusto Example Game

This folder contains an example game that demonstrates how to use the GnustoEngine. The goal is to provide a clear, approachable reference implementation that helps new developers understand how to create games with Gnusto.

## Design Philosophy

The `ExampleGame` class demonstrates:

1. Setting up a complete game with the engine
2. Defining game content (locations, items, verbs)
3. Implementing custom behavior through game hooks
4. Managing time-based events with fuses and daemons
5. Testing client-side ergonomics of the engine

### Adding to the Gnusto Example Game

- Everything in the example game should be intentional, and should serve to demonstrate some piece of functionality that the engine provides.
- The Example Game is the proving ground for functionality and ergonomics.
- The Gnusto Interactive Fiction Engine is still under active development, and remains pre 0.0.1, so we are free to enhance and improve the game engine whenever we find missing functionality or ergonomics in need of improvement.

## Example Features

The example game showcases several important engine features:

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
    adjectives: ["brass"],
    synonyms: ["lamp", "light"],
    description: "A sturdy brass lantern, useful for exploring dark places.",
    properties: [.takable, .lightSource],
    parent: .location("startRoom")
)
```

### Game Hooks

The example demonstrates how to implement custom behavior for specific game events:

```swift
// Custom logic when player enters a room
private static func onEnterRoom(engine: GameEngine, locationID: LocationID) async {
    if locationID == "treasureRoom" {
        let flag = "visited_treasure_room"
        let hasVisited = engine.getCurrentGameState().flags[flag] ?? false

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

### Time-Based Events

The example includes a complete implementation of a lantern timer system similar to Zork's:

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

## Running the Example

To run the example game, simply build and execute the GnustoExamples target. The game will start in the console and guide you through exploring a small cave system with a lantern and treasure.

## Using This as a Template

You can use `ExampleGame.swift` as a starting point for your own games. Key points to understand:

1. The `createGameData()` method sets up your game world
2. The game hooks (`onEnterRoom`, etc.) provide custom behavior
3. The main `run()` method starts the game

Feel free to modify and extend this example to create your own interactive fiction adventures!
