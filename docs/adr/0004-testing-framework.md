# ADR-0004: Testing Framework

* Status: accepted
* Date: 2026-03-29

## Context

Nim offers several testing options:
1. **`std/unittest`** — built-in, simple `suite`/`test`/`check` blocks
2. **Testament** — advanced test runner with spec blocks, multi-backend support
3. **`unittest2`** — community-maintained enhanced unittest

## Decision

We will use **`std/unittest`** from the standard library.

- Tests go in `tests/t*.nim` files
- `nimble test` compiles and runs all test files
- Each source module has a corresponding test file

## Consequences

- **Positive**: Zero external dependencies. Familiar to Nim developers. Good enough for our needs.
- **Negative**: No built-in parallel test execution. Less flexible than Testament for multi-backend testing.
- **Mitigation**: If we need more advanced features later, migration to Testament is straightforward.
