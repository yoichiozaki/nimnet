## Mycielski graph generators

import std/[tables]
import ../graph

proc mycielskian*[N: SomeInteger](g: Graph[N]): Graph[N] =
  ## Return the Mycielskian of graph g.
  ## The Mycielskian M(G) increases the chromatic number by 1.
  ## For n-node G, M(G) has 2n+1 nodes.
  let n = g.numberOfNodes
  let ns = g.nodeSeq
  result = g.copy()
  # Map old nodes to indices
  var nodeIdx: Table[N, int]
  for i, node in ns:
    nodeIdx[node] = i
  # Add mirror nodes: n + i for each original node i
  let base = N(n)
  for i in 0 ..< n:
    result.addNode(base + N(i))
  # Add universal node
  let u = base + N(n)
  result.addNode(u)
  # Each mirror node base+i connects to neighbors of original ns[i]
  for i in 0 ..< n:
    for nb in g.neighbors(ns[i]):
      let j = nodeIdx[nb]
      result.addEdge(base + N(i), nb)
    result.addEdge(base + N(i), u)

proc mycielskiGraph*(n: int): Graph[int] =
  ## Generate the Mycielski graph M_n.
  ## M_1 is a single node, M_2 is K_2, M_n = mycielskian(M_{n-1}).
  if n <= 0:
    return newGraph[int]()
  if n == 1:
    result = newGraph[int]()
    result.addNode(0)
    return
  if n == 2:
    result = newGraph[int]()
    result.addEdge(0, 1)
    return
  result = mycielskiGraph(n - 1)
  result = mycielskian(result)
