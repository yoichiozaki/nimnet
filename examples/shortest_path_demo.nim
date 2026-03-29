## Shortest Path Demo with NimNet
##
## Demonstrates weighted graph construction and pathfinding algorithms.
##
## Run: nim c -r -p:src examples/shortest_path_demo.nim

import std/[tables, sets]
import nimnet
import nimnet/algorithms/components as comp

# Build a weighted road network
var roads = newGraph[string]("City Roads")
roads.addWeightedEdge("Tokyo", "Yokohama", 30.0)
roads.addWeightedEdge("Tokyo", "Chiba", 40.0)
roads.addWeightedEdge("Tokyo", "Saitama", 25.0)
roads.addWeightedEdge("Yokohama", "Chiba", 50.0)
roads.addWeightedEdge("Saitama", "Chiba", 45.0)
roads.addWeightedEdge("Saitama", "Gunma", 80.0)
roads.addWeightedEdge("Yokohama", "Shizuoka", 120.0)
roads.addWeightedEdge("Chiba", "Ibaraki", 70.0)
roads.addWeightedEdge("Gunma", "Ibaraki", 90.0)
roads.addWeightedEdge("Shizuoka", "Nagoya", 180.0)
roads.addWeightedEdge("Ibaraki", "Sendai", 200.0)

echo "=== Road Network ==="
echo roads
echo ""

# BFS shortest path (unweighted — fewest hops)
let bfsPath = shortestPath(roads, "Tokyo", "Sendai")
echo "BFS path (fewest hops): ", bfsPath
echo "Hops: ", bfsPath.len - 1
echo ""

# Dijkstra shortest path (weighted — minimum distance)
let dijPath = dijkstraPath(roads, "Tokyo", "Sendai")
echo "Dijkstra path (minimum distance): ", dijPath
var totalDist = 0.0
for i in 0 ..< dijPath.len - 1:
  totalDist += roads.weight(dijPath[i], dijPath[i + 1])
echo "Total distance: ", totalDist, " km"
echo ""

# Check connectivity
echo "Is connected: ", comp.isConnected(roads)
echo "Number of components: ", numberOfConnectedComponents(roads)
echo ""

# Graph properties
echo "Is tree: ", isTree(roads)
echo "Number of nodes: ", roads.numberOfNodes()
echo "Number of edges: ", roads.numberOfEdges()
echo ""

echo "Done!"
