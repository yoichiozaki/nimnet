## Graph I/O Roundtrip with NimNet
##
## Demonstrates creating a graph and exporting/importing in multiple formats.
##
## Run: nim c -r -p:src examples/graph_io_roundtrip.nim

import std/[tables, sets, os, json]
import nimnet

# Create a sample graph
var g = newGraph[int]("demo")
g.addEdgesFrom([(1, 2), (2, 3), (3, 4), (4, 5), (5, 1), (1, 3)])

echo "=== Original Graph ==="
echo g
echo "Edges: "
for (u, v) in g.edges:
  echo "  ", u, " -- ", v
echo ""

# Create temp directory for output
let tmpDir = getTempDir() / "nimnet_demo"
createDir(tmpDir)

# Export to edge list
let edgeFile = tmpDir / "graph.edgelist"
writeEdgeList(g, edgeFile)
echo "Written edge list to: ", edgeFile

# Export to DOT format (Graphviz)
let dotFile = tmpDir / "graph.dot"
writeDot(g, dotFile)
echo "Written DOT to: ", dotFile

# Export to JSON (node-link format)
let jsonFile = tmpDir / "graph.json"
writeJsonGraph(g, jsonFile)
echo "Written JSON to: ", jsonFile

# Export to GML
let gmlFile = tmpDir / "graph.gml"
writeGml(g, gmlFile)
echo "Written GML to: ", gmlFile
echo ""

# Re-import from edge list
let g2 = readEdgeList(edgeFile)
echo "=== Re-imported from edge list ==="
echo g2
echo "Match: ", g2.numberOfNodes() == g.numberOfNodes() and
               g2.numberOfEdges() == g.numberOfEdges()
echo ""

# Re-import from JSON
let g3 = readJsonGraph(jsonFile)
echo "=== Re-imported from JSON ==="
echo g3
echo "Match: ", g3.numberOfNodes() == g.numberOfNodes() and
               g3.numberOfEdges() == g.numberOfEdges()
echo ""

# Clean up
removeDir(tmpDir)
echo "Cleaned up temp files."
echo "Done!"
