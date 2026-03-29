## BFS and DFS traversal algorithms for nimnet

import std/[deques, sets, tables, sequtils]
import ../types
import ../graph
import ../digraph

# =============================================================================
# BFS — Breadth-First Search
# =============================================================================

iterator bfsEdges*[N](g: Graph[N], source: N): (N, N) =
  ## Iterate over edges in a breadth-first search starting from source.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  var visited = initHashSet[N]()
  visited.incl(source)
  var queue = initDeque[(N, N)]()
  for neighbor in g.neighbors(source):
    queue.addLast((source, neighbor))
  while queue.len > 0:
    let (parent, child) = queue.popFirst()
    if child notin visited:
      visited.incl(child)
      yield (parent, child)
      for neighbor in g.neighbors(child):
        if neighbor notin visited:
          queue.addLast((child, neighbor))

iterator bfsEdges*[N](g: DiGraph[N], source: N): (N, N) =
  ## BFS edges for directed graph.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  var visited = initHashSet[N]()
  visited.incl(source)
  var queue = initDeque[(N, N)]()
  for neighbor in g.neighbors(source):
    queue.addLast((source, neighbor))
  while queue.len > 0:
    let (parent, child) = queue.popFirst()
    if child notin visited:
      visited.incl(child)
      yield (parent, child)
      for neighbor in g.neighbors(child):
        if neighbor notin visited:
          queue.addLast((child, neighbor))

proc bfsTree*[N](g: Graph[N], source: N): Graph[N] =
  ## Return a BFS tree rooted at source as an undirected graph.
  result = newGraph[N]()
  result.addNode(source)
  for (u, v) in bfsEdges(g, source):
    result.addEdge(u, v)

proc bfsTree*[N](g: DiGraph[N], source: N): DiGraph[N] =
  ## Return a BFS tree rooted at source as a directed graph.
  result = newDiGraph[N]()
  result.addNode(source)
  for (u, v) in bfsEdges(g, source):
    result.addEdge(u, v)

proc bfsLayers*[N](g: Graph[N], source: N): seq[seq[N]] =
  ## Return nodes grouped by BFS layer distance from source.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  var visited = initHashSet[N]()
  visited.incl(source)
  var currentLayer = @[source]
  while currentLayer.len > 0:
    result.add(currentLayer)
    var nextLayer: seq[N]
    for node in currentLayer:
      for neighbor in g.neighbors(node):
        if neighbor notin visited:
          visited.incl(neighbor)
          nextLayer.add(neighbor)
    currentLayer = nextLayer

proc bfsLayers*[N](g: DiGraph[N], source: N): seq[seq[N]] =
  ## Return nodes grouped by BFS layer distance from source (directed).
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  var visited = initHashSet[N]()
  visited.incl(source)
  var currentLayer = @[source]
  while currentLayer.len > 0:
    result.add(currentLayer)
    var nextLayer: seq[N]
    for node in currentLayer:
      for neighbor in g.neighbors(node):
        if neighbor notin visited:
          visited.incl(neighbor)
          nextLayer.add(neighbor)
    currentLayer = nextLayer

proc bfsPredecessors*[N](g: Graph[N], source: N): Table[N, N] =
  ## Return a table mapping each node to its predecessor in BFS tree.
  result = initTable[N, N]()
  for (u, v) in bfsEdges(g, source):
    result[v] = u

proc bfsPredecessors*[N](g: DiGraph[N], source: N): Table[N, N] =
  result = initTable[N, N]()
  for (u, v) in bfsEdges(g, source):
    result[v] = u

proc bfsSuccessors*[N](g: Graph[N], source: N): Table[N, seq[N]] =
  ## Return a table mapping each node to its successors in BFS tree.
  result = initTable[N, seq[N]]()
  for (u, v) in bfsEdges(g, source):
    if u notin result:
      result[u] = @[]
    result[u].add(v)

# =============================================================================
# DFS — Depth-First Search
# =============================================================================

iterator dfsEdges*[N](g: Graph[N], source: N): (N, N) =
  ## Iterate over edges in a depth-first search starting from source.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  var visited = initHashSet[N]()
  var stack: seq[(N, N)]
  visited.incl(source)
  for neighbor in g.neighbors(source):
    stack.add((source, neighbor))
  while stack.len > 0:
    let (parent, child) = stack.pop()
    if child notin visited:
      visited.incl(child)
      yield (parent, child)
      for neighbor in g.neighbors(child):
        if neighbor notin visited:
          stack.add((child, neighbor))

iterator dfsEdges*[N](g: DiGraph[N], source: N): (N, N) =
  ## DFS edges for directed graph.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  var visited = initHashSet[N]()
  var stack: seq[(N, N)]
  visited.incl(source)
  for neighbor in g.neighbors(source):
    stack.add((source, neighbor))
  while stack.len > 0:
    let (parent, child) = stack.pop()
    if child notin visited:
      visited.incl(child)
      yield (parent, child)
      for neighbor in g.neighbors(child):
        if neighbor notin visited:
          stack.add((child, neighbor))

proc dfsTree*[N](g: Graph[N], source: N): Graph[N] =
  ## Return a DFS tree rooted at source.
  result = newGraph[N]()
  result.addNode(source)
  for (u, v) in dfsEdges(g, source):
    result.addEdge(u, v)

proc dfsTree*[N](g: DiGraph[N], source: N): DiGraph[N] =
  result = newDiGraph[N]()
  result.addNode(source)
  for (u, v) in dfsEdges(g, source):
    result.addEdge(u, v)

proc dfsPreorderNodes*[N](g: Graph[N], source: N): seq[N] =
  ## Return nodes in DFS preorder starting from source.
  result.add(source)
  for (_, v) in dfsEdges(g, source):
    result.add(v)

proc dfsPreorderNodes*[N](g: DiGraph[N], source: N): seq[N] =
  result.add(source)
  for (_, v) in dfsEdges(g, source):
    result.add(v)

proc dfsPostorderNodes*[N](g: Graph[N], source: N): seq[N] =
  ## Return nodes in DFS postorder starting from source.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  var visited = initHashSet[N]()
  proc dfsVisit(node: N) =
    visited.incl(node)
    for neighbor in g.neighbors(node):
      if neighbor notin visited:
        dfsVisit(neighbor)
    result.add(node)
  dfsVisit(source)

proc dfsPostorderNodes*[N](g: DiGraph[N], source: N): seq[N] =
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  var visited = initHashSet[N]()
  proc dfsVisit(node: N) =
    visited.incl(node)
    for neighbor in g.neighbors(node):
      if neighbor notin visited:
        dfsVisit(neighbor)
    result.add(node)
  dfsVisit(source)

proc dfsLabeledEdges*[N](g: Graph[N], source: N): seq[(N, N, string)] =
  ## Return edges labeled as "forward" or "nontree" during DFS.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  var visited = initHashSet[N]()
  var stack: seq[(N, N, bool)]
  visited.incl(source)
  for neighbor in g.neighbors(source):
    stack.add((source, neighbor, false))
  while stack.len > 0:
    let (parent, child, isBacktrack) = stack.pop()
    if child notin visited:
      visited.incl(child)
      result.add((parent, child, "forward"))
      for neighbor in g.neighbors(child):
        if neighbor notin visited:
          stack.add((child, neighbor, false))
    elif not isBacktrack:
      result.add((parent, child, "nontree"))
