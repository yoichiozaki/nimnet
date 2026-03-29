## Directed graph implementation for nimnet
##
## A ``DiGraph`` stores nodes and directed edges with optional attributes.
## Both successor and predecessor maps are maintained for efficient
## traversal in either direction.
##
## .. code-block:: nim
##   var g = newDiGraph[int]()
##   g.addEdgesFrom([(1, 2), (2, 3)])
##   assert 1 in g
##   assert g.outDegree(1) == 1

import std/[tables, sets, strformat]
import types

type
  DiGraph*[N] = object
    ## A directed graph with nodes of type N.
    adj: Table[N, Table[N, EdgeAttr]]   ## successors
    pred: Table[N, Table[N, EdgeAttr]]  ## predecessors
    nodeAttr: Table[N, NodeAttr]
    edgeCount: int  ## Cached edge count — O(1) access
    name*: string

# --- Constructors ---

func newDiGraph*[N](name: string = ""): DiGraph[N] =
  ## Create a new empty directed graph.
  DiGraph[N](
    adj: initTable[N, Table[N, EdgeAttr]](),
    pred: initTable[N, Table[N, EdgeAttr]](),
    nodeAttr: initTable[N, NodeAttr](),
    edgeCount: 0,
    name: name
  )

# --- Metrics (O(1)) ---

func len*[N](g: DiGraph[N]): int {.inline.} =
  ## Number of nodes. Enables ``g.len``.
  g.adj.len

func numberOfNodes*[N](g: DiGraph[N]): int {.inline.} = g.adj.len
func order*[N](g: DiGraph[N]): int {.inline.} = g.adj.len
func numberOfEdges*[N](g: DiGraph[N]): int {.inline.} = g.edgeCount
func size*[N](g: DiGraph[N]): int {.inline.} = g.edgeCount

# --- Membership (O(1)) ---

func contains*[N](g: DiGraph[N], n: N): bool {.inline.} =
  ## Enables ``n in g``.
  n in g.adj

func hasNode*[N](g: DiGraph[N], n: N): bool {.inline.} = n in g.adj

func hasEdge*[N](g: DiGraph[N], u, v: N): bool {.inline.} =
  u in g.adj and v in g.adj[u]

# --- Node operations ---

proc addNode*[N](g: var DiGraph[N], n: N) {.inline.} =
  ## Add a node to the graph.
  if n notin g.adj:
    g.adj[n] = initTable[N, EdgeAttr]()
    g.pred[n] = initTable[N, EdgeAttr]()

proc addNode*[N](g: var DiGraph[N], n: N, attr: NodeAttr) =
  g.addNode(n)
  g.nodeAttr[n] = attr

proc addNodesFrom*[N](g: var DiGraph[N], nodes: openArray[N]) =
  ## Batch-add multiple nodes.
  for n in nodes:
    g.addNode(n)

proc removeNode*[N](g: var DiGraph[N], n: N) =
  ## Remove a node and all its incident edges.
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  # Decrement for all outgoing edges (including self-loop)
  g.edgeCount -= g.adj[n].len
  for succ in g.adj[n].keys:
    if succ != n:
      g.pred[succ].del(n)
  # Decrement for incoming edges from other nodes
  for pred in g.pred[n].keys:
    if pred != n:
      g.adj[pred].del(n)
      g.edgeCount.dec
  g.adj.del(n)
  g.pred.del(n)
  g.nodeAttr.del(n)

# --- Edge operations ---

proc addEdge*[N](g: var DiGraph[N], u, v: N, attr: EdgeAttr) =
  ## Add a directed edge from ``u`` to ``v`` with attributes.
  g.addNode(u)
  g.addNode(v)
  let isNew = v notin g.adj[u]
  g.adj[u][v] = attr
  g.pred[v][u] = attr
  if isNew:
    g.edgeCount.inc

proc addEdge*[N](g: var DiGraph[N], u, v: N) {.inline.} =
  ## Add a directed edge without attributes.
  g.addEdge(u, v, newEdgeAttr())

proc addWeightedEdge*[N](g: var DiGraph[N], u, v: N, weight: float) {.inline.} =
  g.addEdge(u, v, newEdgeAttr(weight))

proc addEdgesFrom*[N](g: var DiGraph[N], edges: openArray[(N, N)]) =
  ## Batch-add directed edges.
  for (u, v) in edges:
    g.addEdge(u, v)

proc addWeightedEdgesFrom*[N](g: var DiGraph[N],
    edges: openArray[tuple[u, v: N, weight: float]]) =
  for e in edges:
    g.addWeightedEdge(e.u, e.v, e.weight)

proc removeEdge*[N](g: var DiGraph[N], u, v: N) =
  ## Remove the directed edge from ``u`` to ``v``.
  if u notin g.adj or v notin g.adj[u]:
    raise newException(EdgeNotFound, fmt"Edge ({u}, {v}) not found")
  g.adj[u].del(v)
  g.pred[v].del(u)
  g.edgeCount.dec

# --- Subscript operators ---

func `[]`*[N](g: DiGraph[N], n: N): Table[N, EdgeAttr] =
  ## Access the successor dict: ``g[n]``.
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  g.adj[n]

func `[]`*[N](g: DiGraph[N], u, v: N): EdgeAttr =
  ## Access edge attributes: ``g[u, v]``.
  if not g.hasEdge(u, v):
    raise newException(EdgeNotFound, fmt"Edge ({u}, {v}) not found")
  g.adj[u][v]

# --- Attribute operations ---

func getNodeAttr*[N](g: DiGraph[N], n: N): NodeAttr =
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  g.nodeAttr.getOrDefault(n, newNodeAttr())

proc setNodeAttr*[N](g: var DiGraph[N], n: N, attr: NodeAttr) =
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  g.nodeAttr[n] = attr

proc setNodeAttr*[N](g: var DiGraph[N], n: N, key, value: string) =
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  if n notin g.nodeAttr:
    g.nodeAttr[n] = newNodeAttr()
  g.nodeAttr[n][key] = value

func getEdgeAttr*[N](g: DiGraph[N], u, v: N): EdgeAttr =
  if not g.hasEdge(u, v):
    raise newException(EdgeNotFound, fmt"Edge ({u}, {v}) not found")
  g.adj[u][v]

proc setEdgeAttr*[N](g: var DiGraph[N], u, v: N, attr: EdgeAttr) =
  if not g.hasEdge(u, v):
    raise newException(EdgeNotFound, fmt"Edge ({u}, {v}) not found")
  g.adj[u][v] = attr
  g.pred[v][u] = attr

proc setEdgeAttr*[N](g: var DiGraph[N], u, v: N, key, value: string) =
  if not g.hasEdge(u, v):
    raise newException(EdgeNotFound, fmt"Edge ({u}, {v}) not found")
  g.adj[u][v][key] = value
  g.pred[v][u][key] = value

func weight*[N](g: DiGraph[N], u, v: N, default: float = 1.0): float {.inline.} =
  if not g.hasEdge(u, v):
    raise newException(EdgeNotFound, fmt"Edge ({u}, {v}) not found")
  g.adj[u][v].getWeight(default)

# --- Iterators ---

iterator items*[N](g: DiGraph[N]): N =
  ## Iterate over nodes. Enables ``for n in g``.
  for n in g.adj.keys:
    yield n

iterator nodes*[N](g: DiGraph[N]): N =
  for n in g.adj.keys:
    yield n

iterator pairs*[N](g: DiGraph[N]): (N, Table[N, EdgeAttr]) =
  ## Iterate ``(node, successorDict)`` pairs.
  for n, neighbors in g.adj:
    yield (n, neighbors)

iterator edges*[N](g: DiGraph[N]): (N, N) =
  for u in g.adj.keys:
    for v in g.adj[u].keys:
      yield (u, v)

iterator edgesWithAttr*[N](g: DiGraph[N]): (N, N, EdgeAttr) =
  for u in g.adj.keys:
    for v, attr in g.adj[u]:
      yield (u, v, attr)

iterator neighbors*[N](g: DiGraph[N], n: N): N =
  ## Iterate over successors of node ``n``.
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  for neighbor in g.adj[n].keys:
    yield neighbor

iterator successors*[N](g: DiGraph[N], n: N): N =
  ## Alias for ``neighbors``.
  for s in g.neighbors(n):
    yield s

iterator predecessors*[N](g: DiGraph[N], n: N): N =
  ## Iterate over predecessors of node ``n``.
  if n notin g.pred:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  for p in g.pred[n].keys:
    yield p

# --- Degree ---

func outDegree*[N](g: DiGraph[N], n: N): int {.inline.} =
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  g.adj[n].len

func inDegree*[N](g: DiGraph[N], n: N): int {.inline.} =
  if n notin g.pred:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  g.pred[n].len

func degree*[N](g: DiGraph[N], n: N): int {.inline.} =
  ## Return the degree (in + out) of node ``n``.
  g.inDegree(n) + g.outDegree(n)

iterator degree*[N](g: DiGraph[N]): (N, int) =
  for n in g.adj.keys:
    yield (n, g.degree(n))

iterator inDegreeIter*[N](g: DiGraph[N]): (N, int) =
  for n in g.adj.keys:
    yield (n, g.inDegree(n))

iterator outDegreeIter*[N](g: DiGraph[N]): (N, int) =
  for n in g.adj.keys:
    yield (n, g.outDegree(n))

# --- Graph properties ---

func density*[N](g: DiGraph[N]): float =
  let n = g.len
  let m = g.edgeCount
  if n <= 1: 0.0
  else: float(m) / (float(n) * float(n - 1))

func isEmpty*[N](g: DiGraph[N]): bool {.inline.} = g.edgeCount == 0
func isDirected*[N](g: DiGraph[N]): bool {.inline.} = true
func hasSelfLoop*[N](g: DiGraph[N], n: N): bool {.inline.} = g.hasEdge(n, n)

func numberOfSelfLoops*[N](g: DiGraph[N]): int =
  for n in g.adj.keys:
    if n in g.adj[n]: result.inc

# --- Copy and equality ---

func copy*[N](g: DiGraph[N]): DiGraph[N] =
  result.name = g.name
  result.edgeCount = g.edgeCount
  for u, neighbors in g.adj:
    result.adj[u] = initTable[N, EdgeAttr]()
    for v, attr in neighbors:
      result.adj[u][v] = attr
  for v, preds in g.pred:
    result.pred[v] = initTable[N, EdgeAttr]()
    for u, attr in preds:
      result.pred[v][u] = attr
  for n, attr in g.nodeAttr:
    result.nodeAttr[n] = attr

func `==`*[N](a, b: DiGraph[N]): bool =
  a.adj == b.adj and a.nodeAttr == b.nodeAttr

proc clear*[N](g: var DiGraph[N]) =
  g.adj.clear()
  g.pred.clear()
  g.nodeAttr.clear()
  g.edgeCount = 0

proc clearEdges*[N](g: var DiGraph[N]) =
  for n in g.adj.keys: g.adj[n].clear()
  for n in g.pred.keys: g.pred[n].clear()
  g.edgeCount = 0

# --- Subgraph ---

func recomputeEdgeCount[N](g: var DiGraph[N]) =
  g.edgeCount = 0
  for u, neighbors in g.adj:
    g.edgeCount += neighbors.len

func subgraph*[N](g: DiGraph[N], nbunch: HashSet[N]): DiGraph[N] =
  result = newDiGraph[N](g.name)
  for n in nbunch:
    if n in g.adj:
      result.adj[n] = initTable[N, EdgeAttr]()
      result.pred[n] = initTable[N, EdgeAttr]()
      if n in g.nodeAttr:
        result.nodeAttr[n] = g.nodeAttr[n]
  for u in result.adj.keys:
    for v, attr in g.adj[u]:
      if v in result.adj:
        result.adj[u][v] = attr
        result.pred[v][u] = attr
  recomputeEdgeCount(result)

func subgraph*[N](g: DiGraph[N], nbunch: openArray[N]): DiGraph[N] =
  g.subgraph(nbunch.toHashSet)

# --- Reverse ---

func reverse*[N](g: DiGraph[N]): DiGraph[N] =
  ## Return a new graph with all edges reversed.
  result = newDiGraph[N](g.name)
  for n in g.adj.keys:
    result.addNode(n)
  for n, attr in g.nodeAttr:
    result.nodeAttr[n] = attr
  for (u, v, attr) in g.edgesWithAttr:
    let isNew = u notin result.adj[v]
    result.adj[v][u] = attr
    result.pred[u][v] = attr
    if isNew:
      result.edgeCount.inc

# --- String representation ---

func `$`*[N](g: DiGraph[N]): string =
  let name = if g.name.len > 0: g.name else: "DiGraph"
  fmt"{name}(nodes={g.len}, edges={g.edgeCount})"

# --- Utility ---

func nodeSeq*[N](g: DiGraph[N]): seq[N] =
  result = newSeqOfCap[N](g.len)
  for n in g.adj.keys:
    result.add(n)

func edgeSeq*[N](g: DiGraph[N]): seq[(N, N)] =
  result = newSeqOfCap[(N, N)](g.edgeCount)
  for e in g.edges:
    result.add(e)

func adjacencyTable*[N](g: DiGraph[N], n: N): Table[N, EdgeAttr] =
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  g.adj[n]

# --- Operators ---

func `+`*[N](g1, g2: DiGraph[N]): DiGraph[N] =
  ## DiGraph union.
  result = g1.copy()
  for n in g2.nodes:
    if n notin result:
      result.adj[n] = initTable[N, EdgeAttr]()
      result.pred[n] = initTable[N, EdgeAttr]()
  for (u, v, attr) in g2.edgesWithAttr:
    let isNew = v notin result.adj[u]
    result.adj[u][v] = attr
    result.pred[v][u] = attr
    if isNew:
      result.edgeCount.inc
  for n, attr in g2.nodeAttr:
    result.nodeAttr[n] = attr

proc `-`*[N](g1, g2: DiGraph[N]): DiGraph[N] =
  ## DiGraph edge difference: directed edges in ``g1`` not in ``g2``.
  ## All nodes from ``g1`` are kept.
  result = newDiGraph[N](g1.name)
  for n in g1.adj.keys:
    result.addNode(n)
  for n, attr in g1.nodeAttr:
    result.nodeAttr[n] = attr
  for (u, v, attr) in g1.edgesWithAttr:
    if not g2.hasEdge(u, v):
      result.addEdge(u, v, attr)
