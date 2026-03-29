## Link prediction algorithms
##
## Predict future edges based on graph topology.

import std/[tables, sets, algorithm, math]
import ../types
import ../graph

func commonNeighbors*[N](g: Graph[N], u, v: N): int =
  ## Return the number of common neighbors of u and v.
  for w in g.neighbors(u):
    if g.hasEdge(w, v):
      result += 1

func jaccardCoefficient*[N](g: Graph[N], u, v: N): float =
  ## Return the Jaccard coefficient of u and v.
  ## |N(u) ∩ N(v)| / |N(u) ∪ N(v)|
  var neighborU = initHashSet[N]()
  var neighborV = initHashSet[N]()
  for w in g.neighbors(u):
    neighborU.incl(w)
  for w in g.neighbors(v):
    neighborV.incl(w)
  let unionSize = (neighborU + neighborV).len
  if unionSize == 0:
    return 0.0
  let interSize = (neighborU * neighborV).len
  result = interSize.float / unionSize.float

func adamicAdar*[N](g: Graph[N], u, v: N): float =
  ## Return the Adamic-Adar index of u and v.
  ## Sum of 1/log(degree(w)) for common neighbors w.
  for w in g.neighbors(u):
    if g.hasEdge(w, v):
      let deg = g.degree(w)
      if deg > 1:
        result += 1.0 / ln(deg.float)

func preferentialAttachment*[N](g: Graph[N], u, v: N): int =
  ## Return the preferential attachment score: degree(u) * degree(v).
  result = g.degree(u) * g.degree(v)

func resourceAllocationIndex*[N](g: Graph[N], u, v: N): float =
  ## Return the resource allocation index of u and v.
  ## Sum of 1/degree(w) for common neighbors w.
  for w in g.neighbors(u):
    if g.hasEdge(w, v):
      let deg = g.degree(w)
      if deg > 0:
        result += 1.0 / deg.float

proc predictedEdges*[N](g: Graph[N], topK: int = 10,
                        scorer: proc(g: Graph[N], u, v: N): float = nil): seq[(N, N, float)] =
  ## Return top-k predicted edges by score.
  ## Default scorer is Adamic-Adar index.
  var candidates: seq[(N, N, float)] = @[]
  let nodeList = g.nodeSeq()
  for i in 0 ..< nodeList.len:
    for j in i + 1 ..< nodeList.len:
      let u = nodeList[i]
      let v = nodeList[j]
      if not g.hasEdge(u, v):
        let score = if scorer != nil:
          scorer(g, u, v)
        else:
          adamicAdar(g, u, v)
        candidates.add((u, v, score))
  candidates.sort(proc(a, b: (N, N, float)): int =
    if a[2] > b[2]: -1
    elif a[2] < b[2]: 1
    else: 0
  )
  let limit = min(topK, candidates.len)
  result = candidates[0 ..< limit]
