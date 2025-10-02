# Contributing to Gnusto

Thank you for your interest in contributing to the Gnusto Interactive Fiction Engine! We welcome all kinds of contributions, including bug reports, documentation improvements, bug fixes and new features.

> The best way to contribute is to start working on a game of your own. If you find a bug in the engine, or a common action that's missing, file an [issue](https://github.com/samadhiBot/Gnusto/issues) -- or  if you're up for it, open a PR with your fix or new feature.

## Code of Conduct

**Be curious, be kind.**. We're building a welcoming community where everyone can learn, contribute, and enjoy creating interactive fiction together.

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
- Add new articles

### ✨ Features
- Discuss new features in issues before implementing
- Start with small improvements to get familiar with the codebase
- If you're looking for somewhere to start, focus on areas marked as needing improvement (combat, NPCs, etc.)
- Consider backward compatibility

### 🎮 Games
- Create an original game
- Port a classic IF game
- Create a demo game that adds or demonstrates specific mechanics
- Contribute to the [Zork 1](https://github.com/samadhiBot/Gnusto/tree/main/Executables/Zork1)) replica

### 🧪 Testing
- Add test coverage for untested code
- Test on different platforms (Linux, Windows)
- Report platform-specific issues

## Development Guidelines

### Code Style
- Follow Swift API design guidelines
- Use SwiftLint if possible (may need to disable on Linux/Windows)
- Write comprehensive `///` documentation for public APIs
- Organize code logically, then alphabetize within groups
- Keep files under ~300 lines when possible

### Testing Requirements
- **All new code must have tests** using Swift Testing framework
- Maintain 80-90% test coverage for new features
- Test through the full engine pipeline with `engine.execute("command")`
- Use `mockIO.expectOutput()` for exact output verification

### Architecture Principles
- **State changes must flow through the StateChange pipeline**
- **Use proxy objects** (`ItemProxy`, `LocationProxy`, etc.) over direct objects
- **All player-facing messages must go through MessageProvider**
- Follow SOLID principles and maintain type safety
- Use the existing auto-wiring system

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

### PR Description
Include:
- **What** you changed and **why**
- **How** to test the changes
- Any **breaking changes** or migration notes

### Review Process
- Maintainers will review PRs and provide feedback
- Address review comments by pushing new commits
- Once approved, maintainers will merge your PR
- We aim to respond to PRs within a few days

## Specific Areas Needing Help

- **More example games** - Demonstrate different genres and mechanics, find bugs and missing features
- **NPC dialogue system** - Very basic currently, could be much better
- **Combat system refinement** - The melee combat needs refinement
- **Platform development testing** - Especially Linux and Windows edge cases
- **Web deployment** - WebAssembly integration
- **Mobile runtime** - iOS/Android UI wrappers
- **Desktop runtime** - Mac, Linux and Windows dedicated UI wrappers
- **Documentation expansion** - Tutorials, best practices, articles

### Future Focus
- **Visual debugging tools** - Game state inspector
- **Multimedia support** - Graphics and sound architecture?
- **Visual editor** - Game creation tool

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
