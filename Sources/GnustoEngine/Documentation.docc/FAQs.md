# Frequently Asked Questions

Quick answers to common questions about the Gnusto Interactive Fiction Engine.

## What is Gnusto?

**Gnusto is a modern, open-source interactive fiction engine that provides a declarative approach to creating parser-based text adventures.**

You write games using an intuitive DSL (domain-specific language) that Gnusto provides—one that's easy to work with, especially with code completion, and doesn't require deep Swift knowledge to be productive. At the same time, because you're writing in Swift, and Gnusto is built as a Swift package, you have the full power and potential of a fast, safe, general-purpose language standing by whenever you need it. The engine emphasizes type safety, testability, and a structured state-change pipeline that prevents common IF programming bugs.

- **Repository**: [github.com/samadhiBot/Gnusto](https://github.com/samadhiBot/Gnusto)
- **Documentation**: <doc:GnustoEngine> and <doc:GameStructure>
- **License**: MIT (open source, commercial-friendly)

## Why would I choose Gnusto over established systems like Inform 7 or TADS?

**Gnusto offers modern tooling, type safety, and seamless integration with the Apple ecosystem while maintaining respect for IF traditions.**

Key differentiators:
- **Type Safety**: Compile-time checking prevents many runtime errors common in dynamic languages
- **Modern IDE Support**: Full autocomplete, refactoring, and debugging in Xcode, VS Code, Zed, Neovim, etc.
- **Testing Framework**: Built-in support for unit and integration testing your game logic
- **Native Performance**: Compiled Swift runs efficiently on all platforms
- **Ecosystem Access**: Leverage the entire Swift package ecosystem for advanced features

That said, Gnusto is still in beta and lacks the maturity, community resources, and extensive libraries of established systems. It's best suited for authors comfortable with programming or those seeking modern development practices.

## How do I write games in Gnusto?

**You define your game world declaratively using Swift's DSL, then add dynamic behaviors through event handlers.**

Here's a minimal example:

```swift
// Define a location
let foyer = Location(.foyer)
    .name("Foyer of the Opera House")
    .description(
        """
        You are standing in a spacious hall, splendidly decorated in red
        and gold, with glittering chandeliers overhead. The entrance from
        the street is to the north, and there are doorways south and west.
        """
    ),
    .exits(
        .south(.bar),
        .west(.cloakroom),
        .north(
            blocked: """
                You've only just arrived, and besides, the weather outside
                seems to be getting worse.
                """
        )
    ),
    .inherentlyLit
)

// Define an item
let cloak = Item(.cloak)
    .name("velvet cloak")
    .description(
        """
        A handsome cloak, of velvet trimmed with satin, and slightly
        spattered with raindrops. Its blackness is so deep that it
        almost seems to suck light from the room.
        """
    ),
    .adjectives("handsome", "dark", "black", "velvet", "satin")
    .in(.player)
    .isTakable
    .isWearable,
    .isWorn,
)


// Add dynamic behavior
let cloakHandler = ItemEventHandler(for: .cloak) {
    before(.drop, .insert) { context, _ in
        guard await context.player.location == .cloakroom else {
            throw ActionResponse.feedback(
                "This isn't the best place to leave a smart cloak lying around."
            )
        }
        return nil
    }
}
```

The Gnusto auto-wiring tool automatically discovers your content and generates the necessary boilerplate, so you focus on game design rather than plumbing.

## What platforms does Gnusto support?

**Gnusto runs on macOS, Linux, and Windows today, with mobile and web platforms planned.**

| Platform | Development | Distribution | Status |
|----------|------------|--------------|---------|
| macOS    | ✅ | ✅ | Fully supported |
| Linux    | ✅ | ✅ | Fully supported (Ubuntu 24.04 tested) |
| Windows  | ✅ | ✅ | Fully supported (may need to disable SwiftLint) |
| iOS      | ✖️ | 🏗️ | Planned (Swift runs natively) |
| Android  | ✖️ | 🏗️ | Planned (via Swift for Android) |
| Web      | ✖️ | 🔬 | Experimental (via WebAssembly) |

## What development tools do I need?

**You need the Swift 6.2 toolchain and a text editor — everything else is included.**

- **Required**: [Swift 6.2+](https://www.swift.org/download/)
- **Recommended IDEs**:
  - [Xcode](https://developer.apple.com/xcode/) (macOS only, best experience)
  - [VS Code](https://code.visualstudio.com/) with Swift extension (all platforms)
  - [Zed](https://zed.dev/) (fast, modern, great Swift support)
- **Build System**: Swift Package Manager (included with Swift)

## Can I try it without installing anything?

**Yes! You can explore the example games with just a few terminal commands.**

```bash
# Clone and explore
git clone https://github.com/samadhiBot/Gnusto.git
cd Gnusto

# Play the Cloak of Darkness demo
swift run CloakOfDarkness

# Try the Zork 1 port (work in progress)
swift run Zork1
```

## How capable is the parser?

**The parser handles natural language input with support for complex commands, synonyms, and contextual understanding.**

Built-in capabilities:
- **80+ standard verbs** (examine, take, drop, open, close, light, attack, etc.)
- **Complex commands** ("put the brass lamp in the trophy case")
- **Pronouns** ("examine table" then "put lamp on it")
- **Multiple objects** ("take lamp and sword")
- **Disambiguation** ("which key do you mean, the brass key or the iron key?")
- **Synonyms and adjectives** (customizable per game)

The parser is extensible — you can add new verbs, modify syntax rules, or customize responses through the ``StandardMessenger`` system.

## Can I import my existing Inform/TADS/Dialog game?

**No, Gnusto doesn't support importing from or exporting to other IF systems.**

This is a deliberate design choice to avoid the complexity of format conversion and to leverage Swift's native capabilities fully. To port an existing game, you'd need to recreate it using Gnusto's DSL, though the declarative syntax makes this relatively straightforward.

## How does saving and restoring work?

**Games are saved as JSON snapshots of the complete game state, making saves portable and human-readable.**

The save system captures:
- Player location and inventory
- All item states and positions
- Game flags and variables
- Score and turn count
- Active daemons and fuses

Note: The save format may change during beta as we gather feedback on compatibility needs.

## Is there support for multimedia (graphics, sound)?

**Not yet. Gnusto currently focuses on text-only experiences.**

The architecture is designed to support multimedia extensions in the future, but the initial release concentrates on getting the core parser and world model right. The I/O system is abstracted to allow for different presentation layers as the engine matures.

## How do I handle NPCs and dialogue?

**Gnusto provides basic NPC support through the ``CharacterSheet`` system. Conversation handling is on the roadmap.**

```swift
let thief = Item(.thief)
    .name("thief")
    .synonyms("thief", "robber", "man", "person")
    .adjectives("shady", "suspicious", "seedy", "suspicious-looking", "sneaky")
    .firstDescription(
        """
        There is a suspicious-looking individual, holding a large bag,
        leaning against one wall. He is armed with a deadly stiletto.
        """
    )
    .characterSheet(
        CharacterSheet(
            strength: 14,
            dexterity: 18,
            intelligence: 13,
            charisma: 7,
            bravery: 9,
            perception: 16,
            accuracy: 15,
            intimidation: 15,
            stealth: 17,
            level: 2,
            classification: .masculine,
            alignment: .neutralEvil
        )
    )
```

The NPC system is functional but basic. At this stage, complex dialogue trees or sophisticated AI behaviors would need custom implementation.

## What about combat and RPG mechanics?

**Melee combat exists but needs refinement. The Character Sheet system provides RPG stats but is underutilized.**

Current support:
- Simple turn-based attack mechanics
- Hit points and basic stats
- Simple weapon system

This is an area marked for improvement. If your game needs sophisticated combat, you may want to wait for future updates, or contribute improvements.

## How mature is Gnusto?

**Gnusto is in beta — stable enough for creating games but expect occasional API changes.**

Strengths:
- Core engine is well-tested (80%+ test coverage)
- Parser and world model are robust
- Auto-wiring eliminates most boilerplate

Current limitations:
- Documentation is still growing
- No visual IDE or world builder
- Limited community resources
- Some systems (combat, NPCs) need polish

## Can I contribute or get help?

**Yes! We welcome questions, feedback, and contributions from the IF and open source communities.**

- **Questions & Issues**: [GitHub Issues](https://github.com/samadhiBot/Gnusto/issues)
- **Contributions**: PRs welcome (see CONTRIBUTING.md)
- **Community**: Growing! Early adopters shape the engine's direction

We especially value input from experienced IF authors on API design, missing features, and usability improvements.

## Why is it called "Gnusto"?

**It's an homage to Infocom's Enchanter series, where "gnusto" copies magical spells into your spellbook.**

Just as the spell preserves magic for reuse, the Gnusto engine aims to preserve and modernize the craft of interactive fiction. While the name has appeared in other IF tools historically, this project is unrelated to them.

## What's the development philosophy?

**Gnusto balances respect for IF traditions with modern software engineering practices.**

Core principles:
- **Safety First**: Type checking and structured state changes prevent common bugs
- **Test Everything**: Games should be as testable as any other software
- **Developer Experience**: Clear APIs, good error messages, and helpful tooling
- **Honor the Past**: Respect IF conventions while enabling innovation
- **Open Development**: Community feedback shapes the engine's evolution

## What's on the roadmap?

**The focus is on stabilizing the core engine, improving documentation, and building community.**

Near term:
- Stabilize save/restore format
- Improve combat and NPC systems
- Expand documentation and tutorials
- Create more example games

Medium term:
- Visual debugger/inspector
- iOS and Android runtime
- Web-based play via WebAssembly
- World builder tools

Long term:
- Multimedia support
- Advanced NPC/dialogue systems
- Integration with AI for dynamic content

## Should I use Gnusto for my next game?

**If you're comfortable with programming and want modern tooling for IF development, Gnusto is worth exploring.**

Good fit if you:
- Want type safety and IDE support
- Enjoy test-driven development
- Need to integrate with other Swift libraries
- Prefer declarative, code-based authoring
- Want to contribute to a growing project

Maybe wait if you:
- Prefer visual tools or natural language authoring
- Need extensive multimedia support
- Want access to large existing libraries
- Require stable, unchanging APIs
- Need comprehensive documentation/tutorials

## Where can I see example code?

**The repository includes two example games that demonstrate best practices.**

- [**Cloak of Darkness**](https://github.com/samadhiBot/Gnusto/tree/main/Executables/CloakOfDarkness): The standard IF demo, showing core concepts in ~200 lines
- [**Zork 1**](https://github.com/samadhiBot/Gnusto/tree/main/Executables/Zork1): A work-in-progress port demonstrating complex game mechanics

Both examples include extensive comments and show idiomatic Gnusto patterns.

## Troubleshooting

### VS Code debug console isn't interactive
Use the integrated terminal instead and run `swift run YourGame` directly.

### Build fails with SwiftLint errors on Linux/Windows
Disable SwiftLint in your `Package.swift`:
```swift
plugins: [
    "GnustoAutoWiringPlugin",
    // .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
]
```

### "Cannot find type 'LocationID'" errors
Make sure your game module includes the auto-wiring plugin in `Package.swift`. The plugin generates these types automatically.

### Changes to items/locations aren't reflected
The auto-wiring plugin needs to run. Try `swift package clean` then rebuild.

---

*Have a question not covered here? Please [open an issue](https://github.com/samadhiBot/Gnusto/issues) — we'd love to hear from you!*
