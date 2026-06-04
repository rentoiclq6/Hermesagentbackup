---
name: software-design-patterns
description: "GoF design patterns, architectural patterns, and their application across domains — AUTOSAR, web, embedded, ML systems."
version: 1.0.0
author: Hermes Agent
tags: [design-patterns, gof, architecture, autosar, uml, system-design]
---

# Software Design Patterns

A class-level reference for GoF (Gang of Four) design patterns and their real-world application across domains. Load this skill whenever the user asks about design patterns, system architecture, pattern comparisons, UML, or domain-specific pattern mappings (e.g. AUTOSAR, game dev, web backends).

## Quick Reference: 23 GoF Patterns

### Creational (5)

| Pattern | Intent | Classic Example |
|---------|--------|----------------|
| **Singleton** | One instance, global access | DB connection pool, ECU Manager |
| **Factory Method** | Subclass decides which class to instantiate | MCAL drivers: different chips → different drivers |
| **Abstract Factory** | Family of related objects | UI toolkit: Win/Mac/Linux button families |
| **Builder** | Step-by-step construction | Code generators, meal builders |
| **Prototype** | Clone existing instances | Snapshot/undo systems |

### Structural (7)

| Pattern | Intent | Classic Example |
|---------|--------|----------------|
| **Adapter** | Make incompatible interfaces work together | HAL abstraction, electrical plug adapters |
| **Bridge** | Separate abstraction from implementation | Platform-independent UI framework |
| **Composite** | Tree structure, treat leaf & container uniformly | UI component trees, Simulink subsystem hierarchy |
| **Decorator** | Dynamically add responsibilities | Java I/O streams, middleware chains |
| **Facade** | Simplified interface to a complex subsystem | RTE API in AUTOSAR, REST API wrappers |
| **Flyweight** | Share fine-grained objects to save memory | Character glyphs in text editors |
| **Proxy** | Control access to another object | Lazy loading, remote proxies, access control |

### Behavioral (11)

| Pattern | Intent | Classic Example |
|---------|--------|----------------|
| **Chain of Responsibility** | Pass request along a chain until handled | AUTOSAR COM Stack, middleware pipelines |
| **Command** | Encapsulate request as an object | Undo/redo, task queues, transaction logging |
| **Interpreter** | Define grammar + interpreter for a language | Regex engines, DSL evaluation |
| **Iterator** | Sequential access without exposing structure | Collection traversal in C++/Python |
| **Mediator** | Centralize communication between objects | AUTOSAR RTE, chat room server |
| **Memento** | Capture & restore internal state | Save games, checkpoints, Ctrl+Z |
| **Observer** | One-to-many notification on state change | Event systems, AUTOSAR Sender-Receiver |
| **State** | Object behavior changes with internal state | Stateflow/Statecharts, TCP connection states |
| **Strategy** | Interchangeable family of algorithms | Compression algorithms, drive modes (Eco/Sport) |
| **Template Method** | Skeleton algorithm, steps filled by subclasses | Framework callbacks, AUTOSAR SWC Templates |
| **Visitor** | Add operations without changing element classes | AST traversal, compiler optimizations |

## Trigger Conditions

Load this skill when the user:

- Asks about any design pattern (GoF or other)
- Asks about system architecture or architecture documentation
- Asks about AUTOSAR, MBD (Model-Based Design), or embedded software architecture
- Asks about UML diagrams or modeling
- Asks "which pattern should I use for X?"

## Reference Files

- `references/autosar-mbd-patterns.md` — Deep mapping of all 23 GoF patterns to AUTOSAR (Classic + Adaptive), Simulink MBD workflows, and practical advice per development role

## Pitfalls

- **Don't force patterns** — not every problem needs a pattern. Ask the user about constraints first.
- **Domain matters** — State and Observer dominate AUTOSAR; Command and Proxy dominate web backends. Contextualize your answer.
- **MBD ≠ UML** — Model-Based Design (Simulink) is different from UML modeling. Don't conflate them without clarification.
- **Adaptive AUTOSAR is C++ OOP** — patterns apply differently in Classic (C, struct-based) vs Adaptive (C++, class-based).

## How to Answer Pattern Questions

1. Identify the user's domain (web, embedded, game, ML, general)
2. List 2-3 relevant patterns with their intent + one domain-specific example
3. If the user wants a comparison, present pros/cons as a table
4. If the user asks "which pattern?", ask clarifying questions about constraints (performance, maintainability, team size, existing architecture)
5. Point to reference files for deep dives on specific domains
