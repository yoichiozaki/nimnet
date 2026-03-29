## Random graph generators

import std/[random, tables, sets, math]
import ../types
import ../graph

proc erdosRenyiGraph*(n: int, p: float, seed: int64 = 0): Graph[int] =
  ## Generate an Erdős-Rényi random graph G(n, p).
  ## Each edge exists independently with probability p.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int]()
  for i in 0 ..< n:
    result.addNode(i)
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      if rng.rand(1.0) < p:
        result.addEdge(i, j)

proc barabasiAlbertGraph*(n, m: int, seed: int64 = 0): Graph[int] =
  ## Generate a Barabási-Albert preferential attachment graph.
  ## n: final number of nodes
  ## m: number of edges to attach from each new node (m <= initial nodes)
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int]()

  # Start with a complete graph of m+1 nodes
  for i in 0 .. m:
    result.addNode(i)
  for i in 0 .. m:
    for j in i + 1 .. m:
      result.addEdge(i, j)

  # Build repeated_nodes list for preferential attachment
  var repeatedNodes: seq[int]
  for i in 0 .. m:
    for j in 0 .. m:
      if i != j:
        repeatedNodes.add(i)

  for newNode in m + 1 ..< n:
    # Choose m unique targets by preferential attachment
    var targets = initHashSet[int]()
    while targets.len < m:
      let idx = rng.rand(repeatedNodes.len - 1)
      targets.incl(repeatedNodes[idx])

    result.addNode(newNode)
    for target in targets:
      result.addEdge(newNode, target)
      repeatedNodes.add(newNode)
      repeatedNodes.add(target)

proc wattsStrogatzGraph*(n, k: int, p: float, seed: int64 = 0): Graph[int] =
  ## Generate a Watts-Strogatz small-world graph.
  ## n: number of nodes
  ## k: each node connected to k nearest neighbors in ring (must be even)
  ## p: probability of rewiring each edge
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int]()

  for i in 0 ..< n:
    result.addNode(i)

  # Create ring lattice
  let halfK = k div 2
  for i in 0 ..< n:
    for j in 1 .. halfK:
      result.addEdge(i, (i + j) mod n)

  # Rewire edges
  for i in 0 ..< n:
    for j in 1 .. halfK:
      if rng.rand(1.0) < p:
        let oldTarget = (i + j) mod n
        # Find new target
        var newTarget = rng.rand(n - 1)
        var attempts = 0
        while (newTarget == i or result.hasEdge(i, newTarget)) and attempts < n:
          newTarget = rng.rand(n - 1)
          attempts.inc
        if attempts < n:
          result.removeEdge(i, oldTarget)
          result.addEdge(i, newTarget)

proc gnmRandomGraph*(n, m: int, seed: int64 = 0): Graph[int] =
  ## Generate a random graph G(n, m) with exactly m edges.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int]()
  for i in 0 ..< n:
    result.addNode(i)

  var edgeCount = 0
  let maxEdges = n * (n - 1) div 2
  if m > maxEdges:
    # Can't have more edges than complete graph
    for i in 0 ..< n:
      for j in i + 1 ..< n:
        result.addEdge(i, j)
    return

  while edgeCount < m:
    let u = rng.rand(n - 1)
    let v = rng.rand(n - 1)
    if u != v and not result.hasEdge(u, v):
      result.addEdge(u, v)
      edgeCount.inc

proc randomRegularGraph*(n, d: int, seed: int64 = 0): Graph[int] =
  ## Generate a random d-regular graph on n nodes.
  ## Uses the pairing model: may retry on failure.
  ## n*d must be even.
  if (n * d) mod 2 != 0:
    raise newException(ValueError, "n*d must be even for regular graph")
  if d >= n:
    raise newException(ValueError, "d must be less than n")

  var rng = if seed != 0: initRand(seed) else: initRand()

  for attempt in 0 ..< 100:
    result = newGraph[int]()
    for i in 0 ..< n:
      result.addNode(i)

    # Create stubs: d stubs per node
    var stubs: seq[int] = @[]
    for i in 0 ..< n:
      for _ in 0 ..< d:
        stubs.add(i)

    rng.shuffle(stubs)

    var valid = true
    var i = 0
    while i < stubs.len - 1:
      let u = stubs[i]
      let v = stubs[i + 1]
      if u == v or result.hasEdge(u, v):
        valid = false
        break
      result.addEdge(u, v)
      i += 2

    if valid:
      return result

  # Fallback: return last attempt
  result = newGraph[int]()
  for i in 0 ..< n:
    result.addNode(i)

proc newmanWattsStrogatzGraph*(n, k: int, p: float, seed: int64 = 0): Graph[int] =
  ## Generate a Newman-Watts-Strogatz small-world graph.
  ## Like Watts-Strogatz but adds shortcut edges instead of rewiring.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int]()
  for i in 0 ..< n:
    result.addNode(i)

  let halfK = k div 2
  for i in 0 ..< n:
    for j in 1 .. halfK:
      result.addEdge(i, (i + j) mod n)

  # Add shortcut edges with probability p
  for i in 0 ..< n:
    for j in 1 .. halfK:
      if rng.rand(1.0) < p:
        var target = rng.rand(n - 1)
        var attempts = 0
        while (target == i or result.hasEdge(i, target)) and attempts < n:
          target = rng.rand(n - 1)
          attempts.inc
        if attempts < n:
          result.addEdge(i, target)

proc stochasticBlockModel*(sizes: seq[int], p: seq[seq[float]], seed: int64 = 0): Graph[int] =
  ## Generate a stochastic block model graph.
  ## `sizes`: number of nodes in each community.
  ## `p`: k×k matrix of edge probabilities between communities.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int]()

  let k = sizes.len
  var communityOffset: seq[int] = @[]
  var offset = 0
  for s in sizes:
    communityOffset.add(offset)
    offset += s
  let n = offset

  for i in 0 ..< n:
    result.addNode(i)

  proc getCommunity(node: int): int =
    for c in 0 ..< k:
      if node < communityOffset[c] + sizes[c]:
        return c
    return k - 1

  for i in 0 ..< n:
    for j in i + 1 ..< n:
      let ci = getCommunity(i)
      let cj = getCommunity(j)
      if rng.rand(1.0) < p[ci][cj]:
        result.addEdge(i, j)

proc powerLawClusterGraph*(n, m: int, p: float,
                            seed: int64 = 0): Graph[int] =
  ## Generate a Holme-Kim power-law cluster graph.
  ## Extends Barabási-Albert with triangle formation probability ``p``.
  ## After attaching to a node via preferential attachment, with probability
  ## ``p`` a triangle is formed by also connecting to one of its neighbors.
  if m < 1 or m > n:
    raise newException(NimNetError, "m must be >= 1 and <= n")
  if p < 0.0 or p > 1.0:
    raise newException(NimNetError, "p must be in [0, 1]")

  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int]()

  # Start with a complete graph of m+1 nodes
  for i in 0 .. m:
    result.addNode(i)
  for i in 0 .. m:
    for j in i + 1 .. m:
      result.addEdge(i, j)

  # Repeated edges list for preferential attachment
  var repeated: seq[int]
  for i in 0 .. m:
    for j in 0 ..< m: # each has degree m
      repeated.add(i)

  for source in m + 1 ..< n:
    result.addNode(source)
    var targets = initHashSet[int]()

    # First attachment via preferential attachment
    while targets.len < 1:
      let target = repeated[rng.rand(repeated.len - 1)]
      if target != source:
        targets.incl(target)

    var lastTarget = 0
    for t in targets:
      lastTarget = t
    result.addEdge(source, lastTarget)
    repeated.add(source)
    repeated.add(lastTarget)

    var count = 1
    while count < m:
      if rng.rand(1.0) < p:
        # Triangle formation: connect to a neighbor of the last target
        var neighborList: seq[int]
        for nb in result.neighbors(lastTarget):
          if nb != source and not result.hasEdge(source, nb):
            neighborList.add(nb)
        if neighborList.len > 0:
          let nbTarget = neighborList[rng.rand(neighborList.len - 1)]
          result.addEdge(source, nbTarget)
          repeated.add(source)
          repeated.add(nbTarget)
          lastTarget = nbTarget
          count += 1
          continue

      # Preferential attachment
      var found = false
      for attempt in 0 ..< 100:
        let target = repeated[rng.rand(repeated.len - 1)]
        if target != source and not result.hasEdge(source, target):
          result.addEdge(source, target)
          repeated.add(source)
          repeated.add(target)
          lastTarget = target
          found = true
          break
      if not found:
        break
      count += 1
