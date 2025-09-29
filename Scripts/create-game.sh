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
//        .package(url: "https://github.com/samadhiBot/Gnusto.git", from: "0.1.0"),
        .package(path: "~/Gnusto")
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
            name: "$game_nameTests",
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
    blueprint: FrobozzMagicDemoKit(),
    parser: StandardParser(),
    ioHandler: ConsoleIOHandler(
        markdownParser: MarkdownParser(columns: 64)
    )
)

await engine.run()

EOF

    create_file "Sources/$game_name/$game_name.swift" <<EOF
import GnustoEngine

public struct FrobozzMagicDemoKit: GameBlueprint {
    public let title = "FrobozzMagicDemoKit"

    public let abbreviatedTitle = "FrobozzMagicDemoKit"

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

    print_success "Game structure created successfully!"
}

# Function to print usage instructions
print_usage_instructions() {
    local game_name="$1"
    local target_dir="$2"

    echo ""
    echo "🎮 Your new Gnusto game '$game_name' has been created!"
    echo ""
    echo "Next steps:"
    echo "  1. cd '$target_dir'"
    echo "  2. swift build"
    echo "  3. swift run $game_name"
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

    # Get target directory (default to game name)
    local default_target="./$game_name"
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

    # Print usage instructions
    print_usage_instructions "$game_name" "$target_dir"
}

# Run main function with all arguments
main "$@"
