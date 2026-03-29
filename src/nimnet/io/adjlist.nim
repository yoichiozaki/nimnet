## Adjacency list I/O

import std/[strutils, streams]
import ../types
import ../graph

proc writeAdjlist*[N](g: Graph[N], filename: string, delimiter: string = " ") =
  ## Write graph as adjacency list.
  var f = newFileStream(filename, fmWrite)
  if f == nil:
    raise newException(IOError, "Cannot open file: " & filename)
  defer: f.close()
  for n in g.nodes:
    var line = $n
    for neighbor in g.neighbors(n):
      line &= delimiter & $neighbor
    f.writeLine(line)

proc readAdjlist*(filename: string, delimiter: string = " "): Graph[string] =
  ## Read graph from adjacency list file.
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
    if parts.len >= 1:
      let node = parts[0]
      result.addNode(node)
      for i in 1 ..< parts.len:
        if parts[i].len > 0:
          result.addEdge(node, parts[i])
