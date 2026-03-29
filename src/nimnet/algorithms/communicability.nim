## Communicability and closeness vitality for nimnet

import std/[tables, sets, deques, math]
import ../types
import ../graph

# =============================================================================
# Communicability (#114)
# =============================================================================

proc communicability*[N](g: Graph[N]): Table[(N, N), float] =
  ## Compute communicability between all pairs of nodes.
  ## G(u,v) = sum_{k=0}^{inf} (A^k)_{uv} / k!
  ## Equal to (e^A)_{uv} where A is the adjacency matrix.
  ## Approximated using matrix power series.
  result = initTable[(N, N), float]()
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n == 0: return
  var nodeIdx = initTable[N, int]()
  for i, node in nodes:
    nodeIdx[node] = i
  # Build adjacency matrix
  var mat = newSeq[seq[float]](n)
  for i in 0 ..< n:
    mat[i] = newSeq[float](n)
  for (u, v) in g.edges:
    let ui = nodeIdx[u]
    let vi = nodeIdx[v]
    mat[ui][vi] = 1.0
    mat[vi][ui] = 1.0
  # Compute e^A using series expansion: e^A = I + A + A^2/2! + ...
  var expA = newSeq[seq[float]](n)
  var power = newSeq[seq[float]](n)
  for i in 0 ..< n:
    expA[i] = newSeq[float](n)
    power[i] = newSeq[float](n)
    expA[i][i] = 1.0  # I
    power[i][i] = 1.0  # A^0 = I
  var factorial = 1.0
  let maxK = min(n, 20)
  for k in 1 .. maxK:
    factorial *= float(k)
    # power = power * mat
    var newPower = newSeq[seq[float]](n)
    for i in 0 ..< n:
      newPower[i] = newSeq[float](n)
      for j in 0 ..< n:
        for l in 0 ..< n:
          newPower[i][j] += power[i][l] * mat[l][j]
    power = newPower
    for i in 0 ..< n:
      for j in 0 ..< n:
        expA[i][j] += power[i][j] / factorial
  for i in 0 ..< n:
    for j in 0 ..< n:
      result[(nodes[i], nodes[j])] = expA[i][j]

proc communicabilityExp*[N](g: Graph[N]): Table[(N, N), float] =
  ## Alias for communicability (exponential form).
  communicability(g)

# =============================================================================
# Closeness Vitality (#114)
# =============================================================================

proc closenessVitality*[N](g: Graph[N]): Table[N, float] =
  ## Compute closeness vitality for each node.
  ## CV(v) = W(G) - W(G - v) where W(G) is the Wiener index.
  result = initTable[N, float]()
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n <= 1:
    for node in nodes:
      result[node] = 0.0
    return
  # Compute original Wiener index
  var originalWiener = 0.0
  for source in g.nodes:
    var dist = initTable[N, int]()
    dist[source] = 0
    var queue = initDeque[N]()
    queue.addLast(source)
    while queue.len > 0:
      let u = queue.popFirst()
      for v in g.neighbors(u):
        if v notin dist:
          dist[v] = dist[u] + 1
          queue.addLast(v)
    for _, d in dist:
      originalWiener += float(d)
  originalWiener /= 2.0  # Each pair counted twice
  # Compute Wiener index without each node
  for target in g.nodes:
    var wienerWithout = 0.0
    for source in g.nodes:
      if source == target: continue
      var dist = initTable[N, int]()
      dist[source] = 0
      var queue = initDeque[N]()
      queue.addLast(source)
      while queue.len > 0:
        let u = queue.popFirst()
        for v in g.neighbors(u):
          if v == target: continue
          if v notin dist:
            dist[v] = dist[u] + 1
            queue.addLast(v)
      for dest, d in dist:
        if dest != target:
          wienerWithout += float(d)
    wienerWithout /= 2.0
    result[target] = originalWiener - wienerWithout
