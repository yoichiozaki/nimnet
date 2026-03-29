## Compile-time utilities for nimnet.
##
## Provides compile-time graph construction and optimization macros.

import std/[tables, macros]
import ./types, ./graph, ./digraph

template staticGraph*[N](edges: static openArray[(N, N)]): Graph[N] =
  ## Construct a graph from a compile-time known edge list.
  ## The edge list is processed at compile time for zero runtime overhead
  ## on initialization.
  var g = newGraph[N]()
  for (u, v) in edges:
    g.addEdge(u, v)
  g

template staticDiGraph*[N](edges: static openArray[(N, N)]): DiGraph[N] =
  ## Construct a directed graph from a compile-time known edge list.
  var g = newDiGraph[N]()
  for (u, v) in edges:
    g.addEdge(u, v)
  g

template staticWeightedGraph*[N](edges: static openArray[(N, N, float)]): Graph[N] =
  ## Construct a weighted graph from a compile-time known edge list.
  var g = newGraph[N]()
  for (u, v, w) in edges:
    g.addWeightedEdge(u, v, w)
  g
