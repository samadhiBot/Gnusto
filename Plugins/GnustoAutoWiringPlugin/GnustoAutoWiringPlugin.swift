import Foundation
import PackagePlugin

/// A comprehensive build tool plugin that automatically discovers and generates game setup
/// boilerplate by scanning Swift source files for Gnusto Engine patterns.
///
/// This plugin discovers and generates:
///
/// **ID Constants:**
/// - `Location(id: .someID, ...)` → `LocationID.someID`
/// - `Item(id: .someID, ...)` → `ItemID.someID`
/// - `GlobalID("key")` or global state patterns → `GlobalID.key`
/// - `Fuse(id: .someID, ...)` → `FuseID.someID`
/// - `Daemon(id: .someID, ...)` → `DaemonID.someID`
/// - Custom `VerbID("verb")` patterns → `VerbID.verb`
///
/// **Event Handler Discovery:**
/// - `let itemNameHandler = ItemEventHandler { ... }`
/// - `let locationNameHandler = LocationEventHandler { ... }`
///
/// **Game Setup Templates:**
/// - GlobalState initialization reminders
/// - TimeRegistry setup with discovered fuses/daemons
/// - Custom action handler registration examples
/// - Game area organization recommendations
///
/// The plugin eliminates manual ID constant maintenance and provides helpful
/// setup templates, making game development faster and less error-prone.
@main
struct GnustoAutoWiringPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {

        // Only process Swift source module targets
        guard let target = target as? SwiftSourceModuleTarget else {
            print("🚫 GnustoAutoWiringPlugin: Skipping non-Swift target '\(target.name)'")
            return []
        }

        // Get all Swift source files in the target
        let swiftFiles = target.sourceFiles(withSuffix: ".swift")

        // Skip if no Swift files to process
        guard !swiftFiles.isEmpty else {
            print("🚫 GnustoAutoWiringPlugin: No Swift files found in target '\(target.name)'")
            return []
        }

        // Define output file path in plugin work directory
        let outputURL = context.pluginWorkDirectoryURL.appending(path: "GeneratedIDs.swift")

        // Get the ID generator tool
        let tool = try context.tool(named: "GnustoAutoWiringTool")

        // Use the target directory as the source directory
        let sourceDirectory = target.directoryURL

        // Build arguments for the tool
        let arguments = [
            "--output", outputURL.path(),
            "--source", sourceDirectory.path()
        ]

        print("🔧 GnustoAutoWiringPlugin (SPM): Configuring comprehensive game setup generation for target '\(target.name)'")
        print("📁 Will scan \(swiftFiles.count) Swift files in \(sourceDirectory.path())")
        print("📝 Output: \(outputURL.path())")
        print("🛠️ Tool: \(tool.name)")

        return [
            .buildCommand(
                displayName: "Generate Game Setup Code for \(target.name)",
                executable: tool.url,
                arguments: arguments,
                inputFiles: swiftFiles.map(\.url),
                outputFiles: [outputURL]
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)

import XcodeProjectPlugin

extension GnustoAutoWiringPlugin: XcodeBuildToolPlugin {

    func createBuildCommands(
        context: XcodePluginContext,
        target: XcodeTarget
    ) throws -> [Command] {

        print("🔧 GnustoAutoWiringPlugin (Xcode): Starting comprehensive game setup analysis for target '\(target.displayName)'")

        // Get all Swift source files in the target
        let swiftFiles = target.inputFiles.filter {
            $0.type == .source && $0.url.pathExtension == "swift"
        }

        // Skip if no Swift files to process
        guard !swiftFiles.isEmpty else {
            print("🚫 GnustoAutoWiringPlugin (Xcode): No Swift files found in target '\(target.displayName)'")
            return []
        }

        // Define output file path in plugin work directory
        let outputURL = context.pluginWorkDirectoryURL.appending(path: "GeneratedIDs.swift")

        // Get the ID generator tool
        let tool: PluginContext.Tool
        do {
            tool = try context.tool(named: "GnustoAutoWiringTool")
            print("✅ GnustoAutoWiringPlugin (Xcode): Found tool at \(tool.url.path())")
        } catch {
            print("❌ GnustoAutoWiringPlugin (Xcode): Failed to find tool: \(error)")
            throw error
        }

        // For Xcode, we need to determine the source directory from the input files
        // Find the common source directory by getting the directory of the first Swift file
        let sourceDirectory: URL
        if let firstFile = swiftFiles.first {
            sourceDirectory = firstFile.url.deletingLastPathComponent()
        } else {
            // Fallback to plugin work directory if no files found
            sourceDirectory = context.pluginWorkDirectoryURL
        }

        // Build arguments for the tool
        let arguments = [
            "--output", outputURL.path(),
            "--source", sourceDirectory.path()
        ]

        print("🔧 GnustoAutoWiringPlugin (Xcode): Configuring comprehensive game setup generation for target '\(target.displayName)'")
        print("📁 Will scan \(swiftFiles.count) Swift files in \(sourceDirectory.path())")
        print("📝 Output: \(outputURL.path())")
        print("🛠️ Tool: \(tool.name)")
        print("📋 Arguments: \(arguments.joined(separator: " "))")

        return [
            .buildCommand(
                displayName: "Generate Game Setup Code for \(target.displayName)",
                executable: tool.url,
                arguments: arguments,
                inputFiles: swiftFiles.map(\.url),
                outputFiles: [outputURL]
            )
        ]
    }
}

#endif
