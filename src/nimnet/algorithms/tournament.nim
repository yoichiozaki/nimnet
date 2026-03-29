## Tournament graph algorithms for nimnet

import std/[tables, sets, deques, algorithm, random]
import ../types
import ../digraph

# =============================================================================
# Is Tournament
# =============================================================================

proc isTournament*[N](g: DiGraph[N]): bool =
  ## Check if a directed graph is a tournament.
  ## A tournament has exactly one directed edge between every pair of nodes.
  let n = g.numberOfNodes()
  if g.numberOfEdges() != n * (n - 1) div 2:
    return false
  let nodes = g.nodeSeq()
  for i in 0 ..< nodes.len:
    for j in i + 1 ..< nodes.len:
      let hasIJ = g.hasEdge(nodes[i], nodes[j])
      let hasJI = g.hasEdge(nodes[j], nodes[i])
      if not (hasIJ xor hasJI):
        return false
  result = true

# =============================================================================
# Score Sequence
# =============================================================================

proc scoreSequence*[N](g: DiGraph[N]): seq[int] =
  ## Return the sorted score sequence (out-degrees) of a tournament.
  result = newSeq[int]()
  for n in g.nodes:
    result.add(g.outDegree(n))
  result.sort()

# =============================================================================
# Hamiltonian Path in Tournament
# =============================================================================

proc tournamentHamiltonianPath*[N](g: DiGraph[N]): seq[N] =
  ## Find a Hamiltonian path in a tournament using divide-and-conquer.
  ## Every tournament has a Hamiltonian path.
  let nodes = g.nodeSeq()
  if nodes.len == 0: return @[]
  if nodes.len == 1: return nodes
  # Simple insertion algorithm
  result = @[nodes[0]]
  for i in 1 ..< nodes.len:
    let v = nodes[i]
    # Find position to insert v
    var inserted = false
    for j in 0 ..< result.len:
      if g.hasEdge(v, result[j]):
        result.insert(v, j)
        inserted = true
        break
    if not inserted:
      result.add(v)

# =============================================================================
# Reachability
# =============================================================================

proc isTournamentReachable*[N](g: DiGraph[N], s, t: N): bool =
  ## Check if t is reachable from s in a tournament.
  var visited = initHashSet[N]()
  var queue = initDeque[N]()
  visited.incl(s)
  queue.addLast(s)
  while queue.len > 0:
    let u = queue.popFirst()
    if u == t: return true
    for v in g.neighbors(u):
      if v notin visited:
        visited.incl(v)
        queue.addLast(v)
  result = false

# =============================================================================
# Random Tournament Generator
# =============================================================================

proc randomTournament*(n: int, seed: int = 0): DiGraph[int] =
  ## Generate a random tournament on n nodes.
  result = newDiGraph[int]()
  var rng = if seed != 0: initRand(seed) else: initRand()
  for i in 0 ..< n:
    result.addNode(i)
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      if rng.rand(1.0) < 0.5:
        result.addEdge(i, j)
      else:
        result.addEdge(j, i)
