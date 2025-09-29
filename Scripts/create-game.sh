#!/bin/bash

# create-game.sh - Scaffolds a new Gnusto interactive fiction game project
#
# This script creates a complete Swift package structure for a new Gnusto game,
# including Package.swift, source files, and tests with proper boilerplate code.

set -euo pipefail

# ANSI color codes for better output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Helper function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Helper function to create a file with specified path and content
# Usage: create_file "path/to/file.swift" <<'EOF'
# file content here
# EOF
create_file() {
    local file_path="$1"
    local dir_path
    dir_path=$(dirname "$file_path")

    # Create directory if it doesn't exist
    if [[ ! -d "$dir_path" ]]; then
        mkdir -p "$dir_path"
        print_status "Created directory: $dir_path"
    fi

    # Read content from stdin and write to file
    cat > "$file_path"
    print_success "Created file: $file_path"
}

# Function to validate game name
validate_game_name() {
    local name="$1"

    # Check if name is empty
    if [[ -z "$name" ]]; then
        print_error "Game name cannot be empty"
        return 1
    fi

    # Check if name contains only alphanumeric characters and underscores
    if [[ ! "$name" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]]; then
        print_error "Game name must start with a letter and contain only letters, numbers, and underscores"
        return 1
    fi

    return 0
}

# Function to validate target directory
validate_target_directory() {
    local target_dir="$1"

    # Check if directory already exists
    if [[ -d "$target_dir" ]]; then
        print_warning "Directory '$target_dir' already exists"
        read -p "Continue and potentially overwrite files? [y/N]: " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Operation cancelled"
            exit 0
        fi
    fi

    # Check if we can create the directory
    local parent_dir
    parent_dir=$(dirname "$target_dir")
    if [[ ! -d "$parent_dir" ]] || [[ ! -w "$parent_dir" ]]; then
        print_error "Cannot write to parent directory: $parent_dir"
        return 1
    fi

    return 0
}

# Function to create the main game structure
create_game_structure() {
    local game_name="$1"
    local target_dir="$2"

    print_status "Creating game structure for '$game_name' in '$target_dir'"

    # Create base directory
    mkdir -p "$target_dir"
    cd "$target_dir"

    # Create Package.swift
    create_file "Package.swift" <<EOF
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "$game_name",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "$game_name", targets: ["$game_name"]),
    ],
    dependencies: [
        .package(url: "https://github.com/samadhiBot/Gnusto.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "$game_name",
            dependencies: [
                .product(name: "GnustoEngine", package: "Gnusto"),
            ],
            plugins: [
                .plugin(name: "GnustoAutoWiringPlugin", package: "Gnusto"),
            ]
        ),
        .testTarget(
            name: "${game_name}Tests",
            dependencies: [
                "$game_name",
                .product(name: "GnustoEngine", package: "Gnusto"),
            ]
        ),
    ]
)

EOF

    # Create main source file
    create_file "Sources/$game_name/main.swift" <<EOF
import GnustoEngine

let engine = await GameEngine(
    blueprint: $game_name(),
    parser: StandardParser(),
    ioHandler: ConsoleIOHandler(
        markdownParser: MarkdownParser(columns: 64)
    )
)

await engine.run()

EOF

    create_file "Sources/$game_name/$game_name.swift" <<EOF
import GnustoEngine

public struct $game_name: GameBlueprint {
    public let title = "$game_name"

    public let abbreviatedTitle = "$game_name"

    public let introduction = """
        You awaken in the Custodial Singularity.

        If you're reading this, congratulations--your game compiles and runs! This is
        the default world that ships with every new Gnusto project: one closet, one
        screwdriver, infinite possibility.

        Go ahead, try a few commands. EXAMINE SCREWDRIVER. INVENTORY. NORTH (spoiler:
        there is no north). When you're ready to build something real, head back to
        the source. Every great adventure started as an empty room.

        Time to make this one yours.
        """

    public let release = "0.0.1"

    public let maximumScore = 100

    public let player = Player(in: .broomCloset)

    // Declaring messenger and randomNumberGenerator allows you to inject
    // a deterministic random number generator for use in tests.
    public let messenger: StandardMessenger
    public let randomNumberGenerator: any RandomNumberGenerator & Sendable

    public init(
        rng: RandomNumberGenerator & Sendable = SystemRandomNumberGenerator()
    ) {
        self.randomNumberGenerator = rng
        self.messenger = StandardMessenger(randomNumberGenerator: rng)
    }

    // Note: All game content registration (items, locations, handlers, etc.)
    // is automatically handled by GnustoAutoWiringPlugin
}
EOF

    create_file "Sources/$game_name/World/CustodialSingularity.swift" <<EOF
import GnustoEngine

struct CustodialSingularity {
    let broomCloset = Location(
        id: .broomCloset,
        .name("Broom Closet"),
        .description("You are in a narrow closet that smells faintly of detergent."),
        .inherentlyLit
    )

    let screwdriver = Item(
        id: .screwdriver,
        .name("left-handed screwdriver"),
        .description(
            """
            It's a left-handed screwdriver. It looks it could be useful,
            provided you could find a left-handed screw.
            """
        ),
        .isTakable,
        .in(.broomCloset)
    )

    let broomClosetHandler = LocationEventHandler(for: .broomCloset) {
        beforeTurn(.move) { context, command in
            ActionResult(
                context.msg.oneOf(
                    "You stride purposefully into a shelf.",
                    "You take a step, then space takes it back.",
                    "Your movement is canceled on account of reality."
                )
            )
        }
    }
}
EOF

    create_file "Tests/${game_name}Tests/${game_name}Tests.swift" <<EOF
import GnustoEngine
import GnustoTestSupport
import Testing

@testable import $game_name

/// Integration tests for $game_name
///
/// These tests verify that the game works correctly by testing the full
/// engine pipeline from command input to output. Always test through
/// engine.execute() rather than testing individual components in isolation.
@Suite("$game_name Integration Tests")
struct ${game_name}Tests {
    let engine: GameEngine
    let mockIO: MockIOHandler

    init() async {
        (engine, mockIO) = await GameEngine.test(
            blueprint: $game_name(
                rng: SeededRandomNumberGenerator()
            )
        )
    }

    @Test("Player starts in the correct location")
    func testInitialLocation() async throws {
        // When: Game is initialized
        let player = await engine.player

        // Then: Player should be in the starting room
        #expect(await player.location == .broomCloset)
    }

    @Test("Look command shows starting room description")
    func testLookCommand() async throws {
        // When: Player looks around
        try await engine.execute("look")

        // Then: Should see the room description
        await mockIO.expectOutput("""
            > look
            --- Broom Closet ---

            You are in a narrow closet that smells faintly of detergent.

            There is a left-handed screwdriver here.
            """)

    }

    @Test("Player can take the sample item")
    func testTakeSampleItem() async throws {
        // When: Player takes the sample item
        try await engine.execute("take the screwdriver")

        // Then: Item should be taken successfully
        await mockIO.expectOutput("""
            > take the screwdriver
            Taken.
            """)

        // And: Item should now be in player's inventory
        let item = await engine.item(.screwdriver)
        #expect(await item.parent == .player)
    }

    @Test("Inventory command shows carried items")
    func testInventoryCommand() async throws {
        // Given: Player has taken the sample item
        try await engine.execute("""
            inventory
            take the screwdriver
            i
            """)

        // Then: Item should be taken successfully
        await mockIO.expectOutput("""
            > inventory
            Your hands are as empty as your pockets.

            > take the screwdriver
            Got it.

            > i
            You are carrying:
            - A left-handed screwdriver
            """)
    }

    @Test("Help command shows available commands")
    func testHelpCommand() async throws {
        // When: Player asks for help
        try await engine.execute("help")

        // Then: Should show command information
        await mockIO.expectOutput("""
            > help
            This is an interactive fiction game. You control the story by
            typing commands.

            Common commands:
            - LOOK or L - Look around your current location
            - EXAMINE <object> or X <object> - Look at something closely
            - TAKE <object> or GET <object> - Pick up an item
            - DROP <object> - Put down an item you're carrying
            - INVENTORY or I - See what you're carrying
            - GO <direction> or just <direction> - Move in a direction (N,
              S, E, W, etc.)
            - OPEN <object> - Open doors, containers, etc.
            - CLOSE <object> - Close doors, containers, etc.
            - PUT <object> IN <container> - Put something in a container
            - PUT <object> ON <surface> - Put something on a surface
            - SAVE - Save your game
            - RESTORE - Restore a saved game
            - QUIT - End the game

            You can use multiple objects with some commands (TAKE ALL, DROP
            SWORD AND SHIELD).

            Try different things--experimentation is part of the fun!
            """)
    }
}

EOF

    print_success "Game structure created successfully!"
}

# Function to open the project in an appropriate editor
open_project_in_editor() {
    local target_dir="$1"
    local game_name="$2"

    print_status "Opening project in editor..."

    # Check for Xcode first (preferred for Swift projects)
    if command -v xed >/dev/null 2>&1; then
        print_status "Opening in Xcode..."
        xed "$target_dir/Package.swift"
        return 0
    elif [[ -d "/Applications/Xcode.app" ]]; then
        print_status "Opening in Xcode..."
        open -a Xcode "$target_dir/Package.swift"
        return 0
    fi

    # Check for VS Code
    if command -v code >/dev/null 2>&1; then
        print_status "Opening in Visual Studio Code..."
        code "$target_dir"
        return 0
    fi

    # Fallback to system default (Finder on macOS, file manager on Linux, etc.)
    if command -v open >/dev/null 2>&1; then
        print_status "Opening project folder..."
        open "$target_dir"
        return 0
    elif command -v xdg-open >/dev/null 2>&1; then
        print_status "Opening project folder..."
        xdg-open "$target_dir"
        return 0
    else
        print_warning "Could not automatically open the project. Please navigate to: $target_dir"
        return 1
    fi
}

# Function to print usage instructions
print_usage_instructions() {
    local game_name="$1"
    local target_dir="$2"

    echo ""
    echo "🎮 Your new Gnusto game '$game_name' has been created!"
    echo ""
    echo "Next steps:"
    echo "  1. swift build"
    echo "  2. swift run $game_name"
    echo ""
    echo "To run tests:"
    echo "  swift test"
    echo ""
    echo "To customize your game:"
    echo "  - Edit Sources/$game_name/$game_name.swift to add locations, items, and behaviors"
    echo "  - Add tests in Tests/${game_name}Tests/${game_name}Tests.swift"
    echo "  - Update README.md with your game's description"
    echo ""
    echo "Happy coding! 🚀"
}

# Main script execution
main() {
    echo "🎭 Gnusto Game Scaffolding Tool"
    echo "================================="
    echo ""

    # Get game name
    local game_name
    while true; do
        read -p "Enter your game name (e.g., MyAdventure): " game_name
        if validate_game_name "$game_name"; then
            break
        fi
        echo ""
    done

    # Get target directory (default to game name in home directory)
    local default_target="$HOME/$game_name"
    read -p "Enter target directory [$default_target]: " target_dir
    target_dir=${target_dir:-$default_target}

    # Convert to absolute path for clarity and expand ~
    target_dir="${target_dir/#\~/$HOME}"
    if [[ ! "$target_dir" = /* ]]; then
        target_dir="$PWD/$target_dir"
    fi

    echo ""
    print_status "Game name: $game_name"
    print_status "Target directory: $target_dir"
    echo ""

    # Validate target directory
    if ! validate_target_directory "$target_dir"; then
        print_error "Invalid target directory"
        exit 1
    fi

    # Create the game structure
    create_game_structure "$game_name" "$target_dir"

    # Open project in appropriate editor
    open_project_in_editor "$target_dir" "$game_name"

    # Print usage instructions
    print_usage_instructions "$game_name" "$target_dir"
}

# Run main function with all arguments
main "$@"
