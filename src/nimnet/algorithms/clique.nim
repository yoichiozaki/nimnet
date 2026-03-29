## Clique algorithms
##
## Bron-Kerbosch algorithm for maximal clique enumeration.

import std/[sets, tables]
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
