## Run with: nim c -r --threads:on -p:src examples/library_improvements.nim

import std/[json, math, sets, tables]
import nimnet

var bipartite = newGraph[string]()
bipartite.addEdgesFrom([("A", "X"), ("A", "Y"), ("B", "X")])
let left = toHashSet(["A", "B"])
doAssert maximumMatching(bipartite, left).len == 2
doAssert minimumVertexCover(bipartite, left).len == 2

var triangle = newGraph[int]()
triangle.addEdgesFrom([(0, 1), (1, 2), (2, 0)])
doAssert maximumCardinalityMatching(triangle).len == 1
doAssert minEdgeCover(triangle).len == 2
doAssert approxMaxWeightMatching(triangle).len == 1

let sparse = fastGnpRandomGraph(1000, 0.004, seed = 42)
doAssert sparse.numberOfNodes() == 1000

var weighted = newGraph[string]()
var edge = newEdgeAttr([("kind", "road")])
edge.weight = 2.5
let metadata = newNodeAttr([("label", "Alpha")])
metadata["active"] = %true
weighted.addNode("A", metadata)
weighted.addEdge("A", "B", edge)
weighted.addWeightedEdge("B", "C", 1.0)
let distances = johnsons(weighted)
doAssert distances["A"]["C"] == 3.5
doAssert weighted.getNodeAttr("A")["active"].getBool()

var disconnected = newGraph[int]()
disconnected.addNodesFrom([0, 1])
doAssert not johnsons(disconnected)[0].hasKey(1)
doAssert johnsons(disconnected, includeUnreachable = true)[0][1] == Inf
doAssert pageRank(disconnected)[0] == 0.5

let clique = completeGraph[int](4)
doAssert louvainCommunities(clique, resolution = 0.5, seed = 42).len == 1
doAssert louvainCommunities(clique, resolution = 3.0, seed = 42).len == 4

weighted.addWeightedEdge("A", "A", 4.0)
let compact = toCompact(weighted)
let restored = toGraph(compact)
doAssert compact.numberOfEdges() == 3
doAssert restored.degree("A") == 3
doAssert restored.weight("A", "B") == 2.5

let directed = loadFromEdgeListStringDirected[int]("1 2 3.5\n2 3 1.0")
doAssert directed.hasEdge(1, 2) and not directed.hasEdge(2, 1)
doAssert directed.weight(1, 2) == 3.5
doAssert toGraph(toCompact(directed)).weight(1, 2) == 3.5

echo "Exact matching, sparse generation, shortest paths and directed I/O are ready."
