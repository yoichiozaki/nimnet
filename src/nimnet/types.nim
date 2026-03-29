## Core types, exceptions, and utilities for nimnet
##
## Defines fundamental types used throughout nimnet:
## - ``EdgeAttr`` / ``NodeAttr`` — attribute tables for edges and nodes
## - ``Edge[N]`` / ``WeightedEdge[N]`` — typed edge tuples
## - Exception hierarchy for graph operation errors
## - Weight accessor utilities

import std/[tables, hashes, strutils]

type
  # --- Node type concept --------------------------------------------------
  Nodeable* = concept n
    ## Compile-time concept documenting the requirements for graph node types.
    ## Any type used as N in Graph[N] must support hash, ==, and $.
    hash(n) is Hash
    `==`(n, n) is bool
    `$`(n) is string

  # --- Attribute types ---------------------------------------------------
  EdgeAttr* = Table[string, string]
    ## Edge attributes stored as string key-value pairs.
    ## Convention: use key ``"weight"`` for numeric edge weights.

  NodeAttr* = Table[string, string]
    ## Node attributes stored as string key-value pairs.

  # --- Edge tuple aliases ------------------------------------------------
  Edge*[N] = tuple[u, v: N]
    ## A typed edge between two nodes.

  WeightedEdge*[N] = tuple[u, v: N, weight: float]
    ## A typed edge carrying a numeric weight.

  # --- Exception hierarchy -----------------------------------------------
  NimNetError* = object of CatchableError
    ## Base exception for all nimnet errors.

  NodeNotFound* = object of NimNetError
    ## Raised when a node is not found in the graph.

  EdgeNotFound* = object of NimNetError
    ## Raised when an edge is not found in the graph.

  NimNetNoPath* = object of NimNetError
    ## Raised when no path exists between two nodes.

  HasACycle* = object of NimNetError
    ## Raised when a cycle is detected in a graph expected to be acyclic.

  NimNetUnfeasible* = object of NimNetError
    ## Raised when an algorithm cannot find a feasible solution.

  NimNetNotImplemented* = object of NimNetError
    ## Raised for features not yet implemented.

# --- Attribute constructors ------------------------------------------------

func newEdgeAttr*(): EdgeAttr {.inline.} =
  ## Create an empty edge attribute table.
  ## Uses zero-initialized Table (valid for reads; auto-initializes on first write).
  discard

func newEdgeAttr*(weight: float): EdgeAttr {.inline.} =
  ## Create edge attributes with a weight.
  result = initTable[string, string](initialSize = 2)
  result["weight"] = $weight

func newEdgeAttr*(pairs: openArray[(string, string)]): EdgeAttr =
  ## Create edge attributes from key-value pairs.
  ##
  ## .. code-block:: nim
  ##   let attr = newEdgeAttr({"weight": "2.5", "color": "red"})
  pairs.toTable

func newNodeAttr*(): NodeAttr {.inline.} =
  ## Create an empty node attribute table.
  discard

func newNodeAttr*(pairs: openArray[(string, string)]): NodeAttr =
  ## Create node attributes from key-value pairs.
  pairs.toTable

# --- Weight utilities ------------------------------------------------------

func getWeight*(attr: EdgeAttr, default: float = 1.0): float {.inline.} =
  ## Get numeric weight from edge attributes.
  ## Returns ``default`` if the ``"weight"`` key is absent.
  if attr.len == 0: return default
  let w = attr.getOrDefault("weight", "")
  if w.len == 0: return default
  parseFloat(w)

func `weight=`*(attr: var EdgeAttr, w: float) {.inline.} =
  ## Sugar for setting the weight: ``attr.weight = 3.0``
  attr["weight"] = $w
