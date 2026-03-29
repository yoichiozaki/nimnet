import std/[unittest, tables]
import nimnet/types

suite "EdgeAttr":
  test "empty":
    let a = newEdgeAttr()
    check a.len == 0
    check a.getWeight() == 1.0

  test "weight constructor":
    let a = newEdgeAttr(2.5)
    check a.getWeight() == 2.5
    check a["weight"] == "2.5"

  test "openArray constructor":
    let a = newEdgeAttr({"weight": "3.0", "color": "red"})
    check a.getWeight() == 3.0
    check a["color"] == "red"

  test "weight= setter sugar":
    var a = newEdgeAttr()
    a.weight = 4.2
    check a.getWeight() == 4.2

  test "getWeight default":
    let a = newEdgeAttr()
    check a.getWeight(99.0) == 99.0

suite "NodeAttr":
  test "empty":
    let a = newNodeAttr()
    check a.len == 0

  test "openArray constructor":
    let a = newNodeAttr({"label": "hub", "color": "blue"})
    check a["label"] == "hub"

suite "Edge type aliases":
  test "Edge tuple":
    let e: Edge[int] = (u: 1, v: 2)
    check e.u == 1 and e.v == 2

  test "WeightedEdge tuple":
    let e: WeightedEdge[int] = (u: 1, v: 2, weight: 3.14)
    check e.weight == 3.14

suite "Exception hierarchy":
  test "all inherit from NimNetError":
    expect NimNetError:
      raise newException(NodeNotFound, "test")
    expect NimNetError:
      raise newException(EdgeNotFound, "test")
    expect NimNetError:
      raise newException(NimNetNoPath, "test")
