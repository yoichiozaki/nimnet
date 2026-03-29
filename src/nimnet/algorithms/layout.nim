## Graph layout algorithms for 2D positioning.
##
## - ``springLayout`` — Fruchterman-Reingold force-directed layout
## - ``circularLayout`` — nodes evenly on a circle
## - ``shellLayout`` — nodes on concentric circles
## - ``randomLayout`` — random positions
## - ``spectralLayout`` — positions from Laplacian eigenvectors

import std/[tables, sets, math, random]
import ../types, ../graph, ../digraph

type
  Position* = tuple[x, y: float]
  Layout*[N] = Table[N, Position]

proc circularLayout*[N](g: Graph[N], center: Position = (0.0, 0.0),
                         radius: float = 1.0): Layout[N] =
  ## Position nodes evenly on a circle.
  result = initTable[N, Position]()
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)
  let n = nodeList.len
  if n == 0:
    return
  for i, nd in nodeList:
    let angle = 2.0 * PI * float(i) / float(n)
    result[nd] = (center.x + radius * cos(angle),
                  center.y + radius * sin(angle))

proc circularLayout*[N](g: DiGraph[N], center: Position = (0.0, 0.0),
                         radius: float = 1.0): Layout[N] =
  ## Position digraph nodes evenly on a circle.
  result = initTable[N, Position]()
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)
  let n = nodeList.len
  if n == 0:
    return
  for i, nd in nodeList:
    let angle = 2.0 * PI * float(i) / float(n)
    result[nd] = (center.x + radius * cos(angle),
                  center.y + radius * sin(angle))

proc randomLayout*[N](g: Graph[N], seed: int64 = 0): Layout[N] =
  ## Assign random positions to nodes.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = initTable[N, Position]()
  for n in g.nodes:
    result[n] = (rng.rand(1.0), rng.rand(1.0))

proc springLayout*[N](g: Graph[N], iterations: int = 50,
                       k: float = 0.0, seed: int64 = 0): Layout[N] =
  ## Fruchterman-Reingold force-directed layout.
  ## ``k`` is the optimal distance between nodes (default: sqrt(1/n)).
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = initTable[N, Position]()

  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)
  let n = nodeList.len
  if n == 0:
    return
  if n == 1:
    result[nodeList[0]] = (0.0, 0.0)
    return

  # Initial random positions
  for nd in nodeList:
    result[nd] = (rng.rand(1.0), rng.rand(1.0))

  let optDist = if k > 0.0: k else: sqrt(1.0 / float(n))
  var temperature = 1.0

  for iter in 0 ..< iterations:
    var disp = initTable[N, Position]()
    for nd in nodeList:
      disp[nd] = (0.0, 0.0)

    # Repulsive forces between all pairs
    for i in 0 ..< n:
      for j in (i + 1) ..< n:
        let u = nodeList[i]
        let v = nodeList[j]
        let dx = result[u].x - result[v].x
        let dy = result[u].y - result[v].y
        var dist = sqrt(dx * dx + dy * dy)
        if dist < 1e-10:
          dist = 1e-10
        let force = optDist * optDist / dist
        let fx = dx / dist * force
        let fy = dy / dist * force
        disp[u] = (disp[u].x + fx, disp[u].y + fy)
        disp[v] = (disp[v].x - fx, disp[v].y - fy)

    # Attractive forces along edges
    for (u, v) in g.edges:
      let dx = result[u].x - result[v].x
      let dy = result[u].y - result[v].y
      var dist = sqrt(dx * dx + dy * dy)
      if dist < 1e-10:
        dist = 1e-10
      let force = dist * dist / optDist
      let fx = dx / dist * force
      let fy = dy / dist * force
      disp[u] = (disp[u].x - fx, disp[u].y - fy)
      disp[v] = (disp[v].x + fx, disp[v].y + fy)

    # Apply displacements with temperature clamping
    for nd in nodeList:
      let dx = disp[nd].x
      let dy = disp[nd].y
      var dist = sqrt(dx * dx + dy * dy)
      if dist < 1e-10:
        dist = 1e-10
      let scale = min(dist, temperature) / dist
      result[nd] = (result[nd].x + dx * scale,
                     result[nd].y + dy * scale)

    temperature *= 0.95  # cool down

proc springLayout*[N](g: DiGraph[N], iterations: int = 50,
                       k: float = 0.0, seed: int64 = 0): Layout[N] =
  ## Fruchterman-Reingold layout for directed graphs.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = initTable[N, Position]()

  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)
  let n = nodeList.len
  if n == 0:
    return
  if n == 1:
    result[nodeList[0]] = (0.0, 0.0)
    return

  for nd in nodeList:
    result[nd] = (rng.rand(1.0), rng.rand(1.0))

  let optDist = if k > 0.0: k else: sqrt(1.0 / float(n))
  var temperature = 1.0

  for iter in 0 ..< iterations:
    var disp = initTable[N, Position]()
    for nd in nodeList:
      disp[nd] = (0.0, 0.0)

    for i in 0 ..< n:
      for j in (i + 1) ..< n:
        let u = nodeList[i]
        let v = nodeList[j]
        let dx = result[u].x - result[v].x
        let dy = result[u].y - result[v].y
        var dist = sqrt(dx * dx + dy * dy)
        if dist < 1e-10: dist = 1e-10
        let force = optDist * optDist / dist
        let fx = dx / dist * force
        let fy = dy / dist * force
        disp[u] = (disp[u].x + fx, disp[u].y + fy)
        disp[v] = (disp[v].x - fx, disp[v].y - fy)

    for (u, v) in g.edges:
      let dx = result[u].x - result[v].x
      let dy = result[u].y - result[v].y
      var dist = sqrt(dx * dx + dy * dy)
      if dist < 1e-10: dist = 1e-10
      let force = dist * dist / optDist
      let fx = dx / dist * force
      let fy = dy / dist * force
      disp[u] = (disp[u].x - fx, disp[u].y - fy)
      disp[v] = (disp[v].x + fx, disp[v].y + fy)

    for nd in nodeList:
      let dx = disp[nd].x
      let dy = disp[nd].y
      var dist = sqrt(dx * dx + dy * dy)
      if dist < 1e-10: dist = 1e-10
      let scale = min(dist, temperature) / dist
      result[nd] = (result[nd].x + dx * scale,
                     result[nd].y + dy * scale)

    temperature *= 0.95

proc shellLayout*[N](g: Graph[N], shells: seq[seq[N]] = @[]): Layout[N] =
  ## Position nodes on concentric circles.
  ## If ``shells`` is empty, all nodes go on one circle.
  result = initTable[N, Position]()

  var actualShells = shells
  if actualShells.len == 0:
    var all: seq[N]
    for n in g.nodes:
      all.add(n)
    actualShells = @[all]

  for shellIdx, shell in actualShells:
    let radius = if actualShells.len == 1: 1.0 else: float(shellIdx + 1)
    let n = shell.len
    if n == 0:
      continue
    for i, nd in shell:
      let angle = 2.0 * PI * float(i) / float(n)
      result[nd] = (radius * cos(angle), radius * sin(angle))
