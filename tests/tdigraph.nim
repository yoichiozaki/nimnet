import std/[unittest, sets, tables, algorithm]
import nimnet/digraph
import nimnet/types

suite "DiGraph - Node operations":
  test "addNode and hasNode":
    var g = newDiGraph[int]()
    g.addNode(1)
    check g.hasNode(1)
    check not g.hasNode(2)

  test "addNodesFrom batch":
    var g = newDiGraph[int]()
    g.addNodesFrom([1, 2, 3, 4])
    check g.numberOfNodes() == 4
    check g.hasNode(3)

  test "removeNode":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(3, 1)
    g.removeNode(1)
    check not g.hasNode(1)
    check not g.hasEdge(1, 2)
    check not g.hasEdge(3, 1)
    check g.numberOfEdges() == 0

  test "removeNode raises on missing":
    var g = newDiGraph[int]()
    expect NodeNotFound:
      g.removeNode(99)

suite "DiGraph - Contains operator (in)":
  test "n in g":
    var g = newDiGraph[int]()
    g.addNode(42)
    check 42 in g
    check 99 notin g

suite "DiGraph - Edge operations":
  test "directed edges":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    check g.hasEdge(1, 2)
    check not g.hasEdge(2, 1)  # directed!

  test "addEdge is idempotent for count":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 2)
    check g.numberOfEdges() == 1

  test "addEdgesFrom batch":
    var g = newDiGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    check g.numberOfEdges() == 3
    check g.hasEdge(3, 1)

  test "addWeightedEdgesFrom batch":
    var g = newDiGraph[int]()
    g.addWeightedEdgesFrom([(1, 2, 1.0), (2, 3, 2.5)])
    check g.numberOfEdges() == 2
    check g.weight(2, 3) == 2.5

  test "numberOfEdges cached":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    check g.numberOfEdges() == 2
    check g.size() == 2
    g.removeEdge(1, 2)
    check g.numberOfEdges() == 1

  test "removeEdge":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.removeEdge(1, 2)
    check not g.hasEdge(1, 2)
    check g.numberOfEdges() == 0

  test "removeEdge raises on missing":
    var g = newDiGraph[int]()
    expect EdgeNotFound:
      g.removeEdge(1, 2)

  test "self-loop":
    var g = newDiGraph[int]()
    g.addEdge(1, 1)
    check g.hasEdge(1, 1)
    check g.numberOfEdges() == 1

suite "DiGraph - Subscript operators":
  test "g[n] returns successor dict":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    let succs = g[1]
    check succs.len == 2
    check 2 in succs

  test "g[u, v] returns edge attr":
    var g = newDiGraph[int]()
    g.addWeightedEdge(1, 2, 5.0)
    let attr = g[1, 2]
    check attr["weight"] == "5.0"

  test "g[u, v] raises on missing":
    var g = newDiGraph[int]()
    g.addNode(1)
    g.addNode(2)
    expect EdgeNotFound:
      discard g[1, 2]

suite "DiGraph - Len and items":
  test "g.len":
    var g = newDiGraph[int]()
    g.addNodesFrom([1, 2, 3])
    check g.len == 3

  test "for n in g":
    var g = newDiGraph[int]()
    g.addNodesFrom([10, 20, 30])
    var ns: seq[int]
    for n in g:
      ns.add(n)
    check ns.sorted == @[10, 20, 30]

  test "for n, adj in g (pairs)":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    var found = false
    for n, adj in g:
      if n == 1:
        check adj.len == 2
        found = true
    check found

suite "DiGraph - Degree":
  test "inDegree and outDegree":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    g.addEdge(4, 1)
    check g.outDegree(1) == 2
    check g.inDegree(1) == 1
    check g.degree(1) == 3

  test "degree iterator":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 1)
    var degMap: Table[int, int]
    for n, d in g.degree:
      degMap[n] = d
    check degMap[1] == 2
    check degMap[2] == 2

suite "DiGraph - Predecessors and successors":
  test "successors":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    var succs: seq[int]
    for s in g.successors(1):
      succs.add(s)
    check succs.sorted == @[2, 3]

  test "predecessors":
    var g = newDiGraph[int]()
    g.addEdge(2, 1)
    g.addEdge(3, 1)
    var preds: seq[int]
    for p in g.predecessors(1):
      preds.add(p)
    check preds.sorted == @[2, 3]

suite "DiGraph - Properties":
  test "density":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 1)
    g.addEdge(1, 3)
    g.addEdge(3, 1)
    g.addEdge(2, 3)
    g.addEdge(3, 2)
    check g.density() == 1.0

  test "isDirected":
    var g = newDiGraph[int]()
    check g.isDirected()

  test "isEmpty":
    var g = newDiGraph[int]()
    check g.isEmpty()
    g.addEdge(1, 2)
    check not g.isEmpty()

  test "hasSelfLoop":
    var g = newDiGraph[int]()
    g.addEdge(1, 1)
    check g.hasSelfLoop(1)

suite "DiGraph - Reverse":
  test "reverse":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let r = g.reverse()
    check r.hasEdge(2, 1)
    check r.hasEdge(3, 2)
    check not r.hasEdge(1, 2)
    check r.numberOfEdges() == 2

suite "DiGraph - Copy and equality":
  test "copy is independent":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    var h = g.copy()
    h.addEdge(3, 4)
    check g.numberOfEdges() == 1
    check h.numberOfEdges() == 2

  test "equality":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    var h = newDiGraph[int]()
    h.addEdge(1, 2)
    check g == h

  test "clear":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.clear()
    check g.numberOfNodes() == 0
    check g.numberOfEdges() == 0

  test "clearEdges":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.clearEdges()
    check g.numberOfNodes() == 2
    check g.numberOfEdges() == 0

suite "DiGraph - Subgraph":
  test "subgraph preserves direction":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 4)
    let sg = g.subgraph(@[1, 2, 3])
    check sg.hasEdge(1, 2)
    check sg.hasEdge(2, 3)
    check not sg.hasNode(4)
    check sg.numberOfEdges() == 2

suite "DiGraph - Operators + and -":
  test "digraph union (+)":
    var g1 = newDiGraph[int]()
    g1.addEdge(1, 2)
    var g2 = newDiGraph[int]()
    g2.addEdge(2, 3)
    let g3 = g1 + g2
    check g3.numberOfEdges() == 2
    check g3.hasEdge(1, 2)
    check g3.hasEdge(2, 3)

  test "digraph difference (-)":
    var g1 = newDiGraph[int]()
    g1.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    var g2 = newDiGraph[int]()
    g2.addEdge(2, 3)
    let g3 = g1 - g2
    check g3.hasEdge(1, 2)
    check not g3.hasEdge(2, 3)
    check g3.hasEdge(3, 1)
    check g3.numberOfEdges() == 2

suite "DiGraph - Attributes":
  test "edge attributes":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.setEdgeAttr(1, 2, "label", "edge1")
    check g.getEdgeAttr(1, 2)["label"] == "edge1"

  test "weighted edge":
    var g = newDiGraph[int]()
    g.addWeightedEdge(1, 2, 5.0)
    check g.weight(1, 2) == 5.0

  test "node attributes":
    var g = newDiGraph[int]()
    g.addNode(1)
    g.setNodeAttr(1, "color", "blue")
    check g.getNodeAttr(1)["color"] == "blue"

suite "DiGraph - String representation":
  test "$ operator":
    var g = newDiGraph[int]("test")
    g.addEdge(1, 2)
    check $g == "test(nodes=2, edges=1)"

suite "DiGraph - Utility":
  test "nodeSeq":
    var g = newDiGraph[int]()
    g.addNodesFrom([3, 1, 2])
    check g.nodeSeq().sorted == @[1, 2, 3]

  test "edgeSeq":
    var g = newDiGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3)])
    check g.edgeSeq().len == 2

suite "DiGraph - Edge count consistency":
  test "edge count across add/remove":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    check g.numberOfEdges() == 2
    g.removeEdge(1, 2)
    check g.numberOfEdges() == 1
    g.addEdge(1, 1)  # self-loop
    check g.numberOfEdges() == 2
    g.removeNode(1)
    check g.numberOfEdges() == 1  # only (2,3) remains
