import std/[unittest, sets, tables, algorithm, json]
import nimnet/graph
import nimnet/types

suite "Graph - Node operations":
  test "addNode and hasNode":
    var g = newGraph[int]()
    g.addNode(1)
    check g.hasNode(1)
    check not g.hasNode(2)

  test "addNode is idempotent":
    var g = newGraph[int]()
    g.addNode(1)
    g.addNode(1)
    check g.numberOfNodes() == 1

  test "addNode with attributes":
    var g = newGraph[string]()
    var attr = newNodeAttr()
    attr["color"] = newJString("red")
    g.addNode("A", attr)
    check g.hasNode("A")
    check g.getNodeAttr("A")["color"].getStr() == "red"

  test "addNodesFrom batch":
    var g = newGraph[int]()
    g.addNodesFrom([1, 2, 3, 4, 5])
    check g.numberOfNodes() == 5
    check g.hasNode(3)

  test "removeNode":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    g.removeNode(1)
    check not g.hasNode(1)
    check not g.hasEdge(1, 2)
    check not g.hasEdge(2, 1)
    check g.numberOfNodes() == 2
    check g.numberOfEdges() == 0

  test "removeNode raises on missing":
    var g = newGraph[int]()
    expect NodeNotFound:
      g.removeNode(99)

  test "numberOfNodes and order":
    var g = newGraph[int]()
    g.addNode(1)
    g.addNode(2)
    g.addNode(3)
    check g.numberOfNodes() == 3
    check g.order() == 3

suite "Graph - Edge operations":
  test "addEdge and hasEdge":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    check g.hasEdge(1, 2)
    check g.hasEdge(2, 1)  # undirected

  test "addEdge auto-adds nodes":
    var g = newGraph[int]()
    g.addEdge(10, 20)
    check g.hasNode(10)
    check g.hasNode(20)

  test "addEdge is idempotent for edge count":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 2)
    check g.numberOfEdges() == 1

  test "addEdgesFrom batch":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 4)])
    check g.numberOfEdges() == 3
    check g.hasEdge(2, 3)

  test "addWeightedEdge":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 3.5)
    check g.weight(1, 2) == 3.5

  test "addWeightedEdgesFrom batch":
    var g = newGraph[int]()
    g.addWeightedEdgesFrom([(1, 2, 1.0), (2, 3, 2.5)])
    check g.numberOfEdges() == 2
    check g.weight(1, 2) == 1.0
    check g.weight(2, 3) == 2.5

  test "removeEdge":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.removeEdge(1, 2)
    check not g.hasEdge(1, 2)
    check not g.hasEdge(2, 1)
    check g.hasNode(1)  # nodes remain
    check g.numberOfEdges() == 0

  test "removeEdge raises on missing":
    var g = newGraph[int]()
    expect EdgeNotFound:
      g.removeEdge(1, 2)

  test "numberOfEdges cached":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(1, 3)
    check g.numberOfEdges() == 3
    check g.size() == 3
    g.removeEdge(1, 2)
    check g.numberOfEdges() == 2

  test "self-loop":
    var g = newGraph[int]()
    g.addEdge(1, 1)
    check g.hasEdge(1, 1)
    check g.numberOfEdges() == 1

  test "self-loop removal updates edge count":
    var g = newGraph[int]()
    g.addEdge(1, 1)
    g.addEdge(1, 2)
    check g.numberOfEdges() == 2
    g.removeEdge(1, 1)
    check g.numberOfEdges() == 1

suite "Graph - Contains operator (in)":
  test "n in g for nodes":
    var g = newGraph[int]()
    g.addNode(42)
    check 42 in g
    check 99 notin g

  test "string nodes with in":
    var g = newGraph[string]()
    g.addNode("hello")
    check "hello" in g
    check "world" notin g

suite "Graph - Subscript operators":
  test "g[n] returns neighbor dict":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    let neighbors = g[1]
    check neighbors.len == 2
    check 2 in neighbors
    check 3 in neighbors

  test "g[n] raises on missing node":
    var g = newGraph[int]()
    expect NodeNotFound:
      discard g[99]

  test "g[u, v] returns edge attr":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 5.0)
    let attr = g[1, 2]
    check attr["weight"] == "5.0"

  test "g[u, v] raises on missing edge":
    var g = newGraph[int]()
    g.addNode(1)
    g.addNode(2)
    expect EdgeNotFound:
      discard g[1, 2]

suite "Graph - Len operator":
  test "g.len returns node count":
    var g = newGraph[int]()
    check g.len == 0
    g.addNodesFrom([1, 2, 3])
    check g.len == 3

suite "Graph - Items and Pairs iterators":
  test "for n in g iterates nodes":
    var g = newGraph[int]()
    g.addNodesFrom([10, 20, 30])
    var ns: seq[int]
    for n in g:
      ns.add(n)
    check ns.sorted == @[10, 20, 30]

  test "for n, adj in g iterates pairs":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    var count = 0
    for n, adj in g:
      if n == 1:
        check adj.len == 2
      count.inc
    check count == 3

suite "Graph - Other iterators":
  test "nodes iterator":
    var g = newGraph[int]()
    g.addNode(1)
    g.addNode(2)
    g.addNode(3)
    var ns: seq[int]
    for n in g.nodes:
      ns.add(n)
    check ns.sorted == @[1, 2, 3]

  test "edges iterator":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    var es: seq[(int, int)]
    for e in g.edges:
      es.add(e)
    check es.len == 2

  test "edgesWithAttr iterator":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 1.5)
    for u, v, attr in g.edgesWithAttr:
      check attr.getWeight() == 1.5

  test "neighbors iterator":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    g.addEdge(1, 4)
    var ns: seq[int]
    for n in g.neighbors(1):
      ns.add(n)
    check ns.sorted == @[2, 3, 4]

  test "nodesWithAttr iterator":
    var g = newGraph[int]()
    g.addNode(1)
    g.setNodeAttr(1, "color", "red")
    for n, attr in g.nodesWithAttr:
      if n == 1:
        check attr["color"].getStr() == "red"

suite "Graph - Degree":
  test "degree":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    check g.degree(1) == 2
    check g.degree(2) == 1

  test "degree with self-loop":
    var g = newGraph[int]()
    g.addEdge(1, 1)
    g.addEdge(1, 2)
    check g.degree(1) == 3  # self-loop counts twice + edge to 2

  test "degree iterator":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    var degMap: Table[int, int]
    for n, d in g.degree:
      degMap[n] = d
    check degMap[1] == 2
    check degMap[2] == 1
    check degMap[3] == 1

suite "Graph - Properties":
  test "density of complete graph":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    check g.density() == 1.0

  test "isEmpty":
    var g = newGraph[int]()
    check g.isEmpty()
    g.addNode(1)
    check g.isEmpty()
    g.addEdge(1, 2)
    check not g.isEmpty()

  test "isDirected":
    var g = newGraph[int]()
    check not g.isDirected()

  test "numberOfSelfLoops":
    var g = newGraph[int]()
    g.addEdge(1, 1)
    g.addEdge(2, 2)
    g.addEdge(1, 2)
    check g.numberOfSelfLoops() == 2

  test "hasSelfLoop":
    var g = newGraph[int]()
    g.addEdge(1, 1)
    check g.hasSelfLoop(1)
    g.addNode(2)
    check not g.hasSelfLoop(2)

suite "Graph - Copy and equality":
  test "copy creates independent graph":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    var h = g.copy()
    h.addEdge(3, 4)
    check g.numberOfEdges() == 1
    check h.numberOfEdges() == 2

  test "equality":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    var h = newGraph[int]()
    h.addEdge(1, 2)
    check g == h

  test "clear":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.clear()
    check g.numberOfNodes() == 0
    check g.numberOfEdges() == 0

  test "clearEdges":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.clearEdges()
    check g.numberOfNodes() == 2
    check g.numberOfEdges() == 0

suite "Graph - Subgraph":
  test "subgraph from openArray":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 4)
    let sg = g.subgraph(@[1, 2, 3])
    check sg.numberOfNodes() == 3
    check sg.hasEdge(1, 2)
    check sg.hasEdge(2, 3)
    check not sg.hasNode(4)
    check sg.numberOfEdges() == 2

  test "subgraph preserves node attrs":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.setNodeAttr(1, "color", "red")
    let sg = g.subgraph(@[1, 2])
    check sg.getNodeAttr(1)["color"].getStr() == "red"

suite "Graph - Operators + and -":
  test "graph union (+)":
    var g1 = newGraph[int]()
    g1.addEdge(1, 2)
    var g2 = newGraph[int]()
    g2.addEdge(2, 3)
    let g3 = g1 + g2
    check g3.numberOfNodes() == 3
    check g3.numberOfEdges() == 2
    check g3.hasEdge(1, 2)
    check g3.hasEdge(2, 3)

  test "graph difference (-)":
    var g1 = newGraph[int]()
    g1.addEdgesFrom([(1, 2), (2, 3), (3, 4)])
    var g2 = newGraph[int]()
    g2.addEdge(2, 3)
    let g3 = g1 - g2
    check g3.numberOfNodes() == 4  # all nodes kept
    check g3.hasEdge(1, 2)
    check not g3.hasEdge(2, 3)
    check g3.hasEdge(3, 4)
    check g3.numberOfEdges() == 2

suite "Graph - String representation":
  test "$ operator":
    var g = newGraph[int]("my graph")
    g.addEdge(1, 2)
    check $g == "my graph(nodes=2, edges=1)"

  test "$ with default name":
    var g = newGraph[int]()
    g.addNodesFrom([1, 2])
    check $g == "Graph(nodes=2, edges=0)"

suite "Graph - Attributes":
  test "node attributes":
    var g = newGraph[int]()
    g.addNode(1)
    g.setNodeAttr(1, "label", "first")
    check g.getNodeAttr(1)["label"].getStr() == "first"

  test "edge attributes":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.setEdgeAttr(1, 2, "color", "blue")
    check g.getEdgeAttr(1, 2)["color"] == "blue"
    check g.getEdgeAttr(2, 1)["color"] == "blue"  # symmetric

  test "string nodes":
    var g = newGraph[string]()
    g.addEdge("Alice", "Bob")
    check g.hasEdge("Alice", "Bob")
    check g.hasEdge("Bob", "Alice")

suite "Graph - Utility":
  test "nodeSeq":
    var g = newGraph[int]()
    g.addNodesFrom([3, 1, 2])
    check g.nodeSeq().sorted == @[1, 2, 3]

  test "edgeSeq":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3)])
    check g.edgeSeq().len == 2

  test "adjacencyTable":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    let adj = g.adjacencyTable(1)
    check adj.len == 2

suite "Graph - Edge count consistency":
  test "edge count across add/remove":
    var g = newGraph[int]()
    check g.numberOfEdges() == 0
    g.addEdge(1, 2)
    check g.numberOfEdges() == 1
    g.addEdge(2, 3)
    check g.numberOfEdges() == 2
    g.addEdge(1, 1)  # self-loop
    check g.numberOfEdges() == 3
    g.removeEdge(1, 2)
    check g.numberOfEdges() == 2
    g.removeNode(1)  # removes self-loop + edge(1,3)... wait, 1-3 was not added
    # After removeEdge(1,2), node 1 has: self-loop(1,1)
    # Nodes: 1,2,3; Edges: (2,3), (1,1)
    check g.numberOfEdges() == 1  # only (2,3) remains after removing node 1

  test "edgeCount after clear":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    g.clear()
    check g.numberOfEdges() == 0

  test "edgeCount after clearEdges":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3)])
    g.clearEdges()
    check g.numberOfEdges() == 0
    check g.numberOfNodes() == 3
