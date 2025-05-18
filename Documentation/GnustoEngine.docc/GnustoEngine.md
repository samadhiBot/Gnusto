# `GnustoEngine`

## A Modern Interactive Fiction Engine

Welcome to the Gnusto Interactive Fiction Engine! Gnusto is a powerful and flexible Swift-based
framework designed to help you create rich, dynamic text adventure games. Inspired by the
classic Infocom masterpieces, Gnusto provides a modern toolkit that simplifies the development
of interactive narratives, allowing you to focus on storytelling and world-building.

Whether you're a seasoned interactive fiction author or new to the genre, Gnusto offers an
approachable yet robust platform for bringing your interactive stories to life.

## Core Concepts for Game Creators

At its heart, creating a game with Gnusto involves defining your game world, its inhabitants,
and the rules that govern their interactions.

### Defining Your World: Locations and Items

The foundation of your game is built from `Location`s and `Item`s.

#### `Location`s: Crafting Your Spaces

A `Location` represents a distinct place or room that the player can visit. You define
a location with a unique ID, a name, a textual description that sets the scene for the
player, and exits that connect it to other locations.

Here's how you might define a simple cloakroom:

```swift
import GnustoEngine

// In your game's AreaBlueprint (e.g., OperaHouse.swift)
let cloakroom = Location(
    id: "cloakroom", // A unique identifier for this location
    .name("Cloakroom"), // The name displayed to the player
    .description(\"\"\"
        The walls of this small room were clearly once lined with hooks,
        though now only one remains. The exit is a door to the east.
        \"\"\"), // What the player sees when they enter or look around
    .exits([
        .east: Exit(destination: "foyer") // Defines an exit to the east leading to "foyer"
    ]),
    .setFlag(.isInherentlyLit) // This location is always lit
)
```

In this example:

- `id`: Each location needs a unique `LocationID` (here, `"cloakroom"`).
- `.name`: This is often used as the heading when describing the location.
- `.description`: The text paints a picture of the location for the player.
- `.exits`: A dictionary mapping a `Direction` to an `Exit`, defining how the player
  can move between locations. The `Exit` specifies the `destination` `LocationID`.
- `.setFlag(.isInherentlyLit)`: This `LocationAttribute` indicates the room is lit
  by default, without needing a light source.

#### `Item`s: Populating Your World

`Item`s are the objects, characters, or other entities the player can interact with.
Like locations, items have an ID, a name, a description, and various attributes that
define their behavior and state.

Let's add a hook to our cloakroom and a cloak for the player:

```swift
// Continuing in your AreaBlueprint

let hook = Item(
    id: "hook", // Unique ItemID
    .name("small brass hook"),
    .adjectives("small", "brass"), // Words the parser can use to identify the hook
    .synonyms("peg"),              // Alternative nouns for the hook
    .in(.location("cloakroom")),   // The hook starts in the "cloakroom"
    .setFlag(.isScenery)           // Indicates it's part of the background, likely not takable
)

let cloak = Item(
    id: "cloak",
    .name("velvet cloak"),
    .description("A handsome velvet cloak, of exquisite quality."),
    .adjectives("handsome", "dark", "black", "velvet"),
    .in(.player), // The cloak starts in the player's possession
    .setFlag(.isTakable),
    .setFlag(.isWearable)
    // .setFlag(.isWorn) // If the player starts wearing it
)
```

Key `ItemAttribute`s here include:

- `.name`, `.description`, `.adjectives`, `.synonyms`: Help describe the item and how
  the player can refer to it.
- `.in()`: Specifies the item's initial `ParentEntity`, which can be a `LocationID`
  or special entities like `.player`.
- `.setFlag()`: Used to apply boolean properties like `.isTakable` (can the player pick
  it up?), `.isWearable` (can the player wear it?), or `.isScenery` (is it just part
  of the background?).

### Making it Interactive: Actions and Responses

Player commands (like "take cloak" or "go north") are processed by Gnusto's `Parser`,
which translates them into structured `Command` objects. These commands are then handled
by `ActionHandler`s.

While Gnusto provides default handlers for common actions (`TakeActionHandler`,
`GoActionHandler`, etc.), you can customize behavior by providing your own handlers
or by attaching event handlers directly to items or locations.

For example, examining the `hook` might give a dynamic description depending on whether
the `cloak` is on it. This logic could be placed in an `ItemEventHandler` associated
with the hook.

### The `GameEngine` and `GameState`

The `GameEngine` is the central orchestrator of your game. It manages the main game loop,
processes player input, updates the `GameState`, and interacts with the `IOHandler`
to communicate with the player.

The `GameState` is the single source of truth for everything dynamic in your game world:
the player's current location, the properties and locations of all items, active timers,
game flags, and more. As a game developer, you'll primarily interact with the `GameState`
indirectly through methods provided by the `GameEngine`.

## Getting Started

Creating a game with Gnusto generally follows these steps:

1.  **Design Your World:** Sketch out your map, puzzles, items, and story.
2.  **Define Core Entities:** Create your `Location`s and `Item`s using their
    respective initializers and attributes, often grouped within an `AreaBlueprint`.
3.  **Implement Custom Logic:** Add `ItemEventHandler`s, `LocationEventHandler`s,
    or custom `ActionHandler`s for unique interactions and puzzle mechanics.
4.  **Set up a `GameBlueprint`:** This brings together your areas, vocabulary,
    and initial game settings.
5.  **Initialize and Run:** Create a `GameEngine` instance with your `GameBlueprint`
    and an `IOHandler` (like `ConsoleIOHandler`), then start the game loop.

## Key Features

Gnusto is built with game creators in mind, offering features that simplify development:

- **Dynamic Content:** Create living worlds with state-driven descriptions and behaviors using
  `DescriptionHandler`s and event handlers.
- **Rich Action System:** A flexible pipeline processes player commands, allowing for
  complex interactions and easy customization of game verbs.
- **Smart `Parser`:** Gnusto's parser understands natural language, supporting synonyms,
  adjectives, and complex sentence structures.
- **Comprehensive `StateManagement`:** Easily track and modify game progress, item states,
  player attributes, and timed events (`Fuse`s and `Daemon`s).
- **Extensible Architecture:** The engine is designed for modularity. Add custom behaviors,
  new actions, or even entirely new systems without fighting the core framework.

## Where to Go Next

- Explore the **Cloak of Darkness** example game (`Executables/CloakOfDarkness`) for a
  complete, playable demonstration of Gnusto's capabilities.
- Dive deeper into specific components like `Item`, `Location`, `GameEngine`, and
  the various `ActionHandler`s by exploring their detailed documentation.
- Consult the `README.md` for more information on project structure and engine-level concepts.

Happy creating!

## Topics

### Group

- `Symbol`
