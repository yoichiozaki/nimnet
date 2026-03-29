## Type conversion utilities

import std/[tables, sequtils, sets, algorithm]
import types
import graph
import digraph

proc toAdjacencyMatrix*[N](g: Graph[N]): (seq[N], seq[seq[float]]) =
  ## Convert graph to adjacency matrix.
  ## Returns (nodeList, matrix) where matrix[i][j] is the edge weight.
  let nodes = g.nodeSeq()
  var nodeIdx = initTable[N, int]()
  for i, n in nodes:
    nodeIdx[n] = i
  let n = nodes.len
  var matrix = newSeqWith(n, newSeq[float](n))
  for (u, v, attr) in g.edgesWithAttr:
    let w = attr.getWeight()
    matrix[nodeIdx[u]][nodeIdx[v]] = w
    matrix[nodeIdx[v]][nodeIdx[u]] = w
  result = (nodes, matrix)

proc toAdjacencyMatrix*[N](g: DiGraph[N]): (seq[N], seq[seq[float]]) =
  let nodes = g.nodeSeq()
  var nodeIdx = initTable[N, int]()
  for i, n in nodes:
    nodeIdx[n] = i
  let n = nodes.len
  var matrix = newSeqWith(n, newSeq[float](n))
  for (u, v, attr) in g.edgesWithAttr:
    let w = attr.getWeight()
    matrix[nodeIdx[u]][nodeIdx[v]] = w
  result = (nodes, matrix)

proc fromEdgeList*[N](edges: seq[(N, N)]): Graph[N] =
  ## Create a graph from a sequence of edges.
  result = newGraph[N]()
  for (u, v) in edges:
    result.addEdge(u, v)

proc fromEdgeListDirected*[N](edges: seq[(N, N)]): DiGraph[N] =
  ## Create a directed graph from a sequence of edges.
  result = newDiGraph[N]()
  for (u, v) in edges:
    result.addEdge(u, v)

proc fromAdjacencyMatrix*(matrix: seq[seq[float]], directed: bool = false): Graph[int] =
  ## Create a graph from an adjacency matrix.
  result = newGraph[int]()
  let n = matrix.len
  for i in 0 ..< n:
    result.addNode(i)
  for i in 0 ..< n:
    let jStart = if directed: 0 else: i
    for j in jStart ..< n:
      if matrix[i][j] != 0.0:
        result.addEdge(i, j, newEdgeAttr(matrix[i][j]))

proc degreeSequence*[N](g: Graph[N]): seq[int] =
  ## Return the degree sequence (sorted in descending order).
  for (_, d) in g.degree:
    result.add(d)
  result.sort(proc(a, b: int): int = cmp(b, a))
