# ``GnustoEngine``

## A Modern Interactive Fiction Engine

![Gnusto Interactive Fiction Engine](gnusto-heading.png)

### Welcome to the Gnusto Interactive Fiction Engine!

Gnusto is a flexible and powerful framework for writing interactive fiction games. Drawing inspiration from the Infocom classics of the 1980s, it provides a modern toolkit that makes building rich, dynamic text adventures easy and enjoyable--allowing you to focus on storytelling and world-building rather than engine mechanics.

Gnusto is written in cross-platform Swift, allowing you to deploy your games on Mac, Linux, Windows, iOS and Android. The framework emphasizes ergonomics and developer experience, providing type safety without boilerplate code. Built with extensibility in mind, you can customize and extend Gnusto to fit your creative vision.

At its core, Gnusto uses a state change pipeline that ensures safe state management, eliminating many of the bugs that can plague interactive fiction engines. Whether you're creating your first text adventure or building a complex, multi-layered world, Gnusto provides the foundation you need while staying out of your way.

## Building Your First Game

Creating a game with Gnusto begins with two main concepts: ``Location`` and ``Item``.

### Location: Places in Your World

A ``Location`` represents any place the player can visit -- a room, forest clearing, or spaceship bridge. Here's a simple example:

```swift
let westOfHouse = Location(.westOfHouse)
    .name("West of House")
    .description(
        "You are standing in an open field west of a white house, with a boarded front door."
    ),
    .north(.northOfHouse)
    .south(.southOfHouse)
    .east(blocked: "The door is boarded and you can't remove the boards.")
    .inherentlyLit
```

### Item: Objects and Characters

An ``Item`` can be anything the player interacts with -- objects, characters, even abstract concepts:

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

## Key Features

- **Natural Language**: Smart parser understands synonyms, adjectives, and complex commands
- **Rich Interactions**: 80+ built-in action handlers for commands like "take," "examine," "attack"
- **Dynamic Content**: Use event handlers to create living, responsive worlds
- **Advanced Systems**: Built-in combat, character sheets, conversations, and timed events
- **Extensible**: Add custom behaviors without fighting the engine
- **Cross-Platform**: Develop on Mac, Linux or Windows; deploy on Mac, iOS, Linux, Windows, Android and WebAssembly
- **Automatic Setup**: The `GnustoAutoWiringPlugin` eliminates boilerplate

## Getting Started

### Automatic

The easiest way to get started is by running Gnusto's [bootstrap](https://github.com/samadhiBot/Gnusto/blob/main/Scripts/bootstrap) script. It sets up a new game scaffold that you can run and test on your own machine.

If you have Swift 6.2+ installed on your machine, you can get up and running and start working on a new game in less than a minute.

If you're using Linux or Windows and don't have Swift 6.2+ installed, follow the instructions at [swift.org/install](https://www.swift.org/install/linux/), then follow the steps below:

```bash
# Run the bootstrap script from Github:
bash <(curl -sSL https://raw.githubusercontent.com/samadhiBot/Gnusto/refs/heads/main/Scripts/bootstrap)

# Or, clone the repo and run the bootstrap script locally:
git clone https://github.com/samadhiBot/Gnusto.git
./Gnusto/Scripts/bootstrap
```

[![asciicast](https://asciinema.org/a/746386.svg)](https://asciinema.org/a/746386)

### Manual

If you'd rather put things together manually, setting up Gnusto is still easy. Follow these steps to get started:

1. **Add Gnusto to your project** and include the `GnustoAutoWiringPlugin`
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
            ),
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
        static let trollHandler = ItemEventHandler(for: .troll) {
            before(.tell) { context, command in
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

The easiest way to understand Gnusto is by looking at working examples:

- **[Cloak of Darkness](https://github.com/samadhiBot/Gnusto/blob/main/Executables/CloakOfDarkness)**:
    A minimalist interactive fiction game created by Roger Firth in 1999. It is regarded as the "Hello, world!" of interactive fiction, and is used as a reference implementation to compare features and capabilities across IF systems.

- **[Zork 1: The Great Underground Empire](https://github.com/samadhiBot/Gnusto/blob/main/Executables/Zork1)**:
    A pioneering text adventure game released by Infocom in 1980, based on the original MIT mainframe game developed in the late 1970s. It is widely recognized as one of the most influential works of interactive fiction, notable for its sophisticated parser, rich puzzles, and imaginative setting. This comprehensive recreation is still in progress, but already features combat, characters, and complex interactions.

Start with _Cloak of Darkness_ to see how a whole game fits together, then explore _Zork 1_ to study the more advanced patterns.

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
