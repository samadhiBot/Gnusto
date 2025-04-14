# Gloth

`Gloth` is a command-line executable responsible for training the CoreML word tagger model used by Gnusto to understand player commands.

## Overview

The primary function of `Gloth` is to:

1.  **Generate Data:** Create training, testing, and validation datasets based on predefined patterns for various interactive fiction commands (e.g., "attack troll", "go north", "take lamp").
2.  **Train Model:** Use `CreateML` to train an `MLWordTagger` model using the generated datasets.
3.  **Evaluate Model:** Calculate and display the accuracy of the trained model on training, validation, and testing data, including a confusion matrix.
4.  **Output Artifacts:** Save the generated data files (JSON), the trained CoreML model (`Gloth.mlmodel`), and the compiled model (`Gloth.mlmodelc`) into an `Artifacts` directory.

## Dependencies

- `CoreML`: For model training and evaluation.
- `CreateML`: For creating the `MLDataTable` and `MLWordTagger`.
- `Files`: For handling file system operations (creating directories and files).

## Usage

To run Gloth and generate the model artifacts:

1.  Navigate to the root directory of the Gnusto project in your terminal.
2.  Execute the tool using Swift Package Manager:

    ```bash
    swift run Gloth
    ```

3.  If training results look good, copy the ML model into Nitfol's resources:

    ```bash
    cp Artifacts/Gloth.mlmodel Sources/Nitfol/Resources/Gloth.mlmodel
    ```

This command will:

- Delete any existing `Artifacts` directory in the current path.
- Create a new `Artifacts` directory.
- Generate `training-data.json`, `testing-data.json`, and `validation-data.json` within `Artifacts`.
- Train the `MLWordTagger`.
- Print accuracy metrics to the console.
- Save `Gloth.mlmodel` and `Gloth.mlmodelc` to the `Artifacts` directory.
- Create a dummy `Package.swift` file within `Artifacts` to prevent Xcode from trying to index or display the folder contents directly.

## Input Data Generation

Gloth does not require external input data files. Instead, it programmatically generates data using various `Phrase` generators defined within the codebase (e.g., `Attack.generate(1000)`, `Go.generate(1000)`). Each generator produces variations of commands associated with a specific action.

The generated data covers commands such as:
`Attack`, `Burn`, `Close`, `Consume`, `Dig`, `Drop`, `Examine`, `Fill`, `Give`, `Go`, `Help`, `Inventory`, `Lock`, `Open`, `Pull`, `Push`, `PutIn`, `PutOnSurface`, `Quit`, `Read`, `Remove`, `Restore`, `Save`, `Search`, `Smell`, `Take`, `Talk`, `Throw`, `Toggle`, `Touch`, `Traverse`, `Undo`, `Unlock`, `Version`, `Wait`, `Wake`, `Wave`, `Wear`.

## Output Artifacts

Upon successful execution, Gloth creates the following in the `./Artifacts/` directory:

- `training-data.json`: The dataset used for training the model.
- `testing-data.json`: The dataset used for evaluating the model after training.
- `validation-data.json`: The dataset used by `CreateML` for internal validation during training.
- `Gloth.mlmodel`: The trainable CoreML word tagger model file.
- `Gloth.mlmodelc`: The compiled CoreML model, ready to be included in the Gnusto application bundle.
- `Package.swift`: A minimal package manifest file whose sole purpose is to make Xcode ignore the `Artifacts` folder.

## Model

The resulting `Gloth.mlmodelc` is an `MLWordTagger` model. This model takes a sequence of tokens (words from player input) and assigns a label (like `Verb`, `Noun`, `Adjective`, `Preposition`, etc.) to each token. This tagged sequence is then used by Gnusto's parser to understand the structure and meaning of the player's command.
