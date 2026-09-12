---
layout: default
title: Improvement Backlog
nav_order: 3
---

# Library improvement backlog

Assessment date: 2026-09-12. Baseline: `2ece49c` (1.0.0).

## Scope and selection

The assessment covered algorithm APIs and complexity, graph representations,
generators, I/O round-trips, the test inventory, packaging, CI, documentation,
benchmark methodology, and the five open dependency-update pull requests.
Items were selected for observable correctness problems, broadly useful
backward-compatible additions, measurable performance gains, or reproducibility.

This is a finite delivery batch: all fourteen accepted items below must be
implemented and verified. It is not a claim that every possible future feature
or defect has been exhausted. Replacing the adjacency-map architecture, adding
native/GPU dependencies, implementing an exact weighted-blossom solver, and
replacing explicitly documented approximation algorithms were not accepted.
Existing approximation guarantees will instead be made unambiguous.

The initial twelve items were extended by B13 and B14 when benchmark alignment
exposed PageRank probability loss and a nonfunctional Louvain resolution
parameter. These correctness defects are included rather than hidden by
choosing specially restricted fixtures. No further algorithm expansion is
part of this batch.

## Accepted backlog

| ID | Issue | Priority | Work and acceptance criteria | Status |
|----|-------|----------|------------------------------|--------|
| B01 | [#169](https://github.com/yoichiozaki/nimnet/issues/169) | P0 | Exact general-graph cardinality matching; genuinely minimum edge covers; small exhaustive oracles and odd-cycle cases; clear weighted-approximation guarantees. | Implemented |
| B02 | [#177](https://github.com/yoichiozaki/nimnet/issues/177) | P1 | Layered Hopcroft-Karp and validated explicit partitions; optimal results on disconnected/generic-node graphs and measured scaling. | Implemented |
| B03 | [#168](https://github.com/yoichiozaki/nimnet/issues/168) | P1 | Incremental modularity merge gains; reference-objective checks, graph edge cases, and before/after timings. | Implemented |
| B04 | [#167](https://github.com/yoichiozaki/nimnet/issues/167) | P1 | Sparse weighted undirected all-pairs distances; compatible reachable-only defaults, explicit full `Inf` output, Floyd agreement and numeric/negative-cycle handling. | Implemented |
| B05 | [#166](https://github.com/yoichiozaki/nimnet/issues/166) | P0 | Compact self-loop counts, degrees and weighted round-trips; retain ordinary CSR behavior. | Implemented |
| B06 | [#170](https://github.com/yoichiozaki/nimnet/issues/170) | P1 | Typed directed edge-list/dataset loaders, meaningful legacy arguments, and directed GEXF label/weight preservation. | Implemented |
| B07 | [#173](https://github.com/yoichiozaki/nimnet/issues/173) | P1 | Expected-linear `fastGnpRandomGraph`; seed repeatability, boundary/invalid inputs, density checks and sparse performance measurements. | Implemented |
| B08 | [#172](https://github.com/yoichiozaki/nimnet/issues/172) | P0 | Explicit invalid-input/retry errors and valid regular graphs; preserve intentional documented generator behavior. | Implemented |
| B09 | [#174](https://github.com/yoichiozaki/nimnet/issues/174) | P0 | One complete sorted test inventory for all runners and coverage; no masked failures; minimum/stable Nim coverage and version-aware caches. | Implemented |
| B10 | [#176](https://github.com/yoichiozaki/nimnet/issues/176) | P1 | Identical benchmark inputs and work, monotonic elapsed timing, isolated runs, validated configuration, failure propagation and raw evidence. | Implemented |
| B11 | [#175](https://github.com/yoichiozaki/nimnet/issues/175) | P2 | Integrate reviewed action upgrades from #160, #162, #163, #164 and #165 without unrelated dependency churn. | Implemented |
| B12 | [#171](https://github.com/yoichiozaki/nimnet/issues/171) | P1 | Reconcile current attributes/APIs, examples, module inventory, guarantees, contributor guidance and changelog; link completion evidence. | Implemented |
| B13 | [#178](https://github.com/yoichiozaki/nimnet/issues/178) | P0 | PageRank conserves mass for isolates/self-loops; independent transition references, nonnegative normalized ranks and serial/parallel parity. | Implemented |
| B14 | [#179](https://github.com/yoichiozaki/nimnet/issues/179) | P0 | Louvain resolution scales the null model only; weighted objective references, meaningful low/high resolution and default-seed compatibility. | Implemented |

## Delivery evidence

All fourteen implementations are committed on `feat/library-backlog-20260912`
and delivered in [PR #180](https://github.com/yoichiozaki/nimnet/pull/180).
**Implementation completion is not merge completion:** `main` requires one
independent approving review. That requirement is not bypassed. The PR links
all fourteen issues for automatic closure when it is approved and merged.

The verified implementation commit is `6e47786`:

| Evidence | Result |
|----------|--------|
| Complete discovered Nim inventory | 25 files, 1,507 passing cases through both `nimble test` and `build_tests` + `run_tests` |
| Matching | Exhaustive small-graph and seeded oracles, odd-cycle contraction, a long iterative augmenting path, exact cover checks |
| Communities and paths | Greedy objective references, seeded Floyd comparisons, explicit sparse/full result shapes, a 2,048-isolate allocation regression |
| Stochastic algorithms | Independent PageRank transition references, mass conservation, weighted resolution checks; serial/parallel and thread-mode coverage |
| Generators and I/O | Boundary/statistical/invariant checks, invalid-input errors, typed loaders, labels, weights and compact-loop round-trips |
| Tooling | 14 Python tests; strict zero-diagnostic API docs; public examples on stable and exact Nim 2.0.0; actionlint |
| Failure propagation | Injected compile/runtime/coverage failures and unknown selectors return failure; invalid benchmark runs cannot reuse stale CSV |
| CI | [Stable on Ubuntu/macOS/Windows and exact Nim 2.0.0 on Ubuntu](https://github.com/yoichiozaki/nimnet/actions/runs/34675755949) all passed |
| Source coverage | [93.17% across 106 executable Nim source records](https://github.com/yoichiozaki/nimnet/actions/runs/34675755918); generated C and test files excluded |
| Comparison runner | [Full shared-fixture comparison workflow](https://github.com/yoichiozaki/nimnet/actions/runs/34675755933) passed; both native runners and explicit Nim-only modes also exercised |

Controlled release-mode measurements exceeded all four 2x improvement targets:
greedy modularity 3,687.7x (128 nodes), bipartite matching 30.6x (1,024 nodes),
sparse Johnson versus Floyd 160.3x (256 nodes), and fast versus dense G(n,p)
24.6x (10,000 nodes). These ratios describe the selected workloads only.
See [raw CSV, environment, hashes, methods and reproduction commands](https://github.com/yoichiozaki/nimnet/tree/feat/library-backlog-20260912/benchmarks)
for the full evidence and the distinction between revision comparisons and
alternative-algorithm comparisons.
