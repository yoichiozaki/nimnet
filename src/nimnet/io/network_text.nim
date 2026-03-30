## Network text display format
##
## Tree-like text representation of graphs.

import std/[sets, deques, strutils]
import ../types, ../graph, ../digraph

proc writeNetworkText*[N](g: Graph[N]): string =
  ## Generate a tree-like text representation of the graph using BFS.
  result = ""
  var visited: HashSet[N]
  let ns = g.nodeSeq
  for startNode in ns:
    if startNode in visited: continue
    # BFS from this node
    var queue: Deque[tuple[node: N, depth: int]]
    queue.addLast((startNode, 0))
    visited.incl(startNode)
    while queue.len > 0:
      let (node, depth) = queue.popFirst()
      let prefix = if depth == 0: "╙── " else: repeat("│   ", depth - 1) & "├── "
      result &= prefix & $node & "\n"
      for nb in g.neighbors(node):
        if nb notin visited:
          visited.incl(nb)
          queue.addLast((nb, depth + 1))

proc writeNetworkText*[N](g: DiGraph[N]): string =
  ## Generate a tree-like text representation of the digraph.
  result = ""
  var visited: HashSet[N]
  let ns = g.nodeSeq
  for startNode in ns:
    if startNode in visited: continue
    var queue: Deque[tuple[node: N, depth: int]]
    queue.addLast((startNode, 0))
    visited.incl(startNode)
    while queue.len > 0:
      let (node, depth) = queue.popFirst()
      let prefix = if depth == 0: "╙── " else: repeat("│   ", depth - 1) & "├── "
      result &= prefix & $node & "\n"
      for nb in g.neighbors(node):
        if nb notin visited:
          visited.incl(nb)
          queue.addLast((nb, depth + 1))

iterator generateNetworkText*[N](g: Graph[N]): string =
  ## Generate network text lines as an iterator.
  let text = writeNetworkText(g)
  for line in text.splitLines():
    if line.len > 0:
      yield line
