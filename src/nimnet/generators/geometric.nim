## Geometric graph generators.
##
## Generates graphs where nodes are placed in geometric space and edges
## are created based on distance criteria.
##
## - ``randomGeometricGraph(n, radius)`` — uniform random in unit square
## - ``waxmanGraph(n, beta, alpha)`` — Waxman random geographic model
## - ``softRandomGeometricGraph(n, radius)`` — soft radius threshold

import std/[tables, math, random]
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
    attr["x"] = $positions[i][0]
    attr["y"] = $positions[i][1]
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
    attr["x"] = $positions[i][0]
    attr["y"] = $positions[i][1]
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
    attr["x"] = $positions[i][0]
    attr["y"] = $positions[i][1]
    result.setNodeAttr(i, attr)

  for i in 0 ..< n:
    for j in (i + 1) ..< n:
      let dx = positions[i][0] - positions[j][0]
      let dy = positions[i][1] - positions[j][1]
      let d = sqrt(dx * dx + dy * dy)
      let prob = exp(-pow(d / radius, 2.0))
      if rand(1.0) < prob:
        result.addEdge(i, j)
