## Graph product operations
##
## Cartesian product, tensor product, strong product, lexicographic product.

import std/[tables, sets]
import ../graph

proc cartesianProduct*[N](g1, g2: Graph[N]): Graph[string] =
  ## Return the Cartesian product G1 □ G2.
  ## Nodes are "u,v" strings. Two nodes (u1,v1) and (u2,v2) are adjacent
  ## iff (u1=u2 and v1~v2) or (u1~u2 and v1=v2).
  result = newGraph[string]()
  for u in g1.nodes:
    for v in g2.nodes:
      result.addNode($u & "," & $v)
  for u1 in g1.nodes:
    for v1 in g2.nodes:
      let n1 = $u1 & "," & $v1
      # Edge from g2 (same u)
      for v2 in g2.neighbors(v1):
        let n2 = $u1 & "," & $v2
        result.addEdge(n1, n2)
      # Edge from g1 (same v)
      for u2 in g1.neighbors(u1):
        let n2 = $u2 & "," & $v1
        result.addEdge(n1, n2)

proc tensorProduct*[N](g1, g2: Graph[N]): Graph[string] =
  ## Return the tensor (categorical/direct) product G1 × G2.
  ## Nodes are "u,v" strings. Two nodes (u1,v1) and (u2,v2) are adjacent
  ## iff u1~u2 in G1 and v1~v2 in G2.
  result = newGraph[string]()
  for u in g1.nodes:
    for v in g2.nodes:
      result.addNode($u & "," & $v)
  for u1 in g1.nodes:
    for v1 in g2.nodes:
      for u2 in g1.neighbors(u1):
        for v2 in g2.neighbors(v1):
          let n1 = $u1 & "," & $v1
          let n2 = $u2 & "," & $v2
          result.addEdge(n1, n2)

proc strongProduct*[N](g1, g2: Graph[N]): Graph[string] =
  ## Return the strong product G1 ⊠ G2 = Cartesian ∪ Tensor.
  ## Nodes (u1,v1) and (u2,v2) are adjacent iff:
  ##   (u1=u2 and v1~v2) or (u1~u2 and v1=v2) or (u1~u2 and v1~v2).
  result = newGraph[string]()
  for u in g1.nodes:
    for v in g2.nodes:
      result.addNode($u & "," & $v)
  # Precompute adjacency sets for g1 and g2
  var adj1 = initTable[N, HashSet[N]]()
  for u in g1.nodes:
    var s = initHashSet[N]()
    for v in g1.neighbors(u):
      s.incl(v)
    adj1[u] = s
  var adj2 = initTable[N, HashSet[N]]()
  for u in g2.nodes:
    var s = initHashSet[N]()
    for v in g2.neighbors(u):
      s.incl(v)
    adj2[u] = s

  for u1 in g1.nodes:
    for v1 in g2.nodes:
      let n1 = $u1 & "," & $v1
      # Cartesian: same u, edge in g2
      for v2 in sets.items(adj2[v1]):
        result.addEdge(n1, $u1 & "," & $v2)
      # Cartesian: same v, edge in g1
      for u2 in sets.items(adj1[u1]):
        result.addEdge(n1, $u2 & "," & $v1)
      # Tensor: edge in both
      for u2 in sets.items(adj1[u1]):
        for v2 in sets.items(adj2[v1]):
          result.addEdge(n1, $u2 & "," & $v2)

proc lexicographicProduct*[N](g1, g2: Graph[N]): Graph[string] =
  ## Return the lexicographic product G1[G2].
  ## Nodes (u1,v1) and (u2,v2) are adjacent iff:
  ##   u1~u2 in G1, or (u1=u2 and v1~v2 in G2).
  result = newGraph[string]()
  for u in g1.nodes:
    for v in g2.nodes:
      result.addNode($u & "," & $v)

  var adj2 = initTable[N, HashSet[N]]()
  for u in g2.nodes:
    var s = initHashSet[N]()
    for v in g2.neighbors(u):
      s.incl(v)
    adj2[u] = s

  for u1 in g1.nodes:
    for v1 in g2.nodes:
      let n1 = $u1 & "," & $v1
      # If u1~u2, connect to all (u2,*)
      for u2 in g1.neighbors(u1):
        for v2 in g2.nodes:
          result.addEdge(n1, $u2 & "," & $v2)
      # If u1=u2, connect via g2 edges
      for v2 in sets.items(adj2[v1]):
        result.addEdge(n1, $u1 & "," & $v2)
