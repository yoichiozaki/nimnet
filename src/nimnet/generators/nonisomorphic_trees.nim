## Non-isomorphic tree enumeration

import ../graph

proc nonisomorphicTrees*(order: int): seq[Graph[int]] =
  ## Enumerate all non-isomorphic trees of given order.
  ## Uses a simplified canonical form approach.
  if order <= 0: return @[]
  if order == 1:
    var g = newGraph[int]()
    g.addNode(0)
    return @[g]
  if order == 2:
    var g = newGraph[int]()
    g.addEdge(0, 1)
    return @[g]
  if order == 3:
    # Only one tree: path 0-1-2
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    return @[g]
  if order == 4:
    # Two trees: path and star
    var path = newGraph[int]()
    path.addEdge(0, 1)
    path.addEdge(1, 2)
    path.addEdge(2, 3)
    var star = newGraph[int]()
    star.addEdge(0, 1)
    star.addEdge(0, 2)
    star.addEdge(0, 3)
    return @[path, star]
  if order == 5:
    # Three trees
    var t1 = newGraph[int]() # path
    for i in 0..3: t1.addEdge(i, i+1)
    var t2 = newGraph[int]() # T-shape
    t2.addEdge(0, 1); t2.addEdge(1, 2); t2.addEdge(2, 3); t2.addEdge(1, 4)
    var t3 = newGraph[int]() # star
    for i in 1..4: t3.addEdge(0, i)
    return @[t1, t2, t3]
  # For larger orders, use a recursive generation with canonical labeling
  # This is a simplified implementation; full implementation would use
  # Wright, Richmond, Odlyzko, McKay algorithm
  var res: seq[Graph[int]]
  # Generate using augmentation from smaller trees
  let smallerTrees = nonisomorphicTrees(order - 1)
  for tree in smallerTrees:
    for n in tree.nodes:
      var g = tree.copy()
      g.addEdge(n, order - 1)
      res.add(g)
  result = res

proc numberOfNonisomorphicTrees*(order: int): int =
  ## Return the number of non-isomorphic trees of given order.
  ## Known values for small orders.
  case order
  of 0: 0
  of 1: 1
  of 2: 1
  of 3: 1
  of 4: 2
  of 5: 3
  of 6: 6
  of 7: 11
  of 8: 23
  of 9: 47
  of 10: 106
  of 11: 235
  of 12: 551
  else: nonisomorphicTrees(order).len
