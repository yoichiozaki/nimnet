## Lattice graph generators
##
## Grid, hexagonal, triangular lattice, hypercube graphs.

import std/[math]
import ../graph

proc grid2dGraph*(m, n: int, periodic: bool = false): Graph[int] =
  ## Generate a 2D grid graph with m rows and n columns.
  ## If periodic=true, creates a torus (wrapping both dimensions).
  ## Nodes numbered 0..m*n-1 in row-major order.
  result = newGraph[int]()
  for i in 0 ..< m * n:
    result.addNode(i)
  for r in 0 ..< m:
    for c in 0 ..< n:
      let node = r * n + c
      # Right neighbor
      if c + 1 < n:
        result.addEdge(node, node + 1)
      elif periodic and n > 2:
        result.addEdge(node, r * n)  # wrap
      # Down neighbor
      if r + 1 < m:
        result.addEdge(node, node + n)
      elif periodic and m > 2:
        result.addEdge(node, c)  # wrap

proc triangularLatticeGraph*(m, n: int): Graph[int] =
  ## Generate a triangular lattice graph with m rows and n columns.
  ## Each square cell in the grid gets an additional diagonal.
  result = newGraph[int]()
  for i in 0 ..< m * n:
    result.addNode(i)
  for r in 0 ..< m:
    for c in 0 ..< n:
      let node = r * n + c
      if c + 1 < n:
        result.addEdge(node, node + 1)
      if r + 1 < m:
        result.addEdge(node, node + n)
      # Diagonal (down-right)
      if r + 1 < m and c + 1 < n:
        result.addEdge(node, node + n + 1)

proc hypercubeGraph*(dim: int): Graph[int] =
  ## Generate a hypercube graph Q_dim with 2^dim nodes.
  ## Two nodes are adjacent if their binary representations differ in exactly one bit.
  let nNodes = 1 shl dim
  result = newGraph[int]()
  for i in 0 ..< nNodes:
    result.addNode(i)
  for i in 0 ..< nNodes:
    for bit in 0 ..< dim:
      let j = i xor (1 shl bit)
      if j > i:
        result.addEdge(i, j)
