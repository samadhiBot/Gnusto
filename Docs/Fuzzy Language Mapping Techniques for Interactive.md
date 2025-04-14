<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" class="logo" width="120"/>

# Fuzzy Language Mapping Techniques for Interactive Fiction Commands in Swift

---

# Fuzzy Language Mapping Techniques for Interactive Fiction Commands in Swift

Apple's NaturalLanguage framework offers several powerful capabilities that can be combined with other techniques to create an effective fuzzy command mapping system for interactive fiction. Based on the available techniques, you can implement a robust solution that maps varied natural language inputs to standardized game commands.

## Word Embeddings for Semantic Similarity

Word embeddings are one of the most powerful approaches for semantic matching, allowing you to capture the meaning of commands rather than just their textual similarity.

### Using NLEmbedding for Command Mapping

Apple's NaturalLanguage framework provides the `NLEmbedding` class, which lets you find semantically similar words based on pre-trained word vectors:

```swift
import NaturalLanguage

func findSimilarVerbs(for verb: String) -&gt; [String] {
    guard let embedding = NLEmbedding.wordEmbedding(for: .english) else {
        return []
    }
    
    // Get semantically similar verbs with similarity scores
    let similarVerbs = embedding.neighbors(for: verb, maximumCount: 10)
    
    // Return just the words (first element of each tuple)
    return similarVerbs.map { $0.0 }
}

// Example usage
let attackVerbs = findSimilarVerbs(for: "attack")
// Might return: ["assault", "strike", "hit", "fight", "combat", etc.]
```

This approach allows you to map action verbs like "stab", "slay", "kill" to a standardized "ATTACK" command by checking if the input verb is semantically similar to your predefined set of actions[^1_10][^1_20].

### Mapping Complete Commands Using Sentence Embeddings

For more complex commands, you can use sentence-level embeddings to match the overall meaning:

```swift
func findBestCommandMatch(userInput: String, standardCommands: [String: String]) -&gt; String? {
    guard let embedding = NLEmbedding.sentenceEmbedding(for: .english) else {
        return nil
    }
    
    var bestMatch: String? = nil
    var minDistance = Double.greatestFiniteMagnitude
    
    for (pattern, command) in standardCommands {
        let distance = embedding.distance(
            between: userInput.lowercased(),
            and: pattern.lowercased()
        )
        
        if distance &lt; minDistance {
            minDistance = distance
            bestMatch = command
        }
    }
    
    // Only return match if distance is below threshold
    return minDistance &lt; 0.7 ? bestMatch : nil
}
```


## Command Parsing with NLTagger

To break down commands into their components (actions and targets), you can use `NLTagger` for part-of-speech tagging:

```swift
func parseCommand(_ input: String) -&gt; (action: String, target: String?) {
    let tagger = NLTagger(tagSchemes: [.lexicalClass])
    tagger.string = input
    
    var action: String? = nil
    var target: String? = nil
    
    tagger.enumerateTags(in: input.startIndex..&lt;input.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, tokenRange in
        if let tag = tag {
            let word = String(input[tokenRange])
            
            if tag.rawValue == "Verb" &amp;&amp; action == nil {
                action = word
            } else if tag.rawValue == "Noun" &amp;&amp; (target == nil || target == "") {
                target = word
            }
        }
        return true
    }
    
    return (action ?? "", target)
}
```

This allows you to extract the main verb ("stab") and object ("robber") from a command like "stab the robber"[^1_8][^1_21].

## Fuzzy String Matching

For handling typos and minor variations in commands, fuzzy string matching is highly effective:

### Using FuzzyMatchingSwift Library

The FuzzyMatchingSwift library provides robust fuzzy matching capabilities that you can integrate into your command parser[^1_17]:

```swift
import FuzzyMatchingSwift

func findBestCommandWithFuzzyMatch(input: String, commands: [String: String]) -&gt; String? {
    var bestMatch: String? = nil
    var highestScore = 0.0
    
    for (pattern, command) in commands {
        if let score = input.confidenceScore(pattern), score &gt; highestScore {
            highestScore = score
            bestMatch = command
        }
    }
    
    return highestScore &lt; 0.8 ? bestMatch : nil
}
```


### Custom Fuzzy Matching Algorithm

You can also implement your own fuzzy matching algorithm focusing on prefix matching[^1_3]:

```swift
func fuzzyMatch(query: String, target: String) -&gt; Double {
    let query = query.lowercased()
    let target = target.lowercased()
    
    var totalScore = 0
    var patternIndex = 0
    
    for character in target {
        if patternIndex &lt; query.count {
            let queryIndex = query.index(query.startIndex, offsetBy: patternIndex)
            if query[queryIndex] == character {
                totalScore += 1
                patternIndex += 1
            }
        }
    }
    
    // Calculate similarity as a ratio
    return Double(totalScore) / Double(query.count)
}
```


## Comprehensive Solution: Command Interpreter

A comprehensive solution would combine these techniques into a unified command interpreter:

```swift
class CommandInterpreter {
    private let actionMap: [String: [String]] // Maps standard actions to variations
    private let entityMap: [String: [String]] // Maps standard entities to variations
    
    init() {
        // Initialize with your game's command mappings
        self.actionMap = [
            "ATTACK": ["attack", "hit", "strike", "kill", "stab", "slay"],
            "TAKE": ["take", "grab", "pick", "collect", "get"],
            // Add more actions
        ]
        
        self.entityMap = [
            "THIEF": ["thief", "robber", "burglar", "bandit", "criminal"],
            // Add more entities
        ]
    }
    
    func interpretCommand(_ input: String) -&gt; (action: String, target: String)? {
        let (verb, noun) = parseCommand(input)
        
        guard !verb.isEmpty else { return nil }
        
        // Find matching action
        let standardAction = findStandardTerm(verb, in: actionMap)
        
        // Find matching entity if present
        let standardTarget = noun != nil ? findStandardTerm(noun!, in: entityMap) : nil
        
        guard let action = standardAction else { return nil }
        
        return (action, standardTarget ?? "")
    }
    
    private func findStandardTerm(_ term: String, in map: [String: [String]]) -&gt; String? {
        // Direct match
        for (standard, variations) in map {
            if variations.contains(term.lowercased()) {
                return standard
            }
        }
        
        // Fuzzy match
        guard let embedding = NLEmbedding.wordEmbedding(for: .english) else {
            return nil
        }
        
        var bestMatch: String? = nil
        var bestScore = 0.0
        
        for (standard, variations) in map {
            for variation in variations {
                if let similarity = embedding.distance(between: term.lowercased(), and: variation) {
                    let score = 1.0 - similarity // Convert distance to similarity
                    if score &gt; bestScore &amp;&amp; score &gt; 0.7 { // Threshold
                        bestScore = score
                        bestMatch = standard
                    }
                }
            }
        }
        
        return bestMatch
    }
}
```


## Advanced Options

### Create Custom NL Models

For game-specific vocabulary, create a custom NL model with Create ML to recognize specific game actions and entities:

```swift
// Load your custom model
let modelURL = Bundle.main.url(forResource: "GameCommands", withExtension: "mlmodelc")!
let gameModel = try! NLModel(contentsOf: modelURL)

// Use the model to tag input
let tags = gameModel.predictedLabelHypotheses(for: "stab the robber", maximumCount: 1)
// Might return: ["ATTACK_THIEF": 0.92]
```

This approach requires training a model with example commands but can provide very accurate results for your specific game vocabulary[^1_8][^1_11].

### SimilaritySearchKit for Comprehensive Command Matching

The SimilaritySearchKit library offers a complete solution for semantic search and can be effective for command mapping[^1_18]:

```swift
import SimilaritySearchKit

// Initialize with your chosen embedding model and similarity metric
let similarityIndex = await SimilarityIndex(
    model: NativeEmbeddings(),
    metric: CosineSimilarity()
)

// Add your command patterns
await similarityIndex.addItem(
    id: "ATTACK_THIEF",
    text: "attack the thief",
    metadata: ["action": "ATTACK", "target": "THIEF"]
)
await similarityIndex.addItem(
    id: "ATTACK_THIEF",
    text: "kill the robber",
    metadata: ["action": "ATTACK", "target": "THIEF"]
)
// Add more command variations

// Search for the best match
let results = await similarityIndex.search("stab the robber")
if let bestMatch = results.first {
    let command = bestMatch.metadata["action"] as! String
    let target = bestMatch.metadata["target"] as! String
    // Use the standardized command: ATTACK THIEF
}
```


## Conclusion

For your interactive fiction game, I recommend implementing a hybrid approach that combines:

1. Word embeddings through NLEmbedding for semantic matching of verbs and objects
2. NLTagger for parsing commands into their components
3. A lightweight fuzzy matching algorithm for handling typos

This combination will provide robust command recognition while leveraging Apple's NaturalLanguage framework that you're already using. The solution scales well as you add more commands, and it can handle significant variations in how players phrase their intentions.

<div>⁂</div>

[^1_1]: https://www.youtube.com/watch?v=_IGdekeBCoE

[^1_2]: https://codesignal.com/learn/courses/linguistics-for-token-classification-in-spacy/lessons/understanding-semantic-similarity-in-nlp-with-spacy

[^1_3]: https://www.codeedit.app/blog/2024/02/generic-fuzzy-search-algorithm

[^1_4]: https://towardsdatascience.com/raw-text-correction-with-fuzzy-matching-for-nlp-tasks-828547742ef7/

[^1_5]: https://www.freecodecamp.org/news/what-is-semantic-matching-find-words-in-a-document-using-nlp/

[^1_6]: https://stackoverflow.com/questions/2207168/elegant-command-parsing-in-an-oop-based-text-game

[^1_7]: https://www.hackingwithswift.com/example-code/naturallanguage

[^1_8]: https://fritz.ai/natural-language-in-ios-12-customizing-tag-schemes-and-named-entity-recognition/

[^1_9]: https://forums.developer.apple.com/forums/thread/731229

[^1_10]: https://www.hackingwithswift.com/example-code/naturallanguage/how-to-find-similar-words-for-a-search-term

[^1_11]: http://hongchaozhang.github.io/blog/2019/05/22/offline-natural-language-understanding-engine-on-ios/

[^1_12]: https://stackoverflow.com/questions/74487658/ios-word-embedding-vector-is-nil-when-using-text-from-swiftui-textfield

[^1_13]: https://github.com/chullman/text-adventure

[^1_14]: https://intfiction.org/t/rewriting-the-multiple-command-part-of-the-parser/41507

[^1_15]: https://dev.to/integerman/adventure-game-sentence-parsing-with-compromise-50pb?comments_sort=latest

[^1_16]: https://github.com/alexsosn/iOS_ML

[^1_17]: https://github.com/seanoshea/FuzzyMatchingSwift

[^1_18]: https://github.com/ZachNagengast/similarity-search-kit

[^1_19]: https://datascience.stackexchange.com/questions/82186/what-library-to-choose-for-machine-learning-on-swift

[^1_20]: https://livsycode.com/swift/how-to-find-similar-words-with-an-nlembedding/

[^1_21]: https://fritz.ai/4-techniques-you-must-know-for-natural-language-processing-on-ios/

[^1_22]: https://dzone.com/articles/why-you-might-need-to-know-algorithms-as-a-mobile

[^1_23]: https://intfiction.org/t/python-parser-anyone/54814

[^1_24]: https://aclanthology.org/2022.games-1.4/

[^1_25]: https://aclanthology.org/2022.games-1.4.pdf

[^1_26]: https://stackoverflow.com/questions/32337135/fuzzy-search-algorithm-approximate-string-matching-algorithm

[^1_27]: https://github.com/madhurima-nath/nlp_fuzzy_match_algorithms

[^1_28]: https://www.pingcap.com/article/top-10-tools-for-calculating-semantic-similarity/

[^1_29]: https://textadventures.co.uk/forum/design/topic/i-qcvedsf0eugbkp1g7dua/on-parsing

[^1_30]: https://arxiv.org/abs/2205.13754

[^1_31]: https://talk.objc.io/episodes/S01E211-simple-fuzzy-matching

[^1_32]: https://www.amygb.ai/blog/how-does-fuzzy-matching-work

[^1_33]: https://fastdatascience.com/natural-language-processing/semantic-similarity-with-sentence-embeddings/

[^1_34]: https://gamedev.stackexchange.com/questions/92451/better-ways-to-parse-text-adventure-commands

[^1_35]: https://www.lyzr.ai/glossaries/intent-recognition/

[^1_36]: https://www.reddit.com/r/swift/comments/7zo0ms/fuzzy_matching_in_swift/

[^1_37]: https://www.microsoft.com/en-us/research/uploads/prod/2019/04/Auto-EM.pdf

[^1_38]: https://discourse.numenta.org/t/improving-apples-natural-language-framework-using-htm-in-ios-14-5/8624

[^1_39]: https://stackoverflow.com/questions/18439795/nlp-machine-learning-text-comparison

[^1_40]: https://www.tandfonline.com/doi/full/10.1080/08839514.2018.1448137

[^1_41]: https://developer.apple.com/videos/play/wwdc2023/10042/

[^1_42]: https://stefanblos.com/posts/natural-language-on-ios/

[^1_43]: https://slator.com/apple-giving-developers-new-set-nlp-tools/

[^1_44]: https://www.turing.com/kb/guide-on-word-embeddings-in-nlp

[^1_45]: https://www.mdpi.com/2073-8994/14/1/120

[^1_46]: https://www.swiftbysundell.com/wwdc2018/a-first-look-at-the-natural-language-framework

[^1_47]: https://developer.apple.com/documentation/naturallanguage/nllanguagerecognizer

[^1_48]: https://developer.apple.com/documentation/naturallanguage/nlembedding

[^1_49]: https://developer.apple.com/documentation/naturallanguage

[^1_50]: https://blog.boostcommerce.net/posts/fuzzy-search-and-shopify-site-search-tips-for-your-store

[^1_51]: https://www.choiceofgames.com/2010/04/make-a-choice-of-game-your-own-authorial-intent-in-if/

[^1_52]: https://killalldefects.com/2019/09/24/building-text-based-games-with-compromise-nlp/

[^1_53]: https://ganelson.github.io/inform-website/book/WI_18_33.html

[^1_54]: https://dspace.mit.edu/bitstream/handle/1721.1/129076/Montfort-Riddle-Machines.pdf?sequence=2\&isAllowed=y

[^1_55]: https://www.reddit.com/r/adventuregames/comments/1hik9gt/while_i_know_that_the_text_parser_in_adventure/

[^1_56]: https://www.inovex.de/en/blog/playing-text-adventure-games-with-natural-language-processing-and-reinforcement-learning/

[^1_57]: https://intfiction.org/t/replacing-the-parser/13385

[^1_58]: https://intfiction.org/t/audio-if-audio-interactive-fiction-interpreter/50745

[^1_59]: https://intfiction.org/t/question-over-parser-games-commercial-success/67777

[^1_60]: https://intfiction.org/t/ai-instead-of-classical-parser/62011

[^1_61]: https://inform-7-handbook.readthedocs.io/en/latest/chapter_10_advanced_topics/helping_the_parser/

[^1_62]: https://forum.choiceofgames.com/t/what-game-design-factors-make-a-good-piece-of-interactive-fiction/49980

[^1_63]: https://adventuregamers.com/archive/forums/adventure/13837-text-parser-appreciation.html

[^1_64]: https://www.carmatec.com/blog/top-10-natural-language-processing-tools-and-platforms/

[^1_65]: https://learn.microsoft.com/en-us/azure/ai-services/speech-service/get-started-intent-recognition

[^1_66]: https://stackoverflow.com/questions/2037832/semantic-similarity-between-sentences

[^1_67]: https://www.swiftbrief.com/blog/natural-language-processing-tools

[^1_68]: https://github.com/tornikegomareli/Talkify

[^1_69]: https://github.com/matteocrippa/awesome-swift

[^1_70]: https://swiftpackageindex.com/buhe/similarity-search-kit

[^1_71]: https://developer.apple.com/documentation/foundation/nslinguistictagger

[^1_72]: https://github.com/NMAC427/SwiftOCR

[^1_73]: https://www.edenai.co/post/top-free-nlp-tools-apis-and-open-source-models

[^1_74]: https://forums.swift.org/t/good-fuzzy-search-libraries/55325

[^1_75]: https://github.com/mrackwitz/Version

[^1_76]: https://forums.swift.org/t/nslinguistictagger-for-languages-other-than-english/13547

[^1_77]: https://learn.microsoft.com/en-us/azure/ai-services/speech-service/get-started-intent-recognition-clu

[^1_78]: https://forums.swift.org/t/narratore-a-library-that-can-be-used-to-create-and-run-interactive-stories-and-narrative-games/56872

[^1_79]: https://github.com/Flight-School/Guide-to-Swift-Strings-Sample-Code

[^1_80]: https://heartbeat.comet.ml/implementing-a-natural-language-classifier-in-ios-with-keras-core-ml-358f114c0b51

[^1_81]: https://developer.apple.com/videos/play/wwdc2019/232/

[^1_82]: https://www.youtube.com/watch?v=LE7tTYIrggg

[^1_83]: https://stackoverflow.com/questions/50787286/swift-nslinguistictagger-results-for-languages-other-than-english

[^1_84]: https://www.cs.tufts.edu/comp/150FP/archive/graham-nelson/WhitePaper.pdf

[^1_85]: https://stackoverflow.com/questions/10383044/fuzzy-string-comparison

[^1_86]: https://developer.apple.com/documentation/naturallanguage/finding-similarities-between-pieces-of-text

[^1_87]: https://developer.apple.com/documentation/naturallanguage/

[^1_88]: https://www.reddit.com/r/swift/comments/jf9t98/if_i_wanted_to_write_an_interactive_fiction_game/

