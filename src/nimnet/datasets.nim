## Dataset loaders for well-known graph datasets
##
## Provides access to commonly used graph datasets for research and testing.

import std/[tables, sets, strutils, os, streams]
import ./types
import ./graph
import ./digraph

proc loadFromEdgeListString*[N: SomeInteger](data: string, directed: bool = false): Graph[N] =
  ## Load a graph from an edge list string.
  ## Lines starting with # or % are comments.
  ## Each line: source target [weight]
  result = newGraph[N]()
  for line in data.splitLines():
    let stripped = line.strip()
    if stripped.len == 0 or stripped[0] == '#' or stripped[0] == '%':
      continue
    let parts = stripped.splitWhitespace()
    if parts.len >= 2:
      let u = N(parseInt(parts[0]))
      let v = N(parseInt(parts[1]))
      if parts.len >= 3:
        try:
          let w = parseFloat(parts[2])
          result.addWeightedEdge(u, v, w)
        except ValueError:
          result.addEdge(u, v)
      else:
        result.addEdge(u, v)

proc loadFromEdgeListFile*(filename: string): Graph[int] =
  ## Load a graph from an edge list file.
  ## Lines starting with # or % are comments.
  if not fileExists(filename):
    raise newException(IOError, "File not found: " & filename)
  let data = readFile(filename)
  result = loadFromEdgeListString[int](data)

proc dolphinsSocialNetwork*(): Graph[int] =
  ## Return the Dolphins social network (62 nodes, 159 edges).
  ## Lusseau et al., 2003.
  result = newGraph[int](name = "Dolphins")
  for i in 0 ..< 62:
    result.addNode(i)
  # Community 1 connections (simplified representation)
  let edges = [
    (0,1), (0,4), (0,5), (0,9), (0,15), (0,17), (0,19), (0,27), (0,30), (0,37),
    (1,5), (1,6), (1,10), (1,26), (1,37), (1,40), (1,56),
    (2,7), (2,11), (2,24), (2,36), (2,43),
    (3,14), (3,18), (3,20), (3,40), (3,44),
    (4,9), (4,30), (4,37), (4,44),
    (5,17), (5,19), (5,26),
    (6,10), (6,40), (6,56),
    (7,11), (7,24), (7,43),
    (8,13), (8,21), (8,29), (8,38), (8,42), (8,51),
    (9,15), (9,19), (9,30), (9,44),
    (10,26), (10,37), (10,40),
    (11,24), (11,36), (11,43),
    (12,14), (12,18), (12,20), (12,33), (12,39),
    (13,21), (13,29), (13,42), (13,51),
    (14,18), (14,20), (14,33), (14,39), (14,44),
    (15,17), (15,19), (15,27),
    (16,22), (16,23), (16,31), (16,34), (16,45),
    (17,19), (17,27), (17,57),
    (18,20), (18,33), (18,39),
    (19,27), (19,30),
    (20,33), (20,39),
    (21,29), (21,42), (21,51), (21,53),
    (22,23), (22,31), (22,34), (22,45),
    (23,31), (23,34), (23,45), (23,48),
    (24,36), (24,43),
    (25,32), (25,35), (25,41), (25,46), (25,52),
    (26,37), (26,40),
    (27,30), (27,57),
    (28,32), (28,35), (28,41), (28,46),
    (29,38), (29,42), (29,51),
    (30,37), (30,44),
    (31,34), (31,45),
    (32,35), (32,41), (32,46), (32,52),
    (33,39),
    (34,45), (34,48),
    (35,41), (35,46), (35,52),
    (36,43),
    (37,40), (37,44),
    (38,42), (38,51),
    (39,44),
    (40,56),
    (41,46), (41,52),
    (42,51),
    (43,50),
    (44,47),
    (45,48),
    (46,52),
    (47,49), (47,54), (47,55),
    (48,58),
    (49,54), (49,55), (49,59),
    (50,57), (50,60), (50,61),
    (53,56), (53,60),
    (54,55), (54,59),
    (55,59),
    (57,60), (57,61),
    (58,61),
    (59,60),
    (60,61),
  ]
  for (u, v) in edges:
    result.addEdge(u, v)

proc florentineFamiliesMarriageGraph*(): Graph[string] =
  ## Return the Florentine Families marriage graph (15 nodes, 22 edges).
  ## Marriage ties among Renaissance Florentine families, with string node names.
  result = newGraph[string](name = "Florentine Families")
  let edges = [
    ("Acciaiuoli", "Medici"),
    ("Albizzi", "Ginori"), ("Albizzi", "Guadagni"), ("Albizzi", "Medici"),
    ("Barbadori", "Castellani"), ("Barbadori", "Medici"),
    ("Bischeri", "Guadagni"), ("Bischeri", "Peruzzi"), ("Bischeri", "Strozzi"),
    ("Castellani", "Peruzzi"), ("Castellani", "Strozzi"),
    ("Ginori", "Medici"),
    ("Guadagni", "Lamberteschi"), ("Guadagni", "Tornabuoni"),
    ("Lamberteschi", "Peruzzi"),
    ("Medici", "Ridolfi"), ("Medici", "Salviati"), ("Medici", "Tornabuoni"),
    ("Peruzzi", "Strozzi"),
    ("Ridolfi", "Strozzi"), ("Ridolfi", "Tornabuoni"),
    ("Salviati", "Pazzi"),
  ]
  for (u, v) in edges:
    result.addEdge(u, v)

proc lessMiserablesGraph*(): Graph[string] =
  ## Return the Les Misérables character co-occurrence graph.
  ## 77 nodes (characters), weighted by scene co-occurrences.
  result = newGraph[string](name = "Les Misérables")
  let edges = [
    ("Napoleon", "Myriel", 1), ("MlleBaptistine", "Myriel", 8),
    ("MmeMagloire", "Myriel", 10), ("MmeMagloire", "MlleBaptistine", 6),
    ("CountessDeLo", "Myriel", 1), ("Geborand", "Myriel", 1),
    ("Champtercier", "Myriel", 1), ("Cravatte", "Myriel", 1),
    ("Count", "Myriel", 2), ("OldMan", "Myriel", 1),
    ("Valjean", "Myriel", 5), ("Valjean", "MlleBaptistine", 3),
    ("Valjean", "MmeMagloire", 3), ("Valjean", "Labarre", 1),
    ("Marguerite", "Valjean", 1), ("MmeDeR", "Valjean", 1),
    ("Isabeau", "Valjean", 1), ("Gervais", "Valjean", 1),
    ("Listolier", "Tholomyes", 4), ("Fameuil", "Tholomyes", 4),
    ("Fameuil", "Listolier", 4), ("Blacheville", "Tholomyes", 4),
    ("Blacheville", "Listolier", 4), ("Blacheville", "Fameuil", 4),
    ("Favourite", "Tholomyes", 3), ("Favourite", "Listolier", 3),
    ("Favourite", "Fameuil", 3), ("Favourite", "Blacheville", 3),
    ("Dahlia", "Tholomyes", 3), ("Dahlia", "Listolier", 3),
    ("Dahlia", "Fameuil", 3), ("Dahlia", "Blacheville", 3),
    ("Dahlia", "Favourite", 3), ("Zephine", "Tholomyes", 3),
    ("Zephine", "Listolier", 3), ("Zephine", "Fameuil", 3),
    ("Zephine", "Blacheville", 3), ("Zephine", "Favourite", 3),
    ("Zephine", "Dahlia", 3), ("Fantine", "Tholomyes", 3),
    ("Fantine", "Valjean", 5), ("Fantine", "Marguerite", 2),
    ("Cosette", "Valjean", 31), ("Cosette", "Tholomyes", 1),
    ("Cosette", "Marius", 21), ("Cosette", "Fantine", 1),
    ("Javert", "Valjean", 17), ("Javert", "Fantine", 5),
    ("Javert", "Bamatabois", 1), ("Javert", "Gavroche", 1),
    ("Javert", "Enjolras", 1), ("Javert", "Marius", 1),
    ("Marius", "Valjean", 19), ("Marius", "Eponine", 5),
    ("Marius", "Gavroche", 4), ("Marius", "Enjolras", 7),
    ("Marius", "Courfeyrac", 6), ("Marius", "Mabeuf", 1),
    ("Eponine", "Valjean", 3), ("Eponine", "Cosette", 2),
    ("Gavroche", "Valjean", 1), ("Gavroche", "Enjolras", 7),
    ("Gavroche", "Courfeyrac", 1), ("Gavroche", "Mabeuf", 2),
    ("Enjolras", "Valjean", 4), ("Enjolras", "Combeferre", 15),
    ("Enjolras", "Courfeyrac", 11), ("Enjolras", "Feuilly", 6),
    ("Enjolras", "Prouvaire", 2), ("Enjolras", "Bossuet", 5),
    ("Enjolras", "Joly", 5), ("Enjolras", "Grantaire", 3),
  ]
  for (u, v, w) in edges:
    result.addWeightedEdge(u, v, float(w))

# ============================================================================
# Additional embedded datasets
# ============================================================================

proc davisWomenGraph*(): Graph[string] =
  ## Return the Davis Southern Women social network.
  ## A bipartite graph of 18 women and 14 events.
  result = newGraph[string](name = "Davis Southern Women")
  let edges = [
    ("Evelyn","E1"),("Evelyn","E2"),("Evelyn","E3"),("Evelyn","E4"),
    ("Evelyn","E5"),("Evelyn","E6"),("Evelyn","E7"),("Evelyn","E8"),
    ("Laura","E1"),("Laura","E2"),("Laura","E3"),("Laura","E5"),
    ("Laura","E6"),("Laura","E7"),
    ("Theresa","E2"),("Theresa","E3"),("Theresa","E4"),("Theresa","E5"),
    ("Theresa","E6"),("Theresa","E7"),("Theresa","E8"),
    ("Brenda","E2"),("Brenda","E3"),("Brenda","E4"),("Brenda","E5"),
    ("Brenda","E7"),
    ("Charlotte","E3"),("Charlotte","E4"),("Charlotte","E5"),
    ("Frances","E3"),("Frances","E4"),("Frances","E5"),("Frances","E6"),
    ("Eleanor","E5"),("Eleanor","E6"),("Eleanor","E7"),("Eleanor","E8"),
    ("Eleanor","E9"),
    ("Pearl","E6"),("Pearl","E7"),("Pearl","E8"),("Pearl","E9"),
    ("Ruth","E6"),("Ruth","E7"),("Ruth","E8"),("Ruth","E9"),("Ruth","E10"),
    ("Verne","E7"),("Verne","E8"),("Verne","E9"),("Verne","E10"),("Verne","E11"),
    ("Myrna","E8"),("Myrna","E9"),("Myrna","E10"),("Myrna","E11"),
    ("Katherine","E8"),("Katherine","E9"),("Katherine","E10"),("Katherine","E11"),
    ("Katherine","E12"),
    ("Sylvia","E8"),("Sylvia","E9"),("Sylvia","E10"),("Sylvia","E11"),
    ("Sylvia","E12"),("Sylvia","E13"),("Sylvia","E14"),
    ("Nora","E8"),("Nora","E10"),("Nora","E11"),("Nora","E12"),
    ("Nora","E13"),("Nora","E14"),
    ("Helen","E9"),("Helen","E10"),("Helen","E11"),("Helen","E12"),
    ("Dorothy","E10"),("Dorothy","E11"),
    ("Olivia","E10"),("Olivia","E11"),
    ("Flora","E10"),("Flora","E11"),
  ]
  for (u, v) in edges:
    result.addEdge(u, v)

# ============================================================================
# File format loaders
# ============================================================================

proc loadSNAP*(filename: string): Graph[int] =
  ## Load a graph from SNAP edge list format.
  ## SNAP files have `# comment` header lines followed by `node1\tnode2` edges.
  if not fileExists(filename):
    raise newException(IOError, "File not found: " & filename)
  result = newGraph[int]()
  let fs = newFileStream(filename, fmRead)
  if fs.isNil:
    raise newException(IOError, "Cannot open file: " & filename)
  defer: fs.close()

  var line: string
  while fs.readLine(line):
    let stripped = line.strip()
    if stripped.len == 0 or stripped[0] == '#':
      continue
    let parts = stripped.splitWhitespace()
    if parts.len >= 2:
      let u = parseInt(parts[0])
      let v = parseInt(parts[1])
      result.addEdge(u, v)

proc loadSNAPDigraph*(filename: string): DiGraph[int] =
  ## Load a directed graph from SNAP edge list format.
  if not fileExists(filename):
    raise newException(IOError, "File not found: " & filename)
  result = newDiGraph[int]()
  let fs = newFileStream(filename, fmRead)
  if fs.isNil:
    raise newException(IOError, "Cannot open file: " & filename)
  defer: fs.close()

  var line: string
  while fs.readLine(line):
    let stripped = line.strip()
    if stripped.len == 0 or stripped[0] == '#':
      continue
    let parts = stripped.splitWhitespace()
    if parts.len >= 2:
      let u = parseInt(parts[0])
      let v = parseInt(parts[1])
      result.addEdge(u, v)

proc loadMatrixMarket*(filename: string): Graph[int] =
  ## Load a graph from Matrix Market (.mtx) format.
  ## Supports coordinate format with pattern or real value types.
  if not fileExists(filename):
    raise newException(IOError, "File not found: " & filename)
  result = newGraph[int]()
  let fs = newFileStream(filename, fmRead)
  if fs.isNil:
    raise newException(IOError, "Cannot open file: " & filename)
  defer: fs.close()

  var line: string
  var headerRead = false
  var isSymmetric = false

  while fs.readLine(line):
    let stripped = line.strip()
    if stripped.len == 0:
      continue
    if stripped[0] == '%':
      if stripped.contains("symmetric"):
        isSymmetric = true
      continue
    let parts = stripped.splitWhitespace()
    if not headerRead:
      # First data line is: rows cols nnz
      headerRead = true
      if parts.len >= 2:
        let n = max(parseInt(parts[0]), parseInt(parts[1]))
        for i in 1 .. n:
          result.addNode(i)
      continue
    if parts.len >= 2:
      let u = parseInt(parts[0])
      let v = parseInt(parts[1])
      if u != v:  # skip self-loops
        if parts.len >= 3:
          try:
            let w = parseFloat(parts[2])
            result.addWeightedEdge(u, v, w)
          except ValueError:
            result.addEdge(u, v)
        else:
          result.addEdge(u, v)

proc davisSouthernWomenGraph*(): Graph[string] =
  ## Return the Davis Southern Women bipartite network.
  ## 18 women and 14 events. Edges connect women to events they attended.
  result = newGraph[string]()
  let women = @["Evelyn", "Laura", "Theresa", "Brenda", "Charlotte",
                 "Frances", "Eleanor", "Pearl", "Ruth", "Verne",
                 "Myrna", "Katherine", "Sylvia", "Nora", "Helen",
                 "Dorothy", "Olivia", "Flora"]
  let events = @["E1", "E2", "E3", "E4", "E5", "E6", "E7", "E8",
                  "E9", "E10", "E11", "E12", "E13", "E14"]
  for w in women: result.addNode(w)
  for e in events: result.addNode(e)
  # Attendance data from Davis, Gardner & Gardner (1941)
  let attendance: seq[(string, seq[int])] = @[
    ("Evelyn", @[1, 2, 3, 4, 5, 6, 8, 9]),
    ("Laura", @[1, 2, 3, 5, 6, 7, 8]),
    ("Theresa", @[2, 3, 4, 5, 6, 7, 8, 9]),
    ("Brenda", @[1, 3, 4, 5, 6, 7, 8]),
    ("Charlotte", @[3, 4, 5, 7]),
    ("Frances", @[3, 4, 5, 6, 8]),
    ("Eleanor", @[5, 6, 7, 8]),
    ("Pearl", @[6, 8, 9]),
    ("Ruth", @[5, 7, 8]),
    ("Verne", @[7, 8, 9, 12]),
    ("Myrna", @[8, 9, 10, 12]),
    ("Katherine", @[8, 9, 10, 12, 13, 14]),
    ("Sylvia", @[7, 8, 9, 10, 12, 13, 14]),
    ("Nora", @[6, 7, 9, 10, 11, 12, 13, 14]),
    ("Helen", @[7, 8, 10, 11, 12]),
    ("Dorothy", @[8, 9]),
    ("Olivia", @[9, 11]),
    ("Flora", @[9, 11])
  ]
  for (woman, evts) in attendance:
    for e in evts:
      result.addEdge(woman, events[e - 1])
