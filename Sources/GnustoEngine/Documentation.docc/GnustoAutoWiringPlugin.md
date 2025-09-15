# GnustoAutoWiringPlugin

Eliminate boilerplate with automatic ID generation and game setup.

## Overview

The GnustoAutoWiringPlugin is a Swift Package Manager build tool plugin that automatically discovers patterns in your game code and generates all the necessary ID constants, extensions, and GameBlueprint wiring. This eliminates the tedious and error-prone task of manually maintaining ID constants and connection code. The plugin has been enhanced to work with the new proxy system, combat mechanics, character systems, and conversation features.

## What Gets Generated

The plugin scans your Swift source files and automatically generates:

### ID Extensions

```swift
// From: Location(id: .foyer, ...)
// Generates:
extension LocationID {
    static let foyer = LocationID("foyer")
}

// From: Item(id: .cloak, ...)
// Generates:
extension ItemID {
    static let cloak = ItemID("cloak")
}

// From: GlobalID("score") or global state usage
// Generates:
extension GlobalID {
    static let score = GlobalID("score")
}

// From: Fuse(id: .timer, ...)
// Generates:
extension FuseID {
    static let timer = FuseID("timer")
}

// From: Daemon(id: .ambientSound, ...)
// Generates:
extension DaemonID {
    static let ambientSound = DaemonID("ambientSound")
}

// From: Verb("custom") for game-specific verbs
// Generates:
extension Verb {
    static let custom = Verb("custom")
}

// From: CharacterID usage in combat/conversation systems
// Generates:
extension CharacterID {
    static let wizard = CharacterID("wizard")
}

// From: ConversationID usage
// Generates:
extension ConversationID {
    static let wizardChat = ConversationID("wizardChat")
}
```

### GameBlueprint Extensions

The plugin aggregates all your game content and provides complete GameBlueprint implementations:

```swift
extension MyGameBlueprint {
    // Auto-aggregated from all area files
    var items: [Item] {
        [
            SomeArea.cloak,
            SomeArea.hook,
            AnotherArea.sword,
            // ... all items discovered
        ]
    }

    var locations: [Location] {
        [
            SomeArea.foyer,
            SomeArea.cloakroom,
            AnotherArea.cave,
            // ... all locations discovered
        ]
    }

    // Auto-wired event handlers with proper scoping
    var itemEventHandlers: [ItemID: ItemEventHandler] {
        [
            .cloak: SomeArea.cloakHandler,
            .sword: AnotherArea.swordHandler,
            // ... all handlers discovered
        ]
    }

    var locationEventHandlers: [LocationID: LocationEventHandler] {
        [
            .foyer: SomeArea.foyerHandler,
            // ... all handlers discovered
        ]
    }

    // Auto-registered time-based events
    var timeRegistry: TimeRegistry {
        let registry = TimeRegistry()
        registry.registerFuse(SomeArea.timerFuse)
        registry.registerDaemon(AnotherArea.ambientDaemon)
        return registry
    }

    // Auto-configured messenger system
    var messenger: MessageProvider {
        // Uses custom messenger if defined, otherwise defaults
        return CustomGameMessenger()
    }

    // Auto-discovered character sheets and combat configurations
    var characterSheets: [ItemID: CharacterSheet] {
        [
            .troll: CharacterSheet(health: 25, maxHealth: 25, attackPower: 8),
            .wizard: CharacterSheet(health: 15, maxHealth: 15, attackPower: 5),
            // ... all characters with sheets discovered
        ]
    }
}
```

## Usage

### Adding to Your Project

Include the plugin in your `Package.swift`:

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
            plugins: ["GnustoAutoWiringPlugin"]  // Add this line
        ),
    ]
)
```

### Organizing Your Code

The plugin works best when you organize your game content into logical areas:

```swift
// File: Sources/MyGame/Areas/TownSquare.swift
enum TownSquare {
    static let square = Location(
        id: .townSquare,  // Plugin generates LocationID.townSquare
        .name("Town Square"),
        .description("A bustling marketplace...")
    )

    static let fountain = Item(
        id: .fountain,    // Plugin generates ItemID.fountain
        .name("ornate fountain"),
        .in(.townSquare),
        .omitDescription
    )

    static let guard = Item(
        id: .guard,       // Plugin generates ItemID.guard
        .name("town guard"),
        .isCharacter,
        .characterSheet(
            health: 20,
            maxHealth: 20,
            classification: .friendly
        ),
        .in(.townSquare)
    )

    static let fountainHandler = ItemEventHandler(for: .fountain) {
        // Custom fountain behavior
    }

    static let guardHandler = ItemEventHandler(for: .guard) {
        // Custom guard conversation and combat behavior
    }
}
```

### Static vs Instance Properties

The plugin supports both architectural patterns:

#### Enum-Based Areas (Static Properties)

```swift
enum Castle {
    static let throneRoom = Location(id: .throneRoom, ...)
    static let crown = Item(id: .crown, ...)
    static let crownHandler = ItemEventHandler(for: .crown) { ... }
}
```

#### Struct-Based Areas (Instance Properties)

```swift
struct Castle {
    let throneRoom = Location(id: .throneRoom, ...)
    let crown = Item(id: .crown, ...)
    let crownHandler = ItemEventHandler(for: .crown) { ... }
}
```

The plugin automatically detects which pattern you're using and generates appropriate access code.

## Pattern Recognition

The plugin recognizes these patterns automatically:

### Entity Creation Patterns

- `Location(id: .someID, ...)`
- `Item(id: .someID, ...)` including character items with `.isCharacter`
- `Player(in: .someLocation)`
- Exit destinations: `.to(.someLocation)`
- Parent entities: `.location(.someLocation)`, `.item(.someItem)`
- Character sheets: `.characterSheet(health: 20, ...)`
- Combat configurations and weapon definitions

### ID Usage Patterns

- `GlobalID("key")` and global state dictionary usage
- `FuseID("timer")` and `DaemonID("background")`
- `Verb("custom")` for game-specific verbs
- `CharacterID("npc")` for character tracking
- `ConversationID("dialogue")` for conversation systems
- Combat state references and weapon IDs

### Event Handler Patterns

- `let nameHandler = ItemEventHandler(for: .itemName) { ... }`
- `static let nameHandler = LocationEventHandler { ... }`
- Character event handlers with combat and conversation integration
- Custom action handlers with proxy system support

### Time-Based Event Patterns

- `let timerFuse = Fuse(id: .timer, ...)`
- `let ambientDaemon = Daemon(id: .ambient, ...)`
- Combat-related timing events and turn management
- Conversation timeout and state management timers

## Advanced Features

### Scope Resolution

The plugin tracks which area defines each handler and generates proper access code:

```swift
// If CastleArea defines crownHandler as static:
var itemEventHandlers: [ItemID: ItemEventHandler] {
    [.crown: CastleArea.crownHandler]
}

// If CastleArea uses instance properties:
private static let _castleArea = CastleArea()
var itemEventHandlers: [ItemID: ItemEventHandler] {
    [.crown: Self._castleArea.crownHandler]
}
```

### Multiple Area Support

The plugin aggregates content from all areas in your project:

```swift
// Your areas:
enum Castle { ... }
enum Forest { ... }
enum Dungeon { ... }

// Generated aggregation:
var items: [Item] {
    [
        Castle.crown,
        Castle.throne,
        Forest.tree,
        Forest.path,
        Dungeon.torch,
        Dungeon.skeleton,
    ]
}
```

### Custom Verb Discovery

The plugin filters out standard engine verbs and only generates constants for your custom verbs:

```swift
// This won't generate an extension (standard verb):
Verb("take")

// This will generate Verb.cast:
Verb("cast")
```

## Output Location

Generated code is written to your target's build directory as `GeneratedIDs.swift`. This file is automatically included in your build and contains all the generated extensions and setup code.

## Debugging Plugin Issues

If the plugin isn't working as expected:

1. **Check Build Output**: Look for plugin messages starting with "🔍 Scanning" in your build logs
2. **Verify Patterns**: Ensure your code uses the recognized patterns (see Pattern Recognition above)
3. **Check File Organization**: The plugin works best with logical area organization
4. **Manual Alternative**: You can always disable the plugin and handle setup manually

## Manual Setup Alternative

If you prefer complete control, you can skip the plugin and handle everything manually:

```swift
// Manual ID extensions
extension LocationID {
    static let foyer = LocationID("foyer")
    static let cloakroom = LocationID("cloakroom")
}

extension ItemID {
    static let cloak = ItemID("cloak")
    static let hook = ItemID("hook")
    static let guard = ItemID("guard")
}

extension CharacterID {
    static let guard = CharacterID("guard")
}

// Manual GameBlueprint implementation
extension MyGameBlueprint {
    var items: [Item] {
        [OperaHouse.cloak, OperaHouse.hook, TownSquare.guard]
    }

    var locations: [Location] {
        [OperaHouse.foyer, OperaHouse.cloakroom, TownSquare.square]
    }

    var itemEventHandlers: [ItemID: ItemEventHandler] {
        [
            .cloak: OperaHouse.cloakHandler,
            .guard: TownSquare.guardHandler
        ]
    }

    var characterSheets: [ItemID: CharacterSheet] {
        [.guard: CharacterSheet(health: 20, maxHealth: 20)]
    }

    var messenger: MessageProvider {
        return CustomGameMessenger()
    }
}
```

## Best Practices

1. **Organize by Areas**: Group related locations, items, characters, and handlers together
2. **Use Descriptive Names**: Handler names should clearly indicate their purpose
3. **Be Consistent**: Choose either static or instance properties and stick with it
4. **Logical Grouping**: Keep related game content in the same file/area
5. **Character Integration**: Place character sheets and combat configurations near their item definitions
6. **Proxy Compatibility**: Ensure event handlers work with the proxy system for safe state access
7. **Test Thoroughly**: The plugin generates code, so always verify your build succeeds
8. **Combat Organization**: Group combat-related items (weapons, armor, characters) logically

The GnustoAutoWiringPlugin transforms game development from tedious boilerplate management to pure creative focus. With enhanced support for combat systems, character management, conversation mechanics, and the proxy architecture, it handles all the complex wiring while you craft amazing interactive experiences with rich NPCs, dynamic combat, and engaging dialogue!
