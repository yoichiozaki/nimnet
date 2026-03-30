## Expander graph generators

import ../graph

proc margulisGabberGalilGraph*(p: int): Graph[int] =
  ## Generate the Margulis-Gabber-Galil expander graph on p*p nodes.
  ## Nodes are pairs (x, y) in Z_p x Z_p, encoded as x*p + y.
  result = newGraph[int](capacity = p * p)
  for i in 0 ..< p * p:
    result.addNode(i)
  for x in 0 ..< p:
    for y in 0 ..< p:
      let node = x * p + y
      # Neighbors: (x, (y+2x+1) mod p), (x, (y+2x) mod p),
      #            ((x+2y+1) mod p, y), ((x+2y) mod p, y)
      let targets = [
        x * p + ((y + 2*x + 1) mod p),
        x * p + ((y + 2*x) mod p),
        ((x + 2*y + 1) mod p) * p + y,
        ((x + 2*y) mod p) * p + y
      ]
      for t in targets:
        if t != node and not result.hasEdge(node, t):
          result.addEdge(node, t)

proc chordalCycleGraph*(p: int): Graph[int] =
  ## Generate a chordal cycle graph on p nodes.
  ## A cycle with additional chords connecting i to (i*i) mod p.
  result = newGraph[int](capacity = p)
  for i in 0 ..< p:
    result.addNode(i)
    result.addEdge(i, (i + 1) mod p)
  for i in 1 ..< p:
    let target = (i * i) mod p
    if not result.hasEdge(i, target):
      result.addEdge(i, target)

proc paleyGraph*(p: int): Graph[int] =
  ## Generate the Paley graph of order p.
  ## p must be a prime ≡ 1 (mod 4).
  ## Two nodes i, j are adjacent iff (i-j) is a quadratic residue mod p.
  result = newGraph[int](capacity = p)
  for i in 0 ..< p:
    result.addNode(i)
  # Compute quadratic residues
  var qr: set[uint16]  # works for p up to 65535
  for i in 1 ..< p:
    qr.incl(uint16((i * i) mod p))
  for i in 0 ..< p:
    for j in i + 1 ..< p:
      let diff = ((j - i) mod p + p) mod p
      if uint16(diff) in qr:
        result.addEdge(i, j)
