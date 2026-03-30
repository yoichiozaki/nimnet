## Miscellaneous graph generators - cograph, interval, sudoku, visibility

import std/[random, algorithm, sets, math]
import ../graph

proc randomCograph*(n: int, seed: int64 = 0): Graph[int] =
  ## Generate a random cograph on n nodes.
  ## Cographs are P4-free; built recursively by union and join operations.
  var rng = if seed != 0: initRand(seed) else: initRand()
  if n <= 0:
    return newGraph[int]()
  if n == 1:
    result = newGraph[int]()
    result.addNode(0)
    return
  # Split into two random halves, recursively build, then union or join
  let split = max(1, rng.rand(n - 1))
  let right = n - split
  var g1 = randomCograph(split, seed = rng.rand(int64.high))
  var g2 = randomCograph(right, seed = rng.rand(int64.high))
  # Relabel g2 nodes
  result = newGraph[int](capacity = n)
  for node in g1.nodes:
    result.addNode(node)
  for (u, v) in g1.edges:
    result.addEdge(u, v)
  for node in g2.nodes:
    result.addNode(node + split)
  for (u, v) in g2.edges:
    result.addEdge(u + split, v + split)
  # With prob 0.5, join (add all cross-edges)
  if rng.rand(1.0) < 0.5:
    for u in g1.nodes:
      for v in g2.nodes:
        result.addEdge(u, v + split)

proc intervalGraph*(intervals: openArray[(float, float)]): Graph[int] =
  ## Generate an interval graph from a list of intervals.
  ## Node i corresponds to intervals[i]; edges connect overlapping intervals.
  result = newGraph[int](capacity = intervals.len)
  for i in 0 ..< intervals.len:
    result.addNode(i)
  for i in 0 ..< intervals.len:
    for j in i + 1 ..< intervals.len:
      # Intervals overlap if max(start) < min(end)
      if max(intervals[i][0], intervals[j][0]) < min(intervals[i][1], intervals[j][1]):
        result.addEdge(i, j)

proc sudokuGraph*(n: int = 3): Graph[int] =
  ## Generate a Sudoku constraint graph.
  ## n is the box size (standard Sudoku has n=3, giving 9x9=81 nodes).
  ## Two cells are connected if they share a row, column, or box.
  let size = n * n  # grid is size x size
  let total = size * size
  result = newGraph[int](capacity = total)
  for i in 0 ..< total:
    result.addNode(i)
  for i in 0 ..< total:
    let row1 = i div size
    let col1 = i mod size
    let box1r = row1 div n
    let box1c = col1 div n
    for j in i + 1 ..< total:
      let row2 = j div size
      let col2 = j mod size
      let box2r = row2 div n
      let box2c = col2 div n
      if row1 == row2 or col1 == col2 or (box1r == box2r and box1c == box2c):
        result.addEdge(i, j)

proc visibilityGraph*(timeSeries: openArray[float]): Graph[int] =
  ## Generate a visibility graph from a time series.
  ## Node i = time step i. Edge (i,j) if all intermediate values are below
  ## the line connecting (i, ts[i]) and (j, ts[j]).
  let n = timeSeries.len
  result = newGraph[int](capacity = n)
  for i in 0 ..< n:
    result.addNode(i)
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      var visible = true
      for k in i + 1 ..< j:
        # Point k must be below the line from i to j
        let lineHeight = timeSeries[i] + (timeSeries[j] - timeSeries[i]) * float(k - i) / float(j - i)
        if timeSeries[k] >= lineHeight:
          visible = false
          break
      if visible:
        result.addEdge(i, j)
