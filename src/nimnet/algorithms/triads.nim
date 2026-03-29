## Triad census and classification for directed graphs.
##
## A **triad** is a subgraph of 3 nodes in a directed graph.
## There are 16 possible triad types (isomorphism classes),
## classified using the M-A-N notation (Mutual, Asymmetric, Null).
##
## - ``triadicCensus(dg)`` — count all 16 triad types
## - ``triadType(dg, u, v, w)`` — classify a single triad
## - ``allTriads(dg)`` — enumerate all triads
## - ``isTriad(dg)`` — check if graph is a 3-node directed graph

import std/[tables, sets]
import ../digraph

const
  TRIAD_NAMES* = [
    "003", "012", "102", "021D", "021U", "021C",
    "111D", "111U", "030T", "030C", "201",
    "120D", "120U", "120C", "210", "300"
  ]
    ## The 16 triad type names in M-A-N notation.

# Map from 6-bit edge pattern to triad type index.
# Bits: u->v, v->u, u->w, w->u, v->w, w->v
# (each bit = 1 if that directed edge exists)
proc buildTriadMap(): array[64, int] =
  # Initialize all to -1
  for i in 0 ..< 64:
    result[i] = -1

  # 003: no edges
  result[0b000000] = 0

  # 012: exactly one directed edge (6 orientations)
  result[0b100000] = 1  # u->v
  result[0b010000] = 1  # v->u
  result[0b001000] = 1  # u->w
  result[0b000100] = 1  # w->u
  result[0b000010] = 1  # v->w
  result[0b000001] = 1  # w->v

  # 102: one mutual pair, third isolated
  result[0b110000] = 2  # u<->v
  result[0b001100] = 2  # u<->w
  result[0b000011] = 2  # v<->w

  # 021D: A<-B->C (one node has out-degree 2)
  result[0b010010] = 3  # v->u, v->w
  result[0b100001] = 3  # u->v, w->v => w<-v, u<-... no...
  # Let me think more carefully about the mapping.
  # u->v = bit 5, v->u = bit 4, u->w = bit 3, w->u = bit 2, v->w = bit 1, w->v = bit 0
  # 021D: one node points to both others
  # v->u and v->w: 010010 = v->u, v->w
  result[0b010010] = 3
  # u->v and u->w: 101000 = u->v, u->w
  result[0b101000] = 3
  # w->u and w->v: 000101 = w->u, w->v
  result[0b000101] = 3

  # 021U: A->B<-C (one node has in-degree 2)
  # u->v and w->v: 100001 = u->v, w->v
  result[0b100001] = 4
  # v->u and w->u: 010100 = v->u, w->u
  result[0b010100] = 4
  # u->w and v->w: 001010 = u->w, v->w
  result[0b001010] = 4

  # 021C: A->B->C (chain, 2 edges in same direction path)
  # u->v and v->w: 100010 = u->v, v->w
  result[0b100010] = 5
  # v->u and u->w: 011000 = v->u, u->w
  result[0b011000] = 5
  # u->w and w->v: 001001 = u->w, w->v
  result[0b001001] = 5
  # w->u and u->v: 100100 = u->v, w->u
  result[0b100100] = 5
  # v->w and w->u: 000110 = v->w, w->u
  result[0b000110] = 5
  # w->v and v->u: 010001 = v->u, w->v
  result[0b010001] = 5

  # 111D: one mutual + one asymmetric pointing into mutual
  # u<->v and w->v: 110001
  result[0b110001] = 6
  # u<->v and w->u: 110100
  result[0b110100] = 6
  # u<->w and v->w: 001110
  result[0b001110] = 6
  # u<->w and v->u: 011100
  result[0b011100] = 6
  # v<->w and u->w: 001011
  result[0b001011] = 6
  # v<->w and u->v: 100011
  result[0b100011] = 6

  # 111U: one mutual + one asymmetric pointing out of mutual
  # u<->v and v->w: 110010
  result[0b110010] = 7
  # u<->v and u->w: 111000
  result[0b111000] = 7
  # u<->w and w->v: 001101
  result[0b001101] = 7
  # u<->w and u->v: 101100
  result[0b101100] = 7
  # v<->w and w->u: 000111
  result[0b000111] = 7
  # v<->w and v->u: 010011
  result[0b010011] = 7

  # 030T: A->B<-C, A->C (transitive-like, 3 directed edges, feed-forward)
  # u->v, u->w, w->v: 101001
  result[0b101001] = 8
  # u->v, v->w, u->w ... no that's a cycle? No, u->v, v->w, u->w has no cycle
  # Actually 030T is: 3 asymmetric edges forming a transitive triple
  # u->v, u->w, v->w: 101010 — this is a transitive triple!
  result[0b101010] = 8
  # The other 3 rotations:
  # v->u, v->w, u->w: 011010 — wait, v->u, v->w means the "source" is v
  # 030T has exactly one "source" node pointing to both others, and one of the others also points to the third
  # u->v, w->u, w->v: 100101 — w is source, w->u, w->v, and u->v
  result[0b100101] = 8
  # v->u, w->u, v->w: 010110 — hmm
  # Let me be more systematic. 030T =  3 asymmetric, transitive triple
  # That means: a->b, a->c, b->c (or equivalently a->b, b->c, a->c)
  # Permutations of (u,v,w) playing (a,b,c):
  # (u=a,v=b,w=c): u->v,u->w,v->w = 101010
  result[0b101010] = 8
  # (u=a,v=c,w=b): u->v,u->w,w->v = 101001
  result[0b101001] = 8
  # (v=a,u=b,w=c): v->u,v->w,u->w = 011010
  result[0b011010] = 8
  # (v=a,u=c,w=b): v->u,v->w,w->u = 010110 ... wait that's v->u, v->w, w->u
  # but we need a->b, a->c, b->c. With a=v, b=w, c=u: v->w, v->u, w->u = 010110
  result[0b010110] = 8
  # (w=a,u=b,v=c): w->u,w->v,u->v = 100101
  result[0b100101] = 8
  # (w=a,u=c,v=b): w->u,w->v,v->u = 010101
  result[0b010101] = 8

  # 030C: directed 3-cycle (A->B->C->A)
  # u->v, v->w, w->u: 100010 + 000100 = 100110
  result[0b100110] = 9
  # u->w, w->v, v->u: 001001 + 010000 = 011001
  result[0b011001] = 9

  # 201: two mutual, one null
  # u<->v with u<->w: 111100
  result[0b111100] = 10
  # u<->v with v<->w: 110011
  result[0b110011] = 10
  # u<->w with v<->w: 001111
  result[0b001111] = 10

  # 120D: one mutual + two asymmetric forming out-star from mutual node
  # u<->w, v->u, v->w: 010111
  # Let me think again. 120D has 1 mutual, 2 asymmetric, total 4 directed edges
  # Pattern: A<->B, C->A, C->B (the non-mutual node has out-degree 2)
  # u<->v, w->u, w->v: 110101
  result[0b110101] = 11
  # u<->w, v->u, v->w: 011110
  result[0b011110] = 11
  # v<->w, u->v, u->w: 101011 ... wait, that's wrong
  # v<->w: bits 1,0 = 11. u->v: bit 5 = 1. u->w: bit 3 = 1.
  # 101011 = u->v, u->w, v->w, w->v
  # Hmm but that's u->v, u->w, v<->w — which is 120D if u is the out-star center
  # Wait no. 120D is: mutual between A-B, and C points to both A and B
  # So A<->B, C->A, C->B
  # Let's enumerate:
  # mutual=uv, star=w: u<->v, w->u, w->v = 110000 | 000101 = 110101
  result[0b110101] = 11
  # mutual=uw, star=v: u<->w, v->u, v->w = 001100 | 010010 = 011110
  result[0b011110] = 11
  # mutual=vw, star=u: v<->w, u->v, u->w = 000011 | 101000 = 101011
  result[0b101011] = 11

  # 120U: one mutual + two asymmetric pointing into mutual
  # A<->B, A->C, B->C (the mutual pair both point to the third)
  # mutual=uv, target=w: u<->v, u->w, v->w = 110000 | 001010 = 111010
  result[0b111010] = 12
  # mutual=uw, target=v: u<->w, u->v, w->v = 001100 | 100001 = 101101
  result[0b101101] = 12
  # mutual=vw, target=u: v<->w, v->u, w->u = 000011 | 010100 = 010111
  result[0b010111] = 12

  # 120C: one mutual + two asymmetric forming chain through non-mutual
  # A<->B, C->A, B->C (chain going through C)
  # mutual=uv: u<->v, w->u, v->w = 110000 | 000100 | 000010 = 110110
  result[0b110110] = 13
  # mutual=uv: u<->v, u->w, w->v = 110000 | 001000 | 000001 = 111001
  result[0b111001] = 13
  # mutual=uw: u<->w, v->u, w->v = 001100 | 010000 | 000001 = 011101
  result[0b011101] = 13
  # mutual=uw: u<->w, u->v, v->w ... wait
  # Let me reconsider 120C. It's 1 mutual, 2 asymmetric, and forms a cycle with the mutual pair.
  # A<->B, A->C, C->B or A<->B, B->C, C->A
  # mutual=uv, u->w, w->v: 110000 | 001000 | 000001 = 111001
  result[0b111001] = 13
  # mutual=uv, v->w, w->u: 110000 | 000010 | 000100 = 110110
  result[0b110110] = 13
  # mutual=uw, u->v, v->w ... no, that doesn't involve mutual uw in a cycle
  # mutual=uw, w->v, v->u: 001100 | 000001 | 010000 = 011101
  result[0b011101] = 13
  # mutual=uw, u->v, v->w: wait, this makes u->v->w with u<->w, so cycle! 
  # 001100 | 100000 | 000010 = 101110
  result[0b101110] = 13
  # mutual=vw, v->u, u->w: 000011 | 010000 | 001000 = 011011
  result[0b011011] = 13
  # mutual=vw, w->u, u->v: 000011 | 000100 | 100000 = 100111
  result[0b100111] = 13

  # 210: two mutual + one asymmetric
  # A<->B, A<->C, B->C (or B<-C)
  # mutual=uv,uw, v->w: 111100 | 000010 = 111110
  result[0b111110] = 14
  # mutual=uv,uw, w->v: 111100 | 000001 = 111101
  result[0b111101] = 14
  # mutual=uv,vw, u->w: 110011 | 001000 = 111011
  result[0b111011] = 14
  # mutual=uv,vw, w->u: 110011 | 000100 = 110111
  result[0b110111] = 14
  # mutual=uw,vw, u->v: 001111 | 100000 = 101111
  result[0b101111] = 14
  # mutual=uw,vw, v->u: 001111 | 010000 = 011111
  result[0b011111] = 14

  # 300: three mutual pairs (all edges)
  result[0b111111] = 15

const triadMap = buildTriadMap()

proc classifyTriad[N](dg: DiGraph[N], u, v, w: N): int =
  ## Classify the triad (u,v,w) and return its index into TRIAD_NAMES.
  var code = 0
  if dg.hasEdge(u, v): code = code or 0b100000
  if dg.hasEdge(v, u): code = code or 0b010000
  if dg.hasEdge(u, w): code = code or 0b001000
  if dg.hasEdge(w, u): code = code or 0b000100
  if dg.hasEdge(v, w): code = code or 0b000010
  if dg.hasEdge(w, v): code = code or 0b000001
  result = triadMap[code]

proc triadicCensus*[N](dg: DiGraph[N]): Table[string, int] =
  ## Count all 16 types of triads in a directed graph.
  ## Returns a table mapping triad type name to count.
  ##
  ## **Complexity:** O(V^3) — enumerates all node triples.
  for name in TRIAD_NAMES:
    result[name] = 0

  var nodeList: seq[N]
  for nd in dg.nodes:
    nodeList.add(nd)

  let n = nodeList.len
  if n < 3:
    return

  for i in 0 ..< n:
    for j in (i + 1) ..< n:
      for k in (j + 1) ..< n:
        let ttype = classifyTriad(dg, nodeList[i], nodeList[j], nodeList[k])
        if ttype >= 0:
          result[TRIAD_NAMES[ttype]] += 1

proc triadType*[N](dg: DiGraph[N], u, v, w: N): string =
  ## Classify the triad formed by nodes u, v, w and return its
  ## M-A-N type name (e.g. "030T", "300").
  let idx = classifyTriad(dg, u, v, w)
  if idx < 0:
    raise newException(NimNetError, "Invalid triad classification")
  result = TRIAD_NAMES[idx]

iterator allTriads*[N](dg: DiGraph[N]): (N, N, N) =
  ## Enumerate all triples of nodes as triads.
  var nodeList: seq[N]
  for nd in dg.nodes:
    nodeList.add(nd)
  let n = nodeList.len
  for i in 0 ..< n:
    for j in (i + 1) ..< n:
      for k in (j + 1) ..< n:
        yield (nodeList[i], nodeList[j], nodeList[k])

func isTriad*[N](dg: DiGraph[N]): bool =
  ## Return true if the digraph has exactly 3 nodes.
  dg.numberOfNodes() == 3
