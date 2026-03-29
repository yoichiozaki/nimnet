## D-Separation and Dominance algorithms for DAGs

import std/[tables, sets, deques]
import ../types
import ../digraph

# =============================================================================
# D-Separation (#115)
# =============================================================================

proc isDSeparator*[N](g: DiGraph[N], x, y, z: HashSet[N]): bool =
  ## Check if z d-separates x from y in a DAG.
  ## Uses the reachability-based algorithm on the moralized ancestral graph.
  # Build ancestral graph: ancestors of x ∪ y ∪ z
  var ancestors = initHashSet[N]()
  var toVisit = initDeque[N]()
  for n in x: toVisit.addLast(n); ancestors.incl(n)
  for n in y: toVisit.addLast(n); ancestors.incl(n)
  for n in z: toVisit.addLast(n); ancestors.incl(n)
  while toVisit.len > 0:
    let node = toVisit.popFirst()
    for p in g.predecessors(node):
      if p notin ancestors:
        ancestors.incl(p)
        toVisit.addLast(p)
  # Build moral graph of ancestral subgraph
  var moral = initTable[N, HashSet[N]]()
  for n in ancestors:
    moral[n] = initHashSet[N]()
  for n in ancestors:
    var parents = newSeq[N]()
    for p in g.predecessors(n):
      if p in ancestors:
        parents.add(p)
    # Add edges between parents (moralization)
    for i in 0 ..< parents.len:
      for j in i + 1 ..< parents.len:
        moral[parents[i]].incl(parents[j])
        moral[parents[j]].incl(parents[i])
    # Add original edges (undirected)
    for s in g.neighbors(n):
      if s in ancestors:
        moral[n].incl(s)
        moral[s].incl(n)
  # Remove z from the moral graph and check if x and y are connected
  for zn in z:
    moral.del(zn)
  for n in moral.keys:
    moral[n] = moral[n] - z
  # BFS from any x node to see if any y node is reachable
  var visited = initHashSet[N]()
  var queue = initDeque[N]()
  for xn in x:
    if xn in moral and xn notin z:
      visited.incl(xn)
      queue.addLast(xn)
  while queue.len > 0:
    let u = queue.popFirst()
    if u in y: return false
    for v in moral.getOrDefault(u, initHashSet[N]()):
      if v notin visited:
        visited.incl(v)
        queue.addLast(v)
  result = true

proc findMinimalDSeparator*[N](g: DiGraph[N], x, y: HashSet[N]): HashSet[N] =
  ## Find a minimal d-separator between x and y.
  ## Returns a minimal set z that d-separates x from y.
  ## Uses a greedy approach: start with all non-x, non-y nodes,
  ## then remove nodes while maintaining separation.
  var allNodes = initHashSet[N]()
  for n in g.nodes:
    allNodes.incl(n)
  var candidates = allNodes - x - y
  # Start with all candidates
  var z = candidates
  # Greedily remove nodes
  for n in candidates:
    var testZ = z
    testZ.excl(n)
    if isDSeparator(g, x, y, testZ):
      z = testZ
  result = z

proc isMinimalDSeparator*[N](g: DiGraph[N], x, y, z: HashSet[N]): bool =
  ## Check if z is a minimal d-separator between x and y.
  if not isDSeparator(g, x, y, z):
    return false
  # Check that removing any element breaks separation
  for n in z:
    var smallerZ = z
    smallerZ.excl(n)
    if isDSeparator(g, x, y, smallerZ):
      return false
  result = true

# =============================================================================
# Dominance (#115)
# =============================================================================

proc immediateDominators*[N](g: DiGraph[N], start: N): Table[N, N] =
  ## Compute immediate dominators for each node reachable from start.
  ## Uses the iterative algorithm by Cooper, Harvey, and Kennedy.
  result = initTable[N, N]()
  # BFS to get reverse post-order
  var visited = initHashSet[N]()
  var rpo = newSeq[N]()
  var stack = @[start]
  visited.incl(start)
  # DFS for post-order
  var dfsStack: seq[(N, bool)] = @[(start, false)]
  visited.clear()
  while dfsStack.len > 0:
    let (node, processed) = dfsStack.pop()
    if processed:
      rpo.add(node)
      continue
    if node in visited: continue
    visited.incl(node)
    dfsStack.add((node, true))
    for s in g.neighbors(node):
      if s notin visited:
        dfsStack.add((s, false))
  # Reverse post-order
  var rpoOrder = newSeq[N](rpo.len)
  for i in 0 ..< rpo.len:
    rpoOrder[i] = rpo[rpo.len - 1 - i]
  var rpoIdx = initTable[N, int]()
  for i, n in rpoOrder:
    rpoIdx[n] = i
  # Initialize dominators
  var doms = initTable[N, int]()
  let startIdx = rpoIdx[start]
  doms[startIdx] = startIdx
  proc intersect(b1, b2: int): int =
    var f1 = b1
    var f2 = b2
    while f1 != f2:
      while f1 > f2:
        f1 = doms[f1]
      while f2 > f1:
        f2 = doms[f2]
    f1
  var changed = true
  while changed:
    changed = false
    for i in 0 ..< rpoOrder.len:
      let b = rpoOrder[i]
      if b == start: continue
      let bIdx = rpoIdx[b]
      var newIdom = -1
      for p in g.predecessors(b):
        if p notin rpoIdx: continue
        let pIdx = rpoIdx[p]
        if pIdx in doms:
          if newIdom == -1:
            newIdom = pIdx
          else:
            newIdom = intersect(newIdom, pIdx)
      if newIdom >= 0 and (bIdx notin doms or doms[bIdx] != newIdom):
        doms[bIdx] = newIdom
        changed = true
  # Convert to node mapping
  for idx, domIdx in doms:
    if idx != startIdx:
      result[rpoOrder[idx]] = rpoOrder[domIdx]

proc dominanceFrontiers*[N](g: DiGraph[N], start: N): Table[N, HashSet[N]] =
  ## Compute dominance frontiers for all nodes reachable from start.
  let idom = immediateDominators(g, start)
  result = initTable[N, HashSet[N]]()
  for n in g.nodes:
    result[n] = initHashSet[N]()
  for n in g.nodes:
    var preds = newSeq[N]()
    for p in g.predecessors(n):
      preds.add(p)
    if preds.len >= 2:
      for p in preds:
        var runner = p
        while runner in idom and runner != idom.getOrDefault(n, runner):
          result[runner].incl(n)
          if runner notin idom: break
          runner = idom[runner]
