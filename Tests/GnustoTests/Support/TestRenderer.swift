import Gnusto

// A simple test renderer that captures output
class TestRenderer: Renderer {
    var capturedEffects: [Effect] = []
    var inputResponses: [String] = []
    var currentResponseIndex = 0

    func render(_ effect: Effect) {
        capturedEffects.append(effect)
    }

    func getInput(prompt: String) -> String? {
        if currentResponseIndex < inputResponses.count {
            let response = inputResponses[currentResponseIndex]
            currentResponseIndex += 1
            return response
        }
        return nil
    }

    func clearScreen() {
        // Do nothing for tests
    }
}

extension TestRenderer {
    /// Clears the captured effects.
    func clear() {
        capturedEffects.removeAll()
    }

    /// Flush the output from the captured effects.
    ///
    /// - Parameter verbose: Whether to provide **all** output or just the game text.
    /// - Returns: The captured output.
    func flush(verbose: Bool = false) -> String {
        defer {
            clear()
        }
        return output(verbose: verbose)
    }
    
    /// Returns the output from all captured effects.
    ///
    /// - Parameter verbose: Whether to provide **all** output or just the game text.
    /// - Returns: The output from the captured effects.
    func output(verbose: Bool = false) -> String {
        capturedEffects.compactMap {
            switch $0 {
            case .showText(let output):
                output
            case .updateStatusLine(location: let location, score: let score, moves: let moves):
                verbose ? ".updateStatusLine(\(location), \(score), \(moves))" : nil
            case .playSound(let sound):
                verbose ? ".playSound(\(sound))" : nil
            case .endGame:
                ".endGame(GAME OVER)"
            case .requestInput(prompt: let prompt):
                verbose ? ".requestInput(\(prompt))" : nil
            case .showInventoryChange(item: let item, added: let added):
                verbose ? ".showInventoryChange(\(item) \(added))" : nil
            case .highlightObject(name: let name):
                verbose ? ".highlightObject(\(name))" : nil
            case .triggerImplicitLook:
                ".triggerImplicitLook (Error: this should never be triggered)"
            }
        }
        .joined(separator: "\n")
    }
    
    /// Process an array of effects and return the rendered game output.
    ///
    /// - Parameters:
    ///   - effects: The effects to process.
    ///   - verbose: Whether to provide **all** output or just the game text.
    /// - Returns: The rendered game output.
    func process(
        _ effects: [Effect],
        verbose: Bool = false
    ) -> String {
        effects.forEach(render)
        return flush(verbose: verbose)
    }
}
