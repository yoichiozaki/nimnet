## Cycle basis and simple cycle algorithms.

import std/[tables, sets, deques, algorithm]
import ../graph
import ../digraph

proc cycleBasis*[N](g: Graph[N]): seq[seq[N]] =
  ## Return a list of cycles forming a basis for the cycle space.
  ## Each non-tree edge in a BFS spanning tree defines one fundamental cycle.
  var gnodes = initHashSet[N]()
  for n in g.nodes:
    gnodes.incl(n)
  var cycles: seq[seq[N]]
  while gnodes.len > 0:
    var root: N
    for n in sets.items(gnodes):
      root = n
      break
    # BFS spanning tree: pred[v] = parent of v in tree
    var pred = initTable[N, N]()
    var depth = initTable[N, int]()
    var queue = initDeque[N]()
    pred[root] = root
    depth[root] = 0
    queue.addLast(root)
    # Track which edges we've already used as non-tree edges
    var usedNonTree = initHashSet[string]()
    while queue.len > 0:
      let z = queue.popFirst()
      for nbr in g.neighbors(z):
        if nbr notin pred:
          # Tree edge
          pred[nbr] = z
          depth[nbr] = depth[z] + 1
          queue.addLast(nbr)
    # Now find non-tree edges and extract cycles
    var seenEdge = initHashSet[string]()
    for u in sets.items(pred.keys.toSeq.toHashSet):
      for v in g.neighbors(u):
        if v notin pred:
          continue
        let edgeKey = if $u < $v: $u & "|" & $v else: $v & "|" & $u
        if edgeKey in seenEdge:
          continue
        seenEdge.incl(edgeKey)
        # Check if this is a non-tree edge (neither u->v or v->u is a tree edge)
        if pred.getOrDefault(u) == v or pred.getOrDefault(v) == u:
          continue  # tree edge
        if u == v:
          cycles.add(@[u])  # self-loop
          continue
        # Non-tree edge (u, v) — trace paths from u and v back to LCA
        var pathU: seq[N] = @[u]
        var pathV: seq[N] = @[v]
        var cu = u
        var cv = v
        while depth.getOrDefault(cu) > depth.getOrDefault(cv):
          cu = pred[cu]
          pathU.add(cu)
        while depth.getOrDefault(cv) > depth.getOrDefault(cu):
          cv = pred[cv]
          pathV.add(cv)
        while cu != cv:
          cu = pred[cu]
          cv = pred[cv]
          pathU.add(cu)
          pathV.add(cv)
        # Build cycle: pathU + reverse(pathV without LCA)
        var cycle: seq[N]
        for item in pathU:
          cycle.add(item)
        for i in countdown(pathV.len - 2, 0):
          cycle.add(pathV[i])
        cycles.add(cycle)
    # Remove processed nodes
    for k in pred.keys:
      gnodes.excl(k)
  result = cycles

proc simpleCyclesDirected*[N](g: DiGraph[N]): seq[seq[N]] =
  ## Return all simple cycles in a directed graph using Johnson's algorithm.
  ## Warning: can be exponential in the number of cycles.
  var res: seq[seq[N]]

  # Get all nodes as a sorted sequence for consistent ordering
  var allNodes: seq[N]
  for n in g.nodes:
    allNodes.add(n)

  # Build adjacency list
  var adj = initTable[N, seq[N]]()
  for n in allNodes:
    var nbrs: seq[N]
    for s in g.successors(n):
      nbrs.add(s)
    adj[n] = nbrs

  proc findCyclesFrom(startNode: N, adj: Table[N, seq[N]], nodeSet: HashSet[N]) =
    var blocked = initHashSet[N]()
    var blockMap = initTable[N, HashSet[N]]()
    var stack: seq[N]
    var foundCycle = false

    for n in sets.items(nodeSet):
      blockMap[n] = initHashSet[N]()

    proc unblock(u: N) =
      blocked.excl(u)
      if u in blockMap:
        for w in sets.items(blockMap[u]):
          if w in blocked:
            unblock(w)
        blockMap[u] = initHashSet[N]()

    proc circuit(v: N): bool =
      result = false
      stack.add(v)
      blocked.incl(v)
      if v in adj:
        for w in adj[v]:
          if w notin nodeSet:
            continue
          if w == startNode:
            res.add(stack & @[startNode])
            result = true
          elif w notin blocked:
            if circuit(w):
              result = true
      if result:
        unblock(v)
      else:
        if v in adj:
          for w in adj[v]:
            if w in nodeSet:
              if v notin blockMap[w]:
                blockMap[w].incl(v)
      discard stack.pop()

    discard circuit(startNode)

  # For each starting node, find cycles in the subgraph
  var remaining = initHashSet[N]()
  for n in allNodes:
    remaining.incl(n)

  for i in 0 ..< allNodes.len:
    let start = allNodes[i]
    if start notin remaining:
      continue
    findCyclesFrom(start, adj, remaining)
    remaining.excl(start)

  result = res
