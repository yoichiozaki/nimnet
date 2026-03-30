## Structural holes measures for nimnet
## Burt's structural holes: constraint, effective size, local constraint

import std/[tables, sets]
import ../types
import ../graph

# =============================================================================
# Local Constraint
# =============================================================================

proc localConstraint*[N](g: Graph[N], u, v: N): float =
  ## Compute local constraint on u with respect to neighbor v.
  ## c(u,v) = (p(u,v) + sum_{w != u,v} p(u,w) * p(w,v))^2
  ## where p(u,v) = weight(u,v) / sum(weight(u,w) for w in neighbors(u))
  if not g.hasEdge(u, v):
    return 0.0
  # Compute proportional tie strengths from u
  var totalWeightU = 0.0
  for nbr in g.neighbors(u):
    totalWeightU += g[u, nbr].getWeight()
  if totalWeightU == 0.0:
    return 0.0
  let pUV = g[u, v].getWeight() / totalWeightU
  # Sum indirect constraint through mutual neighbors
  var indirect = 0.0
  for w in g.neighbors(u):
    if w == u or w == v: continue
    if g.hasEdge(w, v):
      let pUW = g[u, w].getWeight() / totalWeightU
      var totalWeightW = 0.0
      for wn in g.neighbors(w):
        totalWeightW += g[w, wn].getWeight()
      if totalWeightW > 0.0:
        let pWV = g[w, v].getWeight() / totalWeightW
        indirect += pUW * pWV
  result = (pUV + indirect) * (pUV + indirect)

# =============================================================================
# Constraint
# =============================================================================

proc constraint*[N](g: Graph[N]): Table[N, float] =
  ## Compute Burt's constraint for each node.
  ## C(u) = sum_{v in neighbors(u)} c(u,v)
  ## Higher constraint = fewer structural holes accessible.
  result = initTable[N, float]()
  for u in g.nodes:
    var c = 0.0
    for v in g.neighbors(u):
      c += localConstraint(g, u, v)
    result[u] = c

# =============================================================================
# Effective Size
# =============================================================================

proc effectiveSize*[N](g: Graph[N]): Table[N, float] =
  ## Compute effective size of each node's ego network.
  ## effectiveSize(u) = deg(u) - sum_{v in N(u)} sum_{w in N(u), w!=v} p(v,w)
  ## where p(v,w) = weight(v,w) / sum(weight(v,x) for x in N(v))
  result = initTable[N, float]()
  for u in g.nodes:
    let deg = g.degree(u)
    if deg == 0:
      result[u] = 0.0
      continue
    var redundancy = 0.0
    let neighbors = block:
      var s: seq[N]
      for n in g.neighbors(u): s.add(n)
      s
    let neighborSet = neighbors.toHashSet()
    for v in neighbors:
      var totalWeightV = 0.0
      for vn in g.neighbors(v):
        totalWeightV += g[v, vn].getWeight()
      if totalWeightV == 0.0: continue
      for w in neighbors:
        if w == v: continue
        if g.hasEdge(v, w):
          redundancy += g[v, w].getWeight() / totalWeightV
    result[u] = float(deg) - redundancy
