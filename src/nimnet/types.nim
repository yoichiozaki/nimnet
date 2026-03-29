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
  EdgeAttr* = object
    ## Edge attributes with a fast-path weight field and optional string extras.
    weight*: float                    ## Direct O(1) weight access, default 1.0
    extra*: Table[string, string]     ## Optional string key-value attributes

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
  ## Create an empty edge attribute table with default weight 1.0.
  EdgeAttr(weight: 1.0, extra: initTable[string, string]())

func newEdgeAttr*(weight: float): EdgeAttr {.inline.} =
  ## Create edge attributes with a weight.
  EdgeAttr(weight: weight, extra: initTable[string, string]())

func newEdgeAttr*(pairs: openArray[(string, string)]): EdgeAttr =
  ## Create edge attributes from key-value pairs.
  ## The ``"weight"`` key is parsed into the fast-path weight field;
  ## all other keys go into the ``extra`` table.
  ##
  ## .. code-block:: nim
  ##   let attr = newEdgeAttr({"weight": "2.5", "color": "red"})
  result.weight = 1.0
  result.extra = initTable[string, string]()
  for (k, v) in pairs:
    if k == "weight":
      result.weight = parseFloat(v)
    else:
      result.extra[k] = v

func newNodeAttr*(): NodeAttr {.inline.} =
  ## Create an empty node attribute table.
  discard

func newNodeAttr*(pairs: openArray[(string, string)]): NodeAttr =
  ## Create node attributes from key-value pairs.
  pairs.toTable

# --- Weight utilities ------------------------------------------------------

func getWeight*(attr: EdgeAttr, default: float = 1.0): float {.inline.} =
  ## Get the numeric weight from edge attributes.
  ## The ``default`` parameter is kept for API compatibility but is not used;
  ## this always returns ``attr.weight`` (default 1.0 when created via ``newEdgeAttr()``).
  attr.weight

# --- Compatibility operators (preserve Table-like API) ---------------------

func `[]`*(attr: EdgeAttr, key: string): string {.inline.} =
  ## Get an attribute by key. ``"weight"`` returns the stringified weight field.
  if key == "weight": $attr.weight else: attr.extra[key]

func `[]=`*(attr: var EdgeAttr, key: string, val: string) {.inline.} =
  ## Set an attribute by key. ``"weight"`` updates the fast-path weight field.
  if key == "weight": attr.weight = parseFloat(val)
  else: attr.extra[key] = val

func contains*(attr: EdgeAttr, key: string): bool {.inline.} =
  ## Return true if the attribute exists. ``"weight"`` is always present.
  key == "weight" or key in attr.extra

func hasKey*(attr: EdgeAttr, key: string): bool {.inline.} =
  ## Alias for ``contains``.
  attr.contains(key)

func len*(attr: EdgeAttr): int {.inline.} =
  ## Number of attributes (weight field counts as 1 plus any extra entries).
  1 + attr.extra.len

iterator pairs*(attr: EdgeAttr): (string, string) =
  ## Iterate over all attributes. Yields ``("weight", $attr.weight)`` first,
  ## then all entries in ``extra``.
  yield ("weight", $attr.weight)
  for k, v in attr.extra:
    yield (k, v)

func `==`*(a, b: EdgeAttr): bool {.inline.} =
  a.weight == b.weight and a.extra == b.extra
