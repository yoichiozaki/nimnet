## Undirected graph implementation for nimnet
##
## A ``Graph`` stores nodes and undirected edges with optional attributes.
## Nodes can be any hashable type ``N``. Edges are stored in an adjacency map.
##
## .. code-block:: nim
##   var g = newGraph[int]()
##   g.addNodesFrom([1, 2, 3])
##   g.addEdge(1, 2)
##   assert 1 in g          # contains operator
##   assert g.len == 3      # number of nodes
##   for node in g:         # items iterator
##     echo node

import std/[tables, sets, strformat, algorithm]
import types

type
  Graph*[N] = object
    ## An undirected graph with nodes of type N.
    ##
    ## Internally stores an adjacency map ``Table[N, Table[N, EdgeAttr]]``
    ## and a cached edge count for O(1) ``numberOfEdges``.
    adj: Table[N, Table[N, EdgeAttr]]
    nodeAttr: Table[N, NodeAttr]
    edgeCount: int  ## Cached edge count — O(1) access
    name*: string

# --- Constructors ---

func newGraph*[N](name: string = ""): Graph[N] =
  ## Create a new empty undirected graph.
  Graph[N](
    adj: initTable[N, Table[N, EdgeAttr]](),
    nodeAttr: initTable[N, NodeAttr](),
    edgeCount: 0,
    name: name
  )

# --- Metrics (O(1)) ---

func len*[N](g: Graph[N]): int {.inline.} =
  ## Number of nodes. Enables idiomatic ``g.len``.
  g.adj.len

func numberOfNodes*[N](g: Graph[N]): int {.inline.} =
  ## Return the number of nodes.
  g.adj.len

func order*[N](g: Graph[N]): int {.inline.} =
  ## Return the number of nodes (alias for ``numberOfNodes``).
  g.adj.len

func numberOfEdges*[N](g: Graph[N]): int {.inline.} =
  ## Return the number of edges (O(1) via cached counter).
  g.edgeCount

func size*[N](g: Graph[N]): int {.inline.} =
  ## Return the number of edges (alias for ``numberOfEdges``).
  g.edgeCount

# --- Membership (O(1)) ---

func contains*[N](g: Graph[N], n: N): bool {.inline.} =
  ## Test node membership. Enables ``n in g`` syntax.
  n in g.adj

func hasNode*[N](g: Graph[N], n: N): bool {.inline.} =
  ## Return true if the graph contains node ``n``.
  n in g.adj

func hasEdge*[N](g: Graph[N], u, v: N): bool {.inline.} =
  ## Return true if edge ``(u, v)`` exists.
  u in g.adj and v in g.adj[u]

# --- Node operations ---

proc addNode*[N](g: var Graph[N], n: N) {.inline.} =
  ## Add a node to the graph. No-op if node already exists.
  if n notin g.adj:
    g.adj[n] = initTable[N, EdgeAttr]()

proc addNode*[N](g: var Graph[N], n: N, attr: NodeAttr) =
  ## Add a node with attributes.
  g.addNode(n)
  g.nodeAttr[n] = attr

proc addNodesFrom*[N](g: var Graph[N], nodes: openArray[N]) =
  ## Batch-add multiple nodes.
  ##
  ## .. code-block:: nim
  ##   g.addNodesFrom([1, 2, 3, 4, 5])
  for n in nodes:
    g.addNode(n)

proc removeNode*[N](g: var Graph[N], n: N) =
  ## Remove a node and all its incident edges.
  ## Raises ``NodeNotFound`` if the node doesn't exist.
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  for neighbor in g.adj[n].keys:
    if neighbor == n:
      g.edgeCount.dec          # self-loop
    else:
      g.adj[neighbor].del(n)
      g.edgeCount.dec          # incident edge
  g.adj.del(n)
  g.nodeAttr.del(n)

# --- Edge operations ---

proc addEdge*[N](g: var Graph[N], u, v: N, attr: EdgeAttr) =
  ## Add an edge between ``u`` and ``v`` with attributes.
  ## Implicitly adds nodes if they don't exist.
  ## If the edge already exists, attributes are updated.
  g.addNode(u)
  g.addNode(v)
  let isNew = v notin g.adj[u]
  g.adj[u][v] = attr
  g.adj[v][u] = attr
  if isNew:
    g.edgeCount.inc

proc addEdge*[N](g: var Graph[N], u, v: N) {.inline.} =
  ## Add an edge without attributes (fast path).
  g.addEdge(u, v, newEdgeAttr())

proc addWeightedEdge*[N](g: var Graph[N], u, v: N, weight: float) {.inline.} =
  ## Add an edge with a weight attribute.
  g.addEdge(u, v, newEdgeAttr(weight))

proc addEdgesFrom*[N](g: var Graph[N], edges: openArray[(N, N)]) =
  ## Batch-add multiple edges.
  ##
  ## .. code-block:: nim
  ##   g.addEdgesFrom([(1, 2), (2, 3), (3, 4)])
  for (u, v) in edges:
    g.addEdge(u, v)

proc addWeightedEdgesFrom*[N](g: var Graph[N],
    edges: openArray[tuple[u, v: N, weight: float]]) =
  ## Batch-add weighted edges.
  ##
  ## .. code-block:: nim
  ##   g.addWeightedEdgesFrom([(1, 2, 1.0), (2, 3, 2.5)])
  for e in edges:
    g.addWeightedEdge(e.u, e.v, e.weight)

proc removeEdge*[N](g: var Graph[N], u, v: N) =
  ## Remove the edge between ``u`` and ``v``.
  ## Raises ``EdgeNotFound`` if the edge doesn't exist.
  if u notin g.adj or v notin g.adj[u]:
    raise newException(EdgeNotFound, fmt"Edge ({u}, {v}) not found")
  g.adj[u].del(v)
  g.adj[v].del(u)
  g.edgeCount.dec

# --- Subscript operators ---

func `[]`*[N](g: Graph[N], n: N): Table[N, EdgeAttr] =
  ## Access the neighbor dict: ``g[n]`` returns ``{neighbor: attr, …}``.
  ## Raises ``NodeNotFound`` if ``n`` is absent.
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  g.adj[n]

func `[]`*[N](g: Graph[N], u, v: N): EdgeAttr =
  ## Access edge attributes: ``g[u, v]``.
  ## Raises ``EdgeNotFound`` if the edge is absent.
  if not g.hasEdge(u, v):
    raise newException(EdgeNotFound, fmt"Edge ({u}, {v}) not found")
  g.adj[u][v]

# --- Attribute operations ---

func getNodeAttr*[N](g: Graph[N], n: N): NodeAttr =
  ## Get attributes for node ``n``.
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  g.nodeAttr.getOrDefault(n, newNodeAttr())

proc setNodeAttr*[N](g: var Graph[N], n: N, attr: NodeAttr) =
  ## Set attributes for node ``n``.
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  g.nodeAttr[n] = attr

proc setNodeAttr*[N](g: var Graph[N], n: N, key, value: string) =
  ## Set a single attribute on node ``n``.
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  if n notin g.nodeAttr:
    g.nodeAttr[n] = newNodeAttr()
  g.nodeAttr[n][key] = value

func getEdgeAttr*[N](g: Graph[N], u, v: N): EdgeAttr =
  ## Get attributes for edge ``(u, v)``.
  if not g.hasEdge(u, v):
    raise newException(EdgeNotFound, fmt"Edge ({u}, {v}) not found")
  g.adj[u][v]

proc setEdgeAttr*[N](g: var Graph[N], u, v: N, attr: EdgeAttr) =
  ## Set attributes for edge ``(u, v)``.
  if not g.hasEdge(u, v):
    raise newException(EdgeNotFound, fmt"Edge ({u}, {v}) not found")
  g.adj[u][v] = attr
  g.adj[v][u] = attr

proc setEdgeAttr*[N](g: var Graph[N], u, v: N, key, value: string) =
  ## Set a single attribute on edge ``(u, v)``.
  if not g.hasEdge(u, v):
    raise newException(EdgeNotFound, fmt"Edge ({u}, {v}) not found")
  g.adj[u][v][key] = value
  g.adj[v][u][key] = value

func weight*[N](g: Graph[N], u, v: N, default: float = 1.0): float {.inline.} =
  ## Get the weight of edge ``(u, v)``. Returns ``default`` (1.0) if unset.
  if not g.hasEdge(u, v):
    raise newException(EdgeNotFound, fmt"Edge ({u}, {v}) not found")
  g.adj[u][v].getWeight(default)

# --- Iterators ---

iterator items*[N](g: Graph[N]): N =
  ## Iterate over all nodes. Enables ``for n in g``.
  for n in g.adj.keys:
    yield n

iterator nodes*[N](g: Graph[N]): N =
  ## Iterate over all nodes (explicit name).
  for n in g.adj.keys:
    yield n

iterator pairs*[N](g: Graph[N]): (N, Table[N, EdgeAttr]) =
  ## Iterate ``(node, adjacencyDict)`` pairs. Enables ``for n, adj in g``.
  for n, neighbors in g.adj:
    yield (n, neighbors)

iterator nodesWithAttr*[N](g: Graph[N]): (N, NodeAttr) =
  ## Iterate over all nodes with their attributes.
  for n in g.adj.keys:
    yield (n, g.nodeAttr.getOrDefault(n, newNodeAttr()))

iterator edges*[N](g: Graph[N]): (N, N) =
  ## Iterate over all edges (each edge yielded once).
  var seen = initHashSet[N](g.adj.len * 2)
  for u in g.adj.keys:
    for v in g.adj[u].keys:
      if v notin seen or u == v:
        yield (u, v)
    seen.incl(u)

iterator edgesWithAttr*[N](g: Graph[N]): (N, N, EdgeAttr) =
  ## Iterate over all edges with attributes.
  var seen = initHashSet[N](g.adj.len * 2)
  for u in g.adj.keys:
    for v, attr in g.adj[u]:
      if v notin seen or u == v:
        yield (u, v, attr)
    seen.incl(u)

iterator neighbors*[N](g: Graph[N], n: N): N =
  ## Iterate over neighbours of node ``n``.
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  for neighbor in g.adj[n].keys:
    yield neighbor

iterator adjacency*[N](g: Graph[N]): (N, Table[N, EdgeAttr]) =
  ## Iterate ``(node, adjacencyDict)`` pairs.
  for n, neighbors in g.adj:
    yield (n, neighbors)

# --- Degree ---

func degree*[N](g: Graph[N], n: N): int {.inline.} =
  ## Return the degree of node ``n``.
  ## Self-loops count twice (consistent with NetworkX).
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  result = g.adj[n].len
  if n in g.adj[n]:
    result.inc  # self-loop occupies both endpoints

iterator degree*[N](g: Graph[N]): (N, int) =
  ## Iterate over ``(node, degree)`` pairs.
  for n in g.adj.keys:
    yield (n, g.degree(n))

# --- Graph properties ---

func density*[N](g: Graph[N]): float =
  ## Return the density of the graph.
  let n = g.len
  let m = g.edgeCount
  if n <= 1: 0.0
  else: 2.0 * float(m) / (float(n) * float(n - 1))

func isEmpty*[N](g: Graph[N]): bool {.inline.} =
  ## Return true if the graph has no edges.
  g.edgeCount == 0

func isDirected*[N](g: Graph[N]): bool {.inline.} =
  ## Return false (Graph is undirected).
  false

func hasSelfLoop*[N](g: Graph[N], n: N): bool {.inline.} =
  ## Return true if node ``n`` has a self-loop.
  g.hasEdge(n, n)

func numberOfSelfLoops*[N](g: Graph[N]): int =
  ## Return the number of self-loops.
  for n in g.adj.keys:
    if n in g.adj[n]:
      result.inc

iterator selfLoopNodes*[N](g: Graph[N]): N =
  ## Iterate over nodes with self-loops.
  for n in g.adj.keys:
    if n in g.adj[n]:
      yield n

# --- Copy and equality ---

func copy*[N](g: Graph[N]): Graph[N] =
  ## Return a deep copy of the graph.
  result.name = g.name
  result.edgeCount = g.edgeCount
  for u, neighbors in g.adj:
    result.adj[u] = initTable[N, EdgeAttr]()
    for v, attr in neighbors:
      result.adj[u][v] = attr
  for n, attr in g.nodeAttr:
    result.nodeAttr[n] = attr

func `==`*[N](a, b: Graph[N]): bool =
  ## Check if two graphs have the same structure and attributes.
  a.adj == b.adj and a.nodeAttr == b.nodeAttr

proc clear*[N](g: var Graph[N]) =
  ## Remove all nodes and edges from the graph.
  g.adj.clear()
  g.nodeAttr.clear()
  g.edgeCount = 0

proc clearEdges*[N](g: var Graph[N]) =
  ## Remove all edges from the graph, keeping nodes.
  for n in g.adj.keys:
    g.adj[n].clear()
  g.edgeCount = 0

# --- Subgraph ---

func recomputeEdgeCount[N](g: var Graph[N]) =
  ## Re-derive edgeCount from the adjacency map (internal helper).
  var total = 0
  var selfLoops = 0
  for u, neighbors in g.adj:
    total += neighbors.len
    if u in neighbors: selfLoops.inc
  g.edgeCount = (total - selfLoops) div 2 + selfLoops

func subgraph*[N](g: Graph[N], nbunch: HashSet[N]): Graph[N] =
  ## Return a subgraph induced by the given set of nodes.
  result = newGraph[N](g.name)
  for n in nbunch:
    if n in g.adj:
      result.adj[n] = initTable[N, EdgeAttr]()
      if n in g.nodeAttr:
        result.nodeAttr[n] = g.nodeAttr[n]
  for u in result.adj.keys:
    for v, attr in g.adj[u]:
      if v in result.adj:
        result.adj[u][v] = attr
  recomputeEdgeCount(result)

func subgraph*[N](g: Graph[N], nbunch: openArray[N]): Graph[N] =
  ## Return a subgraph induced by the given sequence of nodes.
  g.subgraph(nbunch.toHashSet)

func edgeSubgraph*[N](g: Graph[N], edges: openArray[(N, N)]): Graph[N] =
  ## Return a subgraph induced by the given edges.
  ## Only the specified edges and their endpoint nodes are included.
  result = newGraph[N](g.name)
  for (u, v) in edges:
    if g.hasEdge(u, v):
      if u notin result.adj:
        result.addNode(u)
        if u in g.nodeAttr: result.nodeAttr[u] = g.nodeAttr[u]
      if v notin result.adj:
        result.addNode(v)
        if v in g.nodeAttr: result.nodeAttr[v] = g.nodeAttr[v]
      result.addEdge(u, v, g.getEdgeAttr(u, v))

iterator selfLoopEdges*[N](g: Graph[N]): (N, N) =
  ## Iterate over all self-loop edges.
  for n in g.adj.keys:
    if n in g.adj[n]:
      yield (n, n)

proc removeSelfLoops*[N](g: var Graph[N]) =
  ## Remove all self-loop edges from the graph.
  for n in g.adj.keys:
    if n in g.adj[n]:
      g.adj[n].del(n)
      g.edgeCount.dec

# --- String representation ---

func `$`*[N](g: Graph[N]): string =
  ## String representation of the graph.
  let name = if g.name.len > 0: g.name else: "Graph"
  fmt"{name}(nodes={g.len}, edges={g.edgeCount})"

# --- Utility ---

func nodeSeq*[N](g: Graph[N]): seq[N] =
  ## Return all nodes as a seq.
  result = newSeqOfCap[N](g.len)
  for n in g.adj.keys:
    result.add(n)

func adjacencyTable*[N](g: Graph[N], n: N): Table[N, EdgeAttr] =
  ## Return the adjacency dict for node ``n``.
  if n notin g.adj:
    raise newException(NodeNotFound, fmt"Node {n} not found")
  g.adj[n]

func edgeSeq*[N](g: Graph[N]): seq[(N, N)] =
  ## Return all edges as a seq of ``(u, v)`` tuples.
  result = newSeqOfCap[(N, N)](g.edgeCount)
  var seen = initHashSet[N](g.adj.len * 2)
  for u in g.adj.keys:
    for v in g.adj[u].keys:
      if v notin seen or u == v:
        result.add((u, v))
    seen.incl(u)

# --- Graph algebra operators ---

proc `+`*[N](g1, g2: Graph[N]): Graph[N] =
  ## Graph union: combine all nodes and edges from both graphs.
  ## Edge attributes from ``g2`` overwrite ``g1`` on conflicts.
  result = g1.copy()
  for n in g2.adj.keys:
    result.addNode(n)
  for n, attr in g2.nodeAttr:
    result.nodeAttr[n] = attr
  var seen = initHashSet[N](g2.adj.len * 2)
  for u in g2.adj.keys:
    for v, attr in g2.adj[u]:
      if v notin seen or u == v:
        result.addEdge(u, v, attr)
    seen.incl(u)

proc `-`*[N](g1, g2: Graph[N]): Graph[N] =
  ## Graph edge difference: edges in ``g1`` that are not in ``g2``.
  ## All nodes from ``g1`` are kept.
  result = newGraph[N](g1.name)
  for n in g1.adj.keys:
    result.addNode(n)
  for n, attr in g1.nodeAttr:
    result.nodeAttr[n] = attr
  var seen = initHashSet[N](g1.adj.len * 2)
  for u in g1.adj.keys:
    for v, attr in g1.adj[u]:
      if (v notin seen or u == v) and not g2.hasEdge(u, v):
        result.addEdge(u, v, attr)
    seen.incl(u)
