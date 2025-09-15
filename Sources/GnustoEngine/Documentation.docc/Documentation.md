# ``GnustoEngine``

## A Modern Interactive Fiction Engine

![Gnusto Interactive Fiction Engine](gnusto-heading.png)

Welcome to the Gnusto Interactive Fiction Engine! Gnusto is a powerful and flexible Swift-based framework designed to help you create rich, dynamic text adventure games. Inspired by the classic Infocom masterpieces, Gnusto provides a modern toolkit that simplifies the development of interactive narratives, allowing you to focus on storytelling and world-building.

Whether you're a seasoned interactive fiction author or new to the genre, Gnusto offers an approachable yet robust platform for bringing your interactive stories to life.

## Core Concepts for Game Creators

At its heart, creating a game with Gnusto involves defining your game world, its inhabitants, and the rules that govern their interactions.

### Defining Your World: Locations and Items

The foundation of your game is built from ``Location``s and ``Item``s.

### Locations: Crafting Your Spaces

A ``Location`` represents a distinct place or room that the player can visit. You define a location with a unique ID, a name, a textual description that sets the scene for the player, and exits that connect it to other locations. The engine's proxy system provides access to both static properties (defined at creation) and dynamic computed properties (calculated at runtime).

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
            """
        ),
        .exits(
            .east(.foyer)
        ),
        .inherentlyLit
    )
}
```

In this example:

- ``Location/id``: Each location needs a unique ``LocationID`` (here, `"cloakroom"`).
- ``LocationProperty/name(_:)``: This is often used as the heading when describing the location.
- ``LocationProperty/description(_:)``: The text paints a picture of the location for the player.
- ``LocationProperty/exits(_:)``: A dictionary mapping a ``Direction`` to an ``Exit``, defining how the player can move between locations. The ``Exit`` specifies the ``Exit/destinationID`` ``LocationID``.
- ``LocationProperty/inherentlyLit``: This ``LocationProperty`` indicates the room is lit by default, without needing a light source.

#### Items: Populating Your World

An ``Item`` is any object, character, or other entity that the player can interact with. Like locations, items have an ID, a name, a description, and various properties that define their behavior and state. Items can represent simple objects, complex devices, NPCs with character sheets, or even abstract concepts through the proxy system.

Let's add a cloak that the player is wearing, and a brass hook in the cloakroom to hang it on:

```swift
import GnustoEngine

extension OperaHouse {
    static let hook = Item(
        id: .hook,
        .adjectives("small", "brass"),
        .in(.cloakroom),
        .omitDescription,
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
            """
        ),
        .adjectives("handsome", "dark", "black", "velvet", "satin"),
        .in(.player),
        .isTakable,
        .isWearable,
        .isWorn,
    )
}
```

Key ``ItemProperty``s here include:

- ``ItemProperty/name(_:)``, ``ItemProperty/description(_:)``, ``ItemProperty/adjectives(_:)``, ``ItemProperty/synonyms(_:)``: Help describe the item and how the player can refer to it.
- ``ItemProperty/in(_:)``: Specifies the item's initial ``ParentEntity``, which can be a location, a container item, or the player.
- Flags are boolean properties like ``ItemProperty/isTakable`` (can the player pick it up?), ``ItemProperty/isWearable`` (can the player wear it?), or ``ItemProperty/omitDescription`` (is it just part of the background?).

### Making it Interactive: Actions and Responses

Player commands (like "take cloak", "attack troll", or "ask wizard about magic") are processed by Gnusto's ``Parser``, which translates them into structured ``Command`` objects. These commands are then handled by the appropriate ``ActionHandler``.

Gnusto provides 80+ built-in action handlers covering everything from basic movement and object manipulation to complex combat, conversation, and puzzle-solving interactions. You can customize behavior by providing your own handlers or by attaching event handlers directly to items or locations.

For example, examining the `hook` might give a dynamic description depending on whether the `cloak` is on it. This logic could be placed in an ``ItemEventHandler`` associated with the hook, or handled through the proxy system's computed properties for more complex scenarios involving combat state, character interactions, or environmental conditions.

### The GameEngine and GameState

The ``GameEngine`` is the central orchestrator of your game. It manages the main game loop, processes player input, updates the ``GameState``, handles combat and character systems, manages conversations, and interacts with the ``IOHandler`` to communicate with the player through the centralized ``Messenger`` system.

The ``GameState`` is the single source of truth for everything dynamic in your game world: the player's current location, the properties and locations of all items, character sheets and combat states, active conversations, timers, game flags, and more. As a game developer, you'll interact with the `GameState` safely through the proxy system and methods provided by the ``GameEngine``.

## Getting Started

Creating a game with Gnusto generally follows these steps:

1.  **Design Your World:** Sketch out your map, puzzles, items, and story.
2.  **Define Core Entities:** Create your ``Location``s and ``Item``s using their respective initializers and properties, often organized into logical area groups (enums or structs).
3.  **Implement Custom Logic:** Add ``ItemEventHandler``s, ``LocationEventHandler``s, or custom ``ActionHandler``s for unique interactions and puzzle mechanics.
4.  **Set up a `GameBlueprint`:** This brings together your areas, vocabulary, and initial game settings.
5.  **Initialize and Run:** Create a ``GameEngine`` instance with your ``GameBlueprint`` and an ``IOHandler`` (like ``ConsoleIOHandler``), then start the game loop.

## Key Features

Gnusto is built with game creators in mind, offering features that simplify development:

- **Automatic Boilerplate Generation:** The GnustoAutoWiringPlugin eliminates the need to manually create ID constants and wire up game components.
- **Proxy-Based State Management:** Safe, concurrent access to game state with automatic computation of dynamic properties and validation of state changes.
- **Dynamic Content:** Create living worlds with state-driven descriptions and behaviors using ``ItemEventHandler``s, ``LocationEventHandler``s, and computed properties.
- **Rich Action System:** 80+ built-in action handlers covering everything from basic interactions to complex combat, conversations, and puzzle mechanics.
- **Combat & Character Systems:** Full RPG-style combat with character sheets, health/consciousness tracking, combat states, and automated combat resolution.
- **Conversation System:** Rich dialogue mechanics with NPCs, topic tracking, and dynamic conversation flow.
- **Smart `Parser`:** Gnusto's parser understands natural language, supporting synonyms, adjectives, complex sentence structures, and conversational contexts.
- **Localization Ready:** Centralized ``Messenger`` system enables easy translation and customization of all player-facing text.
- **Comprehensive State Management:** Easily track and modify game progress, character states, combat conditions, conversations, and timed events through the safe proxy system.
- **Extensible Architecture:** The engine is designed for modularity. Add custom behaviors, new actions, or entire new systems without fighting the core framework.

## New Major Systems

### Proxy-Based State Management

Gnusto uses a sophisticated proxy system that provides safe, concurrent access to game state while enabling both static and computed properties. Instead of accessing game objects directly, you work with proxy objects that automatically handle state computation and validation.

```swift
// Access items and locations through proxies
let swordProxy = try await engine.item(.sword)
let roomProxy = try await engine.location(.throneRoom)

// Proxies provide access to both static and computed properties
let damage = await swordProxy.damage  // Could be static or computed
let isLit = await roomProxy.isLit     // Automatically computed based on light sources
let description = await swordProxy.description  // Dynamic based on current state
```

The proxy system ensures that:
- All state access is thread-safe and respects Swift 6 concurrency
- Computed properties are automatically calculated when accessed
- State changes flow through proper validation pipelines
- Both static (compile-time) and dynamic (runtime) properties work seamlessly

### Combat System

Gnusto includes a comprehensive combat system that handles turn-based combat with multiple participants, weapon systems, and complex combat conditions.

```swift
// Characters automatically get combat capabilities
let troll = Item(
    id: .troll,
    .name("nasty troll"),
    .isCharacter,
    .characterSheet(
        health: 25,
        maxHealth: 25,
        attackPower: 8,
        defenseRating: 3
    ),
    .in(.trollBridge)
)

// Combat is initiated through standard action handlers
// "attack troll with sword" -> AttackActionHandler -> CombatSystem
```

The combat system features:
- **Turn-based combat** with initiative ordering
- **Weapon and armor systems** with different damage types
- **Combat conditions** (bleeding, stunned, weakened, etc.)
- **Automatic combat resolution** with detailed narration
- **Integration with character consciousness** and health systems
- **Flexible weapon definitions** supporting various combat scenarios

### Character System

Characters in Gnusto are represented by comprehensive character sheets that track health, consciousness, combat abilities, and other vital statistics.

```swift
// Characters have detailed stat tracking
let wizard = Item(
    id: .wizard,
    .name("ancient wizard"),
    .isCharacter,
    .characterSheet(
        health: 15,
        maxHealth: 15,
        consciousnessLevel: .awake,
        classification: .friendly,
        attackPower: 5,
        defenseRating: 7
    )
)
```

Character features include:
- **Health and consciousness tracking** (awake, unconscious, dying, dead)
- **Character classifications** (friendly, neutral, hostile, ally)
- **Combat statistics** (attack power, defense, armor class)
- **Condition management** (poisoned, blessed, cursed, etc.)
- **Dynamic state computation** through the proxy system
- **Integration with conversation and combat systems**

### Conversation System

Rich dialogue mechanics enable complex interactions with NPCs, supporting topic-based conversations, dynamic responses, and conversational context tracking.

```swift
// NPCs can engage in detailed conversations
// "ask wizard about magic" -> AskActionHandler -> ConversationSystem
// "tell guard about treasure" -> TellActionHandler -> ConversationSystem

// Conversations can branch based on game state, character relationships, and previous interactions
```

The conversation system provides:
- **Topic-based dialogue** with dynamic topic discovery
- **Context-aware responses** based on game state and character relationships
- **Multi-turn conversations** with conversation state tracking
- **Integration with quest and story systems**
- **Flexible response patterns** supporting both scripted and procedural dialogue

### Messenger System

The centralized Messenger system handles all player-facing text, enabling easy localization and consistent tone across your entire game.

```swift
// All player messages go through the messenger
return ActionResult(
    engine.messenger.taken(),  // "Taken."
    await engine.setFlag(.isTouched, on: item)
)

// Custom games can override messages for their specific tone
class MyGameMessenger: MessageProvider {
    override func taken() -> String {
        output("You've successfully acquired the item!")
    }
}
```

Messenger benefits:
- **Centralized text management** for all player-facing messages
- **Easy localization** - translate in one place, works everywhere
- **Consistent tone** across all game interactions
- **Customizable messaging** - override defaults to match your game's style
- **Rich message formatting** with automatic article handling ("a sword" vs "the sword")

## Automatic ID Generation and Game Setup

**The GnustoAutoWiringPlugin eliminates boilerplate!** One of Gnusto's most powerful features is the included build tool plugin that automatically discovers your game patterns and generates all the necessary ID constants and game setup code for you.

### What the Plugin Does for You

When you include the GnustoAutoWiringPlugin in your game project, it automatically:

- **Generates ID Extensions**: Scans patterns like `Location(id: .foyer, ...)` and creates `static let foyer = LocationID("foyer")`
- **Discovers Event Handlers**: Finds your ``ItemEventHandler`` and ``LocationEventHandler`` definitions and wires them up automatically
- **Sets Up Time Registry**: Discovers ``Fuse`` and ``Daemon`` instances and registers them
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

The choice is yours--use the plugin for convenience, or go manual for complete control.

## Where to Go Next

- Explore the _Cloak of Darkness_ example game (`Executables/CloakOfDarkness`) for a playable demonstration of Gnusto's capabilities.
- Study the _Zork 1_ implementation (`Executables/Zork1`) for a comprehensive example of combat, characters, and complex world interactions.
- Dive deeper into specific components like ``Item``, ``Location``, ``GameEngine``, ``ActionHandler``s, and the new systems by exploring their detailed documentation.
- Check out the [Action Handler Development Guide](ActionHandlerGuide) for creating custom interactions.
- See [Dynamic Properties](DynamicAttributes) for advanced state management patterns.
- Consult the rest of the documentation for more information on project structure and engine-level concepts.

Happy creating!
