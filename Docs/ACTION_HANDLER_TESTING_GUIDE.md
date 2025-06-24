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
