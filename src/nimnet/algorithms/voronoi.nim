## Voronoi cells on graphs.
##
## Partition the nodes of a graph into Voronoi cells based on shortest-path
## distance to a set of center (generator) nodes.
##
## Each node is assigned to the nearest center node. Ties are broken
## by choosing the center that appears first in the input sequence.

import std/[tables, sets]
import ../types
import ../graph
import ./shortest_paths

proc voronoiCells*[N](g: Graph[N],
    centerNodes: openArray[N]): Table[N, HashSet[N]] =
  ## Partition graph nodes into Voronoi cells.
  ##
  ## Each center node defines a cell; every node in the graph is assigned
  ## to the cell of its nearest center (by shortest-path distance).
  ##
  ## Parameters:
  ## - ``g``: undirected graph
  ## - ``centerNodes``: sequence of generator nodes
  ##
  ## Returns: table mapping each center to the set of nodes in its cell.
  ##
  ## Raises ``NodeNotFound`` if a center node is not in the graph.
  for c in centerNodes:
    if not g.hasNode(c):
      raise newException(NodeNotFound, "Center node not found in graph")
    result[c] = initHashSet[N]()

  var assignment = initTable[N, N]()
  var bestDist = initTable[N, int]()

  for c in centerNodes:
    let dist = singleSourceShortestPathLength(g, c)
    for n, d in dist:
      if n notin bestDist or d < bestDist[n]:
        bestDist[n] = d
        assignment[n] = c

  for n, c in assignment:
    result[c].incl(n)
