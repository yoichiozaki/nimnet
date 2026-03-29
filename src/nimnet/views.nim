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
