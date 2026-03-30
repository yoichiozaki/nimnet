## Read-only graph view for zero-copy algorithm input.
##
## ``GraphView`` wraps a ``Graph`` or ``DiGraph`` without copying data.
## Only read-only operations are exposed — no mutation.

import std/[tables, sets]
import ./types, ./graph, ./digraph

type
  GraphView*[N] = object
    ## Read-only view of an undirected graph.
    g: ptr Graph[N]

  DiGraphView*[N] = object
    ## Read-only view of a directed graph.
    g: ptr DiGraph[N]

func view*[N](g: Graph[N]): GraphView[N] =
  ## Create a read-only view of a graph.
  result.g = unsafeAddr g

func view*[N](g: DiGraph[N]): DiGraphView[N] =
  ## Create a read-only view of a directed graph.
  result.g = unsafeAddr g

# --- GraphView read-only operations ---

func len*[N](v: GraphView[N]): int {.inline.} =
  v.g[].len

func numberOfNodes*[N](v: GraphView[N]): int {.inline.} =
  v.g[].numberOfNodes

func numberOfEdges*[N](v: GraphView[N]): int {.inline.} =
  v.g[].numberOfEdges

func hasNode*[N](v: GraphView[N], n: N): bool {.inline.} =
  v.g[].hasNode(n)

func hasEdge*[N](v: GraphView[N], u, w: N): bool {.inline.} =
  v.g[].hasEdge(u, w)

func degree*[N](v: GraphView[N], n: N): int {.inline.} =
  v.g[].degree(n)

func `[]`*[N](v: GraphView[N], n: N): Table[N, EdgeAttr] =
  v.g[][n]

func `[]`*[N](v: GraphView[N], u, w: N): EdgeAttr =
  v.g[][u, w]

func getEdgeAttr*[N](v: GraphView[N], u, w: N): EdgeAttr {.inline.} =
  v.g[].getEdgeAttr(u, w)

iterator nodes*[N](v: GraphView[N]): N =
  for n in v.g[].nodes:
    yield n

iterator edges*[N](v: GraphView[N]): (N, N) =
  for e in v.g[].edges:
    yield e

iterator neighbors*[N](v: GraphView[N], n: N): N =
  for nb in v.g[].neighbors(n):
    yield nb

# --- DiGraphView read-only operations ---

func len*[N](v: DiGraphView[N]): int {.inline.} =
  v.g[].len

func numberOfNodes*[N](v: DiGraphView[N]): int {.inline.} =
  v.g[].numberOfNodes

func numberOfEdges*[N](v: DiGraphView[N]): int {.inline.} =
  v.g[].numberOfEdges

func hasNode*[N](v: DiGraphView[N], n: N): bool {.inline.} =
  v.g[].hasNode(n)

func hasEdge*[N](v: DiGraphView[N], u, w: N): bool {.inline.} =
  v.g[].hasEdge(u, w)

func inDegree*[N](v: DiGraphView[N], n: N): int {.inline.} =
  v.g[].inDegree(n)

func outDegree*[N](v: DiGraphView[N], n: N): int {.inline.} =
  v.g[].outDegree(n)

iterator nodes*[N](v: DiGraphView[N]): N =
  for n in v.g[].nodes:
    yield n

iterator edges*[N](v: DiGraphView[N]): (N, N) =
  for e in v.g[].edges:
    yield e

iterator successors*[N](v: DiGraphView[N], n: N): N =
  for nb in v.g[].successors(n):
    yield nb

iterator predecessors*[N](v: DiGraphView[N], n: N): N =
  for nb in v.g[].predecessors(n):
    yield nb

# --- Subgraph views (lazy filtered view) ---

type
  SubGraphView*[N] = object
    ## Lazy filtered subgraph view with node and edge filter predicates.
    g: ptr Graph[N]
    nodeFilter: proc(n: N): bool {.noSideEffect.}
    edgeFilter: proc(u, v: N): bool {.noSideEffect.}

proc subgraphView*[N](g: Graph[N],
                       filterNode: proc(n: N): bool {.noSideEffect.} = nil,
                       filterEdge: proc(u, v: N): bool {.noSideEffect.} = nil): SubGraphView[N] =
  ## Create a lazy filtered view of a graph.
  result.g = unsafeAddr g
  result.nodeFilter = filterNode
  result.edgeFilter = filterEdge

func acceptNode[N](v: SubGraphView[N], n: N): bool {.inline.} =
  v.nodeFilter.isNil or v.nodeFilter(n)

func acceptEdge[N](v: SubGraphView[N], u, w: N): bool {.inline.} =
  v.edgeFilter.isNil or v.edgeFilter(u, w)

func hasNode*[N](v: SubGraphView[N], n: N): bool =
  v.g[].hasNode(n) and v.acceptNode(n)

func hasEdge*[N](v: SubGraphView[N], u, w: N): bool =
  v.g[].hasEdge(u, w) and v.acceptNode(u) and v.acceptNode(w) and v.acceptEdge(u, w)

iterator nodes*[N](v: SubGraphView[N]): N =
  for n in v.g[].nodes:
    if v.acceptNode(n):
      yield n

iterator edges*[N](v: SubGraphView[N]): (N, N) =
  for (u, w) in v.g[].edges:
    if v.acceptNode(u) and v.acceptNode(w) and v.acceptEdge(u, w):
      yield (u, w)

func numberOfNodes*[N](v: SubGraphView[N]): int =
  for n in v.g[].nodes:
    if v.acceptNode(n):
      inc result

func numberOfEdges*[N](v: SubGraphView[N]): int =
  for (u, w) in v.g[].edges:
    if v.acceptNode(u) and v.acceptNode(w) and v.acceptEdge(u, w):
      inc result

iterator neighbors*[N](v: SubGraphView[N], n: N): N =
  for nb in v.g[].neighbors(n):
    if v.acceptNode(nb) and v.acceptEdge(n, nb):
      yield nb
