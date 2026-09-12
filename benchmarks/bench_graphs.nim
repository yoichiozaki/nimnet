import nimnet
import bench_common

proc buildFixture*(fixture: Fixture, weighted = false): Graph[int] =
  result = newGraph[int](capacity = fixture.size.nodes)
  for i in 0 ..< fixture.size.nodes:
    result.addNode(i)
  for (u, v, weightMillis) in fixture.edges:
    if weighted:
      result.addWeightedEdge(u, v, weightMillis.float / 1000.0)
    else:
      result.addEdge(u, v)
