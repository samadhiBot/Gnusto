# ``GnustoEngine``

## A Modern Interactive Fiction Engine

![Gnusto Interactive Fiction Engine](gnusto-heading.png)

Welcome to Gnusto! This Swift-based framework helps you create rich text adventure games inspired by the classics like Zork and Hitchhiker's Guide to the Galaxy. Whether you're new to interactive fiction or a seasoned author, Gnusto provides a modern toolkit that lets you focus on storytelling rather than engine mechanics.

## Building Your First Game

Creating a game with Gnusto begins with two main concepts: ``Location`` and ``Item``.

### Location: Places in Your World

A ``Location`` represents any place the player can visit—a room, forest clearing, or spaceship bridge. Here's a simple example:

```swift
let cloakroom = Location(
    id: .cloakroom,
    .name("Cloakroom"),
    .description("""
        The walls of this small room were clearly once lined with hooks,
        though now only one remains. The exit is a door to the east.
        """
    ),
    .exits(.east(.foyer)),
    .inherentlyLit
)
```

### Item: Objects and Characters

An ``Item`` can be anything the player interacts with—objects, characters, even abstract concepts:

```swift
let cloak = Item(
    id: .cloak,
    .name("velvet cloak"),
    .description("""
        A handsome cloak, of velvet trimmed with satin, and slightly
        spattered with raindrops.
        """
    ),
    .adjectives("handsome", "dark", "black", "velvet"),
    .isTakable,
    .isWearable,
    .in(.player)
)
```

The GnustoAutoWiringPlugin automatically handles ID generation and wiring, so you can focus on creating content.

## Key Features

- **Automatic Setup**: The plugin eliminates boilerplate code and wiring
- **Cross-Platform**: Deploy on Mac, iOS, Linux, Windows, and Android
- **Rich Interactions**: 80+ built-in action handlers for commands like "take," "examine," "attack"
- **Dynamic Content**: Use event handlers to create living, responsive worlds
- **Advanced Systems**: Built-in combat, character sheets, conversations, and timed events
- **Natural Language**: Smart parser understands synonyms, adjectives, and complex commands
- **Extensible**: Add custom behaviors without fighting the engine

## Getting Started

1. **Add Gnusto to your project** and include the `GnustoAutoWiringPlugin`
2. **Organize your content** into logical groups (like `OperaHouse`, `Forest`, etc.)
3. **Define your world** with ``Location`` and ``Item`` objects
4. **Add custom behavior** using ``ItemEventHandler`` and ``LocationEventHandler`` as needed
5. **Create a GameBlueprint** to bring everything together
6. **Run your game** with ``GameEngine``

## Learning by Example

The best way to understand Gnusto is through working examples:

- **[Cloak of Darkness](../../Executables/CloakOfDarkness/)**: A complete, simple game showcasing core concepts
- **[Zork 1](../../Executables/Zork1/)**: A comprehensive recreation with combat, characters, and complex interactions

Start with _Cloak of Darkness_ to see how things fit together, then explore _Zork 1_ for advanced patterns.

## Topics

### Essential Guides
- <doc:DynamicProperties>
- <doc:GnustoAutoWiringPlugin>
- <doc:ActionHandlerGuide>

### Core Types
- ``GameEngine``
- ``GameBlueprint``
- ``Location``
- ``Item``
- ``ActionHandler``

### Advanced Systems
- ``ItemEventHandler``
- ``LocationEventHandler``
- ``Parser``
- ``Messenger``

Ready to start building? Check out the [Cloak of Darkness](../../Executables/CloakOfDarkness/) source code to see these concepts in action!
