## Graph6 and Sparse6 format reader/writer.
##
## Graph6 is a compact ASCII encoding for simple undirected graphs.
## Sparse6 is optimized for sparse graphs.
## Both formats encode the upper triangle of the adjacency matrix.

import std/[strutils, tables, algorithm]
import ../types, ../graph

proc encodeN(n: int): string =
  ## Encode the number of vertices in Graph6 format.
  if n <= 62:
    result = $chr(n + 63)
  elif n <= 258047:
    result = $chr(126)
    result.add(chr((n shr 12) + 63))
    result.add(chr(((n shr 6) and 63) + 63))
    result.add(chr((n and 63) + 63))
  else:
    result = $chr(126) & $chr(126)
    result.add(chr((n shr 30) + 63))
    result.add(chr(((n shr 24) and 63) + 63))
    result.add(chr(((n shr 18) and 63) + 63))
    result.add(chr(((n shr 12) and 63) + 63))
    result.add(chr(((n shr 6) and 63) + 63))
    result.add(chr((n and 63) + 63))

proc decodeN(s: string, pos: var int): int =
  ## Decode the number of vertices from Graph6 format.
  if s[pos] != chr(126):
    result = ord(s[pos]) - 63
    pos += 1
  elif s[pos + 1] != chr(126):
    pos += 1
    result = (ord(s[pos]) - 63) shl 12
    result = result or ((ord(s[pos + 1]) - 63) shl 6)
    result = result or (ord(s[pos + 2]) - 63)
    pos += 3
  else:
    pos += 2
    result = 0
    for i in 0 ..< 6:
      result = (result shl 6) or (ord(s[pos + i]) - 63)
    pos += 6

proc writeGraph6*[N](g: Graph[N]): string =
  ## Encode an undirected graph as a Graph6 string.
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)
  let n = nodeList.len

  # Map nodes to indices 0..n-1
  var nodeIdx = initTable[N, int]()
  for i, nd in nodeList:
    nodeIdx[nd] = i

  result = encodeN(n)

  # Build bit vector from upper triangle of adjacency matrix
  var bits: seq[int]
  for j in 1 ..< n:
    for i in 0 ..< j:
      if g.hasEdge(nodeList[i], nodeList[j]):
        bits.add(1)
      else:
        bits.add(0)

  # Pad to multiple of 6
  while bits.len mod 6 != 0:
    bits.add(0)

  # Encode 6 bits per character
  var i = 0
  while i < bits.len:
    var val = 0
    for b in 0 ..< 6:
      val = (val shl 1) or bits[i + b]
    result.add(chr(val + 63))
    i += 6

proc readGraph6*(s: string): Graph[int] =
  ## Decode a Graph6 string into an undirected graph.
  var data = s.strip()
  if data.len > 0 and data[0] == '>':
    # Skip optional header ">>graph6<<"
    let idx = data.find("<<")
    if idx >= 0:
      data = data[idx + 2 .. ^1]

  var pos = 0
  let n = decodeN(data, pos)

  result = newGraph[int]()
  for i in 0 ..< n:
    result.addNode(i)

  if n <= 1:
    return

  # Decode bit vector
  var bits: seq[int]
  while pos < data.len:
    let val = ord(data[pos]) - 63
    for b in countdown(5, 0):
      bits.add((val shr b) and 1)
    pos += 1

  # Fill upper triangle
  var bitIdx = 0
  for j in 1 ..< n:
    for i in 0 ..< j:
      if bitIdx < bits.len and bits[bitIdx] == 1:
        result.addEdge(i, j)
      bitIdx += 1

proc writeSparse6*[N](g: Graph[N]): string =
  ## Encode an undirected graph as a Sparse6 string.
  var nodeList: seq[N]
  for n in g.nodes:
    nodeList.add(n)
  let n = nodeList.len

  var nodeIdx = initTable[N, int]()
  for i, nd in nodeList:
    nodeIdx[nd] = i

  result = ":"
  result.add(encodeN(n))

  if n <= 1:
    return

  # Number of bits needed to represent n-1
  var k = 0
  var tmp = n - 1
  while tmp > 0:
    k += 1
    tmp = tmp shr 1
  if k == 0:
    k = 1

  # Collect edges as sorted pairs (i, j) where i < j
  var edges: seq[(int, int)]
  for (u, v) in g.edges:
    let ui = nodeIdx[u]
    let vi = nodeIdx[v]
    if ui < vi:
      edges.add((ui, vi))
    elif vi < ui:
      edges.add((vi, ui))

  # Sort by (j, i)
  edges.sort(proc(a, b: (int, int)): int =
    if a[1] != b[1]: return cmp(a[1], b[1])
    return cmp(a[0], b[0])
  )

  # Encode edges as bits
  var bits: seq[int]
  var v = 0
  for (i, j) in edges:
    if j == v:
      bits.add(0)
    elif j == v + 1:
      bits.add(1)
      v = j
    else:
      v = j
      bits.add(1)
      for b in countdown(k - 1, 0):
        bits.add((v shr b) and 1)
      bits.add(0)
    # Encode i in k bits
    for b in countdown(k - 1, 0):
      bits.add((i shr b) and 1)

  # Pad to multiple of 6
  let padLen = (6 - (bits.len mod 6)) mod 6
  for p in 0 ..< padLen:
    bits.add(1)

  # Convert to characters
  var idx = 0
  while idx < bits.len:
    var val = 0
    for b in 0 ..< 6:
      val = (val shl 1) or bits[idx + b]
    result.add(chr(val + 63))
    idx += 6

proc readSparse6*(s: string): Graph[int] =
  ## Decode a Sparse6 string into an undirected graph.
  var data = s.strip()
  if data.len > 0 and data[0] == ':':
    data = data[1 .. ^1]

  var pos = 0
  let n = decodeN(data, pos)

  result = newGraph[int]()
  for i in 0 ..< n:
    result.addNode(i)

  if n <= 1:
    return

  # Number of bits for n-1
  var k = 0
  var tmp = n - 1
  while tmp > 0:
    k += 1
    tmp = tmp shr 1
  if k == 0:
    k = 1

  # Decode remaining data to bit stream
  var bits: seq[int]
  while pos < data.len:
    let val = ord(data[pos]) - 63
    for b in countdown(5, 0):
      bits.add((val shr b) and 1)
    pos += 1

  # Decode edge list
  var bitIdx = 0
  var v = 0
  while bitIdx + k < bits.len:
    let b = bits[bitIdx]
    bitIdx += 1

    if b == 1:
      v += 1
      if v >= n:
        break

    # Read k-bit vertex number
    var x = 0
    for i in 0 ..< k:
      if bitIdx < bits.len:
        x = (x shl 1) or bits[bitIdx]
        bitIdx += 1

    if x < n and v < n and x <= v:
      result.addEdge(x, v)
