# GnustoAutoWiringPlugin

Eliminate boilerplate with automatic ID generation and game setup.

## Overview

The GnustoAutoWiringPlugin is a Swift Package Manager build tool plugin that automatically discovers patterns in your game code and generates all the necessary ID constants, extensions, and GameBlueprint wiring. This eliminates the tedious and error-prone task of manually maintaining ID constants and connection code.

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

    static let fountainHandler = ItemEventHandler(for: .fountain) {
        // Custom fountain behavior
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
- `Item(id: .someID, ...)`
- `Player(in: .someLocation)`
- Exit destinations: `.to(.someLocation)`
- Parent entities: `.location(.someLocation)`, `.item(.someItem)`

### ID Usage Patterns

- `GlobalID("key")` and global state dictionary usage
- `FuseID("timer")` and `DaemonID("background")`
- `Verb("custom")` for game-specific verbs

### Event Handler Patterns

- `let nameHandler = ItemEventHandler(for: .itemName) { ... }`
- `static let nameHandler = LocationEventHandler { ... }`

### Time-Based Event Patterns

- `let timerFuse = Fuse(id: .timer, ...)`
- `let ambientDaemon = Daemon(id: .ambient, ...)`

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
}

// Manual GameBlueprint implementation
extension MyGameBlueprint {
    var items: [Item] {
        [OperaHouse.cloak, OperaHouse.hook]
    }

    var locations: [Location] {
        [OperaHouse.foyer, OperaHouse.cloakroom]
    }

    var itemEventHandlers: [ItemID: ItemEventHandler] {
        [.cloak: OperaHouse.cloakHandler]
    }
}
```

## Best Practices

1. **Organize by Areas**: Group related locations, items, and handlers together
2. **Use Descriptive Names**: Handler names should clearly indicate their purpose
3. **Be Consistent**: Choose either static or instance properties and stick with it
4. **Logical Grouping**: Keep related game content in the same file/area
5. **Test Thoroughly**: The plugin generates code, so always verify your build succeeds

The GnustoAutoWiringPlugin transforms game development from tedious boilerplate management to pure creative focus. Let it handle the connections while you craft amazing interactive experiences!
