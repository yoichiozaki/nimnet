## Directed graph generators.
##
## - ``gnGraph`` — growing network model
## - ``gnrGraph`` — growing network with redirection
## - ``gncGraph`` — growing network with copying
## - ``scaleFreeGraph`` — scale-free directed graph
## - ``randomKOutGraph`` — random k-out digraph

import std/[tables, random]
import ../types, ../digraph

proc gnGraph*(n: int, seed: int64 = 0): DiGraph[int] =
  ## Generate a growing network digraph with ``n`` nodes.
  ## Each new node attaches to one uniformly chosen existing node.
  var rng = if seed != 0: initRand(seed) else: initRand()
  var dg = newDiGraph[int]()
  if n <= 0:
    return dg

  dg.addNode(0)
  for i in 1 ..< n:
    let target = rng.rand(i - 1)
    dg.addEdge(i, target)

  result = dg

proc gnrGraph*(n: int, p: float, seed: int64 = 0): DiGraph[int] =
  ## Generate a growing network with redirection (GNR).
  ## Each new node tries to attach to a random existing node;
  ## with probability ``p``, it is redirected to that node's successor.
  if p < 0.0 or p > 1.0:
    raise newException(NimNetError, "Probability p must be in [0, 1]")

  var rng = if seed != 0: initRand(seed) else: initRand()
  var dg = newDiGraph[int]()
  if n <= 0:
    return dg

  dg.addNode(0)
  for i in 1 ..< n:
    var target = rng.rand(i - 1)
    if rng.rand(1.0) < p:
      # Redirect: follow an outgoing edge if one exists
      var succs: seq[int]
      for s in dg.successors(target):
        succs.add(s)
      if succs.len > 0:
        target = succs[rng.rand(succs.len - 1)]
    dg.addEdge(i, target)

  result = dg

proc gncGraph*(n: int, seed: int64 = 0): DiGraph[int] =
  ## Generate a growing network with copying (GNC).
  ## Each new node attaches to a random existing node and copies
  ## all of that node's outgoing edges.
  var rng = if seed != 0: initRand(seed) else: initRand()
  var dg = newDiGraph[int]()
  if n <= 0:
    return dg

  dg.addNode(0)
  for i in 1 ..< n:
    let target = rng.rand(i - 1)
    dg.addEdge(i, target)
    # Copy outgoing edges of target
    var succs: seq[int]
    for s in dg.successors(target):
      succs.add(s)
    for s in succs:
      if s != i:
        dg.addEdge(i, s)

  result = dg

proc scaleFreeGraph*(n: int, alpha: float = 0.41, beta: float = 0.54,
                      gamma: float = 0.05,
                      seed: int64 = 0): DiGraph[int] =
  ## Generate a scale-free directed graph using the Bollobás model.
  ## At each step, with probability ``alpha`` add a new node with edge to existing,
  ## with probability ``beta`` add edge between existing nodes,
  ## with probability ``gamma`` add new node with edge from existing.
  if abs(alpha + beta + gamma - 1.0) > 1e-6:
    raise newException(NimNetError, "alpha + beta + gamma must equal 1.0")
  if n <= 0:
    raise newException(NimNetError, "n must be positive")

  var rng = if seed != 0: initRand(seed) else: initRand()
  var dg = newDiGraph[int]()

  # Start with a single edge
  dg.addEdge(0, 0)  # self-loop removed later
  dg.removeEdge(0, 0)
  dg.addNode(0)
  var nextNode = 1

  while dg.numberOfNodes() < n:
    let r = rng.rand(1.0)
    let numNodes = dg.numberOfNodes()
    let numEdges = dg.numberOfEdges()

    if r < alpha:
      # New node → existing node (preferential attachment by in-degree)
      let newNode = nextNode
      nextNode += 1
      dg.addNode(newNode)
      if numNodes > 0:
        # Choose target by in-degree (+1 for each node)
        var target = rng.rand(numNodes - 1)
        var nodeList: seq[int]
        for nd in dg.nodes:
          nodeList.add(nd)
        dg.addEdge(newNode, nodeList[target])

    elif r < alpha + beta:
      # Edge between existing nodes
      if numNodes >= 2:
        var nodeList: seq[int]
        for nd in dg.nodes:
          nodeList.add(nd)
        let u = nodeList[rng.rand(nodeList.len - 1)]
        let v = nodeList[rng.rand(nodeList.len - 1)]
        if u != v and not dg.hasEdge(u, v):
          dg.addEdge(u, v)

    else:
      # Existing node → new node
      let newNode = nextNode
      nextNode += 1
      dg.addNode(newNode)
      if numNodes > 0:
        var nodeList: seq[int]
        for nd in dg.nodes:
          nodeList.add(nd)
        let source = nodeList[rng.rand(nodeList.len - 1)]
        dg.addEdge(source, newNode)

  result = dg

proc randomKOutGraph*(n, k: int, alpha: float = 1.0,
                       seed: int64 = 0): DiGraph[int] =
  ## Generate a random k-out digraph where each node has exactly ``k``
  ## out-edges chosen uniformly at random.
  if k >= n:
    raise newException(NimNetError, "k must be less than n")
  if n <= 0:
    raise newException(NimNetError, "n must be positive")

  var rng = if seed != 0: initRand(seed) else: initRand()
  var dg = newDiGraph[int]()

  for i in 0 ..< n:
    dg.addNode(i)

  for i in 0 ..< n:
    var targets: seq[int]
    for j in 0 ..< n:
      if j != i:
        targets.add(j)
    rng.shuffle(targets)
    for j in 0 ..< k:
      dg.addEdge(i, targets[j])

  result = dg
