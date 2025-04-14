import Gnusto

extension CommandRegistry {
    static var `default`: CommandRegistry {
        let registry = CommandRegistry()
        registry.registerDefaultHandlers()
        return registry
    }
}
