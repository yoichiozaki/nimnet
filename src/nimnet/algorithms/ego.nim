## Ego graph extraction
##
## An ego graph is the subgraph induced by all nodes within
## a given radius (number of hops) from a center node.

import std/[tables, sets, deques]
import ../types
import ../graph
import ../digraph

proc egoGraph*[N](g: Graph[N], n: N, radius: int = 1): Graph[N] =
  ## Return the ego graph of node ``n`` — the subgraph induced by
  ## all nodes within ``radius`` hops of ``n``, including ``n`` itself.
  if n notin g:
    raise newException(NodeNotFound, "Node not found in graph")
  var nodes = initHashSet[N]()
  nodes.incl(n)
  var frontier = initDeque[N]()
  frontier.addLast(n)
  var dist = initTable[N, int]()
  dist[n] = 0
  while frontier.len > 0:
    let u = frontier.popFirst()
    if dist[u] < radius:
      for v in g.neighbors(u):
        if v notin dist:
          dist[v] = dist[u] + 1
          nodes.incl(v)
          frontier.addLast(v)
  result = g.subgraph(nodes)

proc egoGraph*[N](g: DiGraph[N], n: N, radius: int = 1): DiGraph[N] =
  ## Return the ego graph of node ``n`` in a directed graph.
  ## Follows outgoing edges up to ``radius`` hops.
  if n notin g:
    raise newException(NodeNotFound, "Node not found in graph")
  var nodes = initHashSet[N]()
  nodes.incl(n)
  var frontier = initDeque[N]()
  frontier.addLast(n)
  var dist = initTable[N, int]()
  dist[n] = 0
  while frontier.len > 0:
    let u = frontier.popFirst()
    if dist[u] < radius:
      for v in g.neighbors(u):
        if v notin dist:
          dist[v] = dist[u] + 1
          nodes.incl(v)
          frontier.addLast(v)
  result = g.subgraph(nodes)
