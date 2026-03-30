## LEDA format reader (read-only)
##
## LEDA native format for graphs.

import std/[strutils]
import ../graph

proc readLeda*(data: string): Graph[int] =
  ## Read a graph from LEDA format string.
  ## LEDA format: header, then nodes section, then edges section.
  result = newGraph[int]()
  var inNodes = false
  var inEdges = false
  var nodeCount = 0
  var lineNum = 0
  var parsedNodeCount = false
  var parsedEdgeCount = false
  for line in data.splitLines():
    let stripped = line.strip()
    if stripped.len == 0 or stripped.startsWith("#"):
      continue
    inc lineNum
    if stripped == "LEDA.GRAPH" or stripped.startsWith("LEDA"):
      continue
    if stripped == "string" or stripped == "void" or stripped == "int" or stripped == "-1" or stripped == "-2":
      continue
    # Try to detect sections by node/edge count lines
    if not parsedNodeCount:
      try:
        nodeCount = parseInt(stripped)
        parsedNodeCount = true
        inNodes = true
        for i in 1 .. nodeCount:
          result.addNode(i)
        continue
      except ValueError:
        continue
    if inNodes:
      nodeCount -= 1
      if nodeCount <= 0:
        inNodes = false
      continue
    if not parsedEdgeCount:
      try:
        let edgeCount = parseInt(stripped)
        parsedEdgeCount = true
        inEdges = true
        continue
      except ValueError:
        continue
    if inEdges:
      let parts = stripped.splitWhitespace()
      if parts.len >= 2:
        try:
          let u = parseInt(parts[0])
          let v = parseInt(parts[1])
          if u > 0 and v > 0:
            result.addEdge(u, v)
        except ValueError:
          discard

proc parseLeda*(data: string): Graph[int] =
  ## Parse LEDA format (alias for readLeda).
  result = readLeda(data)
