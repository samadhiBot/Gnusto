# Frequently Asked Questions

Answers to common questions about the Gnusto Interactive Fiction Engine.

Please open an [issue](https://github.com/samadhiBot/Gnusto/issues) on GitHub if you have a question that's not covered here. 

## What is Gnusto?

Gnusto is a modern interactive fiction engine with a declarative DSL for defining locations, items, and behaviors. It focuses on ergonomics, a safe state-change pipeline, and extensibility for parser-based games.

- Home: [https://github.com/samadhiBot/Gnusto](https://github.com/samadhiBot/Gnusto)
- Overview: <doc:GnustoEngine>
- More detail: <doc:GameStructure>

## What platforms are supported?

| Platform | Status | Notes |
|---|---|---|
| macOS | ✅ Working | Development + Distribution |
| Linux (Ubuntu 24.04) | ✅ Working | Development + Distribution |
| Windows | ✅ Working | Development + Distribution |
| iOS / Android | 🏗️ Planned | Distribution |
| WebAssembly | 🔬 Experimental | Distribution  |

## What toolchain do I need?

- Toolchain: [Swift 6.2](https://www.swift.org/)
- Build system: [Swift Package Manager](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/)
- IDEs: [Xcode](https://developer.apple.com/xcode/), [Zed](https://zed.dev/), [VS Code](https://code.visualstudio.com/), or [any other editor](https://www.swift.org/tools/#editors) that supports the Language Server Protocol (LSP)

## How do I test it out?

```
git clone https://github.com/samadhiBot/Gnusto.git
cd Gnusto

# Cloak of Darkness
swift run CloakOfDarkness

# Zork 1 (in progress)
swift run Zork1
```

## Can I use Linux and Windows?

To install the Swift 6.2 toolchain, follow the [Linux](https://www.swift.org/install/linux/) or [Windows](https://www.swift.org/install/windows/) instructions at swift.org.

During Linux and Windows testing, it was necessary to disable the [SwiftLint](https://realm.github.io/SwiftLint/) build tool plugin. If you see plugin‑related build errors, comment it out in your `Package.swift` manifest:

```swift
plugins: [
    "GnustoAutoWiringPlugin",
    // .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")  // Disabled for Windows/Linux
]
```

## How do I author games?

Gnusto uses a declarative DSL to define locations, items and behaviors. Games are written in Swift, but the DSL is simple and intuitive, and the engine and auto‑wiring tool remove the complexity. Here's the game development in a nutshell:

- Define static content with ``Location`` and ``Item``
- Add dynamic behavior via ``ItemEventHandler`` and ``LocationEventHandler``
- Use ``ItemComputer`` and ``LocationComputer`` for computed descriptions and properties
- Use ``Daemon`` and ``Fuse`` for time-based logic

See <doc:GameStructure> for more more details, or look at [Cloak of Darkness](https://github.com/samadhiBot/Gnusto/blob/main/Executables/CloakOfDarkness/OperaHouse.swift) and [Zork 1](https://github.com/samadhiBot/Gnusto/tree/main/Executables/Zork1) to see some real examples. 

## Is there a custom language or file format?

Games are written in Swift, using a declarative DSL. There is no separate language, and you have the full power of the Swift language at your disposal.

## Is it compatible with Inform, TADS, Dialog, Ink, Twine, or Z‑machine/Glulx?

No. Gnusto is a separate engine and does not import or export those formats.

## How does the parser behave?

- Natural‑language parser with synonyms, adjectives, and complex commands
- 80+ built‑in actions (e.g., examine, take, drop, open/close, attack)
- Customizable responses via StandardMessenger (override per game)

See the examples in <doc:GnustoEngine> and the example games.

## What's the save format?

Saves are a simple JSON snapshot of game state. The persistence mechanism may vary by I/O handler (today: terminal). The format is subject to change during beta; feedback on portability and versioning is welcome.

## What's the current runtime?

Terminal (CLI). Packaging for desktop, mobile, and web is planned and will be guided by community feedback.

## Accessibility?

Gnusto's interface is currently terminal‑only. Accessibility will be a top priority as user interface work for desktop, mobile and web evolves. 

## Why the name?

The name is an homage.

"Gnusto" is a magical incantation from Infocom's _Enchanter_ series of fantasy text adventure games. It allows a player to copy a spell from a scroll into their spellbook, enabling future use of that spell multiple times rather than just once.

Gnusto has appeared historically in IF tooling, but this project is unrelated to prior tools.

## Are there example games?

- Cloak of Darkness (complete demo): [CloakOfDarkness](https://github.com/samadhiBot/Gnusto/blob/main/Executables/CloakOfDarkness)
- Zork 1 (in progress): [Zork1](https://github.com/samadhiBot/Gnusto/blob/main/Executables/Zork1)

## What are the known limitations?

- Terminal runtime only
- No interoperability with existing IF formats
- Deployment targets (desktop/mobile/web) not packaged yet
- SwiftLint build tool plugin may need to be disabled on Windows/Linux
- Save format and APIs may change during beta
- Documentation is evolving
- Melee combat has a lot of rough edges
- Player/NPC Character Sheet is under-utilized 

## Can I contribute

We welcome feedback, issues, feature requests, documentation improvements, and PRs.

Please use [Gnusto/issues](https://github.com/samadhiBot/Gnusto/issues) to share your thoughts.

License: MIT

## Troubleshooting

- VS Code Debug Console isn't interactive
  - Use the integrated terminal and run swift run from there.

- Build fails due to SwiftLint plugin (Windows/Linux)
  - Comment out the SwiftLint Build Tool Plugin in Package.swift (see note above).
