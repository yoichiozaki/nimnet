## Pajek (.net) format reader/writer.
##
## Pajek format has sections:
## - ``*Vertices n`` — node list
## - ``*Edges`` — undirected edges
## - ``*Arcs`` — directed edges

import std/[streams, strutils, strformat, tables]
import ../types, ../graph, ../digraph

proc writePajek*[N](g: Graph[N], filename: string) =
  ## Write an undirected graph in Pajek .net format.
  let fs = newFileStream(filename, fmWrite)
  if fs.isNil:
    raise newException(IOError, fmt"Cannot open file: {filename}")
  defer: fs.close()

  var nodeList: seq[N]
  var nodeIdx = initTable[N, int]()
  for n in g.nodes:
    nodeList.add(n)
  for i, n in nodeList:
    nodeIdx[n] = i + 1  # Pajek is 1-indexed

  fs.writeLine(fmt"*Vertices {nodeList.len}")
  for i, n in nodeList:
    fs.writeLine(fmt"{i + 1} ""{n}""")

  fs.writeLine("*Edges")
  for (u, v) in g.edges:
    if nodeIdx[u] < nodeIdx[v]:  # avoid duplicates
      let attr = g.getEdgeAttr(u, v)
      let w = attr.getWeight(1.0)
      fs.writeLine(fmt"{nodeIdx[u]} {nodeIdx[v]} {w}")

proc writePajek*[N](g: DiGraph[N], filename: string) =
  ## Write a directed graph in Pajek .net format.
  let fs = newFileStream(filename, fmWrite)
  if fs.isNil:
    raise newException(IOError, fmt"Cannot open file: {filename}")
  defer: fs.close()

  var nodeList: seq[N]
  var nodeIdx = initTable[N, int]()
  for n in g.nodes:
    nodeList.add(n)
  for i, n in nodeList:
    nodeIdx[n] = i + 1

  fs.writeLine(fmt"*Vertices {nodeList.len}")
  for i, n in nodeList:
    fs.writeLine(fmt"{i + 1} ""{n}""")

  fs.writeLine("*Arcs")
  for (u, v) in g.edges:
    let attr = g.getEdgeAttr(u, v)
    let w = attr.getWeight(1.0)
    fs.writeLine(fmt"{nodeIdx[u]} {nodeIdx[v]} {w}")

proc readPajek*(filename: string): Graph[int] =
  ## Read an undirected graph from Pajek .net format.
  ## Returns Graph[int] with integer node labels.
  let fs = newFileStream(filename, fmRead)
  if fs.isNil:
    raise newException(IOError, fmt"Cannot open file: {filename}")
  defer: fs.close()

  result = newGraph[int]()
  var line: string
  var section = ""
  var numVertices = 0

  while fs.readLine(line):
    line = line.strip()
    if line.len == 0 or line[0] == '%':
      continue

    let lower = line.toLowerAscii()
    if lower.startsWith("*vertices"):
      section = "vertices"
      let parts = line.splitWhitespace()
      if parts.len >= 2:
        numVertices = parseInt(parts[1])
      for i in 1 .. numVertices:
        result.addNode(i)
      continue
    elif lower.startsWith("*edges"):
      section = "edges"
      continue
    elif lower.startsWith("*arcs"):
      section = "arcs"
      continue

    if section == "vertices":
      discard  # nodes already added
    elif section == "edges" or section == "arcs":
      let parts = line.splitWhitespace()
      if parts.len >= 2:
        let u = parseInt(parts[0])
        let v = parseInt(parts[1])
        if parts.len >= 3:
          var attr = newEdgeAttr()
          attr.weight = parseFloat(parts[2])
          result.addEdge(u, v, attr)
        else:
          result.addEdge(u, v)

proc readPajekDigraph*(filename: string): DiGraph[int] =
  ## Read a directed graph from Pajek .net format.
  let fs = newFileStream(filename, fmRead)
  if fs.isNil:
    raise newException(IOError, fmt"Cannot open file: {filename}")
  defer: fs.close()

  result = newDiGraph[int]()
  var line: string
  var section = ""
  var numVertices = 0

  while fs.readLine(line):
    line = line.strip()
    if line.len == 0 or line[0] == '%':
      continue

    let lower = line.toLowerAscii()
    if lower.startsWith("*vertices"):
      section = "vertices"
      let parts = line.splitWhitespace()
      if parts.len >= 2:
        numVertices = parseInt(parts[1])
      for i in 1 .. numVertices:
        result.addNode(i)
      continue
    elif lower.startsWith("*arcs"):
      section = "arcs"
      continue
    elif lower.startsWith("*edges"):
      section = "edges"
      continue

    if section == "arcs" or section == "edges":
      let parts = line.splitWhitespace()
      if parts.len >= 2:
        let u = parseInt(parts[0])
        let v = parseInt(parts[1])
        if parts.len >= 3:
          var attr = newEdgeAttr()
          attr.weight = parseFloat(parts[2])
          result.addEdge(u, v, attr)
        else:
          result.addEdge(u, v)
