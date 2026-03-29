## Classic graph generators

import std/[tables, sets]
import ../types
import ../graph
import ../digraph

proc completeGraph*[N: SomeInteger](n: N): Graph[N] =
  ## Generate a complete graph K_n with nodes 0..n-1.
  result = newGraph[N]()
  for i in N(0) ..< n:
    result.addNode(i)
  for i in N(0) ..< n:
    for j in i + 1 ..< n:
      result.addEdge(i, j)

proc cycleGraph*[N: SomeInteger](n: N): Graph[N] =
  ## Generate a cycle graph C_n.
  result = newGraph[N]()
  if n <= 0:
    return
  for i in N(0) ..< n:
    result.addNode(i)
  for i in N(0) ..< n:
    result.addEdge(i, (i + 1) mod n)

proc pathGraph*[N: SomeInteger](n: N): Graph[N] =
  ## Generate a path graph P_n.
  result = newGraph[N]()
  for i in N(0) ..< n:
    result.addNode(i)
  for i in N(0) ..< n - 1:
    result.addEdge(i, i + 1)

proc starGraph*[N: SomeInteger](n: N): Graph[N] =
  ## Generate a star graph S_n with center node 0 and n outer nodes.
  result = newGraph[N]()
  result.addNode(N(0))
  for i in N(1) .. n:
    result.addEdge(N(0), i)

proc wheelGraph*[N: SomeInteger](n: N): Graph[N] =
  ## Generate a wheel graph W_n (hub + cycle of n nodes).
  result = newGraph[N]()
  if n <= 0:
    return
  result.addNode(N(0))  # hub
  for i in N(1) .. n:
    result.addNode(i)
    result.addEdge(N(0), i)
  for i in N(1) .. n:
    let next = if i == n: N(1) else: i + 1
    result.addEdge(i, next)

proc gridGraph*(rows, cols: int): Graph[int] =
  ## Generate a 2D grid graph with rows x cols nodes.
  ## Nodes are numbered 0 to rows*cols-1, row-major.
  result = newGraph[int]()
  for r in 0 ..< rows:
    for c in 0 ..< cols:
      let node = r * cols + c
      result.addNode(node)
      if c > 0:
        result.addEdge(node, node - 1)
      if r > 0:
        result.addEdge(node, node - cols)

proc completeBipartiteGraph*(n1, n2: int): Graph[int] =
  ## Generate a complete bipartite graph K_{n1,n2}.
  ## First set: 0..n1-1, second set: n1..n1+n2-1.
  result = newGraph[int]()
  for i in 0 ..< n1 + n2:
    result.addNode(i)
  for i in 0 ..< n1:
    for j in n1 ..< n1 + n2:
      result.addEdge(i, j)

proc emptyGraph*[N: SomeInteger](n: N): Graph[N] =
  ## Generate an empty graph with n nodes and no edges.
  result = newGraph[N]()
  for i in N(0) ..< n:
    result.addNode(i)

proc trivialGraph*(): Graph[int] =
  ## Generate a trivial graph with a single node (0).
  result = newGraph[int]()
  result.addNode(0)
