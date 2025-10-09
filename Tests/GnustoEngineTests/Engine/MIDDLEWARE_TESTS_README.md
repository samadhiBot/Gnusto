# Middleware Test Suite

This directory contains comprehensive unit and integration tests for Gnusto's middleware architecture.

## Test Files

### GameEngine+MiddlewareTests.swift
**Purpose**: Unit tests for the middleware system's core functionality in `GameEngine+middleware.swift`.

**Coverage**:
- Middleware registration and removal
- Middleware priority-based sorting and execution order
- Individual hook execution (beforeTurn, beforeCommand, afterCommand, etc.)
- Middleware state persistence (save/restore)
- Result chaining and modification
- Command modification and interception
- Short-circuit behavior (handled/skip results)

**Test Middleware Implementations**:
- `RecordingMiddleware` - Tracks all hook calls for verification
- `CommandModifyingMiddleware` - Modifies commands before execution
- `CommandSkippingMiddleware` - Prevents command execution
- `TurnHandlingMiddleware` - Takes over entire turn processing
- `TimeFreezeMiddleware` - Prevents time advancement
- `MessageAppendingMiddleware` - Chains result modifications

**Key Test Patterns**:
```swift
// Test middleware registration through blueprint
let middleware = await RecordingMiddleware(stateKey: "test", priority: 50)
let game = MinimalGame(middleware: [middleware])
let (engine, _) = await GameEngine.test(blueprint: game)

// Verify hook execution
let result = try await engine.executeBeforeTurnMiddleware()
#expect(await middleware.beforeTurnCalls == 1)

// Test priority ordering
let sorted = await engine.sortedMiddleware
#expect(sorted[0].priority > sorted[1].priority)
```

### GameEngine+GameLoopMiddlewareIntegrationTests.swift
**Purpose**: Integration tests verifying middleware behavior within the full game loop (`GameEngine+gameLoop.swift`).

**Coverage**:
- Hook execution order during complete turn processing
- Middleware interaction with game state (player, items, locations)
- Multiple middleware coordination and priority handling
- Integration with fuse and daemon systems
- Parse error handling with middleware
- Command modification affecting game state
- Event trigger systems implemented via middleware
- Statistics tracking and analytics middleware patterns

**Test Middleware Implementations**:
- `GameLoopTrackingMiddleware` - Records complete hook call sequence
- `StateValidatingMiddleware` - Validates game state at hook points
- `ActionModifyingMiddleware` - Demonstrates command transformation
- `ContextualMessageMiddleware` - Adds location-aware messages
- `EventTriggerMiddleware` - Implements event system via middleware
- `StatisticsMiddleware` - Tracks game statistics across turns

**Key Test Patterns**:
```swift
// Verify complete hook sequence in a turn
try await engine.processTurn()
let sequence = await tracker.sequence
#expect(sequence == [
    "beforeTurn",
    "beforeCommandExecution", 
    "afterCommandExecution",
    "beforeTimeAdvancement",
    "afterTurn"
])

// Test middleware modifying game state
try await engine.execute("take item")
let item = await engine.item("item")
#expect(await item.parent == .player)
```

## Test Coverage Goals

The middleware test suite aims for 80-90% coverage of:
- `Sources/GnustoEngine/Engine/GameEngine+middleware.swift`
- `Sources/GnustoEngine/Engine/GameEngine+gameLoop.swift`
- `Sources/GnustoEngine/Middleware/GnustoMiddleware.swift`

## Running Tests

### All Middleware Tests
```bash
swift test --filter GameEngineMiddlewareTests
swift test --filter GameEngineGameLoopMiddlewareIntegrationTests
```

### Specific Test Suites
```bash
# Unit tests only
swift test --filter "GameEngine Middleware System"

# Integration tests only  
swift test --filter "GameEngine Game Loop Middleware Integration"
```

### Individual Tests
```bash
# Example: Test priority ordering
swift test --filter "testSortedMiddleware"

# Example: Test hook execution order
swift test --filter "testMiddlewareHookExecutionOrder"
```

## Test Architecture

### Unit Tests Philosophy
- Test middleware system in isolation
- Mock/simulate minimal game state
- Verify individual hook behavior
- Test priority ordering and execution flow
- Validate state persistence mechanisms

### Integration Tests Philosophy
- Test middleware within full game loop
- Use realistic game scenarios
- Verify interaction with fuses, daemons, parser
- Test multiple middleware coordination
- Validate complete turn processing flow

## Common Test Patterns

### Recording Middleware Pattern
Used to verify hooks are called:
```swift
actor RecordingMiddleware: GnustoMiddleware {
    private(set) var beforeTurnCalls = 0
    
    func beforeTurn(context: MiddlewareContext) async throws -> MiddlewareResult {
        beforeTurnCalls += 1
        return .continue
    }
}

// Register and test:
let middleware = await RecordingMiddleware(stateKey: "test", priority: 50)
let game = MinimalGame(middleware: [middleware])
let (engine, _) = await GameEngine.test(blueprint: game)

#expect(await middleware.beforeTurnCalls == 1)
```

### Sequence Tracking Pattern
Verifies execution order:
```swift
actor SequenceTracker {
    var sequence: [String] = []
    func record(_ event: String) {
        sequence.append(event)
    }
}

// Verify order:
#expect(sequence == ["beforeTurn", "beforeCommand", "afterCommand"])
```

### Result Chaining Pattern
Tests middleware chaining modifications:
```swift
struct MessageAppender: GnustoMiddleware {
    func afterCommandExecution(...) async throws -> ActionResult {
        return result.appending(ActionResult("Added message"))
    }
}

// Verify chaining:
await mockIO.expect(
    """
    Original message
    
    Added message
    """
)
```

### Short-Circuit Pattern
Tests early exit behavior:
```swift
struct EarlyExitMiddleware: GnustoMiddleware {
    func beforeTurn(context: MiddlewareContext) async throws -> MiddlewareResult {
        return .handled(ActionResult("Intercepted!"))
    }
}

// Verify remaining hooks not called:
#expect(await tracker.afterCommandCalls == 0)
```

## Testing Guidelines

### Do
✅ Register middleware through `MinimalGame(middleware: [...])`
✅ Test through full game loop (`engine.processTurn()` or `engine.execute()`)
✅ Verify exact output with `mockIO.expect()`
✅ Test middleware in priority order scenarios
✅ Verify state changes via `await engine.item()`, `await engine.player`, etc.
✅ Test both success and error paths
✅ Use actor-based middleware for thread safety

### Don't
❌ Use `registerMiddleware()` or `removeMiddleware()` (these have been removed)
❌ Test middleware hooks in isolation (bypasses integration)
❌ Rely on `output.contains()` - use exact matching
❌ Assume execution order without priority specification
❌ Mutate game state directly - use StateChange objects
❌ Create middleware with side effects in tests

## Future Test Additions

As new middleware features are added, tests should cover:
- [ ] Middleware error handling and recovery
- [ ] Middleware performance profiling
- [ ] Middleware dependency injection patterns
- [ ] Advanced state migration scenarios
- [ ] Middleware conflict resolution
- [ ] Nested middleware execution

## Debugging Failed Tests

### Common Issues

**Issue**: Middleware hook not called
- Check middleware is registered in blueprint: `MinimalGame(middleware: [...])`
- Verify middleware appears in: `await engine.sortedMiddleware`
- Verify priority doesn't cause early exit
- Ensure hook returns `.continue` to allow chaining

**Issue**: Incorrect execution order
- Check middleware priority values
- Verify `sortedMiddleware` returns expected order
- Higher priority = executes first

**Issue**: State changes not visible
- Use `await` when accessing engine state
- Access via proxies, not direct objects
- Verify changes applied via `ActionResult`

**Issue**: Output doesn't match expected
- Check for extra whitespace or newlines
- Verify all middleware messages included
- Use `mockIO.expect()` not `contains()`

### Debugging Commands
```bash
# Verbose test output
swift test --filter testName --verbose

# Show test list
swift test --list-tests

# Run specific test file
swift test --filter GameEngineMiddlewareTests

# Enable test parallelization
swift test --parallel
```

## Related Documentation

- `Sources/GnustoEngine/Documentation.docc/Middleware.md` - Middleware architecture guide
- `Sources/GnustoEngine/Middleware/GnustoMiddleware.swift` - Protocol definition
- `Sources/GnustoEngine/Engine/GameEngine+middleware.swift` - Implementation
- `Sources/GnustoEngine/Engine/GameEngine+gameLoop.swift` - Integration points
- `.rules` - Project coding standards and testing requirements

## Contributing

When adding new middleware tests:
1. Follow existing naming patterns (`test[FeatureName][Behavior]`)
2. Add descriptive `@Test("description")` annotations
3. Use appropriate test middleware from existing patterns
4. Add integration tests for game loop interaction
5. Update this README with new test coverage
6. Ensure 80-90% coverage for pull requests