## Multiline adjacency list I/O format
##
## Format: node on first line, then each neighbor on subsequent indented lines.

import std/[strutils, tables]
import ../types, ../graph, ../digraph

proc writeMultilineAdjlist*[N](g: Graph[N]): string =
  ## Write a graph in multiline adjacency list format.
  for n in g.nodes:
    result &= $n & "\n"
    for nb in g.neighbors(n):
      let attr = g.getEdgeAttr(n, nb)
      if attr.weight != 1.0:
        result &= "  " & $nb & " {\"weight\": " & $attr.weight & "}\n"
      else:
        result &= "  " & $nb & "\n"

proc readMultilineAdjlist*(data: string): Graph[int] =
  ## Read a graph from multiline adjacency list format.
  result = newGraph[int]()
  var currentNode = -1
  for line in data.splitLines():
    let stripped = line.strip()
    if stripped.len == 0 or stripped[0] == '#':
      continue
    if not line[0].isSpaceAscii:
      # New node
      currentNode = parseInt(stripped)
      result.addNode(currentNode)
    else:
      # Neighbor line
      let parts = stripped.splitWhitespace()
      if parts.len >= 1 and currentNode >= 0:
        let nb = parseInt(parts[0])
        if not result.hasEdge(currentNode, nb):
          result.addEdge(currentNode, nb)

proc parseMultilineAdjlist*(lines: openArray[string]): Graph[int] =
  ## Parse multiline adjacency list from string array.
  result = readMultilineAdjlist(lines.join("\n"))

proc generateMultilineAdjlist*[N](g: Graph[N]): seq[string] =
  ## Generate multiline adjacency list as sequence of lines.
  for line in g.writeMultilineAdjlist().splitLines():
    if line.len > 0:
      result.add(line)
