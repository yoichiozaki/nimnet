## Tree decomposition and treewidth
##
## Greedy heuristic for computing tree decomposition.

import std/[tables, sets]
import ../graph

proc treewidthUpperBound*[N](g: Graph[N]): int =
  ## Compute an upper bound on the treewidth using min-degree heuristic.
  ## Returns the computed upper bound.
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n == 0:
    return 0

  # Min-degree elimination ordering heuristic
  var adj = initTable[N, HashSet[N]]()
  for node in nodes:
    adj[node] = initHashSet[N]()
  for (u, v) in g.edges:
    adj[u].incl(v)
    adj[v].incl(u)

  var remaining = nodes.toHashSet()
  var treewidth = 0

  while remaining.len > 0:
    # Find node with minimum degree
    var minNode: N
    var minDeg = int.high
    for node in remaining:
      let deg = adj[node].len
      if deg < minDeg:
        minDeg = deg
        minNode = node

    if minDeg > treewidth:
      treewidth = minDeg

    # Eliminate: make all neighbors of minNode pairwise adjacent
    let neighbors = adj[minNode]
    for u in neighbors:
      for v in neighbors:
        if u != v and v notin adj[u]:
          adj[u].incl(v)
          adj[v].incl(u)

    # Remove minNode
    for neighbor in neighbors:
      adj[neighbor].excl(minNode)
    adj.del(minNode)
    remaining.excl(minNode)

  result = treewidth

proc treeDecomposition*[N](g: Graph[N]): (Graph[int], Table[int, HashSet[N]]) =
  ## Compute a tree decomposition using min-degree elimination.
  ## Returns (tree, bags) where:
  ##   tree is a Graph[int] representing the tree structure
  ##   bags maps each tree node to a set of original graph nodes
  let nodes = g.nodeSeq()
  let n = nodes.len
  var tree = newGraph[int]()
  var bags = initTable[int, HashSet[N]]()

  if n == 0:
    return (tree, bags)

  var adj = initTable[N, HashSet[N]]()
  for node in nodes:
    adj[node] = initHashSet[N]()
  for (u, v) in g.edges:
    adj[u].incl(v)
    adj[v].incl(u)

  var remaining = nodes.toHashSet()
  var bagId = 0
  var nodeToBag = initTable[N, int]()  # last bag containing each node

  while remaining.len > 0:
    # Find node with minimum degree
    var minNode: N
    var minDeg = int.high
    for node in remaining:
      let deg = adj[node].len
      if deg < minDeg:
        minDeg = deg
        minNode = node

    # Create bag: minNode + its remaining neighbors
    var bag = initHashSet[N]()
    bag.incl(minNode)
    for neighbor in adj[minNode]:
      if neighbor in remaining:
        bag.incl(neighbor)

    bags[bagId] = bag
    tree.addNode(bagId)

    # Connect to existing tree nodes that share vertices
    for prevId in 0 ..< bagId:
      if prevId in bags:
        var shared = 0
        for node in bag:
          if node in bags[prevId]:
            shared.inc
        if shared > 0 and not tree.hasEdge(bagId, prevId):
          # Connect to the most recent bag containing a shared node
          for node in bag:
            if node in nodeToBag:
              let prevBag = nodeToBag[node]
              if prevBag != bagId and not tree.hasEdge(bagId, prevBag):
                tree.addEdge(bagId, prevBag)
                break

    for node in bag:
      nodeToBag[node] = bagId

    # Eliminate: make neighbors pairwise adjacent
    let neighbors = adj[minNode]
    for u in neighbors:
      for v in neighbors:
        if u != v and v notin adj[u]:
          adj[u].incl(v)
          adj[v].incl(u)

    for neighbor in neighbors:
      adj[neighbor].excl(minNode)
    adj.del(minNode)
    remaining.excl(minNode)
    bagId.inc

  result = (tree, bags)
