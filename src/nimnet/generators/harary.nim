## Harary graph generators

import ../graph

proc hnmHararyGraph*(n, m: int): Graph[int] =
  ## Generate Harary graph H_{n,m}: n nodes, m edges, max connectivity.
  ## Constructs the maximally connected graph with n nodes and m edges.
  result = newGraph[int](capacity = n)
  for i in 0 ..< n:
    result.addNode(i)
  var edgesAdded = 0
  # Add edges in circular fashion for maximum connectivity
  var offset = 1
  while edgesAdded < m and offset < n:
    for i in 0 ..< n:
      if edgesAdded >= m: break
      let j = (i + offset) mod n
      if not result.hasEdge(i, j):
        result.addEdge(i, j)
        inc edgesAdded
    inc offset

proc hknHararyGraph*(k, n: int): Graph[int] =
  ## Generate Harary graph H_{k,n}: k-connected graph on n nodes with minimum edges.
  result = newGraph[int](capacity = n)
  for i in 0 ..< n:
    result.addNode(i)
  if k <= 0: return
  # For even k: connect each node to k/2 neighbors on each side in circular layout
  let halfK = k div 2
  for i in 0 ..< n:
    for j in 1 .. halfK:
      let nb = (i + j) mod n
      if not result.hasEdge(i, nb):
        result.addEdge(i, nb)
  # For odd k: additionally add diameter edges
  if k mod 2 == 1:
    if n mod 2 == 0:
      for i in 0 ..< n div 2:
        let j = i + n div 2
        if not result.hasEdge(i, j):
          result.addEdge(i, j)
    else:
      for i in 0 ..< n:
        let j = (i + n div 2) mod n
        if not result.hasEdge(i, j):
          result.addEdge(i, j)
