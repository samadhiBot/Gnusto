import ArgumentParser
import CoreML
import CreateML
import Files

@main
struct Gloth: ParsableCommand {
    @Option(name: .shortAndLong, help: "Number of examples to generate for each action command.")
    var actionCount: Int = 500

    /// The main entry point for the Gloth executable.
    func run() throws {
        let artifacts = try artifactsFolder()

        let trainingDataFile = try artifacts.createFile(named: "training-data.json")
        let testingDataFile = try artifacts.createFile(named: "testing-data.json")
        let validationDataFile = try artifacts.createFile(named: "validation-data.json")

        // Define meta commands separately
        let metaCommandTypes: [any Generator.Type] = [
            Help.self, Quit.self, Restore.self, Save.self, Undo.self, Version.self
        ]
        // Define action commands
        let actionCommandTypes: [any Generator.Type] = [
            Attack.self,
            Burn.self,
            Close.self,
            Consume.self,
            Dig.self,
            Drop.self,
            DropIn.self,
            Examine.self,
            Fill.self,
            Give.self,
            GiveTo.self,
            Go.self,
            Inventory.self,
            Lock.self,
            Open.self,
            Pull.self,
            Push.self,
            PutIn.self,
            PutOnSurface.self,
            Read.self,
            Remove.self,
            Search.self,
            Smell.self,
            Take.self,
            TakeFrom.self,
            Talk.self,
            Throw.self,
            Toggle.self,
            Touch.self,
            Traverse.self,
            Unlock.self,
            Wake.self,
            Wave.self,
            Wear.self,
        ]

        // Generate phrases
        var allPhrases: [Phrase] = []
        print("Generating action command examples (\(actionCount) each)...", terminator: "")
        for commandType in actionCommandTypes {
            allPhrases.append(contentsOf: commandType.generate(actionCount)) // Use variable
            print(".", terminator: "")
        }
        print("\nGenerating meta command examples (50 each)...")
        for commandType in metaCommandTypes {
            allPhrases.append(contentsOf: commandType.generate(50)) // Keep hardcoded 50
        }
        print("Generated \(allPhrases.count) total phrases.")

        // Shuffle and split data (e.g., 80% train, 10% validation, 10% test)
        // Note: CreateML often handles its own internal validation split if not provided,
        // but providing an explicit one gives more control.
        allPhrases.shuffle()
        let totalCount = allPhrases.count
        let trainEndIndex = Int(Double(totalCount) * 0.8)
        let validEndIndex = trainEndIndex + Int(Double(totalCount) * 0.1)

        let trainingPhrases = Array(allPhrases[0..<trainEndIndex])
        let validationPhrases = Array(allPhrases[trainEndIndex..<validEndIndex])
        let testingPhrases = Array(allPhrases[validEndIndex..<totalCount])

        print("Writing data files (\(trainingPhrases.count) train, \(validationPhrases.count) valid, \(testingPhrases.count) test)...")
        try trainingDataFile.write(phrasesJSON(trainingPhrases))
        print("Created data file \(trainingDataFile.path)")
        try validationDataFile.write(phrasesJSON(validationPhrases))
        print("Created data file \(validationDataFile.path)")
        try testingDataFile.write(phrasesJSON(testingPhrases))
        print("Created data file \(testingDataFile.path)")

        try generateModel(
            trainingDataURL: trainingDataFile.url,
            validationDataURL: validationDataFile.url, // Pass validation URL
            testingDataURL: testingDataFile.url,
            destination: artifacts
        )
    }

    // MARK: - Private helpers

    func artifactsFolder() throws -> Folder {
        if let oldArtifacts = try? Folder.current.subfolder(named: "Artifacts") {
            try oldArtifacts.delete()
        }
        let artifacts = try Folder.current.createSubfolder(named: "Artifacts")
        let package = try artifacts.createFile(named: "Package.swift")
        try package.write(
            """
            // swift-tools-version: 6.1
            import PackageDescription
            // This package exists to prevent Xcode from displaying the Artifacts folder.
            let package = Package(name: "Artifacts", products: [], targets: [])
            """
        )
        return artifacts
    }

    func generateModel(
        trainingDataURL: URL,
        validationDataURL: URL, // Added validation URL parameter
        testingDataURL: URL,
        destination: Folder
    ) throws {
        print("Parsing JSON records from \(trainingDataURL.path)")
        let trainingDataTable = try MLDataTable(contentsOf: trainingDataURL)
        print("Successfully parsed \(trainingDataTable.rows.count) elements from the JSON file \(trainingDataURL.path)")
        // print("Loading validation data from \(validationDataURL.path)") // No longer loading validation table here
        // let validationDataTable = try MLDataTable(contentsOf: validationDataURL) // No longer loading
        // print("Successfully loaded \(validationDataTable.rows.count) validation elements.") // No longer loading

        // // Configure parameters to use the explicit validation set // Removed parameters
        // let parameters = MLWordTagger.ModelParameters(validation: .fromFile(at: validationDataURL)) // Removed parameters

        print("Tokenizing data and extracting features")
        let startTime = Date()
        let wordTagger = try MLWordTagger(
            trainingData: trainingDataTable,
            tokenColumn: "tokens",
            labelColumn: "labels"
            // parameters: parameters // Removed parameters
        )
        let trainingTime = Date().timeIntervalSince(startTime)
        print("Finished CRF training in \(String(format: "%.2f", trainingTime)) seconds")
        print(wordTagger)

        print("Parsing JSON records from \(testingDataURL.path)")
        let testingDataTable = try MLDataTable(contentsOf: testingDataURL)
        print("Successfully parsed \(testingDataTable.rows.count) elements from the JSON file \(testingDataURL.path)")

        let evaluationMetrics = wordTagger.evaluation(
            on: testingDataTable, // Use TESTING data for final evaluation
            tokenColumn: "tokens",
            labelColumn: "labels"
        )
        print("\n📚 Evaluation\n", evaluationMetrics)

        let modelPath = destination.url.appendingPathComponent("Gloth.mlmodel")
        let metadata = MLModelMetadata(
            author: "Gnusto Text Adventure Engine",
            shortDescription: "CRF Word Tagger for Gnusto parser.",
            version: "1.0"
        )
        try wordTagger.write(to: modelPath, metadata: metadata)
        print("\n✅ ML Model saved to \(modelPath.path)")

        // Compile the model (Optional but good for deployment)
        do {
            let compiledModelURL = try MLModel.compileModel(at: modelPath)
            let compiledModelPath = compiledModelURL.path.replacingOccurrences(of: ".mlmodelc", with: "") // Get folder path
            print("Compiled model successfully saved at \(compiledModelPath)")
        } catch {
            print("🛑 Failed to compile model: \(error)")
        }
    }

    func phrasesJSON(_ phrases: [Phrase]) -> String {
        let jsonPhrases = phrases
            .map { $0.toJSON }
            .joined(separator: ",\n")
        return "[\n" + jsonPhrases + "\n]"
    }
}
