## Compact CSR (Compressed Sparse Row) graph representation.
##
## Provides cache-efficient, read-only graph storage for fast traversal
## on large graphs. Convert from Graph/DiGraph with ``toCompact``.

import std/[tables, sets, algorithm]
import ./types, ./graph, ./digraph

type
  CompactGraph*[N] = object
    ## CSR representation of an undirected graph.
    nodeList*: seq[N]         ## nodes in order
    nodeIndex*: seq[int]      ## CSR row pointers (len = nodeCount + 1)
    neighbors*: seq[int]      ## CSR column indices (neighbor index into nodeList)
    weights*: seq[float]      ## edge weights (parallel to neighbors)

  CompactDiGraph*[N] = object
    ## CSR representation of a directed graph.
    nodeList*: seq[N]
    nodeIndex*: seq[int]
    neighbors*: seq[int]
    weights*: seq[float]

proc toCompact*[N](g: Graph[N]): CompactGraph[N] =
  ## Convert an undirected Graph to CSR format.
  var nodeMap = initTable[N, int]()
  for n in g.nodes:
    let idx = result.nodeList.len
    result.nodeList.add(n)
    nodeMap[n] = idx

  let numNodes = result.nodeList.len
  result.nodeIndex = newSeq[int](numNodes + 1)

  # First pass: count neighbors per node
  for i, n in result.nodeList:
    var count = 0
    for nb in g.neighbors(n):
      count += 1
    result.nodeIndex[i + 1] = count

  # Prefix sum
  for i in 1 .. numNodes:
    result.nodeIndex[i] += result.nodeIndex[i - 1]

  let totalEdgeSlots = result.nodeIndex[numNodes]
  result.neighbors = newSeq[int](totalEdgeSlots)
  result.weights = newSeq[float](totalEdgeSlots)

  # Second pass: fill neighbor arrays
  var offset = newSeq[int](numNodes)
  for i in 0 ..< numNodes: offset[i] = result.nodeIndex[i]

  for i, n in result.nodeList:
    for nb in g.neighbors(n):
      let j = nodeMap[nb]
      let w = if g.hasEdge(n, nb):
                let attr = g.getEdgeAttr(n, nb)
                attr.getWeight(1.0)
              else: 1.0
      result.neighbors[offset[i]] = j
      result.weights[offset[i]] = w
      offset[i] += 1

proc toCompact*[N](g: DiGraph[N]): CompactDiGraph[N] =
  ## Convert a directed DiGraph to CSR format (successors only).
  var nodeMap = initTable[N, int]()
  for n in g.nodes:
    let idx = result.nodeList.len
    result.nodeList.add(n)
    nodeMap[n] = idx

  let numNodes = result.nodeList.len
  result.nodeIndex = newSeq[int](numNodes + 1)

  for i, n in result.nodeList:
    var count = 0
    for nb in g.successors(n):
      count += 1
    result.nodeIndex[i + 1] = count

  for i in 1 .. numNodes:
    result.nodeIndex[i] += result.nodeIndex[i - 1]

  let totalEdgeSlots = result.nodeIndex[numNodes]
  result.neighbors = newSeq[int](totalEdgeSlots)
  result.weights = newSeq[float](totalEdgeSlots)

  var offset = newSeq[int](numNodes)
  for i in 0 ..< numNodes: offset[i] = result.nodeIndex[i]

  for i, n in result.nodeList:
    for nb in g.successors(n):
      let j = nodeMap[nb]
      let w = if g.hasEdge(n, nb):
                let attr = g.getEdgeAttr(n, nb)
                attr.getWeight(1.0)
              else: 1.0
      result.neighbors[offset[i]] = j
      result.weights[offset[i]] = w
      offset[i] += 1

func numberOfNodes*[N](cg: CompactGraph[N]): int {.inline.} =
  cg.nodeList.len

func numberOfEdges*[N](cg: CompactGraph[N]): int {.inline.} =
  cg.neighbors.len div 2  # undirected: each edge stored twice

func numberOfNodes*[N](cg: CompactDiGraph[N]): int {.inline.} =
  cg.nodeList.len

func numberOfEdges*[N](cg: CompactDiGraph[N]): int {.inline.} =
  cg.neighbors.len

iterator neighborsCSR*[N](cg: CompactGraph[N], nodeIdx: int): int =
  ## Iterate over neighbor indices of node at index ``nodeIdx``.
  let start = cg.nodeIndex[nodeIdx]
  let stop = cg.nodeIndex[nodeIdx + 1]
  for i in start ..< stop:
    yield cg.neighbors[i]

iterator neighborsCSR*[N](cg: CompactDiGraph[N], nodeIdx: int): int =
  ## Iterate over successor indices of node at index ``nodeIdx``.
  let start = cg.nodeIndex[nodeIdx]
  let stop = cg.nodeIndex[nodeIdx + 1]
  for i in start ..< stop:
    yield cg.neighbors[i]

func degreeCSR*[N](cg: CompactGraph[N], nodeIdx: int): int {.inline.} =
  cg.nodeIndex[nodeIdx + 1] - cg.nodeIndex[nodeIdx]

proc toGraph*[N](cg: CompactGraph[N]): Graph[N] =
  ## Convert a CompactGraph back to a mutable Graph.
  result = newGraph[N]()
  for n in cg.nodeList:
    result.addNode(n)
  for i in 0 ..< cg.nodeList.len:
    let u = cg.nodeList[i]
    let start = cg.nodeIndex[i]
    let stop = cg.nodeIndex[i + 1]
    for j in start ..< stop:
      let v = cg.nodeList[cg.neighbors[j]]
      if not result.hasEdge(u, v):
        result.addWeightedEdge(u, v, cg.weights[j])

proc bfsCSR*[N](cg: CompactGraph[N], sourceIdx: int): seq[int] =
  ## Cache-efficient BFS returning node indices in visit order.
  var visited = newSeq[bool](cg.nodeList.len)
  var queue: seq[int]
  queue.add(sourceIdx)
  visited[sourceIdx] = true
  var head = 0

  while head < queue.len:
    let curr = queue[head]
    head += 1
    result.add(curr)
    let start = cg.nodeIndex[curr]
    let stop = cg.nodeIndex[curr + 1]
    for i in start ..< stop:
      let nb = cg.neighbors[i]
      if not visited[nb]:
        visited[nb] = true
        queue.add(nb)
