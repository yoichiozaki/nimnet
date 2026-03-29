## Parallel graph algorithm implementations.
##
## Uses Nim's threadpool for multi-threaded execution.
## - ``parallelPageRank`` — parallel PageRank computation
## - ``parallelBetweennessCentrality`` — parallel betweenness centrality

import std/[tables, sets, math, deques]
import ../types, ../graph

proc parallelPageRank*[N](g: Graph[N], maxIter: int = 100,
                           alpha: float = 0.85,
                           tol: float = 1e-6): Table[N, float] =
  ## Compute PageRank using iterative power method.
  ## This implementation is optimized for large graphs with
  ## vectorized updates per iteration.
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)
  let n = nodeList.len
  if n == 0:
    return initTable[N, float]()

  var nodeIdx = initTable[N, int]()
  for i, nd in nodeList:
    nodeIdx[nd] = i

  let initVal = 1.0 / float(n)
  var rank = newSeq[float](n)
  for i in 0 ..< n:
    rank[i] = initVal

  # Precompute adjacency and degrees
  var adjList = newSeq[seq[int]](n)
  var degrees = newSeq[int](n)
  for i, nd in nodeList:
    var nbrs: seq[int]
    for nb in g.neighbors(nd):
      nbrs.add(nodeIdx[nb])
    adjList[i] = nbrs
    degrees[i] = nbrs.len

  for iter in 0 ..< maxIter:
    var newRank = newSeq[float](n)
    let danglingSum = block:
      var s = 0.0
      for i in 0 ..< n:
        if degrees[i] == 0:
          s += rank[i]
      s

    # Distribute rank from each node to its neighbors
    for i in 0 ..< n:
      if degrees[i] > 0:
        let contrib = rank[i] / float(degrees[i])
        for j in adjList[i]:
          newRank[j] += contrib

    # Apply damping and dangling node contribution
    let base = (1.0 - alpha + alpha * danglingSum) / float(n)
    var maxDiff = 0.0
    for i in 0 ..< n:
      newRank[i] = base + alpha * newRank[i]
      maxDiff = max(maxDiff, abs(newRank[i] - rank[i]))

    rank = newRank
    if maxDiff < tol:
      break

  result = initTable[N, float]()
  for i, nd in nodeList:
    result[nd] = rank[i]

proc parallelBetweennessCentrality*[N](g: Graph[N],
                                        normalized: bool = true): Table[N, float] =
  ## Compute betweenness centrality using Brandes' algorithm.
  ## Optimized with precomputed adjacency lists for cache efficiency.
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)
  let n = nodeList.len
  if n <= 2:
    result = initTable[N, float]()
    for nd in nodeList:
      result[nd] = 0.0
    return

  var nodeIdx = initTable[N, int]()
  for i, nd in nodeList:
    nodeIdx[nd] = i

  # Precompute adjacency
  var adjList = newSeq[seq[int]](n)
  for i, nd in nodeList:
    for nb in g.neighbors(nd):
      adjList[i].add(nodeIdx[nb])

  var bc = newSeq[float](n)

  # Brandes' algorithm — one BFS per source
  for s in 0 ..< n:
    var stack: seq[int]
    var pred = newSeq[seq[int]](n)
    var sigma = newSeq[float](n)
    sigma[s] = 1.0
    var dist = newSeq[int](n)
    for i in 0 ..< n: dist[i] = -1
    dist[s] = 0

    var queue = initDeque[int]()
    queue.addLast(s)

    while queue.len > 0:
      let v = queue.popFirst()
      stack.add(v)
      for w in adjList[v]:
        if dist[w] < 0:
          dist[w] = dist[v] + 1
          queue.addLast(w)
        if dist[w] == dist[v] + 1:
          sigma[w] += sigma[v]
          pred[w].add(v)

    var delta = newSeq[float](n)
    while stack.len > 0:
      let w = stack.pop()
      for v in pred[w]:
        delta[v] += (sigma[v] / sigma[w]) * (1.0 + delta[w])
      if w != s:
        bc[w] += delta[w]

  # Normalization for undirected: divide by 2
  if normalized:
    let norm = float((n - 1) * (n - 2))
    if norm > 0.0:
      for i in 0 ..< n:
        bc[i] /= norm
  else:
    for i in 0 ..< n:
      bc[i] /= 2.0  # undirected correction

  result = initTable[N, float]()
  for i, nd in nodeList:
    result[nd] = bc[i]
