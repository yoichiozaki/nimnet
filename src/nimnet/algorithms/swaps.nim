## Degree-preserving edge swaps and walk counting for nimnet

import std/[tables, sets, random]
import ../types
import ../graph

# =============================================================================
# Double Edge Swap (#113)
# =============================================================================

proc doubleEdgeSwap*[N](g: var Graph[N], nswap: int = 1, maxTries: int = 100, seed: int = 0) =
  ## Perform nswap random double edge swaps that preserve degree sequence.
  ## A double edge swap: (u,v) and (x,y) → (u,x) and (v,y) (or (u,y) and (v,x)).
  var rng = if seed != 0: initRand(seed) else: initRand()
  var edgeList = newSeq[(N, N)]()
  for (u, v) in g.edges:
    edgeList.add((u, v))
  if edgeList.len < 2: return
  var swapsDone = 0
  var tries = 0
  while swapsDone < nswap and tries < maxTries * nswap:
    tries.inc
    let i = rng.rand(edgeList.len - 1)
    let j = rng.rand(edgeList.len - 1)
    if i == j: continue
    let (u, v) = edgeList[i]
    let (x, y) = edgeList[j]
    # Pick a swap type
    if u != x and u != y and v != x and v != y:
      if not g.hasEdge(u, x) and not g.hasEdge(v, y):
        g.removeEdge(u, v)
        g.removeEdge(x, y)
        g.addEdge(u, x)
        g.addEdge(v, y)
        edgeList[i] = (u, x)
        edgeList[j] = (v, y)
        swapsDone.inc

proc connectedDoubleEdgeSwap*[N](g: var Graph[N], nswap: int = 1, seed: int = 0) =
  ## Perform double edge swaps while maintaining connectivity.
  var rng = if seed != 0: initRand(seed) else: initRand()
  var edgeList = newSeq[(N, N)]()
  for (u, v) in g.edges:
    edgeList.add((u, v))
  if edgeList.len < 2: return
  var swapsDone = 0
  var tries = 0
  let maxTries = nswap * 100
  while swapsDone < nswap and tries < maxTries:
    tries.inc
    let i = rng.rand(edgeList.len - 1)
    let j = rng.rand(edgeList.len - 1)
    if i == j: continue
    let (u, v) = edgeList[i]
    let (x, y) = edgeList[j]
    if u != x and u != y and v != x and v != y:
      if not g.hasEdge(u, x) and not g.hasEdge(v, y):
        g.removeEdge(u, v)
        g.removeEdge(x, y)
        g.addEdge(u, x)
        g.addEdge(v, y)
        # Check connectivity with BFS
        var visited = initHashSet[N]()
        var queue: seq[N]
        var first = true
        for n in g.nodes:
          if first:
            queue.add(n)
            visited.incl(n)
            first = false
            break
        var qi = 0
        while qi < queue.len:
          let curr = queue[qi]
          qi.inc
          for nbr in g.neighbors(curr):
            if nbr notin visited:
              visited.incl(nbr)
              queue.add(nbr)
        if visited.len == g.numberOfNodes():
          edgeList[i] = (u, x)
          edgeList[j] = (v, y)
          swapsDone.inc
        else:
          # Undo swap
          g.removeEdge(u, x)
          g.removeEdge(v, y)
          g.addEdge(u, v)
          g.addEdge(x, y)

# =============================================================================
# Walk Counting (#113)
# =============================================================================

proc numberOfWalks*[N](g: Graph[N], length: int): Table[(N, N), int] =
  ## Count the number of walks of a given length between all pairs of nodes.
  ## Uses matrix exponentiation: (A^k)_{ij} = number of walks of length k from i to j.
  result = initTable[(N, N), int]()
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n == 0: return
  var nodeIdx = initTable[N, int]()
  for i, node in nodes:
    nodeIdx[node] = i
  # Build adjacency matrix
  var mat = newSeq[seq[int]](n)
  for i in 0 ..< n:
    mat[i] = newSeq[int](n)
  for (u, v) in g.edges:
    mat[nodeIdx[u]][nodeIdx[v]] = 1
    mat[nodeIdx[v]][nodeIdx[u]] = 1
  # Matrix power
  var power = newSeq[seq[int]](n)
  for i in 0 ..< n:
    power[i] = newSeq[int](n)
    power[i][i] = 1  # Identity
  for _ in 0 ..< length:
    var newPower = newSeq[seq[int]](n)
    for i in 0 ..< n:
      newPower[i] = newSeq[int](n)
      for j in 0 ..< n:
        for k in 0 ..< n:
          newPower[i][j] += power[i][k] * mat[k][j]
    power = newPower
  for i in 0 ..< n:
    for j in 0 ..< n:
      if power[i][j] > 0:
        result[(nodes[i], nodes[j])] = power[i][j]
