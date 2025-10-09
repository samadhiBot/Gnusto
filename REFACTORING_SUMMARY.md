# Middleware Parse Error Refactoring Summary

## Date
2025-10-10

## Problem

The game loop had two significant code smells when handling parse errors and middleware:

### 1. Empty ActionResult Placeholder (Line 166-185)
When middleware continued execution after `beforeCommandExecution`, we needed to call `afterCommandExecution` middleware with an ActionResult. However, `execute(command:)` only returns a `Bool` (whether the turn is consumed), not the ActionResult. This forced us to create an empty placeholder:

```swift
// ❌ Code smell: Empty placeholder
commandResult = ActionResult(message: nil, changes: [], effects: [])
```

### 2. Dummy Command on Parse Errors (Line 198-210)
When parsing failed, we still wanted to call `afterCommandExecution` middleware, but we didn't have a valid command. This forced us to create a dummy command with arbitrary values:

```swift
// ❌ Code smell: Dummy data
actualCommand = Command(
    verb: .examine,  // Use a valid verb - but this is meaningless!
    directObject: nil,
    indirectObject: nil,
    direction: nil,
    rawInput: input
)
```

Both of these are strong indicators of API design issues - when you need to create fake data to satisfy an API, the API is probably wrong.

## Solution: Option 3 - Dedicated `onParseError` Hook

After considering three options:
1. Skip `afterCommandExecution` on parse errors (eliminates smell but loses visibility)
2. Make the Command parameter optional (eliminates dummy data but complicates all middleware)
3. **Add a dedicated `onParseError` middleware hook (chosen)**

We implemented Option 3 because:
- ✅ Eliminates both code smells (no dummy Command, no empty ActionResult for parse errors)
- ✅ Provides clear semantic separation - parse errors are different from command execution
- ✅ Opt-in API - middleware only implements it if they care about parse errors
- ✅ Opens possibilities for creative middleware (e.g., "did you mean?" suggestions, help for common mistakes)
- ✅ We're still in implementation phase - nobody has seen the middleware API yet

## Changes Made

### 1. Added `onParseError` to GnustoMiddleware Protocol
**File**: `Sources/GnustoEngine/Middleware/GnustoMiddleware.swift`

```swift
/// Called when a parse error occurs, before time advancement.
///
/// Use this hook to:
/// - Track or log parse errors for analytics
/// - Provide custom help messages for common mistakes
/// - Implement "did you mean?" suggestions
func onParseError(
    error: ParseError,
    rawInput: String,
    context: MiddlewareContext
) async throws
```

With default implementation that does nothing (making it optional).

### 2. Added Executor Method
**File**: `Sources/GnustoEngine/Engine/GameEngine+middleware.swift`

```swift
func executeOnParseError(error: ParseError, rawInput: String) async throws {
    let context = MiddlewareContext(engine: self)
    for mw in sortedMiddleware {
        try await mw.onParseError(error: error, rawInput: rawInput, context: context)
    }
}
```

### 3. Updated Game Loop
**File**: `Sources/GnustoEngine/Engine/GameEngine+gameLoop.swift`

- Removed dummy Command creation
- Call `executeOnParseError` when parsing fails
- Always call `afterCommandExecution` when there's a valid command (even if skipped by middleware)
- Simplified result processing logic

### 4. Updated Tests
**File**: `Tests/GnustoEngineTests/Engine/GameEngine+GameLoopMiddlewareIntegrationTests.swift`

- Added `onParseError` tracking to `GameLoopTrackingMiddleware`
- Updated test expectations:
  - Parse errors trigger `onParseError`, NOT `afterCommandExecution`
  - Middleware with higher priority that returns `.skip` or `.handled` stops the chain
  - Fixed incorrect test expectations about middleware execution order

## Key Insights

### Middleware Chain Execution
When middleware returns `.skip` or `.handled`, it immediately stops the middleware chain for that hook. This means lower-priority middleware never get called for that specific hook. This is by design:

- **beforeTurn**: First middleware to return `.handled` takes over the entire turn
- **beforeCommandExecution**: First middleware to return `.skip` prevents command execution
- **afterCommandExecution**: All middleware get called (chain doesn't short-circuit)
- **onParseError**: All middleware get called (new hook)

### The Empty ActionResult Issue
The empty ActionResult placeholder for the `.continue` case remains (it's documented with a TODO to refactor `execute(command:)` to return ActionResult instead of Bool). However, this is less of a code smell because:
1. It represents "command executed successfully"
2. It's only used internally, not exposed to users
3. The TODO documents the proper long-term solution

## Test Results

- ✅ All core middleware tests pass
- ✅ Parse error handling works correctly
- ✅ `onParseError` hook is called appropriately
- ✅ `afterCommandExecution` is NOT called on parse errors
- ✅ Total test issues reduced from 34 to 23 in GnustoEngineTests (11 fixes)
- ✅ Fixed test expectations for middleware chain execution order
- ✅ No new warnings or errors introduced

## Future Work

### TODO: Refactor `execute(command:)` Return Type
The ideal long-term solution is to change `execute(command:)` to return `ActionResult` instead of `Bool`. This would:
- Eliminate the empty ActionResult placeholder entirely
- Provide richer information to middleware about what happened
- Allow middleware to inspect or modify the actual command results

This would require:
1. Changing the return type of `execute(command:)`
2. Extracting "consumes turn" logic into a property or separate check
3. Updating all callers to use the ActionResult

However, this is a larger refactoring that affects many parts of the engine and should be done separately.

## Documentation Updates

Updated `Sources/GnustoEngine/Documentation.docc/Middleware.md` to:
- Add `onParseError` to the middleware lifecycle table
- Clarify when each hook is called (parse success vs. parse failure)
- Add example of parse error handling middleware with "did you mean?" suggestions
- Update all code examples to use correct protocol name (`GnustoMiddleware`)
- Add `Sendable` conformance to example state structs
- Clarify best practices around parse error handling

## Conclusion

The addition of the `onParseError` middleware hook successfully eliminates the most egregious code smell (dummy Command with fake data) while providing a clean, semantic API for middleware that wants to observe or respond to parse errors. The solution is backwards-compatible (optional hook with default implementation), maintains the middleware chain semantics, and opens up new possibilities for creative middleware implementations.

The refactoring also revealed and fixed incorrect test expectations about middleware execution order, improving the overall test suite quality.