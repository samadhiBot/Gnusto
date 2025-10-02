# Contributing to Gnusto

Thank you for your interest in contributing to the Gnusto Interactive Fiction Engine! We welcome all kinds of contributions, from bug reports and documentation improvements to new features and example games.

## Code of Conduct

**Be kind, be curious.**. We're building a welcoming community where everyone can learn, contribute, and enjoy creating interactive fiction together.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally: `git clone https://github.com/your-username/Gnusto.git`
3. **Install Swift 6.2+** from [swift.org](https://swift.org/download/)
4. **Build and test** to ensure everything works: `swift build && swift test`
5. **Run the example games** to get familiar with the engine: `swift run CloakOfDarkness`

## Ways to Contribute

### 🐛 Bug Reports
- Use the [GitHub issue tracker](https://github.com/samadhiBot/Gnusto/issues)
- Include your Swift version, OS, and steps to reproduce
- Provide example code when possible
- Check if the issue already exists before creating a new one

### 📖 Documentation
- Fix typos or unclear explanations
- Add examples to existing documentation
- Write tutorials or guides
- Improve code comments and API documentation

### ✨ Features
- Discuss new features in issues before implementing
- Start with small improvements to get familiar with the codebase
- Focus on areas marked as needing improvement (combat, NPCs, etc.)
- Consider backward compatibility

### 🎮 Example Games
- Port classic IF games (with appropriate licensing)
- Create original games demonstrating engine features
- Add test games for specific mechanics
- Improve existing examples

### 🧪 Testing
- Add test coverage for untested code
- Test on different platforms (Linux, Windows)
- Report platform-specific issues
- Performance testing and optimization

## Development Guidelines

### Code Style
- Follow Swift API design guidelines
- Use SwiftLint (may need to disable on Linux/Windows)
- Write comprehensive `///` documentation for public APIs
- Organize code logically, then alphabetize within groups
- Keep files under ~300 lines when possible

### Testing Requirements
- **All new code must have tests** using Swift Testing framework
- Maintain 80-90% test coverage for new features
- Test through the full engine pipeline with `engine.execute("command")`
- Never test action handlers in isolation
- Use `expectNoDifference()` for exact output verification

### Architecture Principles
- **State changes must flow through the StateChange pipeline**
- **Use proxy objects** (`ItemProxy`, `LocationProxy`, etc.) over direct objects
- **All player messages must go through MessageProvider**
- Follow SOLID principles and maintain type safety
- Respect the existing auto-wiring system

### Example Test Pattern
```swift
@Test("Player can take an item")
func testTakeItem() async throws {
    let testItem = Item("gem")
        .name("sparkling gem")
        .isTakable
        .in(.startRoom)
    
    let game = MinimalGame(
        player: Player(in: .startRoom),
        locations: Location(id: .startRoom, .inherentlyLit),
        items: testItem
    )
    
    let (engine, mockIO) = await GameEngine.test(blueprint: game)
    
    try await engine.execute("take gem")
    
    await mockIO.expectOutput(
        """
        > take gem
        Taken.
        """
    )
    
    let finalItem = await engine.item("gem")
    #expect(finalItem?.parent == .player)
}
```

## Pull Request Process

### Before Submitting
- [ ] Create a feature branch: `git checkout -b feature/your-feature-name`
- [ ] Write tests for your changes
- [ ] Run the full test suite: `swift test`
- [ ] Update documentation as needed
- [ ] Add yourself to contributors if this is your first PR

### PR Description
Include:
- **What** you changed and **why**
- **How** to test the changes
- Any **breaking changes** or migration notes
- Screenshots for UI changes (when we have them)

### Review Process
- Maintainers will review PRs and provide feedback
- Address review comments by pushing new commits
- Once approved, maintainers will merge your PR
- We aim to respond to PRs within a few days

## Specific Areas Needing Help

- **More example games** - Demonstrate different genres and mechanics
- **NPC dialogue system** - Basic but could be much better
- **Combat system refinement** - The melee combat needs work
- **Platform development testing** - Especially Linux and Windows edge cases
- **Web deployment** - WebAssembly integration
- **Mobile runtime** - iOS/Android UI wrappers
- **Documentation expansion** - Tutorials, best practices, API reference

### Future Focus
- **Visual debugging tools** - Game state inspector
- **Multimedia support** - Graphics and sound architecture

## Questions?

- **Technical questions**: Open a GitHub issue or discussion
- **General questions**: Feel free to reach out via issues
- **Ideas for contributions**: We'd love to hear them!

## Recognition

All contributors are appreciated and will be:
- Added to the contributors list in the repository
- Mentioned in release notes for significant contributions

## License

By contributing to Gnusto, you agree that your contributions will be licensed under the MIT License, the same license as the project.
