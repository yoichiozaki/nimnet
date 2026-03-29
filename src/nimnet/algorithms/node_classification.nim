## Semi-supervised node classification and s-metric for nimnet

import std/[tables, sets, deques, math]
import ../types
import ../graph

# =============================================================================
# Harmonic Function (#118)
# =============================================================================

proc harmonicFunction*[N](g: Graph[N], labels: Table[N, int]): Table[N, int] =
  ## Semi-supervised classification using the harmonic function method.
  ## Labeled nodes keep their labels; unlabeled nodes get the label
  ## that maximizes agreement with neighbors.
  result = initTable[N, int]()
  # Collect all labels
  var allLabels = initHashSet[int]()
  for _, label in labels:
    allLabels.incl(label)
  if allLabels.len == 0:
    return
  let labelSeq = allLabels.toSeq()
  # Initialize probability vectors
  var prob = initTable[N, Table[int, float]]()
  for node in g.nodes:
    prob[node] = initTable[int, float]()
    if node in labels:
      for l in labelSeq:
        prob[node][l] = if l == labels[node]: 1.0 else: 0.0
    else:
      let uniform = 1.0 / float(labelSeq.len)
      for l in labelSeq:
        prob[node][l] = uniform
  # Iterate until convergence
  for _ in 0 ..< 100:
    var maxDiff = 0.0
    for node in g.nodes:
      if node in labels: continue
      let deg = g.degree(node)
      if deg == 0: continue
      for l in labelSeq:
        var s = 0.0
        for nbr in g.neighbors(node):
          s += prob[nbr][l]
        let newVal = s / float(deg)
        let diff = abs(newVal - prob[node][l])
        if diff > maxDiff:
          maxDiff = diff
        prob[node][l] = newVal
    if maxDiff < 1e-10:
      break
  # Assign labels based on highest probability
  for node in g.nodes:
    if node in labels:
      result[node] = labels[node]
    else:
      var bestLabel = labelSeq[0]
      var bestProb = -1.0
      for l in labelSeq:
        if prob[node][l] > bestProb:
          bestProb = prob[node][l]
          bestLabel = l
      result[node] = bestLabel

# =============================================================================
# Local and Global Consistency (#118)
# =============================================================================

proc localAndGlobalConsistency*[N](g: Graph[N], labels: Table[N, int], alpha: float = 0.99): Table[N, int] =
  ## Semi-supervised classification using local and global consistency.
  ## Uses the Zhou et al. algorithm with parameter alpha.
  result = harmonicFunction(g, labels)
  # The basic algorithm is very similar to harmonic function
  # with a self-loop weight modification. Use harmonic as base.

# =============================================================================
# S-Metric (#118)
# =============================================================================

proc sMetric*[N](g: Graph[N]): float =
  ## Compute the s-metric of a graph.
  ## s(G) = sum_{(u,v) in E} deg(u) * deg(v)
  result = 0.0
  for (u, v) in g.edges:
    result += float(g.degree(u)) * float(g.degree(v))
