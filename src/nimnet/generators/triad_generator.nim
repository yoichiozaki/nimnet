## Triad graph generator - generates one of the 16 triad types

import ../digraph

const triadNames* = [
  "003", "012", "102", "021D", "021U", "021C", "111D", "111U",
  "030T", "030C", "201", "120D", "120U", "120C", "210", "300"
]

proc triadGraph*(triadType: string): DiGraph[int] =
  ## Generate one of the 16 triad types as a 3-node directed graph.
  ## Types: 003, 012, 102, 021D, 021U, 021C, 111D, 111U,
  ##        030T, 030C, 201, 120D, 120U, 120C, 210, 300
  result = newDiGraph[int]()
  result.addNode(0)
  result.addNode(1)
  result.addNode(2)
  case triadType
  of "003": discard  # no edges
  of "012": result.addEdge(0, 1)
  of "102":
    result.addEdge(0, 1)
    result.addEdge(1, 0)
  of "021D":
    result.addEdge(0, 1)
    result.addEdge(0, 2)
  of "021U":
    result.addEdge(1, 0)
    result.addEdge(2, 0)
  of "021C":
    result.addEdge(0, 1)
    result.addEdge(2, 0)
  of "111D":
    result.addEdge(0, 1)
    result.addEdge(1, 0)
    result.addEdge(0, 2)
  of "111U":
    result.addEdge(0, 1)
    result.addEdge(1, 0)
    result.addEdge(2, 0)
  of "030T":
    result.addEdge(0, 1)
    result.addEdge(1, 2)
    result.addEdge(0, 2)
  of "030C":
    result.addEdge(0, 1)
    result.addEdge(1, 2)
    result.addEdge(2, 0)
  of "201":
    result.addEdge(0, 1)
    result.addEdge(1, 0)
    result.addEdge(0, 2)
    result.addEdge(2, 0)
  of "120D":
    result.addEdge(0, 1)
    result.addEdge(1, 0)
    result.addEdge(0, 2)
    result.addEdge(1, 2)
  of "120U":
    result.addEdge(0, 1)
    result.addEdge(1, 0)
    result.addEdge(2, 0)
    result.addEdge(2, 1)
  of "120C":
    result.addEdge(0, 1)
    result.addEdge(1, 0)
    result.addEdge(0, 2)
    result.addEdge(2, 1)
  of "210":
    result.addEdge(0, 1)
    result.addEdge(1, 0)
    result.addEdge(0, 2)
    result.addEdge(2, 0)
    result.addEdge(1, 2)
  of "300":
    result.addEdge(0, 1)
    result.addEdge(1, 0)
    result.addEdge(0, 2)
    result.addEdge(2, 0)
    result.addEdge(1, 2)
    result.addEdge(2, 1)
  else:
    raise newException(ValueError, "Unknown triad type: " & triadType)
