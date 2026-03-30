## Geometric graph generators.
##
## Generates graphs where nodes are placed in geometric space and edges
## are created based on distance criteria.
##
## - ``randomGeometricGraph(n, radius)`` — uniform random in unit square
## - ``waxmanGraph(n, beta, alpha)`` — Waxman random geographic model
## - ``softRandomGeometricGraph(n, radius)`` — soft radius threshold

import std/[math, random, json]
import ../types
import ../graph

proc randomGeometricGraph*(n: int, radius: float, seed = 0): Graph[int] =
  ## Generate a random geometric graph with ``n`` nodes.
  ## Nodes are uniformly placed in the unit square [0,1]×[0,1].
  ## An edge connects two nodes if their Euclidean distance ≤ ``radius``.
  if seed != 0:
    randomize(seed)
  else:
    randomize()

  result = newGraph[int]()
  var positions = newSeq[(float, float)](n)

  for i in 0 ..< n:
    positions[i] = (rand(1.0), rand(1.0))
    result.addNode(i)
    # Store position as node attributes
    var attr = newNodeAttr()
    attr["x"] = newJString($positions[i][0])
    attr["y"] = newJString($positions[i][1])
    result.setNodeAttr(i, attr)

  let r2 = radius * radius
  for i in 0 ..< n:
    for j in (i + 1) ..< n:
      let dx = positions[i][0] - positions[j][0]
      let dy = positions[i][1] - positions[j][1]
      if dx * dx + dy * dy <= r2:
        result.addEdge(i, j)

proc waxmanGraph*(n: int, beta = 0.4, alpha = 0.1,
    seed = 0): Graph[int] =
  ## Generate a Waxman random graph.
  ## Nodes are uniformly placed in the unit square.
  ## Edge probability: P(u,v) = beta * exp(-d(u,v) / (alpha * L))
  ## where L is the maximum distance between any two nodes.
  if seed != 0:
    randomize(seed)
  else:
    randomize()

  result = newGraph[int]()
  var positions = newSeq[(float, float)](n)

  for i in 0 ..< n:
    positions[i] = (rand(1.0), rand(1.0))
    result.addNode(i)
    var attr = newNodeAttr()
    attr["x"] = newJString($positions[i][0])
    attr["y"] = newJString($positions[i][1])
    result.setNodeAttr(i, attr)

  # Find L = max distance
  var maxDist = 0.0
  for i in 0 ..< n:
    for j in (i + 1) ..< n:
      let dx = positions[i][0] - positions[j][0]
      let dy = positions[i][1] - positions[j][1]
      let d = sqrt(dx * dx + dy * dy)
      if d > maxDist:
        maxDist = d

  if maxDist == 0.0:
    return

  for i in 0 ..< n:
    for j in (i + 1) ..< n:
      let dx = positions[i][0] - positions[j][0]
      let dy = positions[i][1] - positions[j][1]
      let d = sqrt(dx * dx + dy * dy)
      let prob = beta * exp(-d / (alpha * maxDist))
      if rand(1.0) < prob:
        result.addEdge(i, j)

proc softRandomGeometricGraph*(n: int, radius: float, seed = 0): Graph[int] =
  ## Generate a soft random geometric graph.
  ## Like ``randomGeometricGraph``, but edge probability decreases with
  ## distance: P(u,v) = exp(-(d(u,v)/radius)^2).
  if seed != 0:
    randomize(seed)
  else:
    randomize()

  result = newGraph[int]()
  var positions = newSeq[(float, float)](n)

  for i in 0 ..< n:
    positions[i] = (rand(1.0), rand(1.0))
    result.addNode(i)
    var attr = newNodeAttr()
    attr["x"] = newJString($positions[i][0])
    attr["y"] = newJString($positions[i][1])
    result.setNodeAttr(i, attr)

  for i in 0 ..< n:
    for j in (i + 1) ..< n:
      let dx = positions[i][0] - positions[j][0]
      let dy = positions[i][1] - positions[j][1]
      let d = sqrt(dx * dx + dy * dy)
      let prob = exp(-pow(d / radius, 2.0))
      if rand(1.0) < prob:
        result.addEdge(i, j)

proc geographicalThresholdGraph*(n: int, theta: float, seed: int64 = 0): Graph[int] =
  ## Generate a geographical threshold graph.
  ## Nodes placed randomly; edge (i,j) exists if (w_i + w_j) * metric(i,j) >= theta.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int](capacity = n)
  var positions = newSeq[(float, float)](n)
  var weights = newSeq[float](n)
  for i in 0 ..< n:
    positions[i] = (rng.rand(1.0), rng.rand(1.0))
    weights[i] = rng.rand(1.0)
    result.addNode(i)
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      let dx = positions[i][0] - positions[j][0]
      let dy = positions[i][1] - positions[j][1]
      let d = sqrt(dx * dx + dy * dy)
      if d > 0 and (weights[i] + weights[j]) / d >= theta:
        result.addEdge(i, j)

proc navigableSmallWorldGraph*(n: int, p: int = 1, q: int = 1, r: float = 2.0, seed: int64 = 0): Graph[int] =
  ## Generate Kleinberg's navigable small-world graph on an n x n grid.
  ## Each node has p short-range and q long-range contacts.
  var rng = if seed != 0: initRand(seed) else: initRand()
  let total = n * n
  result = newGraph[int](capacity = total)
  for i in 0 ..< total:
    result.addNode(i)
  # Short-range: grid connections
  for row in 0 ..< n:
    for col in 0 ..< n:
      let node = row * n + col
      if col + 1 < n:
        result.addEdge(node, node + 1)
      if row + 1 < n:
        result.addEdge(node, node + n)
  # Long-range contacts
  for node in 0 ..< total:
    let row = node div n
    let col = node mod n
    for _ in 0 ..< q:
      # Choose random target with probability ~ 1/d^r
      var bestTarget = -1
      var bestProb = 0.0
      for _ in 0 ..< total:
        let target = rng.rand(total - 1)
        if target != node and not result.hasEdge(node, target):
          let tr = target div n
          let tc = target mod n
          let d = abs(row - tr) + abs(col - tc)
          if d > 0:
            let prob = 1.0 / pow(float(d), r)
            if prob > bestProb:
              bestProb = prob
              bestTarget = target
      if bestTarget >= 0:
        result.addEdge(node, bestTarget)

proc thresholdedRandomGeometricGraph*(n: int, radius, theta: float, seed: int64 = 0): Graph[int] =
  ## Generate a thresholded random geometric graph.
  ## Like random geometric but with additional weight threshold.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int](capacity = n)
  var positions = newSeq[(float, float)](n)
  var weights = newSeq[float](n)
  for i in 0 ..< n:
    positions[i] = (rng.rand(1.0), rng.rand(1.0))
    weights[i] = rng.rand(1.0)
    result.addNode(i)
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      let dx = positions[i][0] - positions[j][0]
      let dy = positions[i][1] - positions[j][1]
      let d = sqrt(dx * dx + dy * dy)
      if d <= radius and (weights[i] + weights[j]) >= theta:
        result.addEdge(i, j)

proc geometricSoftConfigurationGraph*(n: int, beta: float = 1.0, seed: int64 = 0): Graph[int] =
  ## Generate a soft geometric configuration graph.
  ## Nodes placed uniformly; connection prob depends on distance and beta.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int](capacity = n)
  var positions = newSeq[(float, float)](n)
  for i in 0 ..< n:
    positions[i] = (rng.rand(1.0), rng.rand(1.0))
    result.addNode(i)
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      let dx = positions[i][0] - positions[j][0]
      let dy = positions[i][1] - positions[j][1]
      let d = sqrt(dx * dx + dy * dy)
      let prob = 1.0 / (1.0 + exp(beta * (d - 0.5)))
      if rng.rand(1.0) < prob:
        result.addEdge(i, j)
