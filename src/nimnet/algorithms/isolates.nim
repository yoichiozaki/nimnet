## Isolate nodes
##
## Functions for identifying isolated nodes — nodes with no edges.

import ../graph
import ../digraph

iterator isolates*[N](g: Graph[N]): N =
  ## Yield all isolated nodes (degree 0) in the graph.
  for n in g.nodes:
    if g.degree(n) == 0:
      yield n

iterator isolates*[N](g: DiGraph[N]): N =
  ## Yield all isolated nodes (in-degree + out-degree = 0) in the digraph.
  for n in g.nodes:
    if g.degree(n) == 0:
      yield n

func isIsolate*[N](g: Graph[N], n: N): bool =
  ## Return true if node n is isolated (degree 0).
  g.hasNode(n) and g.degree(n) == 0

func isIsolate*[N](g: DiGraph[N], n: N): bool =
  ## Return true if node n is isolated (degree 0) in the digraph.
  g.hasNode(n) and g.degree(n) == 0

func numberOfIsolates*[N](g: Graph[N]): int =
  ## Return the number of isolated nodes.
  for n in g.nodes:
    if g.degree(n) == 0:
      result.inc

func numberOfIsolates*[N](g: DiGraph[N]): int =
  ## Return the number of isolated nodes in the digraph.
  for n in g.nodes:
    if g.degree(n) == 0:
      result.inc
