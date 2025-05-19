# ``GnustoEngine``

## A Modern Interactive Fiction Engine

![Gnusto Interactive Fiction Engine](gnusto-heading.png)

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

#### Locations: Crafting Your Spaces

A ``Location`` represents a distinct place or room that the player can visit. You define
a location with a unique ID, a name, a textual description that sets the scene for the
player, and exits that connect it to other locations.

Here's how you might define a simple cloakroom:

```swift
import GnustoEngine

struct OperaHouse: AreaBlueprint {
    let cloakroom = Location(
        id: .cloakroom,
        .name("Cloakroom"),
        .description("""
            The walls of this small room were clearly once lined with hooks,
            though now only one remains. The exit is a door to the east.
            """),
        .exits([
            .east: Exit(destination: "foyer"),
        ]),
        .inherentlyLit
    )
}
```

In this example:

- ``id``: Each location needs a unique ``LocationID`` (here, ``"cloakroom"``).
- ``.name``: This is often used as the heading when describing the location.
- ``.description``: The text paints a picture of the location for the player.
- ``.exits``: A dictionary mapping a ``Direction`` to an ``Exit``, defining how the player
  can move between locations. The ``Exit`` specifies the ``destination`` ``LocationID``.
  - ``.isInherentlyLit``: This ``LocationAttribute`` indicates the room is lit
  by default, without needing a light source.

#### Items: Populating Your World

An ``Item`` is any object, character, or other entity that the player can interact with.
Like locations, items have an ID, a name, a description, and various attributes that
define their behavior and state.

Let's add a cloak for the player, and a brass hook to the cloakroom to hang it on:

```swift
import GnustoEngine

struct OperaHouse: AreaBlueprint {
    // ...

    let hook = Item(
        id: .hook,
        .adjectives("small", "brass"),
        .in(.location(.cloakroom)),
        .isScenery,
        .isSurface,
        .name("small brass hook"),
        .synonyms("peg"),
    )

    let cloak = Item(
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

Player commands (like "take cloak" or "go north") are processed by Gnusto's ``Parser``,
which translates them into structured ``Command`` objects. These commands are then handled
by the appropriate ``ActionHandler``.

While Gnusto provides default handlers for common actions (``TakeActionHandler``,
``GoActionHandler``, etc.), you can customize behavior by providing your own handlers
or by attaching event handlers directly to items or locations.

For example, examining the `hook` might give a dynamic description depending on whether
the `cloak` is on it. This logic could be placed in an ``ItemEventHandler`` associated
with the hook.

### The GameEngine and GameState

The ``GameEngine`` is the central orchestrator of your game. It manages the main game loop,
processes player input, updates the ``GameState``, and interacts with the ``IOHandler``
to communicate with the player.

The ``GameState`` is the single source of truth for everything dynamic in your game world:
the player's current location, the properties and locations of all items, active timers,
game flags, and more. As a game developer, you'll interact with the ``GameState`` via methods
provided by the ``GameEngine``.

## Getting Started

Creating a game with Gnusto generally follows these steps:

1.  **Design Your World:** Sketch out your map, puzzles, items, and story.
2.  **Define Core Entities:** Create your ``Location``s and ``Item``s using their respective initializers and attributes, often grouped within an ``AreaBlueprint``.
3.  **Implement Custom Logic:** Add ``ItemEventHandler``s, ``LocationEventHandler``s, or custom ``ActionHandler``s for unique interactions and puzzle mechanics.
4.  **Set up a ``GameBlueprint``:** This brings together your areas, vocabulary, and initial game settings.
5.  **Initialize and Run:** Create a ``GameEngine`` instance with your ``GameBlueprint`` and an ``IOHandler`` (like ``ConsoleIOHandler``), then start the game loop.

## Key Features

Gnusto is built with game creators in mind, offering features that simplify development:

- **Dynamic Content:** Create living worlds with state-driven descriptions and behaviors using ``ItemEventHandler``s and ``LocationEventHandler``s.
- **Rich Action System:** A flexible pipeline processes player commands, allowing for complex interactions and easy customization of game verbs.
- **Smart ``Parser``:** Gnusto's parser understands natural language, supporting synonyms, adjectives, and complex sentence structures.
- **Comprehensive ``GameState`` management:** Easily track and modify game progress, item states, player attributes, and timed events (``FuseDefinition``s and ``DaemonDefinition``s).
- **Extensible Architecture:** The engine is designed for modularity. Add custom behaviors, new actions, or even entirely new systems without fighting the core framework.

## Where to Go Next

- Explore the _Cloak of Darkness_ example game (`Executables/CloakOfDarkness`) for a playable demonstration of Gnusto's capabilities.
- Dive deeper into specific components like ``Item``, ``Location``, ``GameEngine``, and the various ``ActionHandler``s by exploring their detailed documentation.
- Consult the rest of the documentation for more information on project structure and engine-level concepts.

Happy creating!
