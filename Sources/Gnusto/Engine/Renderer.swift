import Foundation

/// Interface for rendering game output and collecting input
public protocol Renderer {
    /// Render an effect to the user
    /// - Parameter effect: The effect to render
    func render(_ effect: Effect)

    /// Get input from the user
    /// - Parameter prompt: The prompt to display
    /// - Returns: The user's input, or nil if input is unavailable
    func getInput(prompt: String) -> String?
}

/// A simple console-based renderer
public class Console: Renderer {
    /// Renders an effect to the console
    public func render(_ effect: Effect) {
        switch effect {
        case .showText(let text):
            print(text)

        case .updateStatusLine(let location, let score, let moves):
            print("\n[\(location) | Score: \(score) | Moves: \(moves)]")

        case .playSound(let sound):
            print("[SOUND: \(sound)]")

        case .endGame:
            print("\nPress enter to exit...")
            _ = readLine()

        case .requestInput:
            // Handled by getInput
            break

        case .showInventoryChange(let item, let added):
            let action = added ? "Added to inventory" : "Removed from inventory"
            print("[\(action): \(item)]")

        case .highlightObject/*(let name)*/:
            // Not implemented in console mode
            break

        case .triggerImplicitLook:
            // This effect should be handled and removed by the ActionDispatcher
            // and should never reach the Renderer.
            assertionFailure("Renderer received unexpected .triggerImplicitLook effect.")
            break
        }
    }

    /// Gets input from the console
    public func getInput(prompt: String) -> String? {
        print(prompt, terminator: "")
        return readLine()
    }
}
