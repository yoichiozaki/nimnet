## Cut measures: conductance, volume, boundary, and related metrics.
##
## These measure the quality of a graph partition or cut.
## Given a set S of nodes:
## - ``cutSize`` — edges crossing between S and V\S
## - ``volume`` — sum of degrees of nodes in S
## - ``conductance`` — cutSize / min(vol(S), vol(V\S))
## - ``normalizedCutSize`` — cut/vol(S) + cut/vol(V\S)
## - ``edgeExpansion`` — cut / min(|S|, |V\S|)
## - ``nodeBoundary`` — nodes in V\S adjacent to S
## - ``edgeBoundary`` — edges with one endpoint in S, one in V\S

import std/[tables, sets]
import ../types
import ../graph

proc cutSize*[N](g: Graph[N], s: HashSet[N]): int =
  ## Return the number of edges between node set S and its complement V\S.
  for (u, v) in g.edges:
    if (u in s) xor (v in s):
      result += 1

proc cutSizeWeighted*[N](g: Graph[N], s: HashSet[N]): float =
  ## Return the total weight of edges crossing the cut.
  for (u, v, attr) in g.edgesWithAttr:
    if (u in s) xor (v in s):
      result += attr.getWeight()

proc volume*[N](g: Graph[N], s: HashSet[N]): int =
  ## Return the sum of degrees of nodes in set S.
  for n in s:
    if g.hasNode(n):
      result += g.degree(n)

proc volumeWeighted*[N](g: Graph[N], s: HashSet[N]): float =
  ## Return the weighted volume (sum of weighted degrees) of set S.
  for n in s:
    if g.hasNode(n):
      for v in g.neighbors(n):
        result += g.getEdgeAttr(n, v).getWeight()

proc conductance*[N](g: Graph[N], s: HashSet[N]): float =
  ## Return the conductance of the cut defined by S:
  ## conductance = cutSize(S) / min(vol(S), vol(V\S)).
  ## Returns 0.0 if the denominator is zero.
  let cut = cutSize(g, s).float
  var complement = initHashSet[N]()
  for n in g.nodes:
    if n notin s:
      complement.incl(n)
  let volS = volume(g, s).float
  let volC = volume(g, complement).float
  let denom = min(volS, volC)
  if denom == 0.0:
    return 0.0
  result = cut / denom

proc normalizedCutSize*[N](g: Graph[N], s: HashSet[N]): float =
  ## Return the normalized cut: cut/vol(S) + cut/vol(V\S).
  ## Returns 0.0 if either volume is zero.
  let cut = cutSize(g, s).float
  var complement = initHashSet[N]()
  for n in g.nodes:
    if n notin s:
      complement.incl(n)
  let volS = volume(g, s).float
  let volC = volume(g, complement).float
  if volS == 0.0 or volC == 0.0:
    return 0.0
  result = cut / volS + cut / volC

proc edgeExpansion*[N](g: Graph[N], s: HashSet[N]): float =
  ## Return the edge expansion: cutSize(S) / min(|S|, |V\S|).
  ## Also known as isoperimetric number of the cut.
  let cut = cutSize(g, s).float
  let sizeS = s.len
  let sizeC = g.numberOfNodes() - sizeS
  let denom = min(sizeS, sizeC).float
  if denom == 0.0:
    return 0.0
  result = cut / denom

proc nodeBoundary*[N](g: Graph[N], s: HashSet[N]): HashSet[N] =
  ## Return nodes in V\S that are adjacent to at least one node in S.
  for n in s:
    if g.hasNode(n):
      for v in g.neighbors(n):
        if v notin s:
          result.incl(v)

iterator edgeBoundary*[N](g: Graph[N], s: HashSet[N]): (N, N) =
  ## Yield edges with one endpoint in S and the other in V\S.
  for (u, v) in g.edges:
    if (u in s) xor (v in s):
      yield (u, v)
