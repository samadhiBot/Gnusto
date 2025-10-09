# Middleware Test Updates

## Summary

All middleware tests have been updated to register middleware through the `MinimalGame` blueprint instead of using the now-removed `registerMiddleware()` and `removeMiddleware()` methods.

## Changes Made

### Pattern Change

**Before** (using `registerMiddleware`):
```swift
@Test("registerMiddleware adds middleware to engine")
func testRegisterMiddleware() async throws {
    let game = MinimalGame()
    let (engine, _) = await GameEngine.test(blueprint: game)

    let middleware = await RecordingMiddleware(stateKey: "test", priority: 50)
    await engine.registerMiddleware(middleware)

    let sortedMiddleware = await engine.sortedMiddleware
    #expect(sortedMiddleware.count == 1)
}
```

**After** (using blueprint registration):
```swift
@Test("middleware registered through blueprint")
func testMiddlewareRegisteredThroughBlueprint() async throws {
    let middleware = RecordingMiddleware(stateKey: "test", priority: 50)
    let game = MinimalGame(middleware: [middleware])
    let (engine, _) = await GameEngine.test(blueprint: game)

    let sortedMiddleware = await engine.sortedMiddleware
    #expect(sortedMiddleware.count == 1)
}
```

### Files Updated

1. **`GameEngine+MiddlewareTests.swift`**
   - Updated all 25+ tests to register middleware through `MinimalGame`
   - Removed all `await engine.registerMiddleware()` calls
   - Removed all `await engine.removeMiddleware()` calls
   - Renamed test functions to reflect new registration pattern:
     - `testRegisterMiddleware()` → `testMiddlewareRegisteredThroughBlueprint()`
     - `testRemoveMiddleware()` → `testMultipleMiddlewareRegisteredThroughBlueprint()`
   - Removed unnecessary `await` keywords from `RecordingMiddleware` initializer calls

2. **`MIDDLEWARE_TESTS_README.md`**
   - Updated all example code to show blueprint registration
   - Added guideline: ✅ Register middleware through `MinimalGame(middleware: [...])`
   - Added guideline: ❌ Use `registerMiddleware()` or `removeMiddleware()` (these have been removed)
   - Removed future test item: "Middleware hot-swapping/dynamic registration"
   - Updated debugging section to reference blueprint registration

3. **`GameEngine+GameLoopMiddlewareIntegrationTests.swift`**
   - No changes needed - already used blueprint registration pattern

## Test Coverage Maintained

All test coverage remains intact:
- ✅ Middleware priority-based execution order
- ✅ Hook execution (beforeTurn, beforeCommand, afterCommand, etc.)
- ✅ State persistence (save/restore)
- ✅ Result chaining and modification
- ✅ Command interception and modification
- ✅ Short-circuit behavior
- ✅ Integration with game loop
- ✅ Multiple middleware coordination

## Benefits of This Change

1. **Single Source of Truth**: Middleware is now only configured in one place - the blueprint
2. **No Confusion**: Eliminates questions about when to use `registerMiddleware()` vs blueprint
3. **Consistency**: All game configuration follows the same pattern
4. **Testability**: Tests more accurately reflect how games will actually configure middleware
5. **Immutability**: Middleware list is set at blueprint creation, preventing runtime modifications

## Migration Guide for Other Tests

If you have custom tests that use `registerMiddleware()`, update them like this:

```swift
// OLD PATTERN
let game = MinimalGame()
let (engine, _) = await GameEngine.test(blueprint: game)
let middleware = MyMiddleware()
await engine.registerMiddleware(middleware)

// NEW PATTERN
let middleware = MyMiddleware()
let game = MinimalGame(middleware: [middleware])
let (engine, _) = await GameEngine.test(blueprint: game)
```

## Verification

All tests compile successfully with only warnings about unnecessary `await` on actor initializers (which have been fixed).

```bash
# Run middleware tests
swift test --filter GameEngineMiddlewareTests
swift test --filter GameEngineGameLoopMiddlewareIntegrationTests

# Verify no registerMiddleware calls remain
grep -r "registerMiddleware" Tests/GnustoEngineTests/Engine/GameEngine+*MiddlewareTests.swift
# Should return no results
```

## Related Changes Needed

The following files should also be updated to remove `registerMiddleware()` and `removeMiddleware()` methods:

- `Sources/GnustoEngine/Engine/GameEngine+middleware.swift` - Remove public methods
- `Sources/GnustoEngine/Documentation.docc/Middleware.md` - Update documentation
- Any other test files that might use these methods

## Date

January 2025