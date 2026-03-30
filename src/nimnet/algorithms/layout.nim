## Graph layout algorithms for 2D positioning.
##
## - ``springLayout`` — Fruchterman-Reingold force-directed layout
## - ``circularLayout`` — nodes evenly on a circle
## - ``shellLayout`` — nodes on concentric circles
## - ``randomLayout`` — random positions
## - ``spectralLayout`` — positions from Laplacian eigenvectors

import std/[tables, sets, math, random, algorithm]
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

proc spectralLayout*[N](g: Graph[N]): Layout[N] =
  ## Position nodes using eigenvectors of the Laplacian matrix.
  ## Uses the 2nd and 3rd smallest eigenvectors for x, y coordinates.
  result = initTable[N, Position]()
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)
  let numNodes = nodeList.len
  if numNodes == 0: return
  if numNodes == 1:
    result[nodeList[0]] = (0.0, 0.0)
    return
  if numNodes == 2:
    result[nodeList[0]] = (-1.0, 0.0)
    result[nodeList[1]] = (1.0, 0.0)
    return

  # Build Laplacian
  var nodeIdx = initTable[N, int]()
  for i, nd in nodeList: nodeIdx[nd] = i
  var lap = newSeq[seq[float]](numNodes)
  for i in 0 ..< numNodes:
    lap[i] = newSeq[float](numNodes)
  for (u, v) in g.edges:
    let i = nodeIdx[u]
    let j = nodeIdx[v]
    lap[i][j] = -1.0
    lap[j][i] = -1.0
    lap[i][i] += 1.0
    lap[j][j] += 1.0

  # Simple power iteration to find dominant eigenvector of (maxEig*I - L)
  # then deflate and find next one
  var rng = initRand(42)
  let maxEig = float(numNodes) + 1.0  # Upper bound for Laplacian eigenvalue

  var shifted = newSeq[seq[float]](numNodes)
  for i in 0 ..< numNodes:
    shifted[i] = newSeq[float](numNodes)
    for j in 0 ..< numNodes:
      shifted[i][j] = -lap[i][j]
    shifted[i][i] += maxEig

  # Find eigenvectors by power iteration with deflation
  let c = 1.0 / sqrt(float(numNodes))  # constant eigenvector

  proc findEigenvector(mat: seq[seq[float]], prevVecs: seq[seq[float]]): seq[float] =
    var v = newSeq[float](numNodes)
    for i in 0 ..< numNodes: v[i] = rng.rand(2.0) - 1.0
    # Deflate previous vectors
    for pv in prevVecs:
      var dot = 0.0
      for i in 0 ..< numNodes: dot += v[i] * pv[i]
      for i in 0 ..< numNodes: v[i] -= dot * pv[i]
    var norm = 0.0
    for x in v: norm += x * x
    norm = sqrt(norm)
    if norm > 1e-15:
      for i in 0 ..< numNodes: v[i] /= norm
    for iter in 0 ..< 500:
      var w = newSeq[float](numNodes)
      for i in 0 ..< numNodes:
        for j in 0 ..< numNodes:
          w[i] += mat[i][j] * v[j]
      for pv in prevVecs:
        var dot = 0.0
        for i in 0 ..< numNodes: dot += w[i] * pv[i]
        for i in 0 ..< numNodes: w[i] -= dot * pv[i]
      norm = 0.0
      for x in w: norm += x * x
      norm = sqrt(norm)
      if norm > 1e-15:
        for i in 0 ..< numNodes: w[i] /= norm
      v = w
    result = v

  var constVec = newSeq[float](numNodes)
  for i in 0 ..< numNodes: constVec[i] = c
  let v2 = findEigenvector(shifted, @[constVec])
  let v3 = findEigenvector(shifted, @[constVec, v2])

  for i, nd in nodeList:
    result[nd] = (v2[i], v3[i])

proc kamadaKawaiLayout*[N](g: Graph[N], iterations: int = 50): Layout[N] =
  ## Kamada-Kawai layout using graph-theoretic distances.
  ## Simple spring embedding where ideal distances are shortest path lengths.
  result = initTable[N, Position]()
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)
  let numNodes = nodeList.len
  if numNodes == 0: return
  if numNodes == 1:
    result[nodeList[0]] = (0.0, 0.0)
    return

  var nodeIdx = initTable[N, int]()
  for i, nd in nodeList: nodeIdx[nd] = i

  # BFS shortest paths
  var dist = newSeq[seq[float]](numNodes)
  for i in 0 ..< numNodes:
    dist[i] = newSeq[float](numNodes)
    for j in 0 ..< numNodes:
      dist[i][j] = if i == j: 0.0 else: float(numNodes)  # large default
  for (u, v) in g.edges:
    let i = nodeIdx[u]
    let j = nodeIdx[v]
    dist[i][j] = 1.0
    dist[j][i] = 1.0
  # Floyd-Warshall
  for k in 0 ..< numNodes:
    for i in 0 ..< numNodes:
      for j in 0 ..< numNodes:
        if dist[i][k] + dist[k][j] < dist[i][j]:
          dist[i][j] = dist[i][k] + dist[k][j]

  # Initial circular layout
  for i, nd in nodeList:
    let angle = 2.0 * PI * float(i) / float(numNodes)
    result[nd] = (cos(angle), sin(angle))

  # KK iteration: move node with max energy
  let L0 = 1.0 / max(1.0, float(numNodes - 1))
  for iter in 0 ..< iterations:
    for i in 0 ..< numNodes:
      var gx, gy: float
      for j in 0 ..< numNodes:
        if i == j: continue
        let dx = result[nodeList[i]].x - result[nodeList[j]].x
        let dy = result[nodeList[i]].y - result[nodeList[j]].y
        let d = sqrt(dx * dx + dy * dy)
        if d < 1e-10: continue
        let ideal = dist[i][j] * L0
        let k = 1.0 / (dist[i][j] * dist[i][j])
        gx += k * (dx - ideal * dx / d)
        gy += k * (dy - ideal * dy / d)
      let step = 0.1 / max(1.0, float(iter + 1))
      result[nodeList[i]] = (result[nodeList[i]].x - step * gx,
                              result[nodeList[i]].y - step * gy)

proc spiralLayout*[N](g: Graph[N], equidistant: bool = false,
                       resolution: float = 0.35,
                       center: Position = (0.0, 0.0)): Layout[N] =
  ## Position nodes on an Archimedean spiral.
  result = initTable[N, Position]()
  var nodeList: seq[N]
  for n in g.nodes: nodeList.add(n)
  let numNodes = nodeList.len
  if numNodes == 0: return
  if numNodes == 1:
    result[nodeList[0]] = center
    return
  for i, nd in nodeList:
    let t = if equidistant: float(i) * 2.0 * PI / float(numNodes) * 3.0
            else: resolution * float(i)
    let r = t / (2.0 * PI)
    result[nd] = (center.x + r * cos(t), center.y + r * sin(t))

proc bipartiteLayout*[N](g: Graph[N], topNodes: HashSet[N],
                          align: string = "vertical",
                          center: Position = (0.0, 0.0),
                          scale: float = 1.0): Layout[N] =
  ## Position nodes in two straight lines for bipartite graphs.
  result = initTable[N, Position]()
  var top, bottom: seq[N]
  for n in g.nodes:
    if n in topNodes: top.add(n)
    else: bottom.add(n)

  let topN = top.len
  let botN = bottom.len

  for i, nd in top:
    let frac = if topN > 1: float(i) / float(topN - 1) else: 0.5
    if align == "vertical":
      result[nd] = (center.x - scale, center.y + scale * (2.0 * frac - 1.0))
    else:
      result[nd] = (center.x + scale * (2.0 * frac - 1.0), center.y + scale)

  for i, nd in bottom:
    let frac = if botN > 1: float(i) / float(botN - 1) else: 0.5
    if align == "vertical":
      result[nd] = (center.x + scale, center.y + scale * (2.0 * frac - 1.0))
    else:
      result[nd] = (center.x + scale * (2.0 * frac - 1.0), center.y - scale)

proc multipartiteLayout*[N](g: Graph[N], subsets: seq[seq[N]],
                             align: string = "vertical",
                             scale: float = 1.0): Layout[N] =
  ## Position nodes in multiple layers for multipartite graphs.
  result = initTable[N, Position]()
  let numSubsets = subsets.len
  if numSubsets == 0: return

  for layer, subset in subsets:
    let x = if numSubsets > 1: scale * (2.0 * float(layer) / float(numSubsets - 1) - 1.0) else: 0.0
    let n = subset.len
    for i, nd in subset:
      let y = if n > 1: scale * (2.0 * float(i) / float(n - 1) - 1.0) else: 0.0
      if align == "vertical":
        result[nd] = (x, y)
      else:
        result[nd] = (y, x)

proc arfLayout*[N](g: Graph[N], iterations: int = 50,
                    a: float = 1.1, etol: float = 1e-6,
                    dt: float = 1e-3, seed: int64 = 0): Layout[N] =
  ## ARF (Attractive and Repulsive Forces) layout.
  ## Variant of spring layout with adjustable attraction parameter `a`.
  var rng = if seed != 0: initRand(seed) else: initRand(42)
  result = initTable[N, Position]()
  var nodeList: seq[N]
  for n in g.nodes: nodeList.add(n)
  let numNodes = nodeList.len
  if numNodes == 0: return
  if numNodes == 1:
    result[nodeList[0]] = (0.0, 0.0)
    return

  for nd in nodeList:
    result[nd] = (rng.rand(1.0), rng.rand(1.0))

  var adj = initTable[N, HashSet[N]]()
  for nd in nodeList: adj[nd] = initHashSet[N]()
  for (u, v) in g.edges:
    adj[u].incl(v)
    adj[v].incl(u)

  for iter in 0 ..< iterations:
    var totalE = 0.0
    for i, u in nodeList:
      var fx, fy: float
      for j, v in nodeList:
        if i == j: continue
        let dx = result[u].x - result[v].x
        let dy = result[u].y - result[v].y
        var d = sqrt(dx * dx + dy * dy)
        if d < 1e-10: d = 1e-10
        # Repulsive force
        let repF = 1.0 / d
        fx += dx / d * repF
        fy += dy / d * repF
        # Attractive force (only for neighbors)
        if v in adj[u]:
          let attF = -a * d
          fx += dx / d * attF
          fy += dy / d * attF
      result[u] = (result[u].x + dt * fx, result[u].y + dt * fy)
      totalE += fx * fx + fy * fy
    if totalE < etol: break

proc forceAtlas2Layout*[N](g: Graph[N], iterations: int = 50,
                            gravity: float = 1.0,
                            scalingRatio: float = 2.0,
                            seed: int64 = 0): Layout[N] =
  ## ForceAtlas2 layout algorithm (simplified).
  ## A continuous force-directed layout suitable for large graphs.
  var rng = if seed != 0: initRand(seed) else: initRand(42)
  result = initTable[N, Position]()
  var nodeList: seq[N]
  for n in g.nodes: nodeList.add(n)
  let numNodes = nodeList.len
  if numNodes == 0: return
  if numNodes == 1:
    result[nodeList[0]] = (0.0, 0.0)
    return

  for nd in nodeList:
    result[nd] = (rng.rand(10.0) - 5.0, rng.rand(10.0) - 5.0)

  var nodeIdx = initTable[N, int]()
  for i, nd in nodeList: nodeIdx[nd] = i

  var degs = newSeq[float](numNodes)
  for i, nd in nodeList:
    degs[i] = float(g.degree(nd)) + 1.0

  for iter in 0 ..< iterations:
    var forces = newSeq[Position](numNodes)
    # Repulsive
    for i in 0 ..< numNodes:
      for j in (i + 1) ..< numNodes:
        let dx = result[nodeList[i]].x - result[nodeList[j]].x
        let dy = result[nodeList[i]].y - result[nodeList[j]].y
        var d = sqrt(dx * dx + dy * dy)
        if d < 1e-10: d = 1e-10
        let f = scalingRatio * degs[i] * degs[j] / d
        let fx = dx / d * f
        let fy = dy / d * f
        forces[i] = (forces[i].x + fx, forces[i].y + fy)
        forces[j] = (forces[j].x - fx, forces[j].y - fy)
    # Attractive
    for (u, v) in g.edges:
      let i = nodeIdx[u]
      let j = nodeIdx[v]
      let dx = result[u].x - result[v].x
      let dy = result[u].y - result[v].y
      let d = sqrt(dx * dx + dy * dy)
      forces[i] = (forces[i].x - dx, forces[i].y - dy)
      forces[j] = (forces[j].x + dx, forces[j].y + dy)
    # Gravity
    for i in 0 ..< numNodes:
      let d = sqrt(result[nodeList[i]].x * result[nodeList[i]].x +
                    result[nodeList[i]].y * result[nodeList[i]].y)
      if d > 1e-10:
        forces[i] = (forces[i].x - gravity * degs[i] * result[nodeList[i]].x / d,
                      forces[i].y - gravity * degs[i] * result[nodeList[i]].y / d)
    # Apply
    let speed = 1.0 / max(1.0, float(iter + 1))
    for i in 0 ..< numNodes:
      result[nodeList[i]] = (result[nodeList[i]].x + speed * forces[i].x,
                              result[nodeList[i]].y + speed * forces[i].y)

proc planarLayout*[N](g: Graph[N]): Layout[N] =
  ## Simple planar layout. Positions nodes using a canonical ordering.
  ## Falls back to circular layout as a simplified implementation.
  result = circularLayout(g)
