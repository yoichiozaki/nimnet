## Edge list I/O

import std/[strutils, streams, tables]
import ../types
import ../graph
import ../digraph

proc writeEdgelist*[N](g: Graph[N], filename: string, delimiter: string = " ",
                        writeData: bool = true) =
  ## Write an undirected graph to an edge list file.
  ## Each line contains ``u<delimiter>v[<delimiter>key=val ...]``.
  var f = newFileStream(filename, fmWrite)
  if f == nil:
    raise newException(IOError, "Cannot open file: " & filename)
  defer: f.close()
  for (u, v, attr) in g.edgesWithAttr:
    var line = $u & delimiter & $v
    if writeData and attr.len > 0:
      for k, val in attr:
        line &= delimiter & k & "=" & val
    f.writeLine(line)

iterator readEdgelistEntries(filename, delimiter: string):
    tuple[u, v: string, attr: EdgeAttr] =
  if delimiter.len == 0:
    raise newException(ValueError, "Edge list delimiter must not be empty")
  var f = newFileStream(filename, fmRead)
  if f == nil:
    raise newException(IOError, "Cannot open file: " & filename)
  defer: f.close()
  var line: string
  var lineNumber = 0
  while f.readLine(line):
    inc lineNumber
    let stripped = line.strip()
    if stripped.len == 0 or stripped[0] == '#':
      continue
    var parts = if delimiter == " ": stripped.splitWhitespace()
                else: stripped.split(delimiter)
    for part in parts.mitems:
      part = part.strip()
    if parts.len < 2 or parts[0].len == 0 or parts[1].len == 0:
      raise newException(ValueError, "Invalid edge list on line " & $lineNumber &
        ": expected two nonempty node names")
    var attr = newEdgeAttr()
    for i in 2 ..< parts.len:
      let separator = parts[i].find('=')
      if separator <= 0:
        raise newException(ValueError, "Invalid edge attribute on line " &
          $lineNumber & ": expected key=value")
      let key = parts[i][0 ..< separator].strip()
      let value = parts[i][separator + 1 .. ^1].strip()
      if key.len == 0:
        raise newException(ValueError, "Empty edge attribute name on line " &
          $lineNumber)
      if key == "weight":
        attr.weight = parseFloat(value)
      else:
        attr.extra[key] = value
    yield (parts[0], parts[1], attr)

proc readEdgelist*(filename: string, delimiter: string = " ",
                   createUsing: string = "graph"): Graph[string] =
  ## Read an undirected graph from ``u<delimiter>v[<delimiter>key=value ...]`` lines.
  ## The default delimiter accepts any whitespace; # starts a comment line.
  ## Malformed input raises ``ValueError`` and file errors raise ``IOError``.
  ## Only ``createUsing = "graph"`` is supported; other selectors raise
  ## ``NimNetError``. Use ``readEdgelistDirected`` for a directed graph.
  if createUsing != "graph":
    raise newException(NimNetError, "Unsupported createUsing=\"" & createUsing &
      "\"; readEdgelist requires \"graph\" and returns Graph[string]. " &
      "Use readEdgelistDirected for DiGraph[string]")
  result = newGraph[string]()
  for (u, v, attr) in readEdgelistEntries(filename, delimiter):
    result.addEdge(u, v, attr)

proc readEdgelistDirected*(filename: string,
                          delimiter: string = " "): DiGraph[string] =
  ## Read a directed edge list, preserving arc directions, weights and attributes.
  ## Delimiters, comments and errors follow ``readEdgelist``.
  result = newDiGraph[string]()
  for (u, v, attr) in readEdgelistEntries(filename, delimiter):
    result.addEdge(u, v, attr)

proc writeEdgelistDigraph*[N](g: DiGraph[N], filename: string, delimiter: string = " ") =
  ## Write directed graph to an edge list file.
  var f = newFileStream(filename, fmWrite)
  if f == nil:
    raise newException(IOError, "Cannot open file: " & filename)
  defer: f.close()
  for (u, v, attr) in g.edgesWithAttr:
    var line = $u & delimiter & $v
    for k, val in attr:
      line &= delimiter & k & "=" & val
    f.writeLine(line)
