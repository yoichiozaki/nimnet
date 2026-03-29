## Multi-edge graph types supporting parallel edges.
##
## ``MultiGraph[N]`` — undirected graph with multiple edges per node pair.
## ``MultiDiGraph[N]`` — directed graph with multiple edges per node pair.
## Each edge is identified by (u, v, key) where key is an auto-assigned int.

import std/[tables, sets, hashes, strformat, json]
import ./types

type
  MultiGraph*[N] = object
    ## Undirected multigraph allowing parallel edges.
    adj*: Table[N, Table[N, Table[int, EdgeAttr]]]
    nodeAttr*: Table[N, NodeAttr]
    name*: string
    nextKey: int

  MultiDiGraph*[N] = object
    ## Directed multigraph allowing parallel edges.
    succ*: Table[N, Table[N, Table[int, EdgeAttr]]]
    pred*: Table[N, Table[N, Table[int, EdgeAttr]]]
    nodeAttr*: Table[N, NodeAttr]
    name*: string
    nextKey: int

# ===========================================================================
# MultiGraph
# ===========================================================================

func newMultiGraph*[N](name: string = ""): MultiGraph[N] =
  result.name = name
  result.nextKey = 0

func len*[N](g: MultiGraph[N]): int {.inline.} = g.adj.len

func numberOfNodes*[N](g: MultiGraph[N]): int {.inline.} = g.adj.len

func numberOfEdges*[N](g: MultiGraph[N]): int =
  var count = 0
  var seen = initHashSet[N]()
  for u, nbrs in g.adj:
    for v, keys in nbrs:
      if v notin seen:
        count += keys.len
    seen.incl(u)
  result = count

func hasNode*[N](g: MultiGraph[N], n: N): bool {.inline.} =
  n in g.adj

func hasEdge*[N](g: MultiGraph[N], u, v: N): bool =
  if u notin g.adj: return false
  v in g.adj[u]

func contains*[N](g: MultiGraph[N], n: N): bool {.inline.} = g.hasNode(n)

proc addNode*[N](g: var MultiGraph[N], n: N) =
  if n notin g.adj:
    g.adj[n] = initTable[N, Table[int, EdgeAttr]]()

proc addEdge*[N](g: var MultiGraph[N], u, v: N,
                  attr: EdgeAttr = newJObject()): int =
  ## Add an edge between u and v, return the edge key.
  g.addNode(u)
  g.addNode(v)
  let key = g.nextKey
  g.nextKey += 1

  if v notin g.adj[u]:
    g.adj[u][v] = initTable[int, EdgeAttr]()
  g.adj[u][v][key] = attr

  if u notin g.adj[v]:
    g.adj[v][u] = initTable[int, EdgeAttr]()
  g.adj[v][u][key] = attr

  result = key

proc addWeightedEdge*[N](g: var MultiGraph[N], u, v: N, weight: float): int =
  var attr = newEdgeAttr(weight)
  result = g.addEdge(u, v, attr)

proc removeEdge*[N](g: var MultiGraph[N], u, v: N, key: int) =
  if u notin g.adj or v notin g.adj[u] or key notin g.adj[u][v]:
    raise newException(EdgeNotFound, fmt"Edge ({u}, {v}, {key}) not found")
  g.adj[u][v].del(key)
  if g.adj[u][v].len == 0:
    g.adj[u].del(v)
  g.adj[v][u].del(key)
  if g.adj[v][u].len == 0:
    g.adj[v].del(u)

proc removeNode*[N](g: var MultiGraph[N], n: N) =
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  for v in g.adj[n].keys:
    if v != n:
      g.adj[v].del(n)
  g.adj.del(n)
  g.nodeAttr.del(n)

func degree*[N](g: MultiGraph[N], n: N): int =
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  for v, keys in g.adj[n]:
    result += keys.len

iterator nodes*[N](g: MultiGraph[N]): N =
  for n in g.adj.keys:
    yield n

iterator edges*[N](g: MultiGraph[N]): (N, N, int) =
  ## Yield (u, v, key) for each edge.
  var seen = initHashSet[N]()
  for u in g.adj.keys:
    for v, keys in g.adj[u]:
      if v notin seen or u == v:
        for key in keys.keys:
          yield (u, v, key)
    seen.incl(u)

iterator neighbors*[N](g: MultiGraph[N], n: N): N =
  if n in g.adj:
    for v in g.adj[n].keys:
      yield v

func `$`*[N](g: MultiGraph[N]): string =
  fmt"MultiGraph(nodes={g.numberOfNodes}, edges={g.numberOfEdges})"

# ===========================================================================
# MultiDiGraph
# ===========================================================================

func newMultiDiGraph*[N](name: string = ""): MultiDiGraph[N] =
  result.name = name
  result.nextKey = 0

func len*[N](g: MultiDiGraph[N]): int {.inline.} = g.succ.len

func numberOfNodes*[N](g: MultiDiGraph[N]): int {.inline.} = g.succ.len

func numberOfEdges*[N](g: MultiDiGraph[N]): int =
  var count = 0
  for u, nbrs in g.succ:
    for v, keys in nbrs:
      count += keys.len
  result = count

func hasNode*[N](g: MultiDiGraph[N], n: N): bool {.inline.} =
  n in g.succ

func hasEdge*[N](g: MultiDiGraph[N], u, v: N): bool =
  if u notin g.succ: return false
  v in g.succ[u]

func contains*[N](g: MultiDiGraph[N], n: N): bool {.inline.} = g.hasNode(n)

proc addNode*[N](g: var MultiDiGraph[N], n: N) =
  if n notin g.succ:
    g.succ[n] = initTable[N, Table[int, EdgeAttr]]()
    g.pred[n] = initTable[N, Table[int, EdgeAttr]]()

proc addEdge*[N](g: var MultiDiGraph[N], u, v: N,
                  attr: EdgeAttr = newJObject()): int =
  g.addNode(u)
  g.addNode(v)
  let key = g.nextKey
  g.nextKey += 1

  if v notin g.succ[u]:
    g.succ[u][v] = initTable[int, EdgeAttr]()
  g.succ[u][v][key] = attr

  if u notin g.pred[v]:
    g.pred[v][u] = initTable[int, EdgeAttr]()
  g.pred[v][u][key] = attr

  result = key

proc addWeightedEdge*[N](g: var MultiDiGraph[N], u, v: N, weight: float): int =
  var attr = newEdgeAttr(weight)
  result = g.addEdge(u, v, attr)

proc removeEdge*[N](g: var MultiDiGraph[N], u, v: N, key: int) =
  if u notin g.succ or v notin g.succ[u] or key notin g.succ[u][v]:
    raise newException(EdgeNotFound, fmt"Edge ({u}, {v}, {key}) not found")
  g.succ[u][v].del(key)
  if g.succ[u][v].len == 0:
    g.succ[u].del(v)
  g.pred[v][u].del(key)
  if g.pred[v][u].len == 0:
    g.pred[v].del(u)

proc removeNode*[N](g: var MultiDiGraph[N], n: N) =
  if n notin g.succ:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  for v in g.succ[n].keys:
    g.pred[v].del(n)
  for v in g.pred[n].keys:
    if v != n:
      g.succ[v].del(n)
  g.succ.del(n)
  g.pred.del(n)
  g.nodeAttr.del(n)

func outDegree*[N](g: MultiDiGraph[N], n: N): int =
  if n notin g.succ:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  for v, keys in g.succ[n]:
    result += keys.len

func inDegree*[N](g: MultiDiGraph[N], n: N): int =
  if n notin g.pred:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  for v, keys in g.pred[n]:
    result += keys.len

iterator nodes*[N](g: MultiDiGraph[N]): N =
  for n in g.succ.keys:
    yield n

iterator edges*[N](g: MultiDiGraph[N]): (N, N, int) =
  for u in g.succ.keys:
    for v, keys in g.succ[u]:
      for key in keys.keys:
        yield (u, v, key)

iterator successors*[N](g: MultiDiGraph[N], n: N): N =
  if n in g.succ:
    for v in g.succ[n].keys:
      yield v

iterator predecessors*[N](g: MultiDiGraph[N], n: N): N =
  if n in g.pred:
    for v in g.pred[n].keys:
      yield v

func `$`*[N](g: MultiDiGraph[N]): string =
  fmt"MultiDiGraph(nodes={g.numberOfNodes}, edges={g.numberOfEdges})"
