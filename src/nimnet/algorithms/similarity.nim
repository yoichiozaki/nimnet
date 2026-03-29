## Graph similarity measures.
##
## - ``simrankSimilarity`` — SimRank pairwise similarity
## - ``graphEditDistance`` — approximate graph edit distance

import std/[tables, sets, math]
import ../types, ../graph, ../digraph

proc simrankSimilarity*[N](g: Graph[N], c: float = 0.8,
                            maxIter: int = 100): Table[(N, N), float] =
  ## Compute SimRank similarity for all pairs of nodes.
  ## SimRank(u,v) measures structural equivalence — two nodes are
  ## similar if their neighbors are similar.
  ##
  ## ``c`` is the decay factor (0 < c < 1). Higher values propagate similarity further.
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)

  let n = nodeList.len
  if n == 0:
    return result

  # Initialize: sim(u,u)=1, sim(u,v)=0 for u!=v
  var sim = initTable[(N, N), float]()
  for i in 0 ..< n:
    for j in 0 ..< n:
      if i == j:
        sim[(nodeList[i], nodeList[j])] = 1.0
      else:
        sim[(nodeList[i], nodeList[j])] = 0.0

  for iter in 0 ..< maxIter:
    var newSim = initTable[(N, N), float]()
    var changed = false

    for i in 0 ..< n:
      for j in 0 ..< n:
        let u = nodeList[i]
        let v = nodeList[j]
        if i == j:
          newSim[(u, v)] = 1.0
          continue

        var neighborsU: seq[N]
        for nb in g.neighbors(u):
          neighborsU.add(nb)
        var neighborsV: seq[N]
        for nb in g.neighbors(v):
          neighborsV.add(nb)

        if neighborsU.len == 0 or neighborsV.len == 0:
          newSim[(u, v)] = 0.0
          continue

        var total = 0.0
        for nu in neighborsU:
          for nv in neighborsV:
            total += sim.getOrDefault((nu, nv), 0.0)

        let s = c * total / (neighborsU.len.float * neighborsV.len.float)
        newSim[(u, v)] = s
        if abs(s - sim.getOrDefault((u, v), 0.0)) > 1e-10:
          changed = true

    sim = newSim
    if not changed:
      break

  result = sim

proc simrankSimilarity*[N](dg: DiGraph[N], c: float = 0.8,
                            maxIter: int = 100): Table[(N, N), float] =
  ## Compute SimRank similarity for all pairs of nodes in a directed graph.
  ## Uses predecessors (in-neighbors) for structural equivalence.
  var nodeList: seq[N]
  for n in dg.nodes:
    nodeList.add(n)

  let n = nodeList.len
  if n == 0:
    return result

  var sim = initTable[(N, N), float]()
  for i in 0 ..< n:
    for j in 0 ..< n:
      if i == j:
        sim[(nodeList[i], nodeList[j])] = 1.0
      else:
        sim[(nodeList[i], nodeList[j])] = 0.0

  for iter in 0 ..< maxIter:
    var newSim = initTable[(N, N), float]()
    var changed = false

    for i in 0 ..< n:
      for j in 0 ..< n:
        let u = nodeList[i]
        let v = nodeList[j]
        if i == j:
          newSim[(u, v)] = 1.0
          continue

        var predsU: seq[N]
        for p in dg.predecessors(u):
          predsU.add(p)
        var predsV: seq[N]
        for p in dg.predecessors(v):
          predsV.add(p)

        if predsU.len == 0 or predsV.len == 0:
          newSim[(u, v)] = 0.0
          continue

        var total = 0.0
        for pu in predsU:
          for pv in predsV:
            total += sim.getOrDefault((pu, pv), 0.0)

        let s = c * total / (predsU.len.float * predsV.len.float)
        newSim[(u, v)] = s
        if abs(s - sim.getOrDefault((u, v), 0.0)) > 1e-10:
          changed = true

    sim = newSim
    if not changed:
      break

  result = sim

proc graphEditDistance*[N](g1, g2: Graph[N]): int =
  ## Compute an upper bound on the graph edit distance between g1 and g2.
  ## The edit distance is the minimum number of edit operations (node
  ## insertions/deletions, edge insertions/deletions) to transform g1 into g2.
  ##
  ## Uses a greedy approach for efficiency (exact GED is NP-hard).
  var n1 = g1.numberOfNodes()
  var n2 = g2.numberOfNodes()
  var e1 = g1.numberOfEdges()
  var e2 = g2.numberOfEdges()

  # Collect nodes
  var nodes1 = initHashSet[N]()
  for n in g1.nodes:
    nodes1.incl(n)
  var nodes2 = initHashSet[N]()
  for n in g2.nodes:
    nodes2.incl(n)

  # Node operations
  let commonNodes = nodes1 * nodes2
  let nodeDeletions = nodes1.len - commonNodes.len
  let nodeInsertions = nodes2.len - commonNodes.len

  # Edge operations (for common nodes, check edge matches)
  var edges1 = initHashSet[(N, N)]()
  for (u, v) in g1.edges:
    if u < v:
      edges1.incl((u, v))
    else:
      edges1.incl((v, u))

  var edges2 = initHashSet[(N, N)]()
  for (u, v) in g2.edges:
    if u < v:
      edges2.incl((u, v))
    else:
      edges2.incl((v, u))

  let commonEdges = edges1 * edges2
  let edgeDeletions = edges1.len - commonEdges.len
  let edgeInsertions = edges2.len - commonEdges.len

  result = nodeDeletions + nodeInsertions + edgeDeletions + edgeInsertions
