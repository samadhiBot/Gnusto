# ``GnustoEngine``

## A Modern Interactive Fiction Engine

![Gnusto Interactive Fiction Engine](gnusto-heading.png)

Welcome to the Gnusto Interactive Fiction Engine! Gnusto is a powerful and flexible Swift-based framework designed to help you create rich, dynamic text adventure games. Inspired by the classic Infocom masterpieces, Gnusto provides a modern toolkit that simplifies the development of interactive narratives, allowing you to focus on storytelling and world-building.

Whether you're a seasoned interactive fiction author or new to the genre, Gnusto offers an approachable yet robust platform for bringing your interactive stories to life.

## Core Concepts for Game Creators

At its heart, creating a game with Gnusto involves defining your game world, its inhabitants, and the rules that govern their interactions.

### Defining Your World: Locations and Items

The foundation of your game is built from ``Location``s and ``Item``s.

#### Locations: Crafting Your Spaces

A ``Location`` represents a distinct place or room that the player can visit. You define a location with a unique ID, a name, a textual description that sets the scene for the player, and exits that connect it to other locations.

Here's a simple definition for a cloakroom:

```swift
import GnustoEngine

enum OperaHouse {
    static let cloakroom = Location(
        id: .cloakroom,
        .name("Cloakroom"),
        .description("""
            The walls of this small room were clearly once lined with hooks,
            though now only one remains. The exit is a door to the east.
            """),
        .exits([
            .east: .to(.foyer),
        ]),
        .inherentlyLit
    )
}
```

In this example:

- ``Location/id``: Each location needs a unique ``LocationID`` (here, `"cloakroom"`).
- ``LocationAttribute/name(_:)``: This is often used as the heading when describing the location.
- ``LocationAttribute/description(_:)``: The text paints a picture of the location for the player.
- ``LocationAttribute/exits(_:)``: A dictionary mapping a ``Direction`` to an ``Exit``, defining how the player can move between locations. The ``Exit`` specifies the ``Exit/destinationID`` ``LocationID``.
- ``LocationAttribute/inherentlyLit``: This ``LocationAttribute`` indicates the room is lit by default, without needing a light source.

#### Items: Populating Your World

An ``Item`` is any object, character, or other entity that the player can interact with. Like locations, items have an ID, a name, a description, and various attributes that define their behavior and state.

Let's add a cloak that the player is wearing, and a brass hook in the cloakroom to hang it on:

```swift
import GnustoEngine

extension OperaHouse {
    static let hook = Item(
        id: .hook,
        .adjectives("small", "brass"),
        .in(.location(.cloakroom)),
        .isScenery,
        .isSurface,
        .name("small brass hook"),
        .synonyms("peg"),
    )

    static let cloak = Item(
        id: .cloak,
        .name("velvet cloak"),
        .description("""
            A handsome cloak, of velvet trimmed with satin, and slightly
            spattered with raindrops. Its blackness is so deep that it
            almost seems to suck light from the room.
            """),
        .adjectives("handsome", "dark", "black", "velvet", "satin"),
        .in(.player),
        .isTakable,
        .isWearable,
        .isWorn,
    )
}
```

Key ``ItemAttribute``s here include:

- ``ItemAttribute/name(_:)``, ``ItemAttribute/description(_:)``, ``ItemAttribute/adjectives(_:)``, ``ItemAttribute/synonyms(_:)``: Help describe the item and how the player can refer to it.
- ``ItemAttribute/in(_:)``: Specifies the item's initial ``ParentEntity``, which can be a location, a container item, or the player.
- Flags are boolean properties like ``ItemAttribute/isTakable`` (can the player pick it up?), ``ItemAttribute/isWearable`` (can the player wear it?), or ``ItemAttribute/isScenery`` (is it just part of the background?).

### Making it Interactive: Actions and Responses

Player commands (like "take cloak" or "go north") are processed by Gnusto's ``Parser``, which translates them into structured ``Command`` objects. These commands are then handled by the appropriate ``ActionHandler``.

While Gnusto provides default handlers for common actions (``TakeActionHandler``, ``GoActionHandler``, etc.), you can customize behavior by providing your own handlers or by attaching event handlers directly to items or locations.

For example, examining the `hook` might give a dynamic description depending on whether the `cloak` is on it. This logic could be placed in an ``ItemEventHandler`` associated with the hook.

### The GameEngine and GameState

The ``GameEngine`` is the central orchestrator of your game. It manages the main game loop, processes player input, updates the ``GameState``, and interacts with the ``IOHandler`` to communicate with the player.

The ``GameState`` is the single source of truth for everything dynamic in your game world: the player's current location, the properties and locations of all items, active timers, game flags, and more. As a game developer, you'll interact with the `GameState` via methods provided by the ``GameEngine``.

## Getting Started

Creating a game with Gnusto generally follows these steps:

1.  **Design Your World:** Sketch out your map, puzzles, items, and story.
2.  **Define Core Entities:** Create your ``Location``s and ``Item``s using their respective initializers and attributes, often organized into logical area groups (enums or structs).
3.  **Implement Custom Logic:** Add ``ItemEventHandler``s, ``LocationEventHandler``s, or custom ``ActionHandler``s for unique interactions and puzzle mechanics.
4.  **Set up a `GameBlueprint`:** This brings together your areas, vocabulary, and initial game settings.
5.  **Initialize and Run:** Create a ``GameEngine`` instance with your ``GameBlueprint`` and an ``IOHandler`` (like ``ConsoleIOHandler``), then start the game loop.

## Key Features

Gnusto is built with game creators in mind, offering features that simplify development:

- **Automatic Boilerplate Generation:** The GnustoAutoWiringPlugin eliminates the need to manually create ID constants and wire up game components.
- **Dynamic Content:** Create living worlds with state-driven descriptions and behaviors using ``ItemEventHandler``s and ``LocationEventHandler``s.
- **Rich Action System:** A flexible pipeline processes player commands, allowing for complex interactions and easy customization of game verbs.
- **Smart `Parser`:** Gnusto's parser understands natural language, supporting synonyms, adjectives, and complex sentence structures.
- **Comprehensive `GameState` management:** Easily track and modify game progress, item states, player attributes, and timed events (``FuseDefinition``s and ``DaemonDefinition``s).
- **Extensible Architecture:** The engine is designed for modularity. Add custom behaviors, new actions, or even entirely new systems without fighting the core framework.

## Automatic ID Generation and Game Setup

**The GnustoAutoWiringPlugin eliminates boilerplate!** One of Gnusto's most powerful features is the included build tool plugin that automatically discovers your game patterns and generates all the necessary ID constants and game setup code for you.

### What the Plugin Does for You

When you include the GnustoAutoWiringPlugin in your game project, it automatically:

- **Generates ID Extensions**: Scans patterns like `Location(id: .foyer, ...)` and creates `static let foyer = LocationID("foyer")`
- **Discovers Event Handlers**: Finds your ``ItemEventHandler`` and ``LocationEventHandler`` definitions and wires them up automatically
- **Sets Up Time Registry**: Discovers ``FuseDefinition`` and ``DaemonDefinition`` instances and registers them
- **Aggregates Game Content**: Collects all your items and locations from multiple area files and provides them to your `GameBlueprint`
- **Handles Custom Actions**: Discovers custom ``ActionHandler`` implementations and integrates them

This means you can focus on writing your game content without worrying about the connection logic!

### Including the Plugin in Your Game

To use the GnustoAutoWiringPlugin in your own game project, add it to your `Package.swift`:

```swift
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "MyGame",
    dependencies: [
        .package(url: "https://github.com/samadhiBot/Gnusto", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "MyGame",
            dependencies: ["GnustoEngine"],
            plugins: ["GnustoAutoWiringPlugin"]  // ← Add this line
        ),
    ]
)
```

That's it! The plugin will automatically scan your Swift files during build and generate all the necessary boilerplate code.

### Manual Setup Alternative

If you prefer complete control or want to understand what's happening under the hood, you can skip the plugin and handle ID generation and game setup manually. Simply don't include the plugin in your `Package.swift`, and then:

1. **Create your own ID extensions**:

   ```swift
   extension LocationID {
       static let foyer = LocationID("foyer")
       static let cloakroom = LocationID("cloakroom")
       // ... etc
   }
   ```

2. **Manually wire up your GameBlueprint**:
   ```swift
   extension MyGameBlueprint {
       var items: [Item] { [MyArea.cloak, MyArea.hook, /* ... */] }
       var locations: [Location] { [MyArea.foyer, MyArea.cloakroom, /* ... */] }
       var itemEventHandlers: [ItemID: ItemEventHandler] {
           [.cloak: MyArea.cloakHandler, /* ... */]
       }
       // ... etc
   }
   ```

The choice is yours—use the plugin for convenience, or go manual for complete control!

## Where to Go Next

- Explore the _Cloak of Darkness_ example game (`Executables/CloakOfDarkness`) for a playable demonstration of Gnusto's capabilities.
- Dive deeper into specific components like ``Item``, ``Location``, ``GameEngine``, and the various ``ActionHandler``s by exploring their detailed documentation.
- Consult the rest of the documentation for more information on project structure and engine-level concepts.

Happy creating!
