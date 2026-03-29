## Builder pattern and DSL for graph construction
##
## Provides a fluent API and Nim macro-based DSL for creating graphs.

import std/[tables, macros]
import ./types
import ./graph
import ./digraph

# Builder pattern for Graph
type GraphBuilder*[N] = object
  graph: Graph[N]

proc initGraphBuilder*[N](name: string = ""): GraphBuilder[N] =
  ## Create a new graph builder.
  result.graph = newGraph[N](name)

proc addNode*[N](b: var GraphBuilder[N], node: N): var GraphBuilder[N] {.discardable.} =
  ## Add a node. Returns self for chaining.
  b.graph.addNode(node)
  result = b

proc addEdge*[N](b: var GraphBuilder[N], u, v: N): var GraphBuilder[N] {.discardable.} =
  ## Add an edge. Returns self for chaining.
  b.graph.addEdge(u, v)
  result = b

proc addWeightedEdge*[N](b: var GraphBuilder[N], u, v: N, weight: float): var GraphBuilder[N] {.discardable.} =
  ## Add a weighted edge. Returns self for chaining.
  b.graph.addWeightedEdge(u, v, weight)
  result = b

proc addPath*[N](b: var GraphBuilder[N], nodes: openArray[N]): var GraphBuilder[N] {.discardable.} =
  ## Add a path through the given nodes.
  for i in 0 ..< nodes.len - 1:
    b.graph.addEdge(nodes[i], nodes[i + 1])
  result = b

proc addCycle*[N](b: var GraphBuilder[N], nodes: openArray[N]): var GraphBuilder[N] {.discardable.} =
  ## Add a cycle through the given nodes.
  for i in 0 ..< nodes.len - 1:
    b.graph.addEdge(nodes[i], nodes[i + 1])
  if nodes.len > 2:
    b.graph.addEdge(nodes[^1], nodes[0])
  result = b

proc addStar*[N](b: var GraphBuilder[N], center: N, leaves: openArray[N]): var GraphBuilder[N] {.discardable.} =
  ## Add a star centered at `center` with given leaves.
  for leaf in leaves:
    b.graph.addEdge(center, leaf)
  result = b

proc build*[N](b: GraphBuilder[N]): Graph[N] =
  ## Return the constructed graph.
  result = b.graph

# Builder pattern for DiGraph
type DiGraphBuilder*[N] = object
  graph: DiGraph[N]

proc initDiGraphBuilder*[N](name: string = ""): DiGraphBuilder[N] =
  ## Create a new directed graph builder.
  result.graph = newDiGraph[N](name)

proc addNode*[N](b: var DiGraphBuilder[N], node: N): var DiGraphBuilder[N] {.discardable.} =
  b.graph.addNode(node)
  result = b

proc addEdge*[N](b: var DiGraphBuilder[N], u, v: N): var DiGraphBuilder[N] {.discardable.} =
  b.graph.addEdge(u, v)
  result = b

proc addWeightedEdge*[N](b: var DiGraphBuilder[N], u, v: N, weight: float): var DiGraphBuilder[N] {.discardable.} =
  b.graph.addWeightedEdge(u, v, weight)
  result = b

proc addPath*[N](b: var DiGraphBuilder[N], nodes: openArray[N]): var DiGraphBuilder[N] {.discardable.} =
  for i in 0 ..< nodes.len - 1:
    b.graph.addEdge(nodes[i], nodes[i + 1])
  result = b

proc addCycle*[N](b: var DiGraphBuilder[N], nodes: openArray[N]): var DiGraphBuilder[N] {.discardable.} =
  for i in 0 ..< nodes.len - 1:
    b.graph.addEdge(nodes[i], nodes[i + 1])
  if nodes.len > 2:
    b.graph.addEdge(nodes[^1], nodes[0])
  result = b

proc build*[N](b: DiGraphBuilder[N]): DiGraph[N] =
  result = b.graph

# DSL macros
macro graph*(name: string, body: untyped): untyped =
  ## DSL macro for building a graph.
  ## Usage:
  ##   let g = graph("my graph"):
  ##     nodes 1, 2, 3, 4
  ##     edges (1, 2), (2, 3), (3, 4)
  ##     edge 4, 1
  let builderSym = genSym(nskVar, "builder")
  result = newStmtList()
  result.add quote do:
    var `builderSym` = initGraphBuilder[int](`name`)

  for stmt in body:
    if stmt.kind == nnkCommand:
      let cmd = $stmt[0]
      case cmd
      of "nodes":
        for i in 1 ..< stmt.len:
          let node = stmt[i]
          result.add quote do:
            `builderSym`.addNode(`node`)
      of "edges":
        for i in 1 ..< stmt.len:
          let edge = stmt[i]
          if edge.kind == nnkTupleConstr and edge.len == 2:
            let u = edge[0]
            let v = edge[1]
            result.add quote do:
              `builderSym`.addEdge(`u`, `v`)
      of "edge":
        if stmt.len == 3:
          let u = stmt[1]
          let v = stmt[2]
          result.add quote do:
            `builderSym`.addEdge(`u`, `v`)
      of "path":
        var pathNodes = newNimNode(nnkBracket)
        for i in 1 ..< stmt.len:
          pathNodes.add(stmt[i])
        result.add quote do:
          `builderSym`.addPath(`pathNodes`)
      of "cycle":
        var cycleNodes = newNimNode(nnkBracket)
        for i in 1 ..< stmt.len:
          cycleNodes.add(stmt[i])
        result.add quote do:
          `builderSym`.addCycle(`cycleNodes`)
      else:
        discard

  result.add quote do:
    `builderSym`.build()
