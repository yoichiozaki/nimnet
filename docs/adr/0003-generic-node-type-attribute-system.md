# ADR-0003: Generic Node Type and Attribute System

* Status: accepted
* Date: 2026-03-29

## Context

We need to decide how node and edge types work:
1. What constraints apply to node types?
2. How are edge attributes (especially weights) represented?

Options for edge attributes:
- A) Single generic type parameter `E` for edge data
- B) `Table[string, string]` — simple string-keyed attributes
- C) `Table[string, JsonNode]` — richer typed attributes

## Decision

- **Node type**: Generic `N` constrained to types that implement `hash` and `==` (via Nim's `Hash` concept). This allows `int`, `string`, or any custom type as nodes.
- **Edge attributes**: `Table[string, string]` for the initial implementation. This is simple, avoids heavy dependencies, and covers the common case of labeled/weighted edges via string conversion.
- **Node attributes**: Separate `Table[N, Table[string, string]]` stored on the graph object.
- **Convenience weight accessor**: `weight(g, u, v): float` proc that parses `"weight"` attribute.

## Consequences

- **Positive**: Simple, no external dependencies. Generic node type is flexible.
- **Negative**: String-based attributes require parsing for numeric operations. Less type-safe than a generic edge type.
- **Future**: Migration to `Table[string, JsonNode]` is planned (see issue) to support richer attribute types without changing the public API shape.
