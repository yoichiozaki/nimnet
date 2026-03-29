## Simple path algorithms
##
## Enumerate all simple paths, check simple paths, count paths.

import std/[tables, sets, deques]
import ../graph
import ../digraph
import ../types

iterator allSimplePaths*[N](g: Graph[N], source, target: N, cutoff: int = -1): seq[N] =
  ## Yield all simple paths from source to target in an undirected graph.
  ## If cutoff >= 0, only paths of length <= cutoff are returned.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not in graph")
  if not g.hasNode(target):
    raise newException(NodeNotFound, "Target node not in graph")
  var stack: seq[(N, seq[N], HashSet[N])]
  var initVisited = initHashSet[N]()
  initVisited.incl(source)
  stack.add((source, @[source], initVisited))
  while stack.len > 0:
    let (node, path, visited) = stack.pop()
    if cutoff >= 0 and path.len - 1 >= cutoff:
      continue
    for nbr in g.neighbors(node):
      if nbr == target:
        yield path & @[target]
      elif nbr notin visited:
        var newVisited = visited
        newVisited.incl(nbr)
        stack.add((nbr, path & @[nbr], newVisited))

iterator allSimplePaths*[N](g: DiGraph[N], source, target: N, cutoff: int = -1): seq[N] =
  ## Yield all simple paths from source to target in a directed graph.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not in graph")
  if not g.hasNode(target):
    raise newException(NodeNotFound, "Target node not in graph")
  var stack: seq[(N, seq[N], HashSet[N])]
  var initVisited = initHashSet[N]()
  initVisited.incl(source)
  stack.add((source, @[source], initVisited))
  while stack.len > 0:
    let (node, path, visited) = stack.pop()
    if cutoff >= 0 and path.len - 1 >= cutoff:
      continue
    for nbr in g.successors(node):
      if nbr == target:
        yield path & @[target]
      elif nbr notin visited:
        var newVisited = visited
        newVisited.incl(nbr)
        stack.add((nbr, path & @[nbr], newVisited))

func isSimplePath*[N](path: seq[N]): bool =
  ## Return true if path has no repeated nodes.
  if path.len == 0:
    return false
  var seen = initHashSet[N]()
  for n in path:
    if n in seen:
      return false
    seen.incl(n)
  result = true

proc allSimplePathsSeq*[N](g: Graph[N], source, target: N, cutoff: int = -1): seq[seq[N]] =
  ## Return all simple paths from source to target as a sequence.
  for path in allSimplePaths(g, source, target, cutoff):
    result.add(path)

proc allSimplePathsSeq*[N](g: DiGraph[N], source, target: N, cutoff: int = -1): seq[seq[N]] =
  ## Return all simple paths from source to target as a sequence.
  for path in allSimplePaths(g, source, target, cutoff):
    result.add(path)
