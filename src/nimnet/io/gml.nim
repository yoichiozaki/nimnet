## GML (Graph Modelling Language) format I/O
##
## Read and write graphs in GML format.

import std/[tables, strutils, streams, strformat]
import ../types
import ../graph
import ../digraph

proc writeGml*[N](g: Graph[N], filename: string) =
  ## Write graph in GML format.
  var f = newFileStream(filename, fmWrite)
  if f == nil:
    raise newException(IOError, "Cannot open file: " & filename)
  defer: f.close()

  f.writeLine("graph [")
  f.writeLine("  directed 0")
  if g.name.len > 0:
    f.writeLine(fmt"  label ""{g.name}""")

  for node in g.nodes:
    f.writeLine("  node [")
    f.writeLine(fmt"    id {node}")
    let attrs = g.getNodeAttr(node)
    if "label" in attrs:
      f.writeLine(fmt"    label ""{attrs[""label""]}""")
    f.writeLine("  ]")

  for (u, v) in g.edges:
    f.writeLine("  edge [")
    f.writeLine(fmt"    source {u}")
    f.writeLine(fmt"    target {v}")
    let attrs = g.getEdgeAttr(u, v)
    if "weight" in attrs:
      f.writeLine(fmt"    weight {attrs[""weight""]}")
    f.writeLine("  ]")

  f.writeLine("]")

proc writeGml*[N](g: DiGraph[N], filename: string) =
  ## Write directed graph in GML format.
  var f = newFileStream(filename, fmWrite)
  if f == nil:
    raise newException(IOError, "Cannot open file: " & filename)
  defer: f.close()

  f.writeLine("graph [")
  f.writeLine("  directed 1")
  if g.name.len > 0:
    f.writeLine(fmt"  label ""{g.name}""")

  for node in g.nodes:
    f.writeLine("  node [")
    f.writeLine(fmt"    id {node}")
    f.writeLine("  ]")

  for (u, v) in g.edges:
    f.writeLine("  edge [")
    f.writeLine(fmt"    source {u}")
    f.writeLine(fmt"    target {v}")
    let attrs = g.getEdgeAttr(u, v)
    if "weight" in attrs:
      f.writeLine(fmt"    weight {attrs[""weight""]}")
    f.writeLine("  ]")

  f.writeLine("]")

type GmlToken = enum
  gmlEof, gmlWord, gmlString, gmlInt, gmlFloat, gmlOpen, gmlClose

type GmlLexer = object
  data: string
  pos: int

proc skipWhitespace(lex: var GmlLexer) =
  while lex.pos < lex.data.len:
    let c = lex.data[lex.pos]
    if c == '#':
      while lex.pos < lex.data.len and lex.data[lex.pos] != '\n':
        lex.pos.inc
    elif c in {' ', '\t', '\n', '\r'}:
      lex.pos.inc
    else:
      break

proc nextToken(lex: var GmlLexer): (GmlToken, string) =
  skipWhitespace(lex)
  if lex.pos >= lex.data.len:
    return (gmlEof, "")

  let c = lex.data[lex.pos]
  if c == '[':
    lex.pos.inc
    return (gmlOpen, "[")
  elif c == ']':
    lex.pos.inc
    return (gmlClose, "]")
  elif c == '"':
    lex.pos.inc
    var s = ""
    while lex.pos < lex.data.len and lex.data[lex.pos] != '"':
      s.add(lex.data[lex.pos])
      lex.pos.inc
    if lex.pos < lex.data.len:
      lex.pos.inc  # skip closing quote
    return (gmlString, s)
  elif c in {'0'..'9', '-', '+', '.'}:
    var s = ""
    var isFloat = false
    while lex.pos < lex.data.len:
      let ch = lex.data[lex.pos]
      if ch in {'0'..'9', '-', '+', '.', 'e', 'E'}:
        if ch == '.' or ch == 'e' or ch == 'E':
          isFloat = true
        s.add(ch)
        lex.pos.inc
      else:
        break
    if isFloat:
      return (gmlFloat, s)
    else:
      return (gmlInt, s)
  else:
    var s = ""
    while lex.pos < lex.data.len and lex.data[lex.pos] notin {' ', '\t', '\n', '\r', '[', ']', '"'}:
      s.add(lex.data[lex.pos])
      lex.pos.inc
    return (gmlWord, s)

proc readGml*(filename: string): Graph[int] =
  ## Read a GML file and return an undirected Graph[int].
  let data = readFile(filename)
  var lex = GmlLexer(data: data, pos: 0)

  result = newGraph[int]()
  var isDirected = false

  type ParseState = enum
    psTop, psGraph, psNode, psEdge

  var state = psTop
  var nodeId = -1
  var edgeSource = -1
  var edgeTarget = -1
  var edgeWeight = ""
  var depth = 0

  while true:
    let (tok, val) = lex.nextToken()
    if tok == gmlEof:
      break

    case state
    of psTop:
      if tok == gmlWord and val == "graph":
        let (t2, _) = lex.nextToken()
        if t2 == gmlOpen:
          state = psGraph
          depth = 1
    of psGraph:
      if tok == gmlWord and val == "directed":
        let (_, dirVal) = lex.nextToken()
        isDirected = dirVal == "1"
      elif tok == gmlWord and val == "node":
        let (t2, _) = lex.nextToken()
        if t2 == gmlOpen:
          state = psNode
          nodeId = -1
      elif tok == gmlWord and val == "edge":
        let (t2, _) = lex.nextToken()
        if t2 == gmlOpen:
          state = psEdge
          edgeSource = -1
          edgeTarget = -1
          edgeWeight = ""
      elif tok == gmlClose:
        break
    of psNode:
      if tok == gmlWord and val == "id":
        let (_, idVal) = lex.nextToken()
        nodeId = parseInt(idVal)
      elif tok == gmlClose:
        if nodeId >= 0:
          result.addNode(nodeId)
        state = psGraph
    of psEdge:
      if tok == gmlWord and val == "source":
        let (_, sVal) = lex.nextToken()
        edgeSource = parseInt(sVal)
      elif tok == gmlWord and val == "target":
        let (_, tVal) = lex.nextToken()
        edgeTarget = parseInt(tVal)
      elif tok == gmlWord and val == "weight":
        let (_, wVal) = lex.nextToken()
        edgeWeight = wVal
      elif tok == gmlClose:
        if edgeSource >= 0 and edgeTarget >= 0:
          if edgeWeight.len > 0:
            result.addWeightedEdge(edgeSource, edgeTarget, parseFloat(edgeWeight))
          else:
            result.addEdge(edgeSource, edgeTarget)
        state = psGraph
