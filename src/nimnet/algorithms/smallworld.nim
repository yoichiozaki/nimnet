## Small-world measures: sigma (σ) and omega (ω).
##
## These quantify "small-world-ness" of a network by comparing it
## to random and lattice graph baselines.
##
## - ``sigma(g)`` — σ = (C/C_r) / (L/L_r) where C is clustering coefficient,
##   L is average shortest path length, and subscript r denotes random graph baseline
## - ``omega(g)`` — ω = L_r/L − C/C_l where subscript l denotes lattice baseline

import std/[tables, sets, math, random]
import ../graph
import ../types
import ./clustering
import ./components
import ./shortest_paths

proc avgPathLen[N](g: Graph[N]): float =
  ## Internal: average shortest path length of a connected graph.
  if not isConnected(g):
    raise newException(NimNetError, "Graph is not connected")
  let n = g.numberOfNodes()
  if n <= 1:
    return 0.0
  var total = 0.0
  var count = 0
  for src in g.nodes:
    let dist = singleSourceShortestPathLength(g, src)
    for tgt, d in dist:
      if tgt != src:
        total += d.float
        count += 1
  result = total / count.float

proc randomReferenceGraph[N](g: Graph[N], niter = 1, seed = 0): Graph[N] =
  ## Create a random reference graph by rewiring edges while preserving
  ## degree sequence. Uses the Maslov-Sneppen rewiring algorithm.
  result = g.copy()
  var edgeList: seq[(N, N)]
  for (u, v) in g.edges:
    edgeList.add((u, v))

  if seed != 0:
    randomize(seed)
  else:
    randomize()

  let nEdges = edgeList.len
  if nEdges < 2:
    return

  for iteration in 0 ..< niter * nEdges:
    let i = rand(nEdges - 1)
    let j = rand(nEdges - 1)
    if i == j:
      continue
    let (u, v) = edgeList[i]
    let (x, y) = edgeList[j]

    # Avoid self-loops and multi-edges
    if u == x or u == y or v == x or v == y:
      continue

    # Try swapping: (u,v) and (x,y) -> (u,x) and (v,y) or (u,y) and (v,x)
    if not result.hasEdge(u, x) and not result.hasEdge(v, y):
      result.removeEdge(u, v)
      result.removeEdge(x, y)
      result.addEdge(u, x)
      result.addEdge(v, y)
      edgeList[i] = (u, x)
      edgeList[j] = (v, y)

proc latticeReferenceGraph[N](g: Graph[N], niter = 1, seed = 0): Graph[N] =
  ## Create a lattice-like reference graph from g by gradually rewiring
  ## edges to increase clustering while preserving degree sequence.
  ## Approximated by a ring lattice with same degree sequence.
  result = g.copy()
  var edgeList: seq[(N, N)]
  for (u, v) in g.edges:
    edgeList.add((u, v))

  if seed != 0:
    randomize(seed)
  else:
    randomize()

  let nEdges = edgeList.len
  if nEdges < 2:
    return

  # Rewire to increase clustering (swap to make neighbors closer)
  for iteration in 0 ..< niter * nEdges:
    let i = rand(nEdges - 1)
    let j = rand(nEdges - 1)
    if i == j:
      continue
    let (u, v) = edgeList[i]
    let (x, y) = edgeList[j]
    if u == x or u == y or v == x or v == y:
      continue
    if not result.hasEdge(u, y) and not result.hasEdge(v, x):
      result.removeEdge(u, v)
      result.removeEdge(x, y)
      result.addEdge(u, y)
      result.addEdge(v, x)
      edgeList[i] = (u, y)
      edgeList[j] = (v, x)

proc sigma*[N](g: Graph[N], niter = 100, nrandRef = 10, seed = 0): float =
  ## Return the small-world coefficient σ = (C/C_r) / (L/L_r).
  ## σ > 1 indicates small-world behavior.
  ##
  ## Parameters:
  ## - ``niter``: number of rewiring iterations per edge
  ## - ``nrandRef``: number of random reference graphs to average
  ## - ``seed``: random seed (0 for system random)
  let cOrig = transitivity(g)
  let lOrig = avgPathLen(g)

  var cRand = 0.0
  var lRand = 0.0
  for i in 0 ..< nrandRef:
    let rg = randomReferenceGraph(g, niter, if seed != 0: seed + i else: 0)
    cRand += transitivity(rg)
    lRand += avgPathLen(rg)
  cRand /= nrandRef.float
  lRand /= nrandRef.float

  if cRand == 0.0 or lOrig == 0.0:
    return 0.0

  result = (cOrig / cRand) / (lOrig / lRand)

proc omega*[N](g: Graph[N], niter = 100, nrandRef = 10, seed = 0): float =
  ## Return the small-world coefficient ω = L_r/L − C/C_l.
  ## ω ≈ 0 indicates small-world; ω ≈ −1 is lattice-like; ω ≈ 1 is random-like.
  ##
  ## Parameters:
  ## - ``niter``: number of rewiring iterations per edge
  ## - ``nrandRef``: number of reference graphs to average
  ## - ``seed``: random seed (0 for system random)
  let cOrig = transitivity(g)
  let lOrig = avgPathLen(g)

  var lRand = 0.0
  for i in 0 ..< nrandRef:
    let rg = randomReferenceGraph(g, niter, if seed != 0: seed + i else: 0)
    lRand += avgPathLen(rg)
  lRand /= nrandRef.float

  var cLattice = 0.0
  for i in 0 ..< nrandRef:
    let lg = latticeReferenceGraph(g, niter, if seed != 0: seed + i else: 0)
    cLattice += transitivity(lg)
  cLattice /= nrandRef.float

  if lOrig == 0.0 or cLattice == 0.0:
    return 0.0

  result = lRand / lOrig - cOrig / cLattice
