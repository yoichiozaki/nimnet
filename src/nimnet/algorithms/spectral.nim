## Spectral graph algorithms.
##
## - ``laplacianMatrix`` — compute Laplacian matrix
## - ``normalizedLaplacian`` — normalized Laplacian
## - ``adjacencySpectrum`` — eigenvalues of adjacency matrix (power iteration)
## - ``laplacianSpectrum`` — eigenvalues of Laplacian matrix
## - ``fiedlerVector`` — second smallest eigenvector of Laplacian
## - ``spectralBisection`` — partition graph using Fiedler vector
## - ``algebraicConnectivity`` — second smallest Laplacian eigenvalue

import std/[tables, sets, math, random, algorithm]
import ../types, ../graph, ../digraph

proc laplacianMatrix*[N](g: Graph[N]): (seq[N], seq[seq[float]]) =
  ## Compute the Laplacian matrix L = D - A.
  ## Returns (nodeList, matrix) where nodeList[i] is the node for row/col i.
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)

  var nodeIdx = initTable[N, int]()
  for i, n in nodeList:
    nodeIdx[n] = i

  let n = nodeList.len
  var mat = newSeq[seq[float]](n)
  for i in 0 ..< n:
    mat[i] = newSeq[float](n)

  for (u, v) in g.edges:
    let i = nodeIdx[u]
    let j = nodeIdx[v]
    mat[i][j] = -1.0
    mat[j][i] = -1.0
    mat[i][i] += 1.0
    mat[j][j] += 1.0

  result = (nodeList, mat)

proc normalizedLaplacian*[N](g: Graph[N]): (seq[N], seq[seq[float]]) =
  ## Compute the normalized Laplacian L_norm = D^{-1/2} L D^{-1/2}.
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)

  var nodeIdx = initTable[N, int]()
  for i, n in nodeList:
    nodeIdx[n] = i

  let n = nodeList.len
  var mat = newSeq[seq[float]](n)
  for i in 0 ..< n:
    mat[i] = newSeq[float](n)

  # First compute degrees
  var deg = newSeq[float](n)
  for i, nd in nodeList:
    deg[i] = float(g.degree(nd))

  for (u, v) in g.edges:
    let i = nodeIdx[u]
    let j = nodeIdx[v]
    if deg[i] > 0.0 and deg[j] > 0.0:
      let val = -1.0 / sqrt(deg[i] * deg[j])
      mat[i][j] = val
      mat[j][i] = val

  for i in 0 ..< n:
    if deg[i] > 0.0:
      mat[i][i] = 1.0

  result = (nodeList, mat)

proc adjacencyMatrix*[N](g: Graph[N]): (seq[N], seq[seq[float]]) =
  ## Compute the adjacency matrix.
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)

  var nodeIdx = initTable[N, int]()
  for i, n in nodeList:
    nodeIdx[n] = i

  let n = nodeList.len
  var mat = newSeq[seq[float]](n)
  for i in 0 ..< n:
    mat[i] = newSeq[float](n)

  for (u, v, attr) in g.edgesWithAttr:
    let i = nodeIdx[u]
    let j = nodeIdx[v]
    let w = attr.getWeight(1.0)
    mat[i][j] = w
    mat[j][i] = w

  result = (nodeList, mat)

# Power iteration for finding dominant eigenvalue/eigenvector
proc powerIteration(mat: seq[seq[float]], maxIter: int = 1000,
                     tol: float = 1e-10, seed: int64 = 0): (float, seq[float]) =
  let n = mat.len
  if n == 0:
    return (0.0, @[])

  var rng = if seed != 0: initRand(seed) else: initRand(42)
  var v = newSeq[float](n)
  for i in 0 ..< n:
    v[i] = rng.rand(1.0)

  # Normalize
  var norm = 0.0
  for x in v: norm += x * x
  norm = sqrt(norm)
  if norm > 0.0:
    for i in 0 ..< n: v[i] /= norm

  var eigenvalue = 0.0
  for iter in 0 ..< maxIter:
    # Matrix-vector multiply
    var w = newSeq[float](n)
    for i in 0 ..< n:
      for j in 0 ..< n:
        w[i] += mat[i][j] * v[j]

    # Compute eigenvalue (Rayleigh quotient)
    var newEigenvalue = 0.0
    for i in 0 ..< n:
      newEigenvalue += v[i] * w[i]

    # Normalize
    norm = 0.0
    for x in w: norm += x * x
    norm = sqrt(norm)
    if norm > 0.0:
      for i in 0 ..< n: w[i] /= norm

    v = w
    if abs(newEigenvalue - eigenvalue) < tol:
      return (newEigenvalue, v)
    eigenvalue = newEigenvalue

  result = (eigenvalue, v)

# Inverse power iteration with shift for finding smallest eigenvalue
proc inversePowerIteration(mat: seq[seq[float]], shift: float = 0.0,
                            maxIter: int = 1000,
                            tol: float = 1e-8): (float, seq[float]) =
  let n = mat.len
  if n == 0:
    return (0.0, @[])

  # Create shifted matrix (M - shift*I)
  var shifted = newSeq[seq[float]](n)
  for i in 0 ..< n:
    shifted[i] = newSeq[float](n)
    for j in 0 ..< n:
      shifted[i][j] = mat[i][j]
    shifted[i][i] -= shift

  # Simple Gauss-Seidel solver for Ax=b
  proc solve(a: seq[seq[float]], b: seq[float]): seq[float] =
    var x = newSeq[float](n)
    for i in 0 ..< n: x[i] = b[i]
    for iter in 0 ..< 200:
      for i in 0 ..< n:
        var s = b[i]
        for j in 0 ..< n:
          if j != i:
            s -= a[i][j] * x[j]
        if abs(a[i][i]) > 1e-15:
          x[i] = s / a[i][i]
    result = x

  var v = newSeq[float](n)
  var rng = initRand(42)
  for i in 0 ..< n:
    v[i] = rng.rand(1.0)
  var norm = 0.0
  for x in v: norm += x * x
  norm = sqrt(norm)
  for i in 0 ..< n: v[i] /= norm

  var eigenvalue = 0.0
  for iter in 0 ..< maxIter:
    let w = solve(shifted, v)
    norm = 0.0
    for x in w: norm += x * x
    norm = sqrt(norm)
    if norm < 1e-15:
      break
    for i in 0 ..< n: v[i] = w[i] / norm

    var newEigenvalue = 0.0
    for i in 0 ..< n:
      var mv = 0.0
      for j in 0 ..< n:
        mv += mat[i][j] * v[j]
      newEigenvalue += v[i] * mv

    if abs(newEigenvalue - eigenvalue) < tol:
      return (newEigenvalue, v)
    eigenvalue = newEigenvalue

  result = (eigenvalue, v)

# QR algorithm for computing all eigenvalues of a symmetric matrix
proc qrEigenvalues(mat: seq[seq[float]], maxIter: int = 500): seq[float] =
  let n = mat.len
  if n == 0: return @[]

  # Work on a copy
  var a = newSeq[seq[float]](n)
  for i in 0 ..< n:
    a[i] = newSeq[float](n)
    for j in 0 ..< n:
      a[i][j] = mat[i][j]

  for iter in 0 ..< maxIter:
    # QR decomposition via Gram-Schmidt
    var q = newSeq[seq[float]](n)
    var r = newSeq[seq[float]](n)
    for i in 0 ..< n:
      q[i] = newSeq[float](n)
      r[i] = newSeq[float](n)

    for j in 0 ..< n:
      # Start with column j of A
      var v = newSeq[float](n)
      for i in 0 ..< n:
        v[i] = a[i][j]

      # Subtract projections
      for k in 0 ..< j:
        var dot = 0.0
        for i in 0 ..< n:
          dot += q[i][k] * a[i][j]
        r[k][j] = dot
        for i in 0 ..< n:
          v[i] -= dot * q[i][k]

      var norm = 0.0
      for x in v: norm += x * x
      norm = sqrt(norm)
      r[j][j] = norm
      if norm > 1e-15:
        for i in 0 ..< n:
          q[i][j] = v[i] / norm
      else:
        for i in 0 ..< n:
          q[i][j] = 0.0

    # A = R * Q
    var newA = newSeq[seq[float]](n)
    for i in 0 ..< n:
      newA[i] = newSeq[float](n)
      for j in 0 ..< n:
        for k in 0 ..< n:
          newA[i][j] += r[i][k] * q[k][j]
    a = newA

    # Check convergence (off-diagonal elements small)
    var offDiag = 0.0
    for i in 0 ..< n:
      for j in 0 ..< n:
        if i != j:
          offDiag += a[i][j] * a[i][j]
    if offDiag < 1e-20:
      break

  result = newSeq[float](n)
  for i in 0 ..< n:
    result[i] = a[i][i]
  result.sort()

proc algebraicConnectivity*[N](g: Graph[N]): float =
  ## Compute the algebraic connectivity (Fiedler value) —
  ## the second smallest eigenvalue of the Laplacian matrix.
  let (_, lap) = laplacianMatrix(g)
  let n = lap.len
  if n <= 1:
    return 0.0

  let eigenvals = qrEigenvalues(lap)
  # Second smallest eigenvalue (first is ~0 for connected graphs)
  if eigenvals.len >= 2:
    result = eigenvals[1]
  else:
    result = 0.0

proc fiedlerVector*[N](g: Graph[N]): (seq[N], seq[float]) =
  ## Compute the Fiedler vector — eigenvector corresponding to the
  ## second smallest eigenvalue of the Laplacian.
  ## Uses power iteration on shifted Laplacian with deflation.
  let (nodeList, lap) = laplacianMatrix(g)
  let n = lap.len
  if n <= 1:
    return (nodeList, newSeq[float](n))

  # First eigenvalue of L is 0 with eigenvector (1/sqrt(n), ..., 1/sqrt(n))
  # To find second eigenvector, we use power iteration on (maxEig*I - L)
  # but project out the constant eigenvector at each step.

  # Get max eigenvalue estimate
  let eigenvals = qrEigenvalues(lap)
  let maxEig = eigenvals[^1] + 0.1

  # Create shifted matrix: M = maxEig*I - L
  # Largest eigenvalue of M corresponds to smallest eigenvalue of L
  var shifted = newSeq[seq[float]](n)
  for i in 0 ..< n:
    shifted[i] = newSeq[float](n)
    for j in 0 ..< n:
      shifted[i][j] = -lap[i][j]
    shifted[i][i] += maxEig

  var rng = initRand(42)
  var v = newSeq[float](n)
  for i in 0 ..< n:
    v[i] = rng.rand(2.0) - 1.0

  # The constant vector (eigenvector of eigenvalue 0)
  let c = 1.0 / sqrt(float(n))

  # Project out constant eigenvector
  proc deflate(vec: var seq[float]) =
    var dot = 0.0
    for i in 0 ..< n: dot += vec[i] * c
    for i in 0 ..< n: vec[i] -= dot * c

  deflate(v)
  var norm = 0.0
  for x in v: norm += x * x
  norm = sqrt(norm)
  if norm > 1e-15:
    for i in 0 ..< n: v[i] /= norm

  for iter in 0 ..< 1000:
    # w = M * v
    var w = newSeq[float](n)
    for i in 0 ..< n:
      for j in 0 ..< n:
        w[i] += shifted[i][j] * v[j]

    # Project out constant eigenvector
    deflate(w)

    norm = 0.0
    for x in w: norm += x * x
    norm = sqrt(norm)
    if norm > 1e-15:
      for i in 0 ..< n: w[i] /= norm

    # Check convergence
    var diff = 0.0
    for i in 0 ..< n:
      diff += (w[i] - v[i]) * (w[i] - v[i])
    v = w
    if diff < 1e-16:
      break

  result = (nodeList, v)

proc spectralBisection*[N](g: Graph[N]): (HashSet[N], HashSet[N]) =
  ## Partition the graph into two parts using the Fiedler vector.
  ## Nodes with positive Fiedler values go to one partition,
  ## negative to the other.
  let (nodeList, fiedler) = fiedlerVector(g)
  var part1 = initHashSet[N]()
  var part2 = initHashSet[N]()
  for i, n in nodeList:
    if i < fiedler.len and fiedler[i] >= 0.0:
      part1.incl(n)
    else:
      part2.incl(n)
  result = (part1, part2)

proc adjacencySpectrum*[N](g: Graph[N]): float =
  ## Compute the largest eigenvalue (spectral radius) of the adjacency matrix.
  let (_, adj) = adjacencyMatrix(g)
  if adj.len == 0:
    return 0.0
  let (eigenvalue, _) = powerIteration(adj)
  result = eigenvalue

proc laplacianSpectrum*[N](g: Graph[N]): float =
  ## Compute the largest eigenvalue of the Laplacian matrix.
  let (_, lap) = laplacianMatrix(g)
  if lap.len == 0:
    return 0.0
  let (eigenvalue, _) = powerIteration(lap)
  result = eigenvalue

# --- Incidence Matrix ---

proc incidenceMatrix*[N](g: Graph[N]): (seq[N], seq[(N, N)], seq[seq[float]]) =
  ## Compute the incidence matrix.
  ## Returns (nodeList, edgeList, matrix) where matrix[i][j] indicates
  ## node i is incident to edge j.
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)
  var nodeIdx = initTable[N, int]()
  for i, n in nodeList:
    nodeIdx[n] = i

  var edgeList: seq[(N, N)]
  for (u, v) in g.edges:
    edgeList.add((u, v))

  let nNodes = nodeList.len
  let nEdges = edgeList.len
  var mat = newSeq[seq[float]](nNodes)
  for i in 0 ..< nNodes:
    mat[i] = newSeq[float](nEdges)
  for j, (u, v) in edgeList:
    mat[nodeIdx[u]][j] = 1.0
    mat[nodeIdx[v]][j] = 1.0
  result = (nodeList, edgeList, mat)

proc incidenceMatrix*[N](g: DiGraph[N]): (seq[N], seq[(N, N)], seq[seq[float]]) =
  ## Compute the directed incidence matrix.
  ## Source node gets +1, target node gets -1.
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)
  var nodeIdx = initTable[N, int]()
  for i, n in nodeList:
    nodeIdx[n] = i

  var edgeList: seq[(N, N)]
  for (u, v) in g.edges:
    edgeList.add((u, v))

  let nNodes = nodeList.len
  let nEdges = edgeList.len
  var mat = newSeq[seq[float]](nNodes)
  for i in 0 ..< nNodes:
    mat[i] = newSeq[float](nEdges)
  for j, (u, v) in edgeList:
    mat[nodeIdx[u]][j] = 1.0
    mat[nodeIdx[v]][j] = -1.0
  result = (nodeList, edgeList, mat)

# --- Directed Laplacian ---

proc directedLaplacianMatrix*[N](g: DiGraph[N]): (seq[N], seq[seq[float]]) =
  ## Compute the Laplacian matrix for a directed graph.
  ## L = D_out - A, where D_out is the out-degree diagonal.
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)
  var nodeIdx = initTable[N, int]()
  for i, n in nodeList:
    nodeIdx[n] = i

  let n = nodeList.len
  var mat = newSeq[seq[float]](n)
  for i in 0 ..< n:
    mat[i] = newSeq[float](n)

  for (u, v, attr) in g.edgesWithAttr:
    let i = nodeIdx[u]
    let j = nodeIdx[v]
    let w = attr.getWeight(1.0)
    mat[i][j] -= w
    mat[i][i] += w
  result = (nodeList, mat)

proc directedCombinatorialLaplacianMatrix*[N](g: DiGraph[N]): (seq[N], seq[seq[float]]) =
  ## Compute the combinatorial Laplacian for a directed graph.
  ## Same as directedLaplacianMatrix (L = D_out - A).
  result = directedLaplacianMatrix(g)

# --- Bethe Hessian Matrix ---

proc betheHessianMatrix*[N](g: Graph[N], r: float = 0.0): (seq[N], seq[seq[float]]) =
  ## Compute the Bethe Hessian matrix.
  ## H(r) = (r^2 - 1) * I - r * A + D
  ## If r = 0, uses sqrt(spectral_radius(adjacency)) as default.
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)
  var nodeIdx = initTable[N, int]()
  for i, nd in nodeList:
    nodeIdx[nd] = i

  let n = nodeList.len
  let (_, adjMat) = adjacencyMatrix(g)

  var rVal = r
  if rVal == 0.0:
    let (spectRad, _) = powerIteration(adjMat)
    rVal = sqrt(max(spectRad, 1.0))

  var mat = newSeq[seq[float]](n)
  for i in 0 ..< n:
    mat[i] = newSeq[float](n)
    let deg = float(g.degree(nodeList[i]))
    mat[i][i] = (rVal * rVal - 1.0) + deg
    for j in 0 ..< n:
      mat[i][j] -= rVal * adjMat[i][j]
  result = (nodeList, mat)

# --- Modularity Matrix ---

proc modularityMatrix*[N](g: Graph[N]): (seq[N], seq[seq[float]]) =
  ## Compute the modularity matrix B = A - (k_i * k_j) / (2m).
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)
  var nodeIdx = initTable[N, int]()
  for i, nd in nodeList:
    nodeIdx[nd] = i

  let n = nodeList.len
  let m2 = float(g.numberOfEdges) * 2.0
  let (_, adjMat) = adjacencyMatrix(g)

  var degs = newSeq[float](n)
  for i, nd in nodeList:
    degs[i] = float(g.degree(nd))

  var mat = newSeq[seq[float]](n)
  for i in 0 ..< n:
    mat[i] = newSeq[float](n)
    for j in 0 ..< n:
      if m2 > 0.0:
        mat[i][j] = adjMat[i][j] - (degs[i] * degs[j]) / m2
      else:
        mat[i][j] = adjMat[i][j]
  result = (nodeList, mat)

proc directedModularityMatrix*[N](g: DiGraph[N]): (seq[N], seq[seq[float]]) =
  ## Compute the directed modularity matrix.
  ## B = A - (k_out_i * k_in_j) / m
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)
  var nodeIdx = initTable[N, int]()
  for i, nd in nodeList:
    nodeIdx[nd] = i

  let n = nodeList.len
  let m = float(g.numberOfEdges)

  var adjMat = newSeq[seq[float]](n)
  for i in 0 ..< n:
    adjMat[i] = newSeq[float](n)
  for (u, v) in g.edges:
    let i = nodeIdx[u]
    let j = nodeIdx[v]
    adjMat[i][j] = 1.0

  var outDegs = newSeq[float](n)
  var inDegs = newSeq[float](n)
  for i, nd in nodeList:
    outDegs[i] = float(g.outDegree(nd))
    inDegs[i] = float(g.inDegree(nd))

  var mat = newSeq[seq[float]](n)
  for i in 0 ..< n:
    mat[i] = newSeq[float](n)
    for j in 0 ..< n:
      if m > 0.0:
        mat[i][j] = adjMat[i][j] - (outDegs[i] * inDegs[j]) / m
      else:
        mat[i][j] = adjMat[i][j]
  result = (nodeList, mat)

# --- Additional Spectra ---

proc allEigenvalues(mat: seq[seq[float]]): seq[float] =
  ## Compute all eigenvalues of a symmetric matrix.
  result = qrEigenvalues(mat)

proc betheHessianSpectrum*[N](g: Graph[N], r: float = 0.0): seq[float] =
  ## All eigenvalues of the Bethe Hessian matrix.
  let (_, mat) = betheHessianMatrix(g, r)
  result = allEigenvalues(mat)

proc normalizedLaplacianSpectrum*[N](g: Graph[N]): seq[float] =
  ## All eigenvalues of the normalized Laplacian.
  let (_, mat) = normalizedLaplacian(g)
  result = allEigenvalues(mat)

proc modularitySpectrum*[N](g: Graph[N]): seq[float] =
  ## All eigenvalues of the modularity matrix.
  let (_, mat) = modularityMatrix(g)
  result = allEigenvalues(mat)

proc adjacencySpectrumAll*[N](g: Graph[N]): seq[float] =
  ## All eigenvalues of the adjacency matrix.
  let (_, mat) = adjacencyMatrix(g)
  result = allEigenvalues(mat)

proc laplacianSpectrumAll*[N](g: Graph[N]): seq[float] =
  ## All eigenvalues of the Laplacian matrix.
  let (_, mat) = laplacianMatrix(g)
  result = allEigenvalues(mat)

# --- Spectral Ordering ---

proc spectralOrdering*[N](g: Graph[N]): seq[N] =
  ## Order nodes using the Fiedler vector (spectral ordering).
  ## Sorts nodes by their Fiedler vector components.
  let (nodeList, fiedler) = fiedlerVector(g)
  if nodeList.len == 0:
    return @[]
  var indexed: seq[(float, N)]
  for i, n in nodeList:
    indexed.add((fiedler[i], n))
  indexed.sort(proc(a, b: (float, N)): int = cmp(a[0], b[0]))
  result = newSeq[N](indexed.len)
  for i, (_, n) in indexed:
    result[i] = n
