# Gnusto Engine

A modern Swift implementation of an Interactive Fiction (IF) engine, designed to be powerful, flexible, and maintainable. The engine is built with a focus on clean, efficient, and well-structured code, adhering to SOLID principles and modern Swift practices.

## Project Structure

The project is organized into two main directories:

- **Sources/GnustoEngine:** Contains the core engine code.
- **Executables:** Contains example games and demos built using the engine.

## Core Engine Features

### Item System

The `Item` class represents interactable objects within the game world. Key features include:

- **Properties:** Items can have a set of `ItemProperty` values defining their characteristics.
- **Descriptions:** Items have `description`, `firstDescription`, and `subsequentDescription` for static text.
- **Synonyms and Adjectives:** Items can have synonyms and adjectives for flexible command parsing.
- **Size and Capacity:** Items have a `size` and `capacity` for inventory management.

### Action Handling

- **Current State:** Basic action handling is in place, with plans to enhance it for more dynamic behavior.
- **Future Goals:** Implement `before` and `after` routines for action validation and side effects, as outlined in the ROADMAP.

### Dynamic Content

- **Current State:** Descriptions are static strings.
- **Future Goals:** Implement dynamic descriptions based on game state, using either closure-based or handler-based approaches.

### Custom State Management

- **Current State:** Limited to boolean properties via `Item.properties`.
- **Future Goals:** Extend support for custom, mutable state on items and locations.

### Parser

- **Current State:** Basic command parsing with synonyms and adjectives.
- **Future Goals:** Enhance parser to handle custom grammar and advanced noun phrase parsing.

## Development Conventions

- **Code Style:** Alphabetize properties, functions, enum cases, etc., unless another ordering is more logical.
- **Testing:** Use `Swift Testing` over `XCTest` unless working on a legacy project.
- **Documentation:** Include clear inline documentation for all types, functions, properties, and enumeration cases.
- **Project Organization:** Organize projects in a logical hierarchy of folders and files, with a dedicated file for each type of any complexity or importance.

## Example Games

### Cloak of Darkness

A simple demonstration of Interactive Fiction, showcasing the engine's capabilities. The game features:

- Three rooms: Foyer, Bar, and Cloakroom.
- Three objects: Hook, Cloak, and Message.
- Dynamic descriptions and action handling based on game state.

### Frobozz Magic Demo Kit

A demo kit showcasing the engine's features and providing a template for new games.

## Next Steps

Refer to the [ROADMAP.md](Docs/ROADMAP.md) for detailed information on the next major phase of development, focusing on dynamic content and action handling.

## Getting Started

1. Clone the repository.
2. Open the project in Xcode.
3. Build and run the example games in the `Executables` directory.

## Contributing

Contributions are welcome! Please ensure your code adheres to the project's conventions and includes appropriate tests and documentation.
