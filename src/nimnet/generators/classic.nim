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

proc nullGraph*(): Graph[int] =
  ## Generate a null graph with no nodes and no edges.
  result = newGraph[int]()

proc barbellGraph*(m1, m2: int): Graph[int] =
  ## Generate a barbell graph: two complete graphs of m1 nodes
  ## connected by a path of m2 nodes.
  ## Nodes: 0..m1-1 (left clique), m1..m1+m2-1 (bridge),
  ## m1+m2..2*m1+m2-1 (right clique).
  result = newGraph[int]()
  let total = 2 * m1 + m2
  for i in 0 ..< total:
    result.addNode(i)
  # Left complete graph
  for i in 0 ..< m1:
    for j in i + 1 ..< m1:
      result.addEdge(i, j)
  # Bridge path
  if m2 > 0:
    result.addEdge(m1 - 1, m1)
    for i in m1 ..< m1 + m2 - 1:
      result.addEdge(i, i + 1)
    result.addEdge(m1 + m2 - 1, m1 + m2)
  else:
    result.addEdge(m1 - 1, m1)
  # Right complete graph
  for i in m1 + m2 ..< total:
    for j in i + 1 ..< total:
      result.addEdge(i, j)

proc lollipopGraph*(m, n: int): Graph[int] =
  ## Generate a lollipop graph: a complete graph K_m connected to a
  ## path graph P_n. Nodes: 0..m-1 (clique), m..m+n-1 (path).
  result = newGraph[int]()
  let total = m + n
  for i in 0 ..< total:
    result.addNode(i)
  # Complete graph part
  for i in 0 ..< m:
    for j in i + 1 ..< m:
      result.addEdge(i, j)
  # Path part
  if n > 0:
    result.addEdge(m - 1, m)
    for i in m ..< total - 1:
      result.addEdge(i, i + 1)

proc ladderGraph*(n: int): Graph[int] =
  ## Generate a ladder graph — two parallel paths of n nodes each,
  ## connected by rungs. Nodes: 0..n-1 (first path), n..2n-1 (second path).
  result = newGraph[int]()
  for i in 0 ..< 2 * n:
    result.addNode(i)
  # First path
  for i in 0 ..< n - 1:
    result.addEdge(i, i + 1)
  # Second path
  for i in n ..< 2 * n - 1:
    result.addEdge(i, i + 1)
  # Rungs
  for i in 0 ..< n:
    result.addEdge(i, i + n)

proc circularLadderGraph*(n: int): Graph[int] =
  ## Generate a circular ladder graph (Möbius-Kantor-like).
  ## Two cycles of n nodes each, connected by rungs.
  result = newGraph[int]()
  for i in 0 ..< 2 * n:
    result.addNode(i)
  # First cycle
  for i in 0 ..< n:
    result.addEdge(i, (i + 1) mod n)
  # Second cycle
  for i in 0 ..< n:
    result.addEdge(n + i, n + (i + 1) mod n)
  # Rungs
  for i in 0 ..< n:
    result.addEdge(i, i + n)

proc tadpoleGraph*(m, n: int): Graph[int] =
  ## Generate a tadpole graph: a cycle of m nodes connected to a
  ## path of n nodes. Nodes: 0..m-1 (cycle), m..m+n-1 (tail).
  result = newGraph[int]()
  let total = m + n
  for i in 0 ..< total:
    result.addNode(i)
  # Cycle part
  for i in 0 ..< m:
    result.addEdge(i, (i + 1) mod m)
  # Tail
  if n > 0:
    result.addEdge(m - 1, m)
    for i in m ..< total - 1:
      result.addEdge(i, i + 1)

proc turanGraph*(n, r: int): Graph[int] =
  ## Generate a Turán graph T(n, r) — the complete r-partite graph
  ## with n nodes distributed as evenly as possible among r parts.
  result = newGraph[int]()
  for i in 0 ..< n:
    result.addNode(i)
  # Assign nodes to parts
  var parts: seq[seq[int]]
  let base = n div r
  let extra = n mod r
  var idx = 0
  for i in 0 ..< r:
    let size = base + (if i < extra: 1 else: 0)
    var part: seq[int]
    for j in 0 ..< size:
      part.add(idx)
      idx += 1
    parts.add(part)
  # Connect nodes in different parts
  for i in 0 ..< r:
    for j in i + 1 ..< r:
      for u in parts[i]:
        for v in parts[j]:
          result.addEdge(u, v)

proc bookGraph*(n: int): Graph[int] =
  ## Generate a book graph B_n — n triangles sharing a common edge.
  ## Center edge is (0, 1), leaves are 2..n+1.
  result = newGraph[int]()
  result.addEdge(0, 1)
  for i in 2 .. n + 1:
    result.addEdge(0, i)
    result.addEdge(1, i)

proc friendshipGraph*(n: int): Graph[int] =
  ## Generate a friendship graph (windmill graph) F_n.
  ## n triangles sharing a single common vertex (node 0).
  result = newGraph[int]()
  result.addNode(0)
  for i in 0 ..< n:
    let a = 2 * i + 1
    let b = 2 * i + 2
    result.addEdge(0, a)
    result.addEdge(0, b)
    result.addEdge(a, b)
