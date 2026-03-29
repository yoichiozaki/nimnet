## Lowest Common Ancestor (LCA) algorithms for DAGs and trees.
##
## - ``lowestCommonAncestor(dg, u, v)`` — LCA of two nodes in a DAG
## - ``allPairsLowestCommonAncestor(dg, pairs)`` — LCA for multiple pairs
## - ``treeAllPairsLowestCommonAncestor(dg, root)`` — optimized LCA for trees

import std/[tables, sets, deques, algorithm, math]
import ../types
import ../digraph

proc ancestors[N](dg: DiGraph[N], node: N): HashSet[N] =
  ## Return all ancestors of a node (nodes that can reach this node).
  var visited = initHashSet[N]()
  var queue = initDeque[N]()
  queue.addLast(node)
  visited.incl(node)
  while queue.len > 0:
    let curr = queue.popFirst()
    for p in dg.predecessors(curr):
      if p notin visited:
        visited.incl(p)
        queue.addLast(p)
  result = visited

proc depth[N](dg: DiGraph[N], root, target: N): int =
  ## BFS depth from root to target. Returns -1 if not reachable.
  if root == target:
    return 0
  var visited = initHashSet[N]()
  var queue = initDeque[(N, int)]()
  queue.addLast((root, 0))
  visited.incl(root)
  while queue.len > 0:
    let (curr, d) = queue.popFirst()
    for s in dg.successors(curr):
      if s == target:
        return d + 1
      if s notin visited:
        visited.incl(s)
        queue.addLast((s, d + 1))
  return -1

proc lowestCommonAncestor*[N](dg: DiGraph[N], u, v: N): N =
  ## Return the lowest common ancestor of nodes u and v in a DAG.
  ## The LCA is the deepest node that is an ancestor of both u and v.
  ## Raises ``NodeNotFound`` if either node is not in the graph.
  ## Raises ``NimNetError`` if no common ancestor exists.
  if not dg.hasNode(u):
    raise newException(NodeNotFound, "Node u not found")
  if not dg.hasNode(v):
    raise newException(NodeNotFound, "Node v not found")

  let ancU = ancestors(dg, u)
  let ancV = ancestors(dg, v)

  # Common ancestors
  let common = ancU * ancV  # intersection
  if common.len == 0:
    raise newException(NimNetError, "No common ancestor found")

  # Find the deepest common ancestor
  # We find the one with longest path from any root
  # Use BFS from each root to compute depths
  var roots: seq[N]
  for n in dg.nodes:
    if dg.inDegree(n) == 0:
      roots.add(n)

  var nodeDepth = initTable[N, int]()
  for root in roots:
    var visited = initHashSet[N]()
    var queue = initDeque[(N, int)]()
    queue.addLast((root, 0))
    visited.incl(root)
    while queue.len > 0:
      let (curr, d) = queue.popFirst()
      if curr notin nodeDepth or d > nodeDepth[curr]:
        nodeDepth[curr] = d
      for s in dg.successors(curr):
        if s notin visited:
          visited.incl(s)
          queue.addLast((s, d + 1))

  var bestNode: N
  var bestDepth = -1
  var found = false
  for n in common:
    let d = nodeDepth.getOrDefault(n, 0)
    if not found or d > bestDepth:
      bestDepth = d
      bestNode = n
      found = true

  result = bestNode

proc allPairsLowestCommonAncestor*[N](dg: DiGraph[N],
    pairs: seq[(N, N)]): Table[(N, N), N] =
  ## Return the LCA for each pair of nodes.
  for (u, v) in pairs:
    result[(u, v)] = lowestCommonAncestor(dg, u, v)

proc treeAllPairsLowestCommonAncestor*[N](dg: DiGraph[N],
    root: N): Table[(N, N), N] =
  ## Compute LCA for all pairs of nodes in a rooted tree (arborescence).
  ## Uses Euler tour + sparse table for O(1) queries after O(n log n) preprocessing.
  if not dg.hasNode(root):
    raise newException(NodeNotFound, "Root not found")

  # Build Euler tour via DFS
  var euler: seq[N]
  var depthArr: seq[int]
  var firstOccurrence = initTable[N, int]()
  var nodeDepthMap = initTable[N, int]()

  proc dfs(u: N, d: int) =
    firstOccurrence[u] = euler.len
    nodeDepthMap[u] = d
    euler.add(u)
    depthArr.add(d)
    for s in dg.successors(u):
      dfs(s, d + 1)
      euler.add(u)
      depthArr.add(d)

  dfs(root, 0)

  let m = euler.len
  if m == 0:
    return

  # Sparse table for range minimum query
  let logM = if m > 1: int(log2(m.float)) + 1 else: 1
  var sparse = newSeq[seq[int]](logM)
  sparse[0] = newSeq[int](m)
  for i in 0 ..< m:
    sparse[0][i] = i

  for k in 1 ..< logM:
    let half = 1 shl (k - 1)
    sparse[k] = newSeq[int](m)
    for i in 0 ..< m:
      let j = i + half
      if j < m and depthArr[sparse[k-1][j]] < depthArr[sparse[k-1][i]]:
        sparse[k][i] = sparse[k-1][j]
      else:
        sparse[k][i] = sparse[k-1][i]

  proc queryRMQ(l, r: int): int =
    let length = r - l + 1
    let k = int(log2(length.float))
    let half = 1 shl k
    if depthArr[sparse[k][l]] <= depthArr[sparse[k][r - half + 1]]:
      return sparse[k][l]
    else:
      return sparse[k][r - half + 1]

  # Compute LCA for all pairs
  var nodeList: seq[N]
  for n in dg.nodes:
    nodeList.add(n)

  for i in 0 ..< nodeList.len:
    for j in (i + 1) ..< nodeList.len:
      let u = nodeList[i]
      let v = nodeList[j]
      if u in firstOccurrence and v in firstOccurrence:
        var l = firstOccurrence[u]
        var r = firstOccurrence[v]
        if l > r:
          swap(l, r)
        let idx = queryRMQ(l, r)
        result[(u, v)] = euler[idx]
        result[(v, u)] = euler[idx]
