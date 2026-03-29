## Clique algorithms
##
## Bron-Kerbosch algorithm for maximal clique enumeration.

import std/[sets, tables, algorithm, strutils]
import ../types
import ../graph

proc bronKerbosch[N](g: Graph[N], R, P, X: HashSet[N],
                     cliques: var seq[HashSet[N]]) =
  ## Bron-Kerbosch with pivot for maximal clique enumeration.
  var pSet = P
  var xSet = X
  if pSet.len == 0 and xSet.len == 0:
    cliques.add(R)
    return

  # Choose pivot with max connections to P
  var pivot: N
  var maxDeg = -1
  for u in pSet + xSet:
    var deg = 0
    for v in pSet:
      if g.hasEdge(u, v):
        deg += 1
    if deg > maxDeg:
      maxDeg = deg
      pivot = u

  # Get neighbors of pivot in P
  var pivotNeighbors = initHashSet[N]()
  for v in pSet:
    if g.hasEdge(pivot, v):
      pivotNeighbors.incl(v)

  # Iterate over P \ N(pivot)
  let candidates = pSet - pivotNeighbors
  for v in candidates:
    var vNeighbors = initHashSet[N]()
    for u in g.neighbors(v):
      vNeighbors.incl(u)
    var newR = R
    newR.incl(v)
    bronKerbosch(g, newR, pSet * vNeighbors, xSet * vNeighbors, cliques)
    pSet.excl(v)
    xSet.incl(v)

proc findCliques*[N](g: Graph[N]): seq[HashSet[N]] =
  ## Find all maximal cliques using Bron-Kerbosch with pivoting.
  result = @[]
  var allNodes = initHashSet[N]()
  for n in g.nodes:
    allNodes.incl(n)
  var R = initHashSet[N]()
  var X = initHashSet[N]()
  bronKerbosch(g, R, allNodes, X, result)

proc maxClique*[N](g: Graph[N]): HashSet[N] =
  ## Return the largest maximal clique.
  let cliques = findCliques(g)
  result = initHashSet[N]()
  for c in cliques:
    if c.len > result.len:
      result = c

proc cliqueNumber*[N](g: Graph[N]): int =
  ## Return the clique number (size of the largest clique).
  let cliques = findCliques(g)
  result = 0
  for c in cliques:
    if c.len > result:
      result = c.len

func numberOfCliques*[N](g: Graph[N]): int =
  ## Return the number of maximal cliques.
  let cliques = findCliques(g)
  result = cliques.len

# =============================================================================
# Extended Clique (#130)
# =============================================================================

proc enumerateAllCliques*[N](g: Graph[N]): seq[seq[N]] =
  ## Enumerate all cliques (not just maximal) in order of size.
  ## Returns all cliques from size 1 upward.
  result = newSeq[seq[N]]()
  # Start with single-node cliques
  let nodes = g.nodeSeq()
  for n in nodes:
    result.add(@[n])
  # Extend each clique by one node at a time
  var prev = newSeq[seq[N]]()
  for n in nodes:
    prev.add(@[n])
  while prev.len > 0:
    var next = newSeq[seq[N]]()
    for clique in prev:
      let lastNode = clique[^1]
      for n in nodes:
        if n <= lastNode: continue
        # Check n is connected to all in clique
        var allConnected = true
        for c in clique:
          if not g.hasEdge(n, c):
            allConnected = false
            break
        if allConnected:
          var extended = clique
          extended.add(n)
          next.add(extended)
          result.add(extended)
    prev = next

proc maxWeightClique*[N](g: Graph[N], weightKey: string = "weight"): (HashSet[N], float) =
  ## Find the maximum weight clique.
  ## Uses weight=1.0 per node by default (largest clique).
  let cliques = findCliques(g)
  var bestWeight = -Inf
  var bestClique = initHashSet[N]()
  for clique in cliques:
    let w = float(clique.len)  # Default: each node has weight 1
    if w > bestWeight:
      bestWeight = w
      bestClique = clique
  if bestWeight == -Inf:
    return (initHashSet[N](), 0.0)
  result = (bestClique, bestWeight)

proc makeMaxCliqueGraph*[N](g: Graph[N]): Graph[int] =
  ## Create a graph where each maximal clique is a node and
  ## edges connect cliques that share at least one vertex.
  result = newGraph[int]()
  let cliques = findCliques(g)
  for i in 0 ..< cliques.len:
    result.addNode(i)
  for i in 0 ..< cliques.len:
    for j in i + 1 ..< cliques.len:
      var shared = false
      for n in cliques[i]:
        if n in cliques[j]:
          shared = true
          break
      if shared:
        result.addEdge(i, j)

proc nodeCliqueNumber*[N](g: Graph[N], n: N): int =
  ## Return the size of the largest maximal clique containing node n.
  let cliques = findCliques(g)
  result = 0
  for clique in cliques:
    if n in clique and clique.len > result:
      result = clique.len
