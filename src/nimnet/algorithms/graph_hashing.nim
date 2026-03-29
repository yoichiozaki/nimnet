## Weisfeiler-Lehman graph hashing.
##
## WL hashing iteratively refines node labels based on neighborhood
## structure. It is widely used for graph classification, approximate
## isomorphism testing, and graph neural networks.
##
## - ``weisfeilerLehmanHash(g)`` — whole-graph WL hash
## - ``weisfeilerLehmanSubgraphHashes(g)`` — per-node WL hashes

import std/[tables, sets, hashes, algorithm, strutils]
import ../graph
import ../digraph

proc weisfeilerLehmanHash*[N](g: Graph[N], iterations = 3,
    digestSize = 16): string =
  ## Return the Weisfeiler-Lehman hash of an undirected graph.
  ##
  ## The hash is computed by iteratively refining node labels based on
  ## multi-set neighbor labels, then hashing the sorted final label multiset.
  ##
  ## Parameters:
  ## - ``iterations``: number of WL iterations (default 3)
  ## - ``digestSize``: length of the hex hash string (default 16)

  var labels = initTable[N, string]()

  # Initialize labels with node degree
  for n in g.nodes:
    labels[n] = $g.degree(n)

  for iter in 0 ..< iterations:
    var newLabels = initTable[N, string]()
    for n in g.nodes:
      var neighborLabels: seq[string]
      for v in g.neighbors(n):
        neighborLabels.add(labels[v])
      neighborLabels.sort()
      newLabels[n] = labels[n] & ":" & neighborLabels.join(",")
    labels = newLabels

  # Collect all final labels, sort, and hash
  var allLabels: seq[string]
  for n in g.nodes:
    allLabels.add(labels[n])
  allLabels.sort()

  var h: Hash = 0
  for lbl in allLabels:
    h = h !& hash(lbl)
  h = !$h

  # Convert to hex string
  let hexStr = toHex(h)
  if hexStr.len >= digestSize:
    result = hexStr[0 ..< digestSize]
  else:
    result = hexStr

proc weisfeilerLehmanSubgraphHashes*[N](g: Graph[N],
    iterations = 3): Table[N, seq[string]] =
  ## Return per-node WL hashes at each iteration.
  ## Result maps each node to a sequence of hash strings (one per iteration).

  var labels = initTable[N, string]()

  for n in g.nodes:
    labels[n] = $g.degree(n)

  for n in g.nodes:
    result[n] = @[]

  for iter in 0 ..< iterations:
    var newLabels = initTable[N, string]()
    for n in g.nodes:
      var neighborLabels: seq[string]
      for v in g.neighbors(n):
        neighborLabels.add(labels[v])
      neighborLabels.sort()
      newLabels[n] = labels[n] & ":" & neighborLabels.join(",")
    labels = newLabels

    for n in g.nodes:
      var h: Hash = 0
      h = h !& hash(labels[n])
      h = !$h
      result[n].add(toHex(h))

proc weisfeilerLehmanHash*[N](dg: DiGraph[N], iterations = 3,
    digestSize = 16): string =
  ## Return the Weisfeiler-Lehman hash of a directed graph.
  ## Uses both in-degree and out-degree for initial labels, and
  ## distinguishes successor/predecessor neighborhoods.

  var labels = initTable[N, string]()

  for n in dg.nodes:
    labels[n] = $dg.inDegree(n) & "," & $dg.outDegree(n)

  for iter in 0 ..< iterations:
    var newLabels = initTable[N, string]()
    for n in dg.nodes:
      var succLabels: seq[string]
      for v in dg.successors(n):
        succLabels.add(labels[v])
      succLabels.sort()
      var predLabels: seq[string]
      for v in dg.predecessors(n):
        predLabels.add(labels[v])
      predLabels.sort()
      newLabels[n] = labels[n] & "|s:" & succLabels.join(",") & "|p:" & predLabels.join(",")
    labels = newLabels

  var allLabels: seq[string]
  for n in dg.nodes:
    allLabels.add(labels[n])
  allLabels.sort()

  var h: Hash = 0
  for lbl in allLabels:
    h = h !& hash(lbl)
  h = !$h

  let hexStr = toHex(h)
  if hexStr.len >= digestSize:
    result = hexStr[0 ..< digestSize]
  else:
    result = hexStr
