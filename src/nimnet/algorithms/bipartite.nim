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
  ## Find a maximum matching using augmenting paths.
  ## Returns a list of matched edge pairs.
  ## Requires the graph to be bipartite.
  let (setA, setB) = bipartiteSets(g)
  var matchA = initTable[N, N]()  # A -> B matching
  var matchB = initTable[N, N]()  # B -> A matching

  proc augment(u: N; visitedA, visitedB: var HashSet[N]): bool =
    ## DFS for an augmenting path from u (in setA).
    ## visitedA/visitedB track visited nodes in the current search to prevent cycles.
    ## Returns true if an augmenting path was found and matching updated.
    if u in visitedA:
      return false
    visitedA.incl(u)
    for v in g.neighbors(u):
      if v in setB and v notin visitedB:
        visitedB.incl(v)
        if v notin matchB or augment(matchB[v], visitedA, visitedB):
          matchA[u] = v
          matchB[v] = u
          return true
    return false

  # Repeatedly search for augmenting paths until none can be found.
  while true:
    var changed = false
    for u in setA:
      if u notin matchA:
        var visitedA = initHashSet[N]()
        var visitedB = initHashSet[N]()
        if augment(u, visitedA, visitedB):
          changed = true
    if not changed:
      break

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
        # From A to B, follow only unmatched edges (König's theorem)
        if v in setB and v notin visited and (u notin matchA or matchA[u] != v):
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
