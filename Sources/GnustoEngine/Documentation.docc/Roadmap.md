# Gnusto Engine Roadmap

## Phase 1: Improved Developer Ergonomics

### 1.1 Handler Registration Improvements ✅ COMPLETED

- [x] ✅ **Implement automatic handler discovery with GnustoAutoWiringPlugin**
  - ✅ Allow handlers to be defined as static properties in game area structs/enums
  - ✅ Use automatic pattern discovery to register handlers via build tool plugin
  - ✅ Provide comprehensive game setup generation including items, locations, handlers, and time registry
  - ✅ Support both static (enum-based) and instance (struct-based) area architectures
- [x] ✅ **Automatic ID constant generation**
  - ✅ Scan `Location(id: .someID, ...)` patterns and generate `LocationID.someID` extensions
  - ✅ Scan `Item(id: .someID, ...)` patterns and generate `ItemID.someID` extensions
  - ✅ Support `GlobalID`, `FuseID`, `DaemonID`, and custom `VerbID` generation
- [x] ✅ **Complete GameBlueprint integration**
  - ✅ Auto-aggregate all items and locations from multiple area files
  - ✅ Auto-wire event handlers with proper scoping
  - ✅ Auto-register fuse and daemon definitions in TimeRegistry

**The GnustoAutoWiringPlugin has eliminated virtually all boilerplate code for game setup!**

### 1.2 State Change Ergonomics

- [ ] Expand `GameEngine+stateChanges.swift` helper methods
  - Add helpers for common state change patterns
  - Support batch state changes
  - Add validation helpers
- [ ] SPIKE: Implement state change composition
  - Allow combining multiple state changes
  - Support conditional state changes
  - Add rollback capabilities

### 1.3 Conditional Exits

- [ ] Design and implement conditional exit system
  - Support dynamic exit conditions
  - Allow exit-specific messages
  - Enable exit state tracking
- [ ] SPIKE: Add builder API for exit definition
  - Support fluent exit configuration
  - Enable conditional exit composition
  - Add validation helpers

### 1.4 Testing Infrastructure

- [ ] Enhance testing support
  - Add helper methods for common test scenarios
  - Implement snapshot testing for game state
  - Add performance testing utilities
- [ ] Improve test documentation
  - Add examples for common test cases
  - Document best practices
  - Create testing templates

## Phase 2: Documentation and Developer Experience

### 2.1 API Documentation

- [x] Create comprehensive API documentation
  - Document all public interfaces
  - Add usage examples
  - Include best practices
- [x] Add inline documentation
  - Document all public methods
  - Add parameter descriptions
  - Include return value documentation

### 2.2 Developer Guides

- [ ] Create getting started guide
  - Basic game setup
  - Common patterns
  - Best practices
- [ ] Write advanced topics guide
  - Custom action handlers
  - State management
  - Performance optimization
- [ ] Add troubleshooting guide
  - Common issues
  - Debugging tips
  - Performance considerations

### 2.3 Example Games

- [ ] Expand example game collection
  - Add more complex examples
  - Include commented code
  - Show different patterns
- [ ] Create tutorial games
  - Step-by-step guides
  - Progressive complexity
  - Best practice examples

### 2.4 Tooling

- [ ] SPIKE: Add development tools
  - Game state visualizer
  - Action handler debugger
  - Performance profiler
- [ ] SPIKE: Create templates
  - Project templates
  - Handler templates
  - Test templates

## Phase 3: Engine Enhancements

### 3.1 Extensibility

- [ ] SPIKE: Design plugin system
  - Custom action handlers
  - State change processors
  - Parser extensions
- [ ] SPIKE: Add middleware support
  - Action preprocessing
  - State change validation
  - Result postprocessing

## Success Metrics

1. **Developer Experience**

   - ✅ **Dramatically reduced boilerplate code** - GnustoAutoWiringPlugin eliminates manual ID generation and game setup
   - ✅ **Faster development cycles** - Plugin handles all the wiring automatically
   - ✅ **Fewer runtime errors** - Compile-time discovery ensures consistent setup

2. **Code Quality**

   - Increased test coverage
   - Reduced complexity
   - Better maintainability

3. **Documentation**
   - Complete API coverage
   - Clear examples
   - Up-to-date guides
