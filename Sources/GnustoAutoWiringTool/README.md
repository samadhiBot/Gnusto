## Gnusto Auto‑Wiring Tool

The Gnusto Auto‑Wiring Tool scans your Swift game source to discover content (IDs, items, locations, handlers, etc.) and generates a single Swift file that:

- **Declares ID extensions** for `LocationID`, `ItemID`, `GlobalID`, `FuseID`, `DaemonID`, and `Verb` that the tool finds in code.
- **Extends your `GameBlueprint` type(s)** to automatically wire up arrays and dictionaries of content (items, locations, event handlers, combat systems, daemons, fuses, and compute handlers) so the engine can use them without manual boilerplate.

## Why use it

- **Eliminates boilerplate**: No hand‑written `GameBlueprint` wiring or ID constant definitions.
- **Keeps wiring correct by construction**: Content is discovered directly from source patterns.
- **Safe by default**: If the tool cannot reliably map a property to an owning area, it inserts a commented placeholder instead of guessing.

## CLI usage

```bash
swift run GnustoAutoWiringTool \
  --source /absolute/path/to/your/game/sources \
  --output /absolute/path/to/Generated/GnustoAutoWiring.generated.swift
```

- **--source**: Root directory to scan recursively for `.swift` files (tests excluded).
- **--output**: Path to write the generated Swift file.

Example for this repository:

```bash
swift run GnustoAutoWiringTool \
  --source /Users/sessions/Gnusto/Sources \
  --output /Users/sessions/Gnusto/Sources/GnustoEngine/Generated/GnustoAutoWiring.generated.swift
```

The tool prints a summary of discovered content and writes the generated code to the `--output` path.

> Important: In normal development you should never need to run this tool manually. Instead, use the `GnustoAutoWiringPlugin` to run it automatically during builds of your executable targets.

Example plugin usage from `Package.swift`:

```swift
// In targets
.executableTarget(
    name: "CloakOfDarkness",
    dependencies: ["GnustoEngine"],
    plugins: ["GnustoAutoWiringPlugin"]
),

// Plugin declaration
.plugin(
    name: "GnustoAutoWiringPlugin",
    capability: .buildTool(),
    dependencies: ["GnustoAutoWiringTool"]
),
```

With this configuration, `swift build` or `swift run CloakOfDarkness` invokes the build tool plugin, which scans sources and generates the wiring code before compilation.

## What the tool looks for

Discovery is performed via a lightweight syntax walk using `SwiftParser`/`SwiftSyntax` (see `GameDataCollector`). The collector identifies the following:

- **ID usage**

  - `LocationID` and `ItemID` when seen in initializers like `Location(.foyer) ...)` and `Item(.lamp) ...)`.
  - `GlobalID` when used in single‑argument engine calls such as `engine.hasFlag(.someGlobalFlag)` or `context.engine.setFlag(.someGlobalFlag)`.
  - `FuseID` and `DaemonID` via convenience calls: `.startFuse("id")`, `.stopFuse("id")`, `.runDaemon("id")`, `.stopDaemon("id")`.
  - Additional IDs referenced inside expressions like `.in(.foyer)).

- **Game areas and types**

  - Game areas are inferred from surrounding `struct`, `class`, or `enum` declarations. Any type that contains content is treated as an area.
  - Types conforming to `GameBlueprint` are recorded so the generator can emit extensions on them.

- **Content properties and handlers**

  - `items`: stored or computed properties initialized with `Item(...)`.
  - `locations`: stored or computed properties initialized with `Location(...)`.
  - `itemEventHandlers` and `locationEventHandlers` via `ItemEventHandler { ... }` and `LocationEventHandler { ... }` when the property name ends with `Handler` (e.g., `cloakHandler`).
  - `itemComputers` and `locationComputers` via `ItemComputer { ... }` and `LocationComputer { ... }` when the property name ends with `Computer` (e.g., `torchComputer`).
  - `combatSystems` and `combatMessengers` via types whose names match `*CombatSystem` and `*CombatMessenger` or contain those words; enemy IDs are inferred from arguments like `enemyID: .troll` or from the property name (`trollCombatSystem` → `troll`).
  - `fuses` and `daemons` via `Fuse { ... }` and `Daemon { ... }`; their IDs are taken from the property name (e.g., `bridgeFuse` → `bridgeFuse`).

- **Static vs instance wiring**
  - The tool records whether a discovered property is declared `static`.
  - When generating `GameBlueprint` extensions, non‑static content that belongs to an area (e.g., `Act1Area`) requires a local instance inside the computed property, while static properties are referenced via the type.

## What gets generated

Generation is handled by `CodeGenerator`. If nothing is discovered, it emits a short “nothing to generate” file. Otherwise, it produces:

1. **ID extensions**

```swift
extension LocationID {
    static let foyer = LocationID("foyer")
}

extension ItemID {
    static let lamp = ItemID("lamp")
}

extension GlobalID {
    static let someGlobalFlag = GlobalID("someGlobalFlag")
}

extension FuseID { /* ... */ }
extension DaemonID { /* ... */ }
extension Verb { /* ... */ }
```

2. **`GameBlueprint` extensions** for every blueprint type discovered. Properties are synthesized based on what the scan found:

- `public var items: [Item]`
- `public var locations: [Location]`
- `public var itemEventHandlers: [ItemID: ItemEventHandler]`
- `public var locationEventHandlers: [LocationID: LocationEventHandler]`
- `public var combatMessengers: [ItemID: CombatMessenger]`
- `public var combatSystems: [ItemID: any CombatSystem]`
- `public var daemons: [DaemonID: Daemon]`
- `public var fuses: [FuseID: Fuse]`
- `public var itemComputers: [ItemID: ItemComputer]`
- `public var locationComputers: [LocationID: LocationComputer]`

When non‑static content lives on an area type like `Act1Area`, the generator creates a local area instance:

```swift
public var items: [Item] {
    let act1Area = Act1Area()
    return [
        act1Area.lamp,
        Act1Area.gem, // static example
    ]
}
```

If the generator cannot confidently map a property to its owning area, it inserts a commented placeholder for you to fill in later:

```swift
// sword, // Area mapping unknown - please add manually
```

For compute handlers, if items/locations exist but no corresponding computers were found, the tool emits a short commented scaffold showing how to add them.

## How it works (high level)

1. **Scan**: `Scanner` parses each Swift file with `SwiftParser` and walks it with `GameDataCollector`.
2. **Merge**: `GnustoAutoWiringTool` aggregates `GameData` from all files.
3. **Generate**: `CodeGenerator` writes a single Swift file containing ID extensions and `GameBlueprint` extensions.

## Conventions and heuristics

- A property named `cloakHandler` becomes an item handler keyed by `.cloak`.
- A property named `trollCombatSystem` is keyed by `.troll` unless `enemyID:` is specified.
- `Fuse`/`Daemon` IDs come from the property name; convenience `.startFuse("id")` and `.runDaemon("id")` also add IDs.
- Global flags are discovered from calls with exactly one argument: e.g., `engine.hasFlag(.foo)`; two‑argument calls are treated as item‑scoped and ignored for `GlobalID` discovery.
- Common non‑ID member names like `name`, `description`, `location`, `in`, `to`, `exits`, `adjectives` are filtered out during ID context checks.

## Limitations

- The scanner is intentionally conservative. If it cannot determine an owning area or key, it inserts a commented placeholder instead of guessing.
- Only obvious patterns are recognized (e.g., explicit `Item(...)`, `Location(...)`, `ItemEventHandler { ... }`). Heavily abstracted factories may not be detected.
- Global ID discovery relies on simple call‑shape analysis; unusual wrappers may not be recognized.
- Test files (ending with `Tests.swift`) are ignored.

## Tips for smooth generation

- Prefer clear, direct initializers for items/locations inside area types.
- Name handler/computer properties with the `ThingHandler` / `ThingComputer` convention.
- Use `enemyID: .thing` in combat systems/messengers when possible for unambiguous keys.
- Keep `static` for shared definitions; omit `static` for per‑blueprint instances.

## Relationship to the build plugin

This CLI mirrors the functionality of the build plugin (`Plugins/GnustoAutoWiringPlugin`) and can be run manually for debugging or pre‑generation. In normal builds, the plugin discovers and generates wiring automatically.

## Troubleshooting

- If expected IDs are missing, check that your code uses recognizable patterns (e.g., `Location(id: .room)`).
- If an area mapping comment appears, move the property into a concrete area or rename to match conventions.
- Re‑run with a minimal `--source` to isolate problems and review the printed discovery summary.
