import Foundation
import PackagePlugin

/// A build tool plugin that automatically generates LocationID and ItemID constant extensions
/// by scanning Swift source files for usage patterns.
///
/// This plugin discovers:
/// - `Location(id: .someID, ...)` patterns
/// - `Item(id: .someID, ...)` patterns  
/// - `LocationID("rawValue")` patterns
/// - `ItemID("rawValue")` patterns
///
/// And generates corresponding static constants in extensions, eliminating the need
/// for manual ID constant maintenance.
@main
struct IDGeneratorPlugin: BuildToolPlugin {
    
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        
        // Only process Swift source module targets
        guard let target = target as? SwiftSourceModuleTarget else {
            print("🚫 IDGeneratorPlugin: Skipping non-Swift target '\(target.name)'")
            return []
        }
        
        // Get all Swift source files in the target
        let swiftFiles = target.sourceFiles(withSuffix: ".swift")
        
        // Skip if no Swift files to process
        guard !swiftFiles.isEmpty else {
            print("🚫 IDGeneratorPlugin: No Swift files found in target '\(target.name)'")
            return []
        }
        
        // Define output file path in plugin work directory
        let outputURL = context.pluginWorkDirectoryURL.appending(path: "GeneratedIDs.swift")

        // Get the ID generator tool
        let tool = try context.tool(named: "IDGeneratorTool")
        
        // Build arguments for the tool
        var arguments = [
            "--output", outputURL.absoluteString,
            "--source-files"
        ]
        arguments += swiftFiles.map { $0.url.absoluteString }

        print("🔧 IDGeneratorPlugin (SPM): Configuring ID generation for target '\(target.name)'")
        print("📁 Will scan \(swiftFiles.count) Swift files")
        print("📝 Output: \(outputURL)")
        print("🛠️ Tool: \(tool.url.path())")

        return [
            .buildCommand(
                displayName: "Generate ID Constants for \(target.name)",
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

extension IDGeneratorPlugin: XcodeBuildToolPlugin {
    
    func createBuildCommands(
        context: XcodePluginContext,
        target: XcodeTarget
    ) throws -> [Command] {
        
        print("🔧 IDGeneratorPlugin (Xcode): Starting plugin for target '\(target.displayName)'")
        
        // Get all Swift source files in the target
        let swiftFiles = target.inputFiles.filter {
            $0.type == .source && $0.url.pathExtension == "swift"
        }
        
        // Skip if no Swift files to process
        guard !swiftFiles.isEmpty else {
            print("🚫 IDGeneratorPlugin (Xcode): No Swift files found in target '\(target.displayName)'")
            return []
        }
        
        // Define output file path in plugin work directory
        let outputURL = context.pluginWorkDirectoryURL.appending(path: "GeneratedIDs.swift")

        // Get the ID generator tool
        let tool: PluginContext.Tool
        do {
            tool = try context.tool(named: "IDGeneratorTool")
            print("✅ IDGeneratorPlugin (Xcode): Found tool at \(tool.url.path())")
        } catch {
            print("❌ IDGeneratorPlugin (Xcode): Failed to find tool: \(error)")
            throw error
        }
        
        // Build arguments for the tool
        var arguments = [
            "--output", outputURL.absoluteString,
            "--source-files"
        ]
        arguments += swiftFiles.map { $0.url.absoluteString }

        print("🔧 IDGeneratorPlugin (Xcode): Configuring ID generation for target '\(target.displayName)'")
        print("📁 Will scan \(swiftFiles.count) Swift files")
        print("📝 Output: \(outputURL)")
        print("🛠️ Tool: \(tool.url.path())")
        print("📋 Arguments: \(arguments.joined(separator: " "))")
        
        return [
            .buildCommand(
                displayName: "Generate ID Constants for \(target.displayName)",
                executable: tool.url,
                arguments: arguments,
                inputFiles: swiftFiles.map(\.url),
                outputFiles: [outputURL]
            )
        ]
    }
}
#endif 
