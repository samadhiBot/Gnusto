# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Gnusto is a modern Swift-based interactive fiction (IF) engine designed for creating text adventure games. It provides a clean, extensible architecture that honors classic IF traditions while leveraging modern Swift 6 concurrency and SOLID principles.

## Build System & Development Commands

### Building and Testing
```bash
# Build the entire project
swift build

# Run all tests
swift test

# Run specific test target
swift test --filter GnustoEngineTests
swift test --filter GnustoAutoWiringToolTests

# Run specific test by name pattern
swift test --filter "testTakeAction"

# Build with verbose output
swift build --verbose

# Clean build artifacts
swift package clean
```

### Running Example Games
```bash
# Note: Executables are currently commented out in Package.swift
# To enable them, uncomment the relevant sections and run:
swift run CloakOfDarkness
swift run FrobozzMagicDemoKit
swift run Zork1
```

### Auto-Wiring Tool
```bash
# Run the auto-wiring tool manually
swift run GnustoAutoWiringTool
```

## Core Architecture

### High-Level Structure
- **`Sources/GnustoEngine/`**: Core interactive fiction engine
- **`Executables/`**: Example games demonstrating engine capabilities
- **`Tests/`**: Comprehensive test suite using Swift Testing
- **`Plugins/`**: Build tools including the GnustoAutoWiringPlugin

### Engine Components
- **`Core/`**: Fundamental game types (Item, Location, Player, GameState, GameBlueprint)
- **`Engine/`**: Central GameEngine actor that orchestrates all game operations
- **`Actions/`**: Action handler pipeline with 80+ built-in handlers for common IF verbs
- **`Parsing/`**: Command parsing system with natural language support
- **`Proxies/`**: State change pipeline using proxy objects for safe mutations
- **`Vocabulary/`**: Word recognition, synonyms, and grammar systems
- **`Time/`**: Fuse and daemon system for timed events

### Key Design Patterns

#### State Change Pipeline
ALL game state mutations must flow through `StateChange` objects via the engine:
```swift
// ✅ RIGHT - Use state change builders
//
return try await ActionResult(
    await context.msg.inflateSuccess(raft.withDefiniteArticle),
    raft.setFlag(.isTouched),
    raft.setFlag(.isInflated)
)

// ❌ WRONG - Never mutate state directly
gameState.items["raft"]?.properties[.isOn] = true
```

#### Auto-Wiring System
The GnustoAutoWiringPlugin automatically discovers game content patterns and generates boilerplate:
- Scans for `Location(id: .foyer, ...)` patterns and generates `LocationID.foyer`
- Discovers `Item(id: .cloak, ...)` patterns and generates `ItemID.cloak`
- Wires up ItemEventHandlers and LocationEventHandlers
- Creates GameBlueprint implementations

#### Event-Driven Architecture
- **ItemEventHandler**: Custom behavior for specific items
- **LocationEventHandler**: Custom behavior for specific locations
- **ActionHandler**: Generic verb implementations across item types

## Testing Standards

### Framework & Coverage
- Uses **Swift Testing** framework (not XCTest)
- Requires 80-90% test coverage for pull requests
- Uses `CustomDump` library for precise output comparison

### Testing Patterns
```swift
@Test("Description of what is being tested")
func testSomething() async throws {
    // Given: Setup complete game state
    let testRoom = Location(
        id: .startRoom,
        .name("Test Room"),
        .inherentlyLit
    )

    let testItem = Item(
        id: "testItem",
        .name("test item"),
        .isTakable,
        .in(.startRoom)
    )

    let game = MinimalGame(
        player: Player(in: .startRoom),
        locations: testRoom,
        items: testItem
    )

    let (engine, mockIO) = await GameEngine.test(blueprint: game)

    // When: Execute through full pipeline (parser + action handler)
    try await engine.execute("take test item")

    // Then: Verify results
    let output = await mockIO.flush()
    expectNoDifference(
        output,
        """
        > take test item
        Taken.
        """
    )

    let finalState = try await engine.item("testItem")
    #expect(finalState?.parent == .player)
}
```

### Critical Testing Rules
- **ALWAYS test through the full engine pipeline** using `engine.execute("command")`
- **NEVER test action handlers in isolation** - this bypasses the parser and misses integration bugs
- **ALWAYS include command echo** in test expectations (the `> command` line)
- ALWAYS test exact mockIO output with `expectNoDifference(expected, actual)`, NEVER rely on `output.contains("expected")`

### Diffs

Diff legend:
  - lines are actual output
  + lines are expected output

You are blind to the difference between the following two lines. The first uses a curly apostrophe, and the second uses a straight apostrophe. If there is a failing test with an apostrophe or quote, and you cannot see the difference, leave the test for me and I will fix it.

```diff
− This item cannot be taken - it’s cursed!
+ This item cannot be taken - it's cursed!
```

## Development Guidelines

### Code Organization
- Logical grouping: Properties → Initializers → Computed Properties → Public Methods → Private Methods
- Alphabetize within logical groups unless natural ordering is clearer
- Use nested types, extract to separate files when parent >300 lines
- Comprehensive `///` documentation for all public APIs

### Swift Style
- Multi-line function signatures for 2+ parameters or >80 characters
- Multi-condition guards/ifs on separate lines
- Use heredocs for long strings, variadic args for simple collections
- No redundant type annotations
- Organize logically, then alphabetize within groups
- Use modern Swift optional binding: `if let character, let topic` instead of `if let character = character, let topic = topic`

### Localization and Messaging
- **ALL player-facing text MUST go through `MessageProvider`** (Core/MessageProvider.swift)
- Never use hardcoded strings like `"You don't see any \(noun) here."`
- Always use `engine.messenger.itemNotInScope(noun)` instead
- This enables easy localization and customization for downstream game developers
- Action handlers should use `context.msg` for all player messages

### Proxy System Architecture
- **ALWAYS use proxies over direct objects**: `PlayerProxy` over `Player`, `ItemProxy` over `Item`, `LocationProxy` over `Location`
- Proxies provide access to dynamic computed values via `ItemComputer`, `LocationComputer`, etc.
- Direct objects only contain static values defined at compile time
- The proxy system checks computed values first, then falls back to static values
- Bypassing proxies breaks dynamic computation and creates hard-to-debug issues
- **Never access `Player.currentLocationID` directly** - use `PlayerProxy` methods instead

### Action Handler Requirements
For items to work with specific action handlers:
- **TurnOnActionHandler**: Items need `.isDevice` flag (critical!)
- **TakeActionHandler**: Items need `.isTakable` flag
- **Light sources**: Use `.isLightSource` flag, often combined with `.isDevice` + `.isOn`

### Syntax Rules
Use clean, readable syntax for action handlers:
```swift
// ✅ RIGHT - Clean syntax
public let syntax: [SyntaxRule] = [
    .match(.light, .directObject),           // "light lamp"
    .match(.turn, .on, .directObject),       // "turn on lamp"
]

// ❌ WRONG - Verbose syntax (avoid unless necessary)
.match(.specificVerb(.light), .directObject)
```

### Commands
When parsing a player command, NEVER use the command's verb, ALWAYS use intents:
```swift
// ✅ RIGHT - Inclusive
if command.hasIntent(.attack) {...}

// ❌ WRONG - Brittle, exclusive
if [.attack, .hit, .kill, .fight].contains(command.verb) {...}
 ```

## Game Content Patterns

### Standard Item Setup
```swift
// Light source (lamp, torch, candle)
let lamp = Item(
    id: "lamp",
    .name("brass lamp"),
    .description("A shiny brass lamp."),
    .isTakable,
    .isLightSource,
    .isDevice,  // Required for TurnOnActionHandler!
    .in(.startRoom)
)

// Basic takeable item
let gem = Item(
    id: "gem",
    .name("sparkling gem"),
    .description("A beautiful gem."),
    .isTakable,
    .in(.startRoom)
)

// Fixed scenery item
let statue = Item(
    id: "statue",
    .name("stone statue"),
    .description("A heavy statue."),
    // No .isTakable - makes it untakeable
    .in(.startRoom)
)
```

### Location Setup
```swift
// Standard lit room (most common)
let room = Location(
    id: .startRoom,
    .name("Test Room"),
    .description("A laboratory in which strange experiments are being conducted."),
    .inherentlyLit  // Most tests need this
)

// Dark room (for darkness mechanics)
let darkRoom = Location(
    id: "darkRoom",
    .name("Dark Room"),
    .description("Pitch black without light."),
    // No .inherentlyLit - makes it dark
)
```

## State Verification Patterns

```swift
// Check item state
let item = try await engine.item("itemID")
#expect(item.parent == .player)
#expect(await item.hasFlag(.isOn) == true)

// Check location lighting
let isLit = try await engine.player.location.isLit
#expect(isLit == true)

// Check global state
let isVerboseMode = await engine.hasFlag(.isVerboseMode)
#expect(isVerboseMode == true)
```

## Important Notes

- This is currently on the `proxy` branch - a major architectural refactor
- Many integration tests are temporarily excluded during the proxy migration
- The project includes extensive historical IF references in `References/` for authenticity
- Focus on player-facing experience that honors classic IF traditions
- All state mutations MUST flow through the StateChange pipeline
- The auto-wiring system eliminates most boilerplate - just define content as static properties
