import GnustoEngine

// MARK: - Special/Virtual Locations

enum SpecialLocations {
    static let blockedExit = Location(
        id: .blockedExit,
        .name("Blocked Exit"),
        .description("This is a placeholder for blocked exits."),
        .exits([:]),
        .inherentlyLit
    )
}
