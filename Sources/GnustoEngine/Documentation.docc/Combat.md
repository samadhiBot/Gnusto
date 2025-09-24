# Combat System

## Overview

The Gnusto combat system provides a flexible, extensible framework for implementing turn-based melee combat in interactive fiction games. It supports both default combat behavior and full customization through combat systems and messengers.

> The combat system is functional, but still has a lot of rough edges. Better documentation will come as the melee combat system matures.

## Architecture Components

### Core Protocols

- ``CombatSystem``
    - Defines combat behavior for enemies
    - **`enemyID`**: Links the system to a specific enemy
    - **`description`**: Custom combat event descriptions
    - **`processCombatTurn()`**: Main combat turn processing
    - **`calculateAttackOutcome()`**: Attack resolution logic
    - **`determineEnemyAction()`**: Enemy AI decisions

### Default Implementation

- ``StandardCombatSystem``
    - D&D-style d20 combat mechanics
    - Attribute-based attack and damage calculations
    - Intelligent enemy AI (fleeing, surrender, pacification)
    - Dynamic combat intensity and fatigue systems
    - Special combat events (disarming, staggering, vulnerability)

- ``CombatMessenger``
    - Rich narrative descriptions for all combat events
    - Context-aware messaging based on weapons and combatants
    - Multiple variations for each event type
    - Supports grammatically appropriate pronouns
