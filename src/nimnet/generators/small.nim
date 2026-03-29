## Small / famous graph generators

# no std imports needed
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
    attr["club"] = if n in club0: "Mr. Hi" else: "Officer"
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
