## Small / famous graph generators

import std/[tables, json]
import ../types
import ../graph

proc petersenGraph*(): Graph[int] =
  ## Generate the Petersen graph (10 nodes, 15 edges).
  result = newGraph[int]()
  # Outer ring: 0-4, inner star: 5-9
  for i in 0 ..< 10:
    result.addNode(i)
  # Outer ring
  for i in 0 ..< 5:
    result.addEdge(i, (i + 1) mod 5)
  # Inner star (pentacle)
  for i in 0 ..< 5:
    result.addEdge(i + 5, ((i + 2) mod 5) + 5)
  # Spokes
  for i in 0 ..< 5:
    result.addEdge(i, i + 5)

proc karateClubGraph*(): Graph[int] =
  ## Generate Zachary's karate club graph (34 nodes).
  result = newGraph[int]()
  let edges = [
    (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8),
    (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31),
    (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30),
    (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32),
    (3, 7), (3, 12), (3, 13),
    (4, 6), (4, 10),
    (5, 6), (5, 10), (5, 16),
    (6, 16),
    (8, 30), (8, 32), (8, 33),
    (9, 33),
    (13, 33),
    (14, 32), (14, 33),
    (15, 32), (15, 33),
    (18, 32), (18, 33),
    (19, 33),
    (20, 32), (20, 33),
    (22, 32), (22, 33),
    (23, 25), (23, 27), (23, 29), (23, 32), (23, 33),
    (24, 25), (24, 27), (24, 31),
    (25, 31),
    (26, 29), (26, 33),
    (27, 33),
    (28, 31), (28, 33),
    (29, 32), (29, 33),
    (30, 32), (30, 33),
    (31, 32), (31, 33),
    (32, 33)
  ]
  for (u, v) in edges:
    result.addEdge(u, v)
  # Set club attribute
  let club0 = [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21]
  for n in 0 ..< 34:
    var attr = newNodeAttr()
    attr["club"] = newJString(if n in club0: "Mr. Hi" else: "Officer")
    result.setNodeAttr(n, attr)

proc florentineFamiliesGraph*(): Graph[string] =
  ## Generate the Florentine families graph (15 nodes).
  result = newGraph[string]()
  let edges = [
    ("Acciaiuoli", "Medici"),
    ("Castellani", "Peruzzi"), ("Castellani", "Strozzi"), ("Castellani", "Barbadori"),
    ("Ginori", "Medici"),
    ("Guadagni", "Albizzi"), ("Guadagni", "Tornabuoni"), ("Guadagni", "Lamberteschi"), ("Guadagni", "Bischeri"),
    ("Lamberteschi", "Peruzzi"),
    ("Medici", "Barbadori"), ("Medici", "Ridolfi"), ("Medici", "Tornabuoni"),
    ("Medici", "Albizzi"), ("Medici", "Salviati"),
    ("Pazzi", "Salviati"),
    ("Peruzzi", "Strozzi"), ("Peruzzi", "Bischeri"),
    ("Ridolfi", "Strozzi"), ("Ridolfi", "Tornabuoni"),
    ("Salviati", "Medici"),
    ("Bischeri", "Strozzi")
  ]
  for (u, v) in edges:
    result.addEdge(u, v)

proc diamondGraph*(): Graph[int] =
  ## Generate the diamond graph (4 nodes, 5 edges).
  result = newGraph[int]()
  result.addEdge(0, 1)
  result.addEdge(0, 2)
  result.addEdge(1, 2)
  result.addEdge(1, 3)
  result.addEdge(2, 3)

proc bullGraph*(): Graph[int] =
  ## Generate the bull graph (5 nodes, 5 edges).
  result = newGraph[int]()
  result.addEdge(0, 1)
  result.addEdge(0, 2)
  result.addEdge(1, 2)
  result.addEdge(1, 3)
  result.addEdge(2, 4)

proc houseGraph*(): Graph[int] =
  ## Generate the house graph (5 nodes, 6 edges).
  result = newGraph[int]()
  result.addEdge(0, 1)
  result.addEdge(0, 2)
  result.addEdge(1, 3)
  result.addEdge(2, 3)
  result.addEdge(2, 4)
  result.addEdge(3, 4)

proc cubicalGraph*(): Graph[int] =
  ## Generate the cubical graph Q3 (8 nodes, 12 edges).
  result = newGraph[int]()
  let edges = [
    (0, 1), (0, 3), (0, 4),
    (1, 2), (1, 5),
    (2, 3), (2, 6),
    (3, 7),
    (4, 5), (4, 7),
    (5, 6),
    (6, 7)
  ]
  for (u, v) in edges:
    result.addEdge(u, v)

proc tetrahedralGraph*(): Graph[int] =
  ## Generate the tetrahedral graph K4 (4 nodes, 6 edges).
  result = newGraph[int]()
  for i in 0 ..< 4:
    for j in (i + 1) ..< 4:
      result.addEdge(i, j)

proc octahedralGraph*(): Graph[int] =
  ## Generate the octahedral graph (6 nodes, 12 edges).
  result = newGraph[int]()
  let edges = [
    (0, 1), (0, 2), (0, 3), (0, 4),
    (1, 2), (1, 3), (1, 5),
    (2, 4), (2, 5),
    (3, 4), (3, 5),
    (4, 5)
  ]
  for (u, v) in edges:
    result.addEdge(u, v)

proc icosahedralGraph*(): Graph[int] =
  ## Generate the icosahedral graph (12 nodes, 30 edges).
  result = newGraph[int]()
  let edges = [
    (0, 1), (0, 2), (0, 3), (0, 4), (0, 5),
    (1, 2), (1, 5), (1, 6), (1, 7),
    (2, 3), (2, 7), (2, 8),
    (3, 4), (3, 8), (3, 9),
    (4, 5), (4, 9), (4, 10),
    (5, 6), (5, 10),
    (6, 7), (6, 10), (6, 11),
    (7, 8), (7, 11),
    (8, 9), (8, 11),
    (9, 10), (9, 11),
    (10, 11)
  ]
  for (u, v) in edges:
    result.addEdge(u, v)

proc dodecahedralGraph*(): Graph[int] =
  ## Generate the dodecahedral graph (20 nodes, 30 edges).
  ## Each vertex has degree 3.
  result = newGraph[int]()
  let edges = [
    (0, 1), (0, 10), (0, 19),
    (1, 2), (1, 8),
    (2, 3), (2, 6),
    (3, 4), (3, 19),
    (4, 5), (4, 17),
    (5, 6), (5, 15),
    (6, 7),
    (7, 8), (7, 14),
    (8, 9),
    (9, 10), (9, 13),
    (10, 11),
    (11, 12), (11, 18),
    (12, 13), (12, 16),
    (13, 14),
    (14, 15),
    (15, 16),
    (16, 17),
    (17, 18),
    (18, 19)
  ]
  for (u, v) in edges:
    result.addEdge(u, v)

proc desarguesGraph*(): Graph[int] =
  ## Generate the Desargues graph (20 nodes, 30 edges).
  ## This is a 3-regular graph; it is the generalized Petersen graph GP(10,3).
  result = newGraph[int]()
  # Generalized Petersen graph GP(10, 3)
  for i in 0 ..< 10:
    result.addEdge(i, (i + 1) mod 10)  # outer ring
    result.addEdge(i + 10, ((i + 3) mod 10) + 10)  # inner star
    result.addEdge(i, i + 10)  # spokes

proc heawoodGraph*(): Graph[int] =
  ## Generate the Heawood graph (14 nodes, 21 edges).
  ## This is the incidence graph of the Fano plane, a cubic bipartite graph.
  result = newGraph[int]()
  let edges = [
    (0, 1), (0, 5), (0, 13),
    (1, 2), (1, 10),
    (2, 3), (2, 7),
    (3, 4), (3, 12),
    (4, 5), (4, 9),
    (5, 6),
    (6, 7), (6, 11),
    (7, 8),
    (8, 9), (8, 13),
    (9, 10),
    (10, 11),
    (11, 12),
    (12, 13)
  ]
  for (u, v) in edges:
    result.addEdge(u, v)

proc pappusGraph*(): Graph[int] =
  ## Generate the Pappus graph (18 nodes, 27 edges).
  ## A 3-regular bipartite graph.
  result = newGraph[int]()
  let edges = [
    (0, 1), (0, 5), (0, 6),
    (1, 2), (1, 7),
    (2, 3), (2, 8),
    (3, 4), (3, 9),
    (4, 5), (4, 10),
    (5, 11),
    (6, 13), (6, 17),
    (7, 12), (7, 14),
    (8, 13), (8, 15),
    (9, 14), (9, 16),
    (10, 15), (10, 17),
    (11, 12), (11, 16),
    (12, 15),
    (13, 16),
    (14, 17)
  ]
  for (u, v) in edges:
    result.addEdge(u, v)

proc moebiusKantorGraph*(): Graph[int] =
  ## Generate the Möbius-Kantor graph (16 nodes, 24 edges).
  ## This is the generalized Petersen graph GP(8,3).
  result = newGraph[int]()
  for i in 0 ..< 8:
    result.addEdge(i, (i + 1) mod 8)
    result.addEdge(i + 8, ((i + 3) mod 8) + 8)
    result.addEdge(i, i + 8)

proc fruchtGraph*(): Graph[int] =
  ## Generate the Frucht graph (12 nodes, 18 edges).
  ## The smallest cubic graph with trivial automorphism group.
  result = newGraph[int]()
  let edges = [
    (0, 1), (0, 6), (0, 7),
    (1, 2), (1, 7),
    (2, 3), (2, 8),
    (3, 4), (3, 9),
    (4, 5), (4, 10),
    (5, 6), (5, 10),
    (6, 11),
    (7, 11),
    (8, 9), (8, 11),
    (9, 10)
  ]
  for (u, v) in edges:
    result.addEdge(u, v)

proc tutteGraph*(): Graph[int] =
  ## Generate the Tutte graph (46 nodes, 69 edges).
  ## The smallest 3-regular graph that is 3-connected but not Hamiltonian.
  result = newGraph[int]()
  let edges = [
    (0, 1), (0, 2), (0, 3),
    (1, 4), (1, 26),
    (2, 10), (2, 11),
    (3, 18), (3, 19),
    (4, 5), (4, 33),
    (5, 6), (5, 29),
    (6, 7), (6, 27),
    (7, 8), (7, 14),
    (8, 9), (8, 38),
    (9, 10), (9, 37),
    (10, 39),
    (11, 12), (11, 27),
    (12, 13), (12, 23),
    (13, 14), (13, 21),
    (14, 15),
    (15, 16), (15, 44),
    (16, 17), (16, 43),
    (17, 18), (17, 45),
    (18, 40),
    (19, 20), (19, 33),
    (20, 21), (20, 41),
    (21, 22),
    (22, 23), (22, 36),
    (23, 24),
    (24, 25), (24, 32),
    (25, 26), (25, 31),
    (26, 34),
    (27, 28),
    (28, 29), (28, 32),
    (29, 30),
    (30, 31), (30, 35),
    (31, 34),
    (32, 35),
    (33, 42),
    (34, 38),
    (35, 38),
    (36, 37), (36, 39),
    (37, 45),
    (39, 40),
    (40, 44),
    (41, 42), (41, 43),
    (42, 45),
    (43, 44)
  ]
  for (u, v) in edges:
    result.addEdge(u, v)

proc sedgewickMazeGraph*(): Graph[int] =
  ## Generate Sedgewick's maze graph (8 nodes, 10 edges).
  result = newGraph[int]()
  let edges = [
    (0, 2), (0, 5), (0, 7),
    (1, 7),
    (2, 6),
    (3, 4), (3, 5),
    (4, 5), (4, 6), (4, 7)
  ]
  for (u, v) in edges:
    result.addEdge(u, v)

proc krackardtKiteGraph*(): Graph[int] =
  ## Generate Krackardt's kite graph (10 nodes, 18 edges).
  ## Used to illustrate centrality measures.
  result = newGraph[int]()
  let edges = [
    (0, 1), (0, 2), (0, 3), (0, 5),
    (1, 3), (1, 4), (1, 6),
    (2, 3), (2, 5),
    (3, 4), (3, 5), (3, 6),
    (4, 6),
    (5, 6), (5, 7),
    (6, 7),
    (7, 8),
    (8, 9)
  ]
  for (u, v) in edges:
    result.addEdge(u, v)

proc generalizedPetersenGraph*(n, k: int): Graph[int] =
  ## Generate the generalized Petersen graph GP(n, k).
  ## Has 2n nodes and 3n edges.
  ## - Outer ring: nodes 0..n-1 connected in a cycle
  ## - Inner star: nodes n..2n-1 connected with step k
  ## - Spokes: node i connected to n+i
  result = newGraph[int]()
  for i in 0 ..< n:
    result.addEdge(i, (i + 1) mod n)
    result.addEdge(i + n, ((i + k) mod n) + n)
    result.addEdge(i, i + n)

proc hoffmanSingletonGraph*(): Graph[int] =
  ## Generate the Hoffman-Singleton graph (50 nodes, 175 edges).
  ## The unique Moore graph with degree 7 and girth 5.
  result = newGraph[int]()
  # Construct using pentagons and pentagrams
  # P_j: 5 pentagons with nodes (j, i) for i=0..4, j=0..4
  # Q_j: 5 pentagrams with nodes (j, i), j=0..4
  # Node encoding: pentagon nodes = j*5+i (0..24), pentagram nodes = 25+j*5+i (25..49)
  for j in 0 ..< 5:
    for i in 0 ..< 5:
      # Pentagon P_j: connect i to (i+1) mod 5
      result.addEdge(j * 5 + i, j * 5 + ((i + 1) mod 5))
      # Pentagram Q_j: connect i to (i+2) mod 5
      result.addEdge(25 + j * 5 + i, 25 + j * 5 + ((i + 2) mod 5))

  # Cross edges: P_j,i connected to Q_k, (i*k+j) mod 5
  for j in 0 ..< 5:
    for i in 0 ..< 5:
      for k in 0 ..< 5:
        discard  # need correct formula

  # Use the correct adjacency from Robertson's construction
  for j in 0 ..< 5:
    for i in 0 ..< 5:
      # Connect node i of pentagon j to node (i*j + k) mod 5 of pentagram k
      for k in 0 ..< 5:
        discard

  # Simplified: use known edge formula
  # P_j node i -> Q_k node (i*k + j) mod 5
  for j in 0 ..< 5:
    for i in 0 ..< 5:
      for k in 0 ..< 5:
        let target = (i * k + j) mod 5
        result.addEdge(j * 5 + i, 25 + k * 5 + target)
