# Gnusto Engine Roadmap

## Phase 1: Improved Developer Ergonomics

### 1.1 Handler Registration Improvements

- [x] Implement reflection-based handler discovery for `ItemEventHandler` and `LocationActionHandler`
  - Allow handlers to be defined as static methods in the same struct as items/locations
  - Use naming conventions (e.g., `{itemID}Handler`) to automatically register handlers
  - Provide compile-time validation of handler signatures
- [ ] SPIKE: Add builder-style API for handler registration
  - Support fluent chaining of handler registrations
  - Enable type-safe handler composition
  - Allow conditional handler registration

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

   - Reduced boilerplate code
   - Faster development cycles
   - Fewer runtime errors

2. **Code Quality**

   - Increased test coverage
   - Reduced complexity
   - Better maintainability

3. **Documentation**
   - Complete API coverage
   - Clear examples
   - Up-to-date guides
