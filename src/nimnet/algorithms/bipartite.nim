## Bipartite graph algorithms
##
## Bipartiteness check, 2-coloring, maximum matching (Hopcroft-Karp).

import std/[sets, tables, deques]
import ../types
import ../graph

proc isBipartite*[N](g: Graph[N]): bool =
  ## Check if the graph is bipartite using 2-coloring BFS.
  var color = initTable[N, int]()
  for startNode in g.nodes:
    if startNode in color:
      continue
    color[startNode] = 0
    var queue = initDeque[N]()
    queue.addLast(startNode)
    while queue.len > 0:
      let u = queue.popFirst()
      for v in g.neighbors(u):
        if v notin color:
          color[v] = 1 - color[u]
          queue.addLast(v)
        elif color[v] == color[u]:
          return false
  return true

proc bipartiteSets*[N](g: Graph[N]): (HashSet[N], HashSet[N]) =
  ## Return the two partitions of a bipartite graph.
  ## Raises NimNetError if the graph is not bipartite.
  var color = initTable[N, int]()
  var setA = initHashSet[N]()
  var setB = initHashSet[N]()
  for startNode in g.nodes:
    if startNode in color:
      continue
    color[startNode] = 0
    setA.incl(startNode)
    var queue = initDeque[N]()
    queue.addLast(startNode)
    while queue.len > 0:
      let u = queue.popFirst()
      for v in g.neighbors(u):
        if v notin color:
          color[v] = 1 - color[u]
          if color[v] == 0:
            setA.incl(v)
          else:
            setB.incl(v)
          queue.addLast(v)
        elif color[v] == color[u]:
          raise newException(NimNetError, "Graph is not bipartite")
  result = (setA, setB)

proc maximumMatching*[N](g: Graph[N]): seq[(N, N)] =
  ## Find a maximum matching using augmenting paths (Hopcroft-Karp style).
  ## Returns a list of matched edge pairs.
  ## Requires the graph to be bipartite.
  let (setA, setB) = bipartiteSets(g)
  var matchA = initTable[N, N]()  # A -> B matching
  var matchB = initTable[N, N]()  # B -> A matching

  proc augment(u: N): bool =
    for v in g.neighbors(u):
      if v in setB:
        if v notin matchB:
          matchA[u] = v
          matchB[v] = u
          return true
  
    for v in g.neighbors(u):
      if v in setB:
        let w = matchB[v]
        if augment(w):
          matchA[u] = v
          matchB[v] = u
          return true
    return false

  # Augmenting path search with BFS layers (Hopcroft-Karp)
  var changed = true
  while changed:
    changed = false
    # BFS to find shortest augmenting paths
    var dist = initTable[N, int]()
    var queue = initDeque[N]()
    for u in setA:
      if u notin matchA:
        dist[u] = 0
        queue.addLast(u)

    var found = false
    while queue.len > 0:
      let u = queue.popFirst()
      for v in g.neighbors(u):
        if v in setB:
          let w = if v in matchB: matchB[v] else: v  # sentinel
          if v notin matchB:
            found = true
          elif matchB[v] notin dist:
            dist[matchB[v]] = dist[u] + 1
            queue.addLast(matchB[v])

    if not found:
      break

    # DFS to find augmenting paths
    for u in setA:
      if u notin matchA:
        if augment(u):
          changed = true

  result = @[]
  for u, v in matchA:
    result.add((u, v))

proc minimumVertexCover*[N](g: Graph[N]): HashSet[N] =
  ## Find minimum vertex cover for bipartite graph using König's theorem.
  ## |minimum vertex cover| = |maximum matching|
  let matching = maximumMatching(g)
  let (setA, setB) = bipartiteSets(g)

  # Build matching sets
  var matchedA = initHashSet[N]()
  var matchedB = initHashSet[N]()
  var matchA = initTable[N, N]()
  var matchB = initTable[N, N]()
  for (u, v) in matching:
    matchedA.incl(u)
    matchedB.incl(v)
    matchA[u] = v
    matchB[v] = u

  # Find alternating tree from unmatched vertices in A
  var visited = initHashSet[N]()
  var queue = initDeque[N]()
  for u in setA:
    if u notin matchedA:
      queue.addLast(u)
      visited.incl(u)

  while queue.len > 0:
    let u = queue.popFirst()
    if u in setA:
      for v in g.neighbors(u):
        if v in setB and v notin visited:
          visited.incl(v)
          queue.addLast(v)
    else:  # u in setB
      if u in matchB:
        let w = matchB[u]
        if w notin visited:
          visited.incl(w)
          queue.addLast(w)

  # König's theorem: min vertex cover = (A \ Z) ∪ (B ∩ Z)
  result = initHashSet[N]()
  for u in setA:
    if u notin visited:
      result.incl(u)
  for v in setB:
    if v in visited:
      result.incl(v)
