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
| B01 | [#169](https://github.com/yoichiozaki/nimnet/issues/169) | P0 | Exact general-graph cardinality matching; genuinely minimum edge covers; small exhaustive oracles and odd-cycle cases; clear weighted-approximation guarantees. | In progress |
| B02 | [#177](https://github.com/yoichiozaki/nimnet/issues/177) | P1 | Layered Hopcroft-Karp and validated explicit partitions; optimal results on disconnected/generic-node graphs and measured scaling. | In progress |
| B03 | [#168](https://github.com/yoichiozaki/nimnet/issues/168) | P1 | Incremental modularity merge gains; reference-objective checks, graph edge cases, and before/after timings. | In progress |
| B04 | [#167](https://github.com/yoichiozaki/nimnet/issues/167) | P1 | Sparse weighted undirected all-pairs distances; compatible reachable-only defaults, explicit full `Inf` output, Floyd agreement and numeric/negative-cycle handling. | In progress |
| B05 | [#166](https://github.com/yoichiozaki/nimnet/issues/166) | P0 | Compact self-loop counts, degrees and weighted round-trips; retain ordinary CSR behavior. | In progress |
| B06 | [#170](https://github.com/yoichiozaki/nimnet/issues/170) | P1 | Typed directed edge-list/dataset loaders, meaningful legacy arguments, and directed GEXF label/weight preservation. | In progress |
| B07 | [#173](https://github.com/yoichiozaki/nimnet/issues/173) | P1 | Expected-linear `fastGnpRandomGraph`; seed repeatability, boundary/invalid inputs, density checks and sparse performance measurements. | In progress |
| B08 | [#172](https://github.com/yoichiozaki/nimnet/issues/172) | P0 | Explicit invalid-input/retry errors and valid regular graphs; preserve intentional documented generator behavior. | In progress |
| B09 | [#174](https://github.com/yoichiozaki/nimnet/issues/174) | P0 | One complete sorted test inventory for all runners and coverage; no masked failures; minimum/stable Nim coverage and version-aware caches. | In progress |
| B10 | [#176](https://github.com/yoichiozaki/nimnet/issues/176) | P1 | Identical benchmark inputs and work, monotonic elapsed timing, isolated runs, validated configuration, failure propagation and raw evidence. | In progress |
| B11 | [#175](https://github.com/yoichiozaki/nimnet/issues/175) | P2 | Integrate reviewed action upgrades from #160, #162, #163, #164 and #165 without unrelated dependency churn. | In progress |
| B12 | [#171](https://github.com/yoichiozaki/nimnet/issues/171) | P1 | Reconcile current attributes/APIs, examples, module inventory, guarantees, contributor guidance and changelog; link completion evidence. | In progress |
| B13 | [#178](https://github.com/yoichiozaki/nimnet/issues/178) | P0 | PageRank conserves mass for isolates/self-loops; independent transition references, nonnegative normalized ranks and serial/parallel parity. | In progress |
| B14 | [#179](https://github.com/yoichiozaki/nimnet/issues/179) | P0 | Louvain resolution scales the null model only; weighted objective references, meaningful low/high resolution and default-seed compatibility. | In progress |

## Delivery evidence

Implementation is on `feat/library-backlog-20260912`.
Completion evidence and measured results will be recorded here when the batch
has passed its acceptance checks.
