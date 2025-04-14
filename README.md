# Gnusto

A Swift interactive fiction game engine with unidirectional data flow.

## Overview

Gnusto is a modern text adventure engine built with Swift that emphasizes:

- Clean unidirectional data flow
- Component-based game objects
- Separation of concerns
- Testability
- Ergonomic API for game creators

## Architecture

Gnusto uses a unidirectional data flow pattern to manage state and user interactions:

```
┌─────────────┐ Player Input  ┌─────────────────┐ Parsed Command  ┌───────────────────┐ Actions  ┌─────────────────┐ State Changes  ┌───────────┐
│   Sources   ├──────────────▶│     Parser      ├────────────────▶│ Action Dispatcher ├─────────▶│      Engine     │───────────────▶│   State   │
│ (Renderer)  │               │    (Nitfol)     │                 │                   │          │                 │                │  (World)  │
└─────────────┘               └─────────────────┘                 └───────────┬───────┘          └────────┬────────┘                └──────┬────┘
      ▲                                                                       │                           │                                │
      │                                                                       │ Effects                   │                                │
      │ Effects Rendered                                                      │                           │                                │
      │                                                                       └───────────────────────────┘                                │
      │                                                                                                                                    │
      └────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

1.  **Player Input** is received (e.g., from a console `Renderer`).
2.  The input string is sent to the **Parser** (`Nitfol` library) which uses a Core ML model to tag words and structure the input into a `Command`.
3.  The `Command` is wrapped in an `Action` (e.g., `.command(Command)`) and sent to the **Action Dispatcher**.
4.  The **Action Dispatcher** consults the current game **State** (the `World` object) and determines the appropriate `CommandHandler` or custom game logic to execute.
5.  Command Handlers interact with the **World** (potentially reading and writing `Component` data) and produce **Effects** (like `.showText`, `.updateStatusLine`). Object-specific logic or Room Hooks might generate further **Actions**.
6.  The **Engine** receives `Effects` from the `ActionDispatcher`.
7.  The **Engine** sends the `Effects` to the **Renderer**.
8.  The **Renderer** presents the `Effects` to the player (e.g., printing text to the console).
9.  The cycle repeats.

## Core Components

### Engine (`Sources/Gnusto/Engine`)

The central coordinator (`Engine.swift`) that manages the game loop, receives Actions, sends Effects to the Renderer, and holds the core game state (`World`). It relies on the `Game` protocol (`Game.swift`) which defines how a specific adventure is set up. It also uses an `EventManager` (`EventManager.swift`) for time-based events.

```swift
// Example Initialization
import Gnusto
import GnustoConsole

struct MyGame: Game { /* ... game definition ... */ }

let game = MyGame()
let renderer = ConsoleRenderer() // From GnustoConsole package

do {
    let engine = try Engine(game: game, renderer: renderer)
    try engine.run() // Start the game loop
} catch {
    print("Error starting engine: \\(error)")
}

```

### World (`Sources/Gnusto/Models/World`)

Stores the entire game state (`World.swift`), primarily consisting of a collection of `Object` instances managed by an Entity Component System (ECS) inspired approach.

### Objects & Components (`Sources/Gnusto/Models/Objects`, `Sources/Gnusto/Models/Components`)

Game entities (`Object.swift`) are defined by the `Component`s (`Component.swift`) attached to them. Core components include `DescriptionComponent`, `LocationComponent`, `ContainerComponent`, `RoomComponent`, `PlayerComponent`, `ObjectComponent`, etc. See `Flag.swift` for object attributes.

```swift
// Game world holds all objects
let world = World()

// Create an object using the builder pattern (preferred)
Object.item(
    id: "lantern",
    name: "brass lantern",
    description: "An old brass lantern.",
    location: "cabin", // ID of the containing object/room
    flags: [.takeable, .lightSource],
    in: world, // Pass the world to register the object
    LightSourceComponent(isOn: false) // Add specific components
)
```

### Parser (`Nitfol` Library)

Responsible for taking raw player input strings and converting them into structured `Command` objects. Gnusto uses the external `Nitfol` library for this, which leverages a Core ML model trained by `Gloth`. See the [Nitfol README](Docs/Nitfol-README.md) for details.

### Command (`Sources/Gnusto/Models/Command.swift`)

A struct representing a parsed player command, typically containing a `verb`, `directObject`, `preposition`, and `indirectObject`, along with modifiers. This is the output of the `Nitfol` parser.

### Actions & Effects (`Sources/Gnusto/Models/Actions`, `Sources/Gnusto/Models/Effect.swift`)

The primary data structures that flow through the system:

- **Actions**: Represent intentions or events that need processing (e.g., `.command(Command)`, `.gameEvent(String)`).
- **Effects**: Represent the outcomes of Actions that need to be presented to the player (e.g., `.showText(String)`, `.updateStatusLine(...)`).

### Action Dispatcher (`Sources/Gnusto/Services/ActionDispatcher.swift`)

Receives `Action`s, determines the appropriate handler (usually one from `Sources/Gnusto/Services/CommandHandlers`), executes it against the `World`, and returns the resulting `Effect`s.

```swift
// Internal usage example:
let command = nitfolParser.parse("look") // Assume Nitfol parser returns a Command
let lookAction = Action.command(command)
let effects = dispatcher.dispatch(lookAction, in: world)
// effects might be [.showText("You are in a cabin...")]
```

### Renderer (`Sources/Gnusto/Engine/Renderer.swift` & external packages)

A protocol defining how `Effect`s are presented. Concrete implementations handle the actual output (e.g., `GnustoConsole` for terminal output, potential future graphical renderers).

```swift
// Example ConsoleRenderer (lives in a separate package)
public protocol Renderer {
    func render(_ effect: Effect)
    func readInputLine() async -> String?
    // Other methods for setup/teardown as needed
}

public class ConsoleRenderer: Renderer {
    public func render(_ effect: Effect) {
        switch effect {
        case .showText(let text):
            print(text)
        case .updateStatusLine(let locationName, let score, let moves):
            // Use helper to get Location object if needed for name
            print("\\n[\\(locationName ?? "Unknown") | Score: \\(score) | Moves: \\(moves)]")
        // ... other cases
        default:
            print("Unhandled effect: \\(effect)")
        }
    }
    // ... implementation for readInputLine, etc. ...
}
```

## Creating a Game

Implement the `Game` protocol (`Sources/Gnusto/Engine/Game.swift`) to define your adventure:

```swift
import Gnusto

struct MyAdventureGame: Game {
    let welcomeMessage = "Welcome to My Adventure!" // Changed from welcomeText
    let versionInfo = "My Adventure v1.0 by Developer"

    func setupWorld() throws -> World { // Changed from createWorld
        let world = World() // Start with an empty world

        // Use static builders on Object for creation
        Object.room(
            id: "cabin",
            name: "Cabin",
            description: "A cozy log cabin with a wooden door.",
            in: world // Add directly to the world
        )

        Object.player(id: "player", location: "cabin", in: world)

        Object.item(
            id: "lantern",
            name: "brass lantern",
            description: "An old brass lantern that still works.",
            location: "cabin",
            flags: [.takeable], // Note: LightSourceComponent handles light aspect
            in: world,
            LightSourceComponent(isOn: false) // Add components like this
        )

        // Connect rooms after they exist in the world
        Object.room(id: "forest", name: "Forest", description: "...", in: world)
        world.connect(from: "cabin", direction: .east, to: "forest", bidirectional: true)

        return world
    }

    // Optional: Define custom actions or modify dispatcher behavior
    func modifyDispatcher(_ dispatcher: ActionDispatcher) {
        dispatcher.registerCustomAction(verb: "light") { context in
            guard context.directObject?.id == "lantern" else {
                return [.showText("You don't see that here to light.")]
            }
            // Logic to modify the lantern's LightSourceComponent state
            // ...
            return [.showText("You light the lantern.")]
        }
    }
}
```

## Component System

Gnusto uses an Entity Component System (ECS) inspired approach for game objects. See `Sources/Gnusto/Models/Components` for available components.

### Core Components

- `DescriptionComponent`: Basic info (name, description, synonyms).
- `LocationComponent`: Where the object is located (parent `Object.ID`).
- `ContainerComponent`: For objects that hold others (capacity, open state).
- `RoomComponent`: Defines a location, tracks light level, holds exits (`ExitsComponent`).
- `PlayerComponent`: Player-specific state (score, moves, current location).
- `ObjectComponent`: General object attributes and `Flag`s.
- `LightSourceComponent`: Light source behavior (on/off, brightness).
- `ExitsComponent`: Attached to rooms, holds `Exit` definitions.
- `StateComponent`: Generic key-value store for custom object state.

### Object Flags (`Sources/Gnusto/Models/Flag.swift`)

Objects can have various flags affecting behavior (defined in `ObjectComponent`):

```swift
public enum Flag: Hashable, Codable {
    case takeable       // Can be picked up
    case openable       // Can be opened/closed
    case container      // Can hold other objects (requires ContainerComponent)
    case surface        // Objects can be put *on* it (requires ContainerComponent)
    case wearable       // Can be worn
    case edible         // Can be eaten
    case lockable       // Can be locked/unlocked (requires ContainerComponent)
    case locked         // Currently locked
    case lightSource    // Provides light (requires LightSourceComponent)
    case supporter      // Alias for surface
    case scenery        // Cannot be interacted with directly, part of room description
    case door           // Behaves like a door (openable, affects exits)
    // etc.
}
```

## Command Processing

Standard commands are handled by dedicated `CommandHandler` classes in `Sources/Gnusto/Services/CommandHandlers`. The `ActionDispatcher` routes parsed `Command`s to the appropriate handler based on the verb.

- **Movement**: `GoHandler` (`go north`, `n`, `u`, `d`, etc.)
- **Inventory**: `InventoryHandler` (`inventory`, `i`)
- **Examination**: `ExamineHandler` (`examine lantern`, `x lantern`, `look at key`)
- **Object Interaction**: `TakeHandler`, `DropHandler`
- **Container Interaction**: `OpenHandler`, `CloseHandler`, `PutHandler`, `RemoveHandler` (handles `put coin in chest`, `take coin from chest`)
- **Other**: `LookHandler`, `QuitHandler`, `SaveHandler`, `RestoreHandler`, `ScoreHandler`, `VersionHandler`, etc.

Custom commands beyond the standard set can be added via the `Game` protocol's `modifyDispatcher` function.

## Usage Example

A separate executable package (like `GnustoGame`) would typically consume the `Gnusto` library:

```swift
// In your game's main.swift or equivalent
import Gnusto
import GnustoConsole // Assuming a console renderer package

// 1. Define your game structure
struct MyGame: Game {
    // ... implementation from "Creating a Game" section ...
}

// 2. Create instances
let game = MyGame()
let renderer = ConsoleRenderer()

// 3. Set up and run the engine
do {
    let engine = try Engine(game: game, renderer: renderer)
    try engine.run()
} catch {
    print("Failed to run game: \\(error)")
}
```

## Building Objects

Use the static builder methods on `Object` for creating entities:

```swift
// In your Game's setupWorld() method, assuming 'world' is the World instance

// Create a room
Object.room(
    id: "forest",
    name: "Forest",
    description: "A dense forest with tall trees.",
    in: world
)

// Create an item
Object.item(
    id: "key",
    name: "small key",
    description: "A small brass key.",
    location: "cabin",  // ID of the cabin object
    flags: [.takeable],
    synonyms: ["brass key"],
    in: world
)

// Create a container (chest)
Object.container(
    id: "chest",
    name: "wooden chest",
    description: "A sturdy wooden chest.",
    location: "cabin",
    flags: [.openable, .lockable], // Chest can be opened and locked
    isOpen: false,
    isLocked: true, // Starts locked
    keyID: "key", // ID of the key that unlocks it
    capacity: 20, // How much it can hold
    in: world
)

// Create a surface (table)
Object.surface(
    id: "table",
    name: "wooden table",
    description: "A simple wooden table.",
    location: "cabin",
    flags: [.supporter], // Indicates things can be put on it
    capacity: 5,
    in: world
)
```

## Connecting Rooms

Use the `world.connect(...)` method _after_ both room objects have been added to the world:

```swift
// Assuming cabin and forest objects exist in the world
world.connect(
    from: "cabin",
    direction: .east,
    to: "forest",
    bidirectional: true // Creates east exit in cabin, west exit in forest
)

// One-way exit
world.connect(from: "forest", direction: .south, to: "clearing")
```

## Conventions

Gnusto promotes clean, readable, and type-safe Swift code.

### Object.ID Literal Usage

`Object.ID` conforms to `ExpressibleByStringLiteral` and automatically normalizes input. Use string literals for IDs:

```swift
// Preferred
Object.item(id: "lantern", ..., in: world)
world.move("lantern", to: "player") // Assuming player ID is "player"

// Avoid
let lanternID = Object.ID("lantern")
Object.item(id: lanternID, ...)
world.move(lanternID, to: Object.ID("player"))
```

### Command Handlers

Located in `Sources/Gnusto/Services/CommandHandlers`. Designed to be potentially overridden or extended by specific games if needed, though registering custom actions via `modifyDispatcher` is often preferred.

### Other Style Conventions

- Use Swift's type inference judiciously.
- Prefer trailing closure syntax.
- Utilize modern Swift features (property wrappers, result builders if applicable) where they enhance clarity.
- Follow the API design patterns established within the Gnusto library (e.g., using static builders for object creation).

## Next Steps / Roadmap

- **Persistence:** Implement saving and loading game state (`SaveHandler`, `RestoreHandler`).
- **Parser Integration:** Fully replace internal parsing logic with the `Nitfol` library.
- **NPCs & Dialogue:** Add support for non-player characters, basic dialogue trees, and interaction commands (`TalkToHandler`, `GiveHandler`).
- **Rules Engine:** Implement a more sophisticated system for conditional game logic (e.g., "IF player has X AND Y is true THEN Z happens"). Consider `StateComponent` or dedicated rule components.
- **Combat System:** (Optional) Add basic combat mechanics if desired.
- **Advanced Container Logic:** Refine interactions with surfaces, wearables, complex containers.
- **Renderer Features:** Enhance renderers (e.g., console renderer with color, status bar updates, graphical renderer).
- **Testing:** Increase test coverage across all components and handlers.

## Implementation Path

_Items moved to Roadmap or completed_

## ZIL-compatible `TAKE` Implementation Gap

_This section remains relevant as a design consideration._

To implement a complete ZIL-compatible take system, we would need:

1.  Enhanced Object Hierarchy & Relationships: Ability to traverse the containment tree easily (find common parents, check direct containment).
2.  Expanded Component System & Flags: `touchbit`, `wornbit`, capacity/weight system, better container/surface/wearable distinction.
3.  Blocking Mechanism: Logic to determine if taking object A is blocked by object B (e.g., B is closed container holding A, B is a person holding A).
4.  Contextual Messaging: Generate messages based on _why_ a take failed (e.g., "You can't reach it.", "It's inside the closed chest.", "The troll is holding it!").
5.  Automatic Actions: Handling things like automatically trying to open a closed container when taking something from it, or auto-wearing clothes.

Room Hooks (if implemented via `RoomComponent` or similar) could supplement this by allowing location-specific overrides.

## License

MIT License
