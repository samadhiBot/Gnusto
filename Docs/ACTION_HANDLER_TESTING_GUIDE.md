# Action Handler Testing Guide

This document outlines the systematic approach for testing action handlers in the Gnusto Interactive Fiction Engine.

## Core Testing Principles

### 1. Test Structure

Each action handler should have comprehensive tests covering three main areas:

- **Syntax Rule Validation**: Verify that all supported syntax patterns work and unsupported patterns fail
- **Action Validation**: Test all prerequisite checks and their error messages
- **Action Processing**: Verify that successful actions produce the expected state changes

**CRITICAL PRINCIPLE: Always test through the full engine pipeline!**

Testing action handlers in isolation by calling `handler.perform(command, engine)` directly bypasses the parser and can miss critical bugs in:

- Verb recognition and disambiguation
- Object resolution and scope handling
- Syntax pattern matching
- Command parsing edge cases
- Integration between parser and action handlers

Use `engine.execute("command string")` to test the complete flow from raw input to final output.

### 2. Test Organization

- Use descriptive test names that clearly indicate what is being tested
- Group related tests using `@Suite` when appropriate
- Test both success and failure cases for each scenario

### 3. Required Test Setup

**CRITICAL: Always test through the full pipeline, including the parser!**

```swift
@Test("Description of what is being tested")
func testSomething() async throws {
    // Given: Setup game state
    let testRoom = Location(
        id: "testRoom",
        .name("Test Room"),
        .description("A room for testing."),
        .inherentlyLit
    )

    let testItem = Item(
        id: "testItem",
        .name("test item"),
        .description("An item for testing."),
        .isTakable,
        .in(.location("testRoom"))
    )

    let game = MinimalGame(
        player: Player(in: "testRoom"),
        locations: testRoom,
        items: testItem
    )

    let (engine, mockIO) = await GameEngine.test(blueprint: game)

    // When: Execute through the full pipeline (parser + action handler)
    try await engine.execute("take test item")

    // Then: Verify results
    let output = await mockIO.flush()
    expectNoDifference(output, """
        > take test item
        Taken.
        """)

    // Verify state changes
    let finalState = await engine.itemSnapshot(with: "testItem")
    #expect(finalState?.parent == .player)
}
```

**❌ WRONG - Don't skip the parser:**

```swift
// This bypasses the parser and misses real bugs!
let command = Command(verbID: "take", directObject: "testItem", rawInput: "take test item")
try await handler.perform(command: command, engine: engine)
```

**✅ RIGHT - Test the full pipeline:**

```swift
// This tests the complete flow: input → parser → action handler → output
try await engine.execute("take test item")
```

## Syntax Rule Testing

### Test Every Supported Pattern

For each syntax rule defined in the handler, create a test that verifies it works:

```swift
// If handler has: .match(.turn, .on, .directObject)
@Test("TURN ON syntax works")
func testTurnOnSyntax() async throws {
    // Test "turn on lamp" works
}

// If handler has: .match(.light, .directObject)
@Test("LIGHT syntax works")
func testLightSyntax() async throws {
    // Test "light lamp" works
}
```

### Test Unsupported Patterns

Verify that patterns NOT in the syntax rules fail appropriately:

```swift
@Test("Invalid syntax patterns are rejected")
func testInvalidSyntax() async throws {
    // Test that "turn lamp" fails (missing "on")
    // Test that "extinguish off lamp" fails (wrong verb combination)
}
```

## Validation Testing

### Test All Prerequisites

For each validation check in the handler, create dedicated tests:

```swift
@Test("Requires item to be held")
func testRequiresItemHeld() async throws {
    // Setup: Item not held by player
    // When: Try to perform action
    // Then: Should fail with appropriate message
    let output = await mockIO.flush()
    expectNoDifference(output, "You aren't holding the lamp.")
}

@Test("Requires item to be accessible")
func testRequiresItemAccessible() async throws {
    // Setup: Item not in scope
    // When: Try to perform action
    // Then: Should fail with appropriate message
}
```

### Test Light Requirements

If the handler has `requiresLight: true`:

```swift
@Test("Requires light to perform action")
func testRequiresLight() async throws {
    // Setup: Dark room, no light sources
    // When: Try to perform action
    // Then: Should fail with darkness message
    let output = await mockIO.flush()
    expectNoDifference(output, "It is pitch black. You can't see a thing.")
}
```

## Processing Testing

### Test Successful State Changes

Verify that successful actions produce the expected state modifications:

```swift
@Test("Turn on sets isOn property")
func testTurnOnSetsProperty() async throws {
    // Given: Lamp that can be turned on
    let testRoom = Location(
        id: "testRoom",
        .name("Test Room"),
        .inherentlyLit
    )

    let lamp = Item(
        id: "lamp",
        .name("brass lamp"),
        .description("A shiny brass lamp."),
        .isTakable,
        .isLightSource,
        .in(.player)
    )

    let game = MinimalGame(
        player: Player(in: "testRoom"),
        locations: testRoom,
        items: lamp
    )

    let (engine, mockIO) = await GameEngine.test(blueprint: game)

    // When: Turn on the lamp through full pipeline
    try await engine.execute("turn on lamp")

    // Then: Lamp should have .isOn property
    let finalState = await engine.itemSnapshot(with: "lamp")
    #expect(finalState?.hasProperty(.isOn) == true)

    // Verify the message too
    let output = await mockIO.flush()
    expectNoDifference(output, """
        > turn on lamp
        The brass lamp is now on.
        """)
}
```

### Test Side Effects

Verify additional effects like lighting changes, score updates, etc.:

```swift
@Test("Turning on light source illuminates room")
func testLightSourceIllumination() async throws {
    // Given: Dark room with light source
    // When: Turn on light source
    // Then: Room should become lit
    let isLit = await engine.isCurrentLocationLit()
    #expect(isLit == true)
}
```

## Message Testing

### Use Exact Message Matching

**NEVER** use `.contains()` patterns. Always test exact message output:

```swift
// ❌ WRONG - Don't use contains()
#expect(output.contains("You turn on"))

// ✅ RIGHT - Use exact matching
let output = await mockIO.flush()
expectNoDifference(output, "You turn on the lamp.")
```

### Test All Message Scenarios

Create tests for each possible message the handler can produce:

```swift
@Test("Success message for turning on lamp")
func testSuccessMessage() async throws {
    // Test successful action message
}

@Test("Already on message")
func testAlreadyOnMessage() async throws {
    // Test message when item is already on
}

@Test("Cannot turn on message")
func testCannotTurnOnMessage() async throws {
    // Test message when item cannot be turned on
}
```

## ActionID Testing

### Test Conceptual Action Mapping

Verify that handlers correctly expose their conceptual actions:

```swift
@Test("Handler exposes correct ActionIDs")
func testActionIDs() async throws {
    let handler = TurnOnActionHandler()
    #expect(handler.actions.contains(.lightSource))
    #expect(handler.actions.contains(.burn))
}
```

### Test ActionID Queries

Test that the engine can find handlers by conceptual action:

```swift
@Test("Engine finds handler by ActionID")
func testEngineFindsHandlerByActionID() async throws {
    let handlers = await engine.actionHandlers(for: .lightSource)
    #expect(handlers.count > 0)
}
```

## Test Data Organization

### Use Realistic Test Items

Create test items that represent real game scenarios:

```swift
// Good test items
let lamp = Item(
    id: "lamp",
    name: "brass lamp",
    longDescription: "A shiny brass lamp.",
    properties: [.takable, .lightSource],
    parent: .player
)

let torch = Item(
    id: "torch",
    name: "wooden torch",
    longDescription: "A wooden torch with an unlit tip.",
    properties: [.takable, .lightSource, .flammable],
    parent: .location("startingRoom")
)
```

### Use Descriptive Test Names

Test names should clearly indicate the scenario being tested:

```swift
@Test("Turn on lamp when held succeeds")
@Test("Turn on lamp when not held fails with not held message")
@Test("Turn on already lit lamp fails with already on message")
@Test("Turn on non-light-source fails with cannot turn on message")
```

## Coverage Requirements

### Minimum Test Coverage

Each action handler should have tests covering:

- ✅ All syntax rules (positive cases)
- ✅ Invalid syntax patterns (negative cases)
- ✅ All validation checks (both pass and fail)
- ✅ All possible processing outcomes
- ✅ All possible message outputs
- ✅ State changes and side effects
- ✅ ActionID exposure and mapping

### Integration Testing

Include tests that verify the handler works within the full engine context:

- Parser integration (real command parsing)
- Game state persistence
- Cross-handler interactions

## Anti-Patterns to Avoid

### ❌ Don't Test Implementation Details

```swift
// Wrong - testing internal method calls
#expect(handler.validate(context) throws)

// Right - testing external behavior
let output = await mockIO.flush()
expectNoDifference(output, "You aren't holding that.")
```

### ❌ Don't Use Brittle Message Matching

```swift
// Wrong - fragile partial matching
#expect(output.contains("turn"))

// Right - exact message verification
expectNoDifference(output, "You turn on the lamp.")
```

### ❌ Don't Skip Negative Test Cases

Always test both success and failure scenarios for each validation check.

### ❌ Don't Use Overly Complex Test Setup

Keep test setup minimal and focused on the specific scenario being tested.

## Testing Tools Reference

### Essential Imports

```swift
import Testing
import CustomDump
@testable import GnustoEngine
```

### Common Test Patterns

```swift
// ✅ RIGHT - Standard test setup with full pipeline testing
let testRoom = Location(
    id: "testRoom",
    .name("Test Room"),
    .inherentlyLit
)

let testItem = Item(
    id: "testItem",
    .name("test item"),
    .isTakable,
    .in(.location("testRoom"))
)

let game = MinimalGame(
    player: Player(in: "testRoom"),
    locations: testRoom,
    items: testItem
)

let (engine, mockIO) = await GameEngine.test(blueprint: game)

// Command execution through full pipeline
try await engine.execute("take test item")

// Output verification (includes command echo)
let output = await mockIO.flush()
expectNoDifference(output, """
    > take test item
    Taken.
    """)

// State verification
let finalState = await engine.itemSnapshot(with: "testItem")
#expect(finalState?.parent == .player)
```

### Anti-Pattern Examples

```swift
// ❌ WRONG - Bypassing the parser
let command = Command(verbID: "take", directObject: "testItem", rawInput: "take test item")
try await handler.perform(command: command, engine: engine)

// ❌ WRONG - Manual mock setup instead of GameEngine.test()
let mockIO = await MockIOHandler()
let mockParser = MockParser()
let engine = GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

// ❌ WRONG - Not including command echo in expectations
expectNoDifference(output, "Taken.")  // Missing "> take test item\n"
```

## Engine Helper Methods & Patterns

### GameEngine State Query Methods

These are the correct methods to use when verifying game state in tests:

```swift
// ✅ RIGHT - Getting item state
let item = try await engine.item("itemID")  // Returns Item, throws if not found
#expect(item.parent == .player)
#expect(item.hasFlag(.isOn) == true)
#expect(item.hasFlag(.isLit) == false)

// ❌ WRONG - Don't use these non-existent methods
let item = await engine.itemSnapshot(with: "itemID")  // This method doesn't exist!
```

### Item Property/Flag Checking

Use `hasFlag()` to check item properties:

```swift
// ✅ RIGHT - Checking item flags/properties
let lamp = try await engine.item("lamp")
#expect(lamp.hasFlag(.isOn) == true)
#expect(lamp.hasFlag(.isLit) == true)
#expect(lamp.hasFlag(.isTakable) == true)
#expect(lamp.hasFlag(.isDevice) == true)
#expect(lamp.hasFlag(.isLightSource) == true)

// ❌ WRONG - Don't use these patterns
#expect(lamp.properties.contains(.isOn))  // More verbose
#expect(lamp.hasProperty(.touched))       // Method doesn't exist
```

### Common Item Setup Patterns

Based on testing, here are the correct item flag combinations for common game objects:

#### Light Sources (Lamps, Torches, Candles)

```swift
let lamp = Item(
    id: "lamp",
    .name("brass lamp"),
    .description("A shiny brass lamp."),
    .isTakable,
    .isLightSource,  // Makes it a light source
    .isDevice,       // REQUIRED for TurnOnActionHandler to work!
    .in(.location("room"))
)

// When testing, note that TurnOnActionHandler sets .isOn, not .isLit
// Light sources might need both flags for proper illumination
```

#### Items That Can't Be Taken

```swift
let statue = Item(
    id: "statue",
    .name("stone statue"),
    .description("A heavy stone statue."),
    // Note: No .isTakable flag - this makes it untakeable
    .in(.location("room"))
)
```

#### Items Already Held by Player

```swift
let book = Item(
    id: "book",
    .name("leather book"),
    .description("A worn leather-bound book."),
    .isTakable,
    .in(.player)  // Already in player's inventory
)
```

### Location Setup Patterns

#### Lit Rooms (Default for Most Tests)

```swift
let testRoom = Location(
    id: "testRoom",
    .name("Test Room"),
    .description("A room for testing."),
    .inherentlyLit  // IMPORTANT: Most tests need this for visibility
)
```

#### Dark Rooms (For Darkness Testing)

```swift
let darkRoom = Location(
    id: "darkRoom",
    .name("Dark Room"),
    .description("A room that is pitch black if you aren't carrying a light.")
    // Note: No .inherentlyLit - this makes it dark
)
```

### Game Test Setup Pattern

Always use this standard pattern for test setup:

```swift
@Test("Test description")
func testSomething() async throws {
    // Given: Setup complete game state
    let testRoom = Location(
        id: "testRoom",
        .name("Test Room"),
        .inherentlyLit
    )

    let testItem = Item(
        id: "testItem",
        .name("test item"),
        .isTakable,
        .in(.location("testRoom"))
    )

    let game = MinimalGame(
        player: Player(in: "testRoom"),
        locations: testRoom,
        items: testItem
    )

    let (engine, mockIO) = await GameEngine.test(blueprint: game)

    // When: Execute command through full pipeline
    try await engine.execute("take test item")

    // Then: Verify output and state
    let output = await mockIO.flush()
    expectNoDifference(output, """
        > take test item
        Taken.
        """)

    let finalState = try await engine.item("testItem")
    #expect(finalState.parent == .player)
}
```

### Syntax Rule Best Practices

#### Always Use Clean, Readable Syntax

```swift
// ✅ RIGHT - Clean, readable syntax
public let syntax: [SyntaxRule] = [
    .match(.light, .directObject),           // "light lamp"
    .match(.turn, .on, .directObject),       // "turn on lamp"
    .match(.switch, .on, .directObject),     // "switch on lamp"
]

// ❌ WRONG - Verbose, ugly syntax (avoid this!)
public let syntax: [SyntaxRule] = [
    .match(.specificVerb(.light), .directObject),
    .match(.specificVerb(.turn), .on, .directObject),
    .match(.specificVerb(.switch), .on, .directObject),
]
```

The clean syntax works perfectly when action handlers are ordered correctly in `GameEngine.defaultActionHandlers`. If you encounter verb conflicts (e.g., both `TurnOnActionHandler` and `BurnActionHandler` want to handle "light"), solve it by **reordering the handlers**, not by switching to verbose syntax.

#### Handler Registration Order Matters

Syntax-based handlers (those with complex patterns like "turn on") should come **before** simple verb-based handlers to avoid conflicts:

```swift
// ✅ RIGHT - Syntax-based handler comes first
TurnOnActionHandler(),  // Has syntax: .match(.turn, .on, .directObject)
TurnActionHandler(),    // Has verbs: [.turn] - simpler matching

// ❌ WRONG - Simple handler steals "turn" verb before syntax can match
TurnActionHandler(),    // Matches "turn" and stops looking
TurnOnActionHandler(),  // Never gets a chance to match "turn on"
```

### Action Handler Discovery Patterns

#### Handler Requirements by Action Type

Through testing, here are the flag requirements for common action handlers:

**TurnOnActionHandler**:

- Requires: `.isDevice` flag (critical!)
- Sets: `.isOn` flag when successful
- Also works with: `.isLightSource` items
- Syntax: `"turn on item"`, `"light item"`, `"switch on item"`

**TakeActionHandler**:

- Requires: `.isTakable` flag
- Requires: Item must be visible/accessible
- Sets: `.isTouched` flag when successful (not tested in our examples)

**BurnActionHandler**:

- Note: Has `.light` in its verbs, can conflict with TurnOnActionHandler
- Handler order matters for verb conflicts!

#### Handler Order Dependencies

Some handlers conflict with each other based on shared verbs. The order in `GameEngine.defaultActionHandlers` matters:

```swift
// TurnOnActionHandler must come BEFORE BurnActionHandler
// because both handle the "light" verb, but with different syntax rules
TurnOnActionHandler(),  // Handles "light lamp" with syntax rules
BurnActionHandler(),    // Handles "light fire" with simpler verb matching
```

**IMPORTANT:** Always use the clean syntax like `.match(.turn, .on, .directObject)` instead of `.match(.specificVerb(.turn), .on, .directObject)`. The readable syntax works correctly when handlers are ordered properly. Handler order conflicts should be solved by reordering handlers in `GameEngine.defaultActionHandlers`, NOT by changing to the verbose `.specificVerb()` syntax.

### Common Testing Pitfalls & Solutions

#### Message Format Differences

```swift
// Tests often fail due to message format differences.
// Update expectations to match actual engine output:

// Engine generates specific messages:
expectNoDifference(output, "You can't turn that on.")           // Not "You can't turn on the X"
expectNoDifference(output, "It's already on.")                  // Not "The X is already on"
expectNoDifference(output, "You can't see any such thing.")     // Not "You can't see any X here"
expectNoDifference(output, "You already have that.")            // Not "You already have the X"
```

#### Dark Room Testing

```swift
// When testing in dark rooms, the lamp should usually be held by player:
let lamp = Item(
    id: "lamp",
    .isLightSource,
    .isDevice,
    .in(.player)  // Player carries the lamp into the dark room
)

// This way "turn on lamp" will work and illuminate the room
```

#### Quote Character Issues

Per the testing guide, ignore any test failures that appear to be only about quote/apostrophe character differences (`'` vs `'` or `"` vs `"`). These are visual artifacts of Markdown rendering and should not be "fixed".

### State Verification Patterns

```swift
// ✅ RIGHT - Checking final item state
let finalItem = try await engine.item("itemID")
#expect(finalItem.parent == .player)
#expect(finalItem.hasFlag(.isOn) == true)

// ✅ RIGHT - Checking location state
let isLit = await engine.isCurrentLocationLit()
#expect(isLit == true)

// ✅ RIGHT - Checking global game state
let hasKey = await engine.hasGlobal(.someGlobalFlag)
#expect(hasKey == true)
```

### Mock Output Testing

```swift
// ✅ RIGHT - Always include command echo in expectations
let output = await mockIO.flush()
expectNoDifference(output, """
    > turn on lamp
    The brass lamp is now on.
    """)

// ❌ WRONG - Missing command echo
expectNoDifference(output, "The brass lamp is now on.")

// ✅ RIGHT - Multi-line output with room descriptions
expectNoDifference(output, """
    > turn on lamp
    The brass lamp is now on. You can see your surroundings now.

    — Dark Room —

    A room that is pitch black if you aren't carrying a light.
    """)
```
