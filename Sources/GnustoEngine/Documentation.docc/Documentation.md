# ``GnustoEngine``

## A Modern Interactive Fiction Engine

![Gnusto Interactive Fiction Engine Hero Graphic](gnusto-heading.png)

Gnusto is a [Swift](https://www.swift.org/) framework for writing [interactive fiction](https://en.wikipedia.org/wiki/Interactive_fiction) games. Drawing inspiration from the Infocom classics of the 1980s, it provides a modern toolkit for building old school text adventures. Gnusto handles state management, allowing you to focus on storytelling and world-building.

- Gnusto is written in cross-platform Swift, allowing you to deploy your games on Mac, Linux, Windows, iOS, Android and Web.
- It provides a declarative syntax to define places and things in the game world.
- Gnusto offers type safety, eliminating many potential errors at compile time.
- It's easy to customize and extend to fit your creative vision.
- Gnusto's state change pipeline provides safe state management, avoiding most race conditions and state conflicts.

Gnusto strives to be as intuitive as possible: someone new to Swift should be able to write their first text adventures with Gnusto.

It also strives to be extensible and customizable: someone experienced in Swift and/or interactive fiction writing should have rock solid foundation that doesn't get in their way.

## Getting Started

The following instructions assume that you have Bash and Swift 6.2+ installed on your Mac, Linux or Windows machine. You can check these with the following commands:

```bash
# Verify that Bash is available
bash —version

# Verify that Swift 6.2+ is available
swift -v
```

If you're using Windows, please use [WSL](https://learn.microsoft.com/en-us/windows/wsl/) or [git bash emulation](https://gitforwindows.org/) for bash access, or use the manual setup instructions below.

Swift 6.2 is a requirement, so if you don't have it locally, please follow the installation instructions at [swift.org](https://www.swift.org/install/), and then continue with the steps below.

### Bootstrap

Gnusto's [bootstrap](https://github.com/samadhiBot/Gnusto/blob/main/Scripts/bootstrap) script provides the easiest way to get started. It sets up a new game scaffold on your machine. If you'd rather set up Gnusto by hand, there are manual setup instructions below.

```bash
# Run the bootstrap script from Github:
bash <(curl -sSL https://raw.githubusercontent.com/samadhiBot/Gnusto/refs/heads/main/Scripts/bootstrap)
```

[![asciicast](https://asciinema.org/a/746386.svg)](https://asciinema.org/a/746386)

When the `bootstrap` script is done, it tries to open your new game in [Xcode](https://apps.apple.com/us/app/xcode/id497799835) or [VS Code](https://code.visualstudio.com/download).

Before you continue, please find and open the file called `CustodialSingularity.swift`. This file contains a location, and item, and an event, which are described in the next section.

## Building Your First Game

Gnusto's basic building blocks are locations, items, and events.

### Locations: Places in Your World

A ``Location`` represents any place the player can visit — a room, a forest clearing, a spaceship bridge. Gnusto provides a declarative syntax that starts with a unique identifier, and includes any properties you want to define, in any order you like.

Here's a simple example:

```swift
let westOfHouse = Location(.westOfHouse)
    .name("West of House")
    .description(
        """
        You are standing in an open field west of a white house,
        with a boarded front door.
        """
    )
    .north(.northOfHouse)
    .south(.southOfHouse)
    .east(blocked: "The door is boarded and you can't remove the boards.")
    .inherentlyLit
```

The first line declares the location and its unique identifier: `.westOfHouse`. Note that this strongly-typed identifier doesn't exist until the first time you build the project.

The next lines give it a player-facing name and description, followed by the places you can go from here — or specifically cannot go, in the case of walking east. The final line gives the location light, so you don't need your lantern to see here.

### Items: Objects and Characters

An ``Item`` can be anything the player interacts with — objects, characters, even abstract concepts:

```swift
let cloak = Item(.cloak)
    .name("velvet cloak")
    .description(
        """
        A handsome cloak, of velvet trimmed with satin, and slightly
        spattered with raindrops. Its blackness is so deep that it
        almost seems to suck light from the room.
        """
    )
    .adjectives("handsome", "dark", "black", "velvet", "satin")
    .in(.player)
    .isTakable
    .isWearable
    .isWorn
```

The first line declares the item and its unique identifier: `.cloak`, and the next lines give it a name and description. Next are adjectives used to describe the item, so that the engine will understand commands like `LOOK AT MY HANDSOME BLACK CLOAK`. The next line places the item in the player's possession, and the final lines specify that the item can be taken and worn, and that indeed the player is currently wearing it.

### Events: Responding to Player Commands

``LocationEvent`` and ``ItemEvent`` are event handlers that let you customize how your game responds when the player interacts with specific locations or items. You can intercept actions before they happen, to override default behavior, or after they complete, to add side effects or additional narrative.

The first example watches for interactions that take place in the `.trollRoom`. In this location there is a troll who prevents the player from going through the room's east and west exits. The player must either go back south to the cellar, or find some way to outwit the nasty troll.

```swift
let trollRoomHandler = LocationEventHandler(for: .trollRoom) {
    before(.move) { context, command in
        if let direction = command.direction, [.east, .west].contains(direction) {
            throw ActionResponse.feedback(
                "The troll fends you off with a menacing gesture."
            )
        }
    }
}
```

The next example watches for interactions with the `.cloak` item, and prevents the player from putting it down unless they're standing in the Cloak Room.

```swift
let cloakHandler = ItemEventHandler(for: .cloak) {
    before(.drop, .insert) { context, _ in
        guard await context.player.location == .cloakroom else {
            throw ActionResponse.feedback(
                "This isn't the best place to leave a smart cloak lying around."
            )
        }
    }
}
```

In addition to providing player-facing messages, event handlers can also trigger changes to the state of the game.

## Gnusto's Key Features

- **Declarative Syntax**: Define places and things with fluent, chainable builders
- **Type Safety**: Strongly-typed IDs and Swift 6 strict concurrency prevent common bugs at compile time
- **State Change Pipeline**: All mutations flow through a safe, structured pipeline that eliminates state management bugs
- **Natural Language Parser**: Handles synonyms, adjectives, pronouns, multiple objects, and complex commands like "put the brass lamp in the trophy case"
- **Rich Interactions**: More than 80 built-in action handlers covering everything from "take" and "examine" to "attack" and "tell"
- **Event System**: Intercept and modify behaviors with before/after hooks on items and locations
- **Time-Based Mechanics**: Daemons and fuses enable autonomous behaviors and timed events independent of player actions
- **Combat & RPG Systems**: D&D-style d20 combat with character sheets, attributes, and enemy AI
- **Extensible Architecture**: Add custom action handlers, messengers, property computers, and combat systems without fighting the framework
- **Cross-Platform**: Develop on Mac, Linux or Windows; deploy on Mac, iOS, Linux, Windows, Android and WebAssembly
- **Automatic Setup**: The `GnustoAutoWiringPlugin` discovers your content and generates all ID constants and wiring code
- **Test-Driven**: Built for testability with Swift Testing integration and 80-90% coverage standards


## Manual Setup

To add Gnusto manually to an existing Swift package, follow these steps:

1. **Add Gnusto to your Swift package** and include the `GnustoAutoWiringPlugin`
    ```swift
    // Package.swift
    dependencies: [
        .package(url: "https://github.com/samadhiBot/Gnusto", from: "0.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "MyGame",
            dependencies: ["GnustoEngine"],
            plugins: ["GnustoAutoWiringPlugin"]
        ),
    ]
    ```
2. **Organize your content** into logical groups that make sense to you
    ```
    CloakOfDarkness/                  Zork1/
    ├── CloakOfDarkness.swift         ├── main.swift
    ├── main.swift                    ├── World
    └── OperaHouse.swift              │   ├── Forest.swift
                                      │   ├── OutsideHouse.swift
                                      │   ├── ...
                                      │   ├── Thief.swift
                                      │   ├── Troll.swift
                                      │   └── Underground.swift
                                      ├── Zork1.swift
                                      └── ZorkMessenger.swift
    ```
3. **Define your world** with ``Location`` and ``Item`` objects
    ```swift
    struct OperaHouse {
        let cloakroom = Location(.cloakroom)
            .name("Cloakroom")
            .description(
                """
                The walls of this small room were clearly once lined with hooks,
                though now only one remains. The exit is a door to the east.
                """
            )
            .east(.foyer)
            .inherentlyLit

        let hook = Item(.hook)
            .adjectives("small", "brass")
            .in(.cloakroom)
            .omitDescription
            .isSurface
            .name("small brass hook")
            .synonyms("peg")
    }
    ```
4. **Add dynamic behavior** using ``ItemEventHandler`` and ``LocationEventHandler``, ``Daemon`` and ``Fuse``
    ```swift
    extension Troll {
        static let trollHandler = ItemEventHandler(for: .troll) { when in
            when.before(.tell) { context, command in
                ActionResult("The troll isn't much of a conversationalist.")
            }
        }
    }
    ```
5. **Customize default responses** by overriding standard messaging
    ```swift
    class ZorkMessenger: StandardMessenger {
        override func roomIsDark() -> String {
            output("It is pitch black. You are likely to be eaten by a grue.")
        }
    }
    ```
6. **Create a** ``GameBlueprint`` to bring everything together
    ```swift
    struct CloakOfDarkness: GameBlueprint {
        let title = "Cloak of Darkness"
        let abbreviatedTitle = "Cloak"
        let introduction = """
            A basic IF demonstration.

            Hurrying through the rainswept November night, you're glad to see the
            bright lights of the Opera House. It's surprising that there aren't more
            people about but, hey, what do you expect in a cheap demo game...?
            """
        let release = "0.0.3"
        let maximumScore = 2
        let player = Player(in: .foyer)
    }
    ```
7. **Run your game** with ``GameEngine``
    ```swift
    import GnustoEngine

    let engine = await GameEngine(
        blueprint: CloakOfDarkness(),
        parser: StandardParser(),
        ioHandler: ConsoleIOHandler()
    )

    await engine.run()
    ```

## Learning by Example

The quickest way to understand Gnusto is by looking at working examples:

- [Cloak of Darkness](https://github.com/samadhiBot/Gnusto/tree/main/Executables/CloakOfDarkness)
    A minimalist interactive fiction game created by Roger Firth in 1999. It is regarded as the "Hello, world!" of interactive fiction, and is used as a reference implementation to compare features and capabilities across IF systems.

- [Zork 1: The Great Underground Empire](https://github.com/samadhiBot/Gnusto/tree/main/Executables/Zork1)
    A pioneering text adventure game released by Infocom in 1980, based on the original MIT mainframe game developed in the late 1970s. It is widely recognized as one of the most influential works of interactive fiction, notable for its sophisticated parser, rich puzzles, and imaginative setting. This comprehensive recreation is still in progress, but already features combat, characters, and complex interactions.

Start with _Cloak of Darkness_ to see how a whole game fits together, then explore _Zork_ to study the more advanced patterns.

## How to Run the Example Games

To run the example games in a terminal, first clone the Gnusto repository and `cd` into the project folder, then `swift run` either `CloakOfDarkness` or `Zork1`.

```zsh
git clone https://github.com/samadhiBot/Gnusto.git
cd Gnusto

# Run Cloak of Darkness
swift run CloakOfDarkness

# Run Zork
swift run Zork1
```

Xcode users can select `CloakOfDarkness` or `Zork1` as the active scheme, Run the scheme, and play the game in the Xcode console.

For VS Code users, the Debug Console does not support interactive keyboard input, and the Swift debug adapter does not support rerouting to a different terminal. For now, the best option is to run the commands above in the integrated terminal.

[![asciicast](https://asciinema.org/a/743893.svg)](https://asciinema.org/a/743893)

## Where to Go from Here

[Game Structure and Dynamic Behavior](https://samadhibot.github.io/Gnusto/documentation/gnustoengine/gamestructure) goes deeper into locations, items and event handlers. It also introduces property computers, daemons and fuses.

[Frequently Asked Questions](https://samadhibot.github.io/Gnusto/documentation/gnustoengine/faqs) needs no explanation.

If you have a question that hasn't been addressed, or run into a problem while using Gnusto, please open an issue at [Gnusto/issues](https://github.com/samadhiBot/Gnusto/issues). We'll strive to provide timely responses.

### Contributing to Gnusto

Contributions are welcome. Please see [Contributing to Gnusto](https://github.com/samadhiBot/Gnusto/blob/main/CONTRIBUTING.md) for details.
