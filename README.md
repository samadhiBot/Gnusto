![Gnusto Interactive Fiction Engine Hero Graphic](Sources/GnustoEngine/Documentation.docc/Resources/gnusto-heading.png)

# Gnusto: A Modern Interactive Fiction Engine

Gnusto is a powerful, flexible Swift-based framework for creating interactive fiction games. Drawing inspiration from the classic Infocom masterpieces, it provides a modern toolkit that makes building rich, dynamic text adventures easy and enjoyable--allowing you to focus on storytelling and world-building rather than engine mechanics.

## For Game Creators

### Why Gnusto?

- **Zero Boilerplate:** The GnustoAutoWiringPlugin automatically generates all ID constants and wires up your game components--no tedious manual setup required
- **Modern Swift Foundation:** Built with Swift 6 concurrency, SOLID principles, and clean architecture for maintainable, safe code
- **Thoroughly Tested:** Engine maintains 80-90% test coverage  
- **Cross-Platform Ready:** Deploy your game on macOS, iOS, Linux, Windows, and Android
- **Powerful Yet Approachable:** Start with simple text adventures and scale up to complex, dynamic worlds with timed events and sophisticated puzzles
- **Battle-Tested Patterns:** Leverage proven design patterns from the golden age of interactive fiction, rebuilt with modern tools
- **Nostalgic Excellence:** Authentic phrases and mechanics from the interactive fiction classics

### Key Features for Creators

- **Automatic Setup:** GnustoAutoWiringPlugin discovers your game patterns and generates all necessary ID constants, GameBlueprint wiring, and component connections
- **Dynamic Content:** Create living, breathing worlds with state-driven descriptions and behaviors using ItemEventHandlers and LocationEventHandlers
- **Rich Action System:** Support complex player interactions with a flexible action pipeline that's easy to customize
- **Smart Parser:** Natural language understanding with support for complex commands, synonyms, adjectives, and object references
- **Comprehensive State Management:** Track game progress, handle timed events (fuses and daemons), and manage complex game states with full Codable support
- **Extensible Architecture:** Add custom behaviors and game mechanics without fighting the engine--everything is designed for modularity

### Quick Start for Creators

1. **Add Gnusto to Your Project:**

   ```swift
   // Package.swift
   dependencies: [
       .package(url: "https://github.com/samadhiBot/Gnusto", from: "1.0.0"),
   ],
   targets: [
       .executableTarget(
           name: "MyGame",
           dependencies: ["GnustoEngine"],
           plugins: ["GnustoAutoWiringPlugin"]  // ← This eliminates all boilerplate!
       ),
   ]
   ```

2. **Define Your World:** Create locations and items organized into logical areas
3. **Add Dynamic Behavior:** Write event handlers for custom interactions
4. **Create Your GameBlueprint:** The plugin handles all the wiring automatically
5. **Run Your Game:** Deploy to any supported platform

### Example Code

Here's how simple it is to create an interactive world with Gnusto:

```swift
import GnustoEngine

enum OperaHouse {  // Organize content into logical areas
    static let foyer = Location(
        id: .foyer,  // Plugin auto-generates LocationID.foyer
        .name("Foyer of the Opera House"),
        .description("""
            You are standing in a spacious hall, splendidly decorated in red
            and gold, with glittering chandeliers overhead. The entrance from
            the street is to the north, and there are doorways south and west.
            """
        ),
        .exits(
            .south(.bar),
            .west(.cloakroom),
            .north(blocked: """
                You've only just arrived, and besides, the weather outside
                seems to be getting worse.
                """)
        ),
        .inherentlyLit
    )

    static let cloak = Item(
        id: .cloak,  // Plugin auto-generates ItemID.cloak
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

    static let hook = Item(
        id: .hook,  // Plugin auto-generates ItemID.hook
        .adjectives("small", "brass"),
        .in(.cloakroom),
        .omitDescription,
        .isSurface,
        .name("small brass hook"),
        .synonyms("peg"),
    )

    // Custom behavior for examining the hook
    static let hookHandler = ItemEventHandler(for: .hook) {
        before(.examine) { context, command in
            let cloak = try await context.engine.item(.cloak)
            let hookDetail = if try await cloak.parent == .item(context.item) {
                "with a cloak hanging on it"
            } else {
                "screwed to the wall"
            }
            return ActionResult("It's just a small brass hook, \(hookDetail).")
        }
    }
}
```

### The Power of the GnustoAutoWiringPlugin

Gnusto includes a build tool plugin that **eliminates virtually all boilerplate code**. The plugin automatically:

- **Discovers ID Patterns:** Scans `Location(id: .foyer, ...)` and generates `LocationID.foyer` extensions
- **Aggregates Content:** Collects all your items and locations from multiple area files
- **Wires Event Handlers:** Automatically connects your ItemEventHandlers and LocationEventHandlers
- **Sets Up Time Registry:** Discovers and registers Fuses and Daemons
- **Handles Custom Actions:** Integrates custom ActionHandler implementations

This means you can focus purely on creating your game world without worrying about the connection logic!

### Ready to Start?

Check out our comprehensive resources:

- **[Complete Documentation](Sources/GnustoEngine/Documentation.docc/Documentation.md):** Detailed guides and API reference
- **[Cloak of Darkness](Executables/CloakOfDarkness):** A complete, playable example showcasing core features
- **[Frobozz Magic Demo Kit](Executables/FrobozzMagicDemoKit):** Templates and advanced patterns
- **[GnustoAutoWiringPlugin Guide](Sources/GnustoEngine/Documentation.docc/GnustoAutoWiringPlugin.md):** Master the automatic setup system

---

## For Engine Developers

## Project Architecture

The project is organized with a clean separation between the core engine and example implementations:

- **`Sources/GnustoEngine/`:** The complete interactive fiction engine
- **`Executables/`:** Example games and demos showcasing engine capabilities

### Core Engine Components

- **`Core/`:** Fundamental types (GameState, Item, Location, ScopeResolver)
- **`Engine/`:** The central GameEngine orchestrator
- **`Actions/`:** Action handling pipeline and built-in ActionHandlers
- **`Parsing/`:** Command parsing and vocabulary systems
- **`IO/`:** Input/output abstraction for different frontends
- **`Blueprints/`:** GameBlueprint system for defining game structure
- **`Time/`:** Fuse and daemon system for timed events
- **`Vocabulary/`:** Word recognition and synonym systems
- **`Extensions/`:** Utility extensions

## Core Concepts

### Modern Swift Architecture

- **Sendable Throughout:** Full Swift 6 concurrency compliance with `Sendable` types
- **State Change Pipeline:** All mutations flow through `StateChange` objects for proper validation and event handling
- **Protocol-Oriented Design:** Extensible architecture using protocols like `ActionHandler`, `IOHandler`, and `GameBlueprint`
- **Type Safety:** Strong typing with specialized ID types (`ItemID`, `LocationID`, `Verb`) prevents common errors

### Game World Model

- **Entities:** The game world consists of `Location` and `Item` objects with:

  - Static definition data (ID, name, vocabulary words)
  - Dynamic state via `[PropertyID: StateValue]` properties dictionary
  - Optional event handlers for dynamic descriptions and custom behavior
  - Codable support for save/load functionality

- **Centralized State Management:**

  - Single source of truth in `GameState`
  - All mutations tracked via `StateChange` objects
  - Support for custom state on items, locations, and global game state
  - Automatic validation and event handler triggering

- **Action Processing Pipeline:**
  - Player input parsed into structured `Command` objects
  - `ActionHandler`s process commands through validate → process → postProcess
  - Returns `ActionResult` with success status, messages, and state changes
  - Easy customization and extension of game verbs

### Key Engine Features

#### Automatic Boilerplate Elimination

The **GnustoAutoWiringPlugin** revolutionizes game development by:

- Scanning source files for patterns like `Location(id: .foyer, ...)`
- Generating all necessary ID extensions automatically
- Aggregating game content from multiple area files
- Wiring up event handlers with proper scoping
- Handling both static (enum-based) and instance (struct-based) architectures

#### Dynamic Content System

- **Event Handlers:** `ItemEventHandler` and `LocationEventHandler` enable custom responses
- **State-Driven Descriptions:** Dynamic text based on current game state
- **Flexible Properties:** Custom properties on any game entity
- **Conditional Logic:** Easy branching based on game state

#### Advanced Parser

The `StandardParser` provides ZIL-inspired natural language processing:

- **Flexible Grammar:** Multi-word verbs, synonyms, and adjectives
- **Object Resolution:** Smart handling of pronouns and ambiguous references
- **Scope Awareness:** Context-sensitive object recognition
- **Error Handling:** Helpful messages for parsing failures

#### Time and Event System

- **Fuses:** One-time delayed events with automatic cleanup
- **Daemons:** Recurring background processes
- **TimeRegistry:** Centralized management of all timed events
- **Integration:** Seamless integration with the state change pipeline

## Development Standards

### Code Organization

Following SOLID principles and modern Swift best practices:

- **Logical Grouping:** Properties → Initializers → Computed Properties → Public Methods → Private Methods
- **Alphabetization:** Within logical groups (unless natural ordering is clearer)
- **Nested Types:** Keep related types together, extract when files become large (~300+ lines)
- **Documentation:** Comprehensive `///` documentation for all public APIs

### Testing Excellence

- **Framework:** Swift Testing for all new code
- **Coverage:** 80-90% test coverage required for pull requests
- **Organization:** Tests mirror source structure
- **Patterns:** Helper methods for common test scenarios

### Documentation Standards

- **API Documentation:** Complete `///` documentation with examples
- **Usage Guides:** Step-by-step tutorials for common patterns
- **Best Practices:** Documented patterns and anti-patterns
- **Examples:** Working code samples for all major features

## Example Games

### Cloak of Darkness

A faithful recreation of the Interactive Fiction standard demo, showcasing:

- Three-room layout with dynamic connections
- Light/dark mechanics affecting game state
- Object interaction and state tracking
- Dynamic descriptions based on player actions
- Score tracking and win conditions

### Frobozz Magic Demo Kit

A comprehensive demonstration package featuring:

- Advanced pattern examples
- Custom action handler implementations
- Complex state management scenarios
- Time-based event demonstrations
- Multi-area game organization

## Getting Started as a Developer

1. **Clone and Explore:**

   ```bash
   git clone https://github.com/samadhiBot/Gnusto
   cd Gnusto
   ```

2. **Run the Examples:**

   ```bash
   swift run CloakOfDarkness
   swift run FrobozzMagicDemoKit
   ```

3. **Study the Architecture:**

   - Start with `Sources/GnustoEngine/Core/`
   - Examine `GameEngine.swift` for the central orchestration
   - Look at `Actions/` for the command processing pipeline

4. **Reference Materials:**
   Historical Interactive Fiction source code is available for research and inspiration, helping maintain authenticity to the classic IF experience.

## Contributing

We welcome contributions! Please:

1. Follow our development standards and Swift style guide
2. Include comprehensive tests (80-90% coverage)
3. Document your changes with clear `///` comments
4. Reference the [Roadmap](Sources/GnustoEngine/Documentation.docc/Roadmap.md) for planned features
5. Maintain the focus on developer ergonomics and zero-boilerplate experience

## What's Next?

Check out our [development roadmap](Sources/GnustoEngine/Documentation.docc/Roadmap.md) to see upcoming features, including enhanced state change ergonomics, conditional exit systems, and expanded testing infrastructure.

## License

MIT License

Copyright (c) 2025 Chris Sessions

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
