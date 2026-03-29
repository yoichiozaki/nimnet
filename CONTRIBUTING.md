# Contributing to nimnet

Thank you for your interest in contributing to nimnet!

## Getting Started

1. Fork and clone the repository
2. Open in DevContainer (recommended) or install Nim >= 2.0.0
3. Run `nimble test` to verify your setup

## Development Workflow

1. Check existing [Issues](https://github.com/yoichiozaki/nimnet/issues) or create a new one
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Write code and tests
4. Run `nimble test` to ensure all tests pass
5. Submit a Pull Request referencing the issue

## Code Style

- Follow [NEP-1](https://nim-lang.org/docs/nep1.html) naming conventions
- Types: `PascalCase`
- Procs/vars: `camelCase`
- Constructors: `initFoo` (value types), `newFoo` (ref types)
- Export public API with `*` suffix
- Write unit tests for all public procs in `tests/t*.nim`

## Testing

```bash
nimble test
```

Tests use `std/unittest`. Each module `src/nimnet/foo.nim` should have a corresponding `tests/tfoo.nim`.

## Architecture Decisions

Significant design decisions are recorded as ADRs in `docs/adr/`. If your change involves an architectural decision, please create a new ADR using the template at `docs/adr/0000-template.md`.

## Commit Messages

Use clear, descriptive commit messages:
- `feat: add Dijkstra's shortest path algorithm`
- `fix: correct edge removal in undirected graph`
- `docs: update API documentation for Graph[N]`
- `test: add tests for BFS traversal`

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
