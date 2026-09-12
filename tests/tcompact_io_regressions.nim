import std/[unittest, os, json, strutils, tables, sets, hashes, xmlparser]
import nimnet/[types, graph, digraph, compact, datasets]
import nimnet/io/[edgelist, gexf]

var fixtureNumber = 0

template withFixture(data: string, body: untyped) =
  block:
    createDir("build")
    inc fixtureNumber
    let filename {.inject.} = "build" /
      ("compact_io_regressions_" & $getCurrentProcessId() & "_" &
       $fixtureNumber & ".txt")
    doAssert not fileExists(filename)
    writeFile(filename, data)
    defer:
      if fileExists(filename):
        removeFile(filename)
    body

type UnorderedLabel = object
  text: string

func hash(node: UnorderedLabel): Hash =
  hash(node.text)

proc checkCompactRoundtrip[N](g: Graph[N]) =
  let cg = g.toCompact()
  let restored: Graph[N] = cg.toGraph()
  check cg.numberOfNodes() == g.numberOfNodes()
  check cg.numberOfEdges() == g.numberOfEdges()
  check cg.nodeIndex.len == g.numberOfNodes() + 1
  check cg.weights.len == cg.neighbors.len
  check restored.numberOfNodes() == g.numberOfNodes()
  check restored.numberOfEdges() == g.numberOfEdges()
  var degreeSum = 0
  var loopCount = 0
  for i, node in cg.nodeList:
    check restored.hasNode(node)
    check cg.degreeCSR(i) == g.degree(node)
    check restored.degree(node) == g.degree(node)
    degreeSum += cg.degreeCSR(i)
    let hasLoop = ord(g.hasEdge(node, node))
    loopCount += hasLoop
    var seen = initHashSet[N]()
    for neighborIndex in cg.neighborsCSR(i):
      let neighbor = cg.nodeList[neighborIndex]
      check neighbor notin seen
      check g.hasEdge(node, neighbor)
      seen.incl(neighbor)
    check seen.len == g.degree(node) - hasLoop
    for neighbor in g.neighbors(node):
      check neighbor in seen
    for slot in cg.nodeIndex[i] ..< cg.nodeIndex[i + 1]:
      check cg.weights[slot] ==
        g.getEdgeAttr(node, cg.nodeList[cg.neighbors[slot]]).weight
  check degreeSum == 2 * g.numberOfEdges()
  check cg.neighbors.len == 2 * g.numberOfEdges() - loopCount
  for (u, v, attr) in g.edgesWithAttr():
    check restored.hasEdge(u, v)
    check restored.getEdgeAttr(u, v).weight == attr.weight
  check restored.toCompact().numberOfEdges() == cg.numberOfEdges()

proc checkCompactRoundtrip[N](g: DiGraph[N]) =
  let cg = g.toCompact()
  let restored: DiGraph[N] = cg.toGraph()
  check cg.numberOfNodes() == g.numberOfNodes()
  check cg.numberOfEdges() == g.numberOfEdges()
  check cg.nodeIndex.len == g.numberOfNodes() + 1
  check cg.weights.len == cg.neighbors.len
  check restored.numberOfNodes() == g.numberOfNodes()
  check restored.numberOfEdges() == g.numberOfEdges()
  var outDegreeSum = 0
  var inDegreeSum = 0
  for i, node in cg.nodeList:
    check restored.hasNode(node)
    check restored.degree(node) == g.degree(node)
    check restored.inDegree(node) == g.inDegree(node)
    check restored.outDegree(node) == g.outDegree(node)
    check cg.nodeIndex[i + 1] - cg.nodeIndex[i] == g.outDegree(node)
    outDegreeSum += restored.outDegree(node)
    inDegreeSum += restored.inDegree(node)
    var seen = initHashSet[N]()
    for neighborIndex in cg.neighborsCSR(i):
      let neighbor = cg.nodeList[neighborIndex]
      check neighbor notin seen
      check g.hasEdge(node, neighbor)
      seen.incl(neighbor)
    check seen.len == g.outDegree(node)
    for neighbor in g.successors(node):
      check neighbor in seen
    for slot in cg.nodeIndex[i] ..< cg.nodeIndex[i + 1]:
      check cg.weights[slot] ==
        g.getEdgeAttr(node, cg.nodeList[cg.neighbors[slot]]).weight
  check outDegreeSum == g.numberOfEdges()
  check inDegreeSum == g.numberOfEdges()
  for (u, v, attr) in g.edgesWithAttr():
    check restored.hasEdge(u, v)
    check restored.getEdgeAttr(u, v).weight == attr.weight
    check restored.hasEdge(v, u) == g.hasEdge(v, u)
  check restored.toCompact().numberOfEdges() == cg.numberOfEdges()

suite "Compact graph self-loop regressions":
  test "an undirected self-loop is one edge and two degree endpoints":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 1, 2.5)
    let cg = g.toCompact()
    check cg.numberOfEdges() == 1
    check cg.degreeCSR(0) == 2
    check cg.neighbors == @[0]
    let restored = cg.toGraph()
    check restored.numberOfEdges() == 1
    check restored.degree(1) == 2
    check restored.getEdgeAttr(1, 1).weight == 2.5

  test "multiple loops and ordinary edges retain counts and weights":
    var g = newGraph[string]()
    g.addWeightedEdge("left", "left", -2.0)
    g.addWeightedEdge("left", "right", 3.5)
    g.addWeightedEdge("right", "right", 0.0)
    g.addNode("isolated")
    let cg = g.toCompact()
    check cg.numberOfEdges() == 3
    check cg.neighbors.len == 4
    let restored = cg.toGraph()
    check restored.numberOfNodes() == 3
    check restored.numberOfEdges() == 3
    for i, node in cg.nodeList:
      check cg.degreeCSR(i) == g.degree(node)
      check restored.degree(node) == g.degree(node)
    for (u, v, attr) in g.edgesWithAttr():
      check restored.getEdgeAttr(u, v).weight == attr.weight

  test "empty graphs and default compact objects roundtrip":
    checkCompactRoundtrip(newGraph[int]())
    checkCompactRoundtrip(newDiGraph[string]())
    let cg = default(CompactGraph[int])
    let cdg = default(CompactDiGraph[string])
    check cg.numberOfNodes() == 0
    check cg.numberOfEdges() == 0
    check cg.toGraph().numberOfEdges() == 0
    check cdg.numberOfNodes() == 0
    check cdg.numberOfEdges() == 0
    check cdg.toGraph().numberOfEdges() == 0

  test "isolated nodes survive both compact representations":
    var g = newGraph[string]()
    var dg = newDiGraph[string]()
    for node in ["first", "second", "third"]:
      g.addNode(node)
      dg.addNode(node)
    checkCompactRoundtrip(g)
    checkCompactRoundtrip(dg)

  test "loop-only graphs keep each loop once in CSR traversal":
    var g = newGraph[int]()
    var dg = newDiGraph[int]()
    for node in 1 .. 3:
      g.addWeightedEdge(node, node, float(node - 2))
      dg.addWeightedEdge(node, node, float(node - 2))
    checkCompactRoundtrip(g)
    checkCompactRoundtrip(dg)

  test "directed reciprocal and one-way arcs retain distinct weights":
    var g = newDiGraph[string]()
    g.addWeightedEdge("left", "right", 2.5)
    g.addWeightedEdge("right", "left", -3.5)
    g.addWeightedEdge("right", "sink", 0.0)
    g.addEdge("left", "left")
    g.addNode("isolated")
    checkCompactRoundtrip(g)

  test "labels need hashing and equality but no ordering":
    let first = UnorderedLabel(text: "first")
    let second = UnorderedLabel(text: "second")
    let isolated = UnorderedLabel(text: "isolated")
    var g = newGraph[UnorderedLabel]()
    var dg = newDiGraph[UnorderedLabel]()
    g.addWeightedEdge(first, second, 2.5)
    g.addWeightedEdge(first, first, 0.0)
    g.addNode(isolated)
    dg.addWeightedEdge(first, second, 3.5)
    dg.addWeightedEdge(second, first, -1.5)
    dg.addEdge(first, first)
    dg.addNode(isolated)
    checkCompactRoundtrip(g)
    checkCompactRoundtrip(dg)

  test "a compact snapshot is unaffected by subsequent graph edits":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 1, 2.5)
    let cg = g.toCompact()
    g.addWeightedEdge(1, 1, 9.0)
    g.addEdge(1, 2)
    check cg.numberOfEdges() == 1
    check cg.degreeCSR(0) == 2
    check cg.toGraph().getEdgeAttr(1, 1).weight == 2.5

  test "BFS visits looped nodes once without changing neighbor slots":
    var g = newGraph[int]()
    g.addEdge(0, 0)
    g.addEdge(0, 1)
    g.addEdge(1, 1)
    g.addNode(2)
    let cg = g.toCompact()
    let sourceIndex = cg.nodeList.find(0)
    let visited = cg.bfsCSR(sourceIndex)
    check visited.len == 2
    check visited[0] == sourceIndex
    check visited.toHashSet().len == 2
    check cg.neighbors.len == 4

  test "all three-node undirected graphs preserve counts degrees and weights":
    for mask in 0 ..< (1 shl 6):
      var g = newGraph[int]()
      g.addNodesFrom([0, 1, 2])
      var edgeIndex = 0
      for u in 0 .. 2:
        for v in u .. 2:
          if (mask and (1 shl edgeIndex)) != 0:
            g.addWeightedEdge(u, v, float(edgeIndex - 2))
          inc edgeIndex
      checkCompactRoundtrip(g)

  test "all three-node directed graphs preserve counts degrees and weights":
    for mask in 0 ..< (1 shl 9):
      var g = newDiGraph[int]()
      g.addNodesFrom([0, 1, 2])
      var edgeIndex = 0
      for u in 0 .. 2:
        for v in 0 .. 2:
          if (mask and (1 shl edgeIndex)) != 0:
            g.addWeightedEdge(u, v, float(edgeIndex - 4))
          inc edgeIndex
      checkCompactRoundtrip(g)

suite "Dataset direction and parsing regressions":
  test "legacy directed argument has an actionable error":
    try:
      discard loadFromEdgeListString[int]("1 2", directed = true)
      check false
    except NimNetError as error:
      check "loadFromEdgeListStringDirected" in error.msg

  test "invalid dataset weights are not converted to unweighted edges":
    expect ValueError:
      discard loadFromEdgeListString[int]("1 2 not-a-weight")

  test "incomplete dataset rows are rejected":
    expect ValueError:
      discard loadFromEdgeListString[int]("1")

  test "empty strings and comment-only files load empty typed graphs":
    for data in ["", "\r\n \t# comment\r\n  % comment\n"]:
      let g: Graph[int] = loadFromEdgeListString[int](data)
      let dg: DiGraph[int] = loadFromEdgeListStringDirected[int](data)
      check g.numberOfNodes() == 0
      check dg.numberOfNodes() == 0
      withFixture(data):
        check loadFromEdgeListFile(filename).numberOfEdges() == 0
        check loadFromEdgeListFileDirected(filename).numberOfEdges() == 0

  test "whitespace comments signed nodes and optional weights are shared":
    let data = " \t# header\r\n % header\r\n -1 \t 2 \t2.5\r\n2   3\n3 3 0.0\n"
    let g = loadFromEdgeListString[int](data, directed = false)
    let dg = loadFromEdgeListStringDirected[int](data)
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 3
    check g.hasEdge(2, -1)
    check g.getEdgeAttr(-1, 2).weight == 2.5
    check g.getEdgeAttr(2, 3).weight == 1.0
    check dg.numberOfNodes() == 3
    check dg.numberOfEdges() == 3
    check dg.hasEdge(-1, 2)
    check not dg.hasEdge(2, -1)
    check dg.getEdgeAttr(-1, 2).weight == 2.5
    check dg.getEdgeAttr(2, 3).weight == 1.0
    check dg.getEdgeAttr(3, 3).weight == 0.0
    check dg.inDegree(3) == 2
    check dg.outDegree(3) == 1

  test "duplicate edges update weights while reciprocal arcs stay separate":
    let data = "1 2 1.5\n1 2 7.0\n2 1 -3.0\n"
    let g = loadFromEdgeListString[int](data)
    let dg = loadFromEdgeListStringDirected[int](data)
    check g.numberOfEdges() == 1
    check g.getEdgeAttr(1, 2).weight == -3.0
    check dg.numberOfEdges() == 2
    check dg.getEdgeAttr(1, 2).weight == 7.0
    check dg.getEdgeAttr(2, 1).weight == -3.0

  test "directed and undirected files match their string loader contracts":
    let data = "# header\n-1 2 2.5\n2 -1 -3.5\n2 3\n3 3 0\n"
    withFixture(data):
      let g: Graph[int] = loadFromEdgeListFile(filename)
      let dg: DiGraph[int] = loadFromEdgeListFileDirected(filename)
      let expected = loadFromEdgeListString[int](data)
      let directedExpected = loadFromEdgeListStringDirected[int](data)
      check g.numberOfEdges() == expected.numberOfEdges()
      check dg.numberOfEdges() == directedExpected.numberOfEdges()
      for (u, v, attr) in expected.edgesWithAttr():
        check g.getEdgeAttr(u, v).weight == attr.weight
      for (u, v, attr) in directedExpected.edgesWithAttr():
        check dg.getEdgeAttr(u, v).weight == attr.weight
      check not dg.hasEdge(3, 2)
      check dg.degree(3) == directedExpected.degree(3)

  test "malformed rows propagate through all dataset loaders":
    for data in ["1", "1 2 3 4", "one 2", "1 two", "1 2 invalid",
                 "1 2 2.5suffix", "9999999999999999999999999999999 2"]:
      expect ValueError:
        discard loadFromEdgeListString[int](data)
      expect ValueError:
        discard loadFromEdgeListStringDirected[int](data)
      withFixture(data):
        expect ValueError:
          discard loadFromEdgeListFile(filename)
        expect ValueError:
          discard loadFromEdgeListFileDirected(filename)

  test "integer node types retain valid ranges without wrapping":
    let signed = loadFromEdgeListStringDirected[int8]("127 -128 2.5")
    check signed.hasEdge(127'i8, -128'i8)
    check signed.getEdgeAttr(127'i8, -128'i8).weight == 2.5
    let unsigned = loadFromEdgeListString[uint64]("18446744073709551615 0")
    check unsigned.hasEdge(high(uint64), 0'u64)
    for data in ["128 1", "-129 1"]:
      expect ValueError:
        discard loadFromEdgeListString[int8](data)
      expect ValueError:
        discard loadFromEdgeListStringDirected[int8](data)
    for data in ["256 1", "-1 2"]:
      expect ValueError:
        discard loadFromEdgeListString[uint8](data)
      expect ValueError:
        discard loadFromEdgeListStringDirected[uint8](data)

  test "missing dataset files report IOError":
    withFixture(""):
      removeFile(filename)
      expect IOError:
        discard loadFromEdgeListFile(filename)
      expect IOError:
        discard loadFromEdgeListFileDirected(filename)

  test "scoped fixture files are cleaned up even after a parse error":
    var path = ""
    expect ValueError:
      withFixture("invalid"):
        path = filename
        discard loadFromEdgeListFileDirected(filename)
    check path.len > 0
    check not fileExists(path)

suite "Edge list direction and parsing regressions":
  test "the default delimiter accepts arbitrary whitespace":
    withFixture("  # comment\r\n\r\nalpha\t  beta   weight=2.5\r\n"):
      let g = readEdgelist(filename)
      check g.hasEdge("alpha", "beta")
      check not g.hasNode("")
      if g.hasEdge("alpha", "beta"):
        check g.getEdgeAttr("alpha", "beta").weight == 2.5
      let dg = readEdgelistDirected(filename)
      check dg.hasEdge("alpha", "beta")
      check not dg.hasEdge("beta", "alpha")
      check dg.getEdgeAttr("alpha", "beta").weight == 2.5

  test "unsupported createUsing values cannot silently become graphs":
    withFixture("a b\n"):
      for mode in ["digraph", "directed", "multigraph", ""]:
        try:
          discard readEdgelist(filename, createUsing = mode)
          check false
        except NimNetError as error:
          check "readEdgelistDirected" in error.msg

  test "invalid edge list weights propagate parse errors":
    withFixture("a b weight=not-a-weight\n"):
      expect ValueError:
        discard readEdgelist(filename)
      expect ValueError:
        discard readEdgelistDirected(filename)

  test "empty and comment-only files preserve string return types":
    for data in ["", "  # header\n \t\r\n"]:
      withFixture(data):
        let g: Graph[string] = readEdgelist(filename, createUsing = "graph")
        let dg: DiGraph[string] = readEdgelistDirected(filename)
        check g.numberOfNodes() == 0
        check dg.numberOfNodes() == 0
        check g.numberOfEdges() == 0
        check dg.numberOfEdges() == 0

  test "custom delimiters trim fields and preserve spaces within labels":
    for delimiter in [",", "::", "\t"]:
      let data = "  # header\r\n node one " & delimiter & " node two " &
        delimiter & " weight = -2.5 " & delimiter & " formula = a=b " &
        delimiter & " empty= \r\n"
      withFixture(data):
        let g = readEdgelist(filename, delimiter)
        let dg = readEdgelistDirected(filename, delimiter)
        check g.hasEdge("node one", "node two")
        check g.getEdgeAttr("node one", "node two").weight == -2.5
        check g.getEdgeAttr("node one", "node two")["formula"] == "a=b"
        check g.getEdgeAttr("node one", "node two")["empty"] == ""
        check dg.hasEdge("node one", "node two")
        check not dg.hasEdge("node two", "node one")
        check dg.getEdgeAttr("node one", "node two") ==
          g.getEdgeAttr("node one", "node two")

  test "directed integer writer roundtrips direction and weights":
    var g = newDiGraph[int]()
    g.addWeightedEdge(1, 2, 2.5)
    g.addWeightedEdge(2, 1, -3.5)
    g.addWeightedEdge(2, 3, 0.0)
    g.addEdge(3, 3)
    for delimiter in [" ", ","]:
      withFixture(""):
        writeEdgelistDigraph(g, filename, delimiter)
        let restored = readEdgelistDirected(filename, delimiter)
        check restored.numberOfNodes() == 3
        check restored.numberOfEdges() == 4
        for (u, v, attr) in g.edgesWithAttr():
          check restored.getEdgeAttr($u, $v).weight == attr.weight
        check not restored.hasEdge("3", "2")

  test "directed string writer preserves extra attributes and loop weights":
    var g = newDiGraph[string]()
    var attr = newEdgeAttr(2.5)
    attr["formula"] = "a=b"
    attr["color"] = "blue"
    g.addEdge("first node", "second node", attr)
    g.addWeightedEdge("second node", "second node", 0.0)
    withFixture(""):
      writeEdgelistDigraph(g, filename, delimiter = "::")
      let restored = readEdgelistDirected(filename, delimiter = "::")
      check restored.numberOfEdges() == 2
      check restored.getEdgeAttr("first node", "second node") == attr
      check restored.getEdgeAttr("second node", "second node").weight == 0.0
      check not restored.hasEdge("second node", "first node")

  test "undirected writer and explicit graph selector preserve weights":
    var g = newGraph[int]()
    var attr = newEdgeAttr(-2.5)
    attr["color"] = "red"
    g.addEdge(1, 2, attr)
    g.addWeightedEdge(2, 2, 0.0)
    withFixture(""):
      writeEdgelist(g, filename)
      let restored = readEdgelist(filename, createUsing = "graph")
      check restored.numberOfEdges() == 2
      check restored.hasEdge("2", "1")
      check restored.getEdgeAttr("1", "2") == attr
      check restored.getEdgeAttr("2", "2").weight == 0.0
      writeEdgelist(g, filename, writeData = false)
      let withoutData = readEdgelist(filename)
      check withoutData.getEdgeAttr("1", "2").weight == 1.0
      check withoutData.getEdgeAttr("2", "2").weight == 1.0

  test "duplicate rows replace edge attributes without adding edges":
    withFixture("a b weight=2\na b weight=4\nb a weight=-1\n"):
      let g = readEdgelist(filename)
      let dg = readEdgelistDirected(filename)
      check g.numberOfEdges() == 1
      check g.getEdgeAttr("a", "b").weight == -1.0
      check dg.numberOfEdges() == 2
      check dg.getEdgeAttr("a", "b").weight == 4.0
      check dg.getEdgeAttr("b", "a").weight == -1.0

  test "incomplete rows and malformed attributes fail explicitly":
    for data in ["a", "a b trailing", "a b =value", "a b weight=",
                 "a b weight=2.5suffix"]:
      withFixture(data):
        expect ValueError:
          discard readEdgelist(filename)
        expect ValueError:
          discard readEdgelistDirected(filename)
    for data in [",b", "a,,weight=1", "a,b,", "a,b,=value"]:
      withFixture(data):
        expect ValueError:
          discard readEdgelist(filename, delimiter = ",")
        expect ValueError:
          discard readEdgelistDirected(filename, delimiter = ",")

  test "empty delimiters are rejected":
    withFixture("a b\n"):
      expect ValueError:
        discard readEdgelist(filename, delimiter = "")
      expect ValueError:
        discard readEdgelistDirected(filename, delimiter = "")

  test "missing edge list files report IOError":
    withFixture(""):
      removeFile(filename)
      expect IOError:
        discard readEdgelist(filename)
      expect IOError:
        discard readEdgelistDirected(filename)

suite "Directed GEXF labels and weights regressions":
  test "directed node labels and weighted arcs survive a file roundtrip":
    var g = newDiGraph[int]()
    g.addNode(1, newNodeAttr({"label": "First node"}))
    g.addNode(2, newNodeAttr({"label": "Second node"}))
    g.addNode(3, newNodeAttr({"label": "Isolated node"}))
    g.addWeightedEdge(1, 2, 3.5)
    withFixture(""):
      writeGexf(g, filename)
      let restored = readGexfDirected(filename)
      check restored.numberOfNodes() == 3
      check restored.hasEdge("1", "2")
      check not restored.hasEdge("2", "1")
      check restored.getEdgeAttr("1", "2").weight == 3.5
      for (node, label) in [("1", "First node"), ("2", "Second node"),
                            ("3", "Isolated node")]:
        let attr = restored.getNodeAttr(node)
        check attr.hasKey("label")
        if attr.hasKey("label"):
          check attr["label"].getStr() == label

  test "invalid GEXF weights propagate parse errors":
    withFixture("""<gexf><graph>
      <edges><edge source="a" target="b" weight="invalid"/></edges>
      </graph></gexf>"""):
      expect ValueError:
        discard readGexfDirected(filename)
      expect ValueError:
        discard readGexf(filename)

  test "directed GEXF preserves escaped empty and absent labels":
    withFixture("""<gexf><graph defaultedgetype="directed">
      <nodes>
        <node id="source" label="A &amp; B"/>
        <node id="target" label=""/>
        <node id="isolated" label="Isolated node"/>
        <node id="unlabeled"/>
      </nodes>
      <edges>
        <edge source="source" target="target" weight="-2.5"/>
        <edge source="target" target="source" weight="0.0"/>
        <edge source="target" target="target"/>
      </edges>
      </graph></gexf>"""):
      let g = readGexfDirected(filename)
      check g.numberOfNodes() == 4
      check g.numberOfEdges() == 3
      check g.getNodeAttr("source")["label"].getStr() == "A & B"
      check g.getNodeAttr("target")["label"].getStr() == ""
      check g.getNodeAttr("isolated")["label"].getStr() == "Isolated node"
      check not g.getNodeAttr("unlabeled").hasKey("label")
      check g.getEdgeAttr("source", "target").weight == -2.5
      check g.getEdgeAttr("target", "source").weight == 0.0
      check g.getEdgeAttr("target", "target").weight == 1.0
      check g.degree("target") == 4
      check g.degree("isolated") == 0

  test "undirected GEXF retains its node-label and weight behavior":
    var g = newGraph[string]()
    g.addNode("source", newNodeAttr({"label": "Source node"}))
    g.addNode("target", newNodeAttr({"label": "Target node"}))
    g.addNode("isolated", newNodeAttr({"label": "Isolated node"}))
    g.addWeightedEdge("source", "target", 2.5)
    g.addWeightedEdge("source", "source", 0.0)
    withFixture(""):
      writeGexf(g, filename)
      let restored = readGexf(filename)
      check restored.numberOfNodes() == 3
      check restored.numberOfEdges() == 2
      for node in g.nodes():
        check restored.getNodeAttr(node)["label"].getStr() ==
          g.getNodeAttr(node)["label"].getStr()
      check restored.getEdgeAttr("source", "target").weight == 2.5
      check restored.getEdgeAttr("source", "source").weight == 0.0
      check restored.degree("source") == 3

  test "malformed XML propagates parse errors":
    withFixture("<gexf><graph><nodes></gexf>"):
      expect XmlError:
        discard readGexf(filename)
      expect XmlError:
        discard readGexfDirected(filename)

  test "missing GEXF files report IOError":
    withFixture(""):
      removeFile(filename)
      expect IOError:
        discard readGexf(filename)
      expect IOError:
        discard readGexfDirected(filename)
