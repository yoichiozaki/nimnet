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
                   createUsing: string = "graph"): Graph[string] =
  ## Read an undirected graph from an edge list file.
  ## Lines starting with ``#`` are treated as comments.
  result = newGraph[string]()
  var f = newFileStream(filename, fmRead)
  if f == nil:
    raise newException(IOError, "Cannot open file: " & filename)
  defer: f.close()
  var line: string
  while f.readLine(line):
    let stripped = line.strip()
    if stripped.len == 0 or stripped[0] == '#':
      continue
    let parts = stripped.split(delimiter)
    if parts.len >= 2:
      let u = parts[0]
      let v = parts[1]
      var attr = newEdgeAttr()
      for i in 2 ..< parts.len:
        let kv = parts[i].split("=")
        if kv.len == 2:
          attr[kv[0]] = kv[1]
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
