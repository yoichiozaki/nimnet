## Network Resilience Analysis with NimNet
##
## Analyzes a network's vulnerability by finding bridges,
## articulation points, and connectivity measures.
##
## Run: nim c -r -p:src examples/network_resilience.nim

import std/[tables, sets]
import nimnet
import nimnet/algorithms/components as comp

# Build a small infrastructure network
var net = newGraph[string]("Infrastructure")
# Core backbone
net.addEdge("DataCenter-A", "DataCenter-B")
net.addEdge("DataCenter-B", "DataCenter-C")
net.addEdge("DataCenter-C", "DataCenter-A")
# Branch offices connected via single links (vulnerable!)
net.addEdge("DataCenter-A", "Office-Tokyo")
net.addEdge("DataCenter-B", "Office-Osaka")
net.addEdge("DataCenter-C", "Office-Nagoya")
# Extra redundancy for Tokyo
net.addEdge("DataCenter-B", "Office-Tokyo")
# Leaf nodes
net.addEdge("Office-Tokyo", "Branch-Shinjuku")
net.addEdge("Office-Osaka", "Branch-Namba")

echo "=== Infrastructure Network ==="
echo net
echo ""

# Find bridges (single points of failure for connectivity)
let bridgeEdges = bridges(net)
echo "--- Bridges (critical links) ---"
if bridgeEdges.len == 0:
  echo "  No bridges — good redundancy!"
else:
  for (u, v) in bridgeEdges:
    echo "  ", u, " -- ", v, " (removing this disconnects the network)"
echo ""

# Find articulation points (critical nodes)
let aps = articulationPoints(net)
echo "--- Articulation Points (critical nodes) ---"
if aps.len == 0:
  echo "  No articulation points — good redundancy!"
else:
  for n in aps:
    echo "  ", n, " (removing this disconnects the network)"
echo ""

# Connectivity measures
echo "--- Connectivity ---"
echo "Is connected: ", comp.isConnected(net)
echo "Is biconnected: ", isBiconnected(net)
echo ""

# Ego graph — what depends on DataCenter-A?
let ego = egoGraph(net, "DataCenter-A", radius = 2)
echo "--- Ego Graph of DataCenter-A (radius=2) ---"
echo ego
echo "Nodes in 2-hop neighborhood: "
for n in ego.nodes:
  echo "  ", n
echo ""

# Connected components
let components = connectedComponents(net)
echo "Connected components: ", components.len
echo ""

echo "Done!"
