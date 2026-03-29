## Social Network Analysis with NimNet
##
## This example demonstrates loading the Zachary Karate Club graph,
## computing centrality measures, and detecting communities.
##
## Run: nim c -r -p:src examples/social_network_analysis.nim

import std/[tables, sets, algorithm, sequtils]
import nimnet

# Load the famous Zachary Karate Club dataset
let g = karateClubGraph()
echo "=== Zachary Karate Club ==="
echo g
echo "Nodes: ", g.numberOfNodes()
echo "Edges: ", g.numberOfEdges()
echo "Density: ", g.numberOfEdges().float / (g.numberOfNodes().float * (g.numberOfNodes().float - 1.0) / 2.0)
echo ""

# Compute centrality
let dc = degreeCentrality(g)
let bc = betweennessCentrality(g)
let cc = closenessCentrality(g)

# Find top 5 most central nodes by degree
echo "--- Degree Centrality (top 5) ---"
var dcPairs: seq[(int, float)]
for n, c in dc:
  dcPairs.add((n, c))
dcPairs.sort(proc(a, b: (int, float)): int = cmp(b[1], a[1]))
for i in 0 ..< min(5, dcPairs.len):
  echo "  Node ", dcPairs[i][0], ": ", dcPairs[i][1]
echo ""

# Find top 5 by betweenness
echo "--- Betweenness Centrality (top 5) ---"
var bcPairs: seq[(int, float)]
for n, c in bc:
  bcPairs.add((n, c))
bcPairs.sort(proc(a, b: (int, float)): int = cmp(b[1], a[1]))
for i in 0 ..< min(5, bcPairs.len):
  echo "  Node ", bcPairs[i][0], ": ", bcPairs[i][1]
echo ""

# Community detection
let communities = greedyModularityCommunities(g)
echo "--- Communities (greedy modularity) ---"
echo "Number of communities: ", communities.len
for i, comm in communities:
  echo "  Community ", i + 1, " (", comm.len, " nodes): ", comm
echo ""

# Network resilience
let bridges = bridges(g)
let aps = articulationPoints(g)
echo "--- Resilience ---"
echo "Bridges: ", bridges.len
echo "Articulation points: ", aps.len
echo ""

echo "Done!"
