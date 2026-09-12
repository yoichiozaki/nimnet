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
- **Current edge attributes**: `EdgeAttr` is an object with a numeric `weight: float`
  and `extra: Table[string, string]`. This avoids parsing a string in weighted
  algorithm hot loops. `newEdgeAttr()` initializes the weight to `1.0`.
- **Current node attributes**: `NodeAttr = JsonNode`, stored separately for each
  node. JSON values support strings, numbers, booleans and nested objects.
- **Convenience weight accessors**: `weight(g, u, v)` and `getWeight(attr)` read the
  stored numeric field. The legacy `default` parameter to `getWeight` is retained
  for source compatibility, but does not override the stored field.

### Historical note

The original 2026-03-29 decision used string tables for both attribute kinds and
parsed edge weights. The representation above was already present in baseline
`2ece49c`; this ADR was reconciled with the shipped implementation on 2026-09-12.
This documentation update does not introduce an attribute migration.

## Consequences

- **Positive**: Numeric weight access without repeated parsing; flexible generic
  nodes and typed node metadata; only standard-library attribute types.
- **Negative**: Non-weight edge metadata remains string-valued, while node
  metadata uses reference-valued JSON. Neither attribute type is a table alias;
  callers should use the constructors and documented accessors.
