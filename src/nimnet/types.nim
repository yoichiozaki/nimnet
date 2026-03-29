## Core types, exceptions, and utilities for nimnet
##
## Defines fundamental types used throughout nimnet:
## - ``EdgeAttr`` / ``NodeAttr`` — attribute tables for edges and nodes
## - ``Edge[N]`` / ``WeightedEdge[N]`` — typed edge tuples
## - Exception hierarchy for graph operation errors
## - Weight accessor utilities

import std/[tables, hashes, strutils, json]

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

  NodeAttr* = JsonNode
    ## Node attributes stored as a JSON object.

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
  ## Create an empty edge attribute with default weight 1.0.
  EdgeAttr(weight: 1.0, extra: initTable[string, string]())

func newEdgeAttr*(weight: float): EdgeAttr {.inline.} =
  ## Create edge attributes with a weight.
  EdgeAttr(weight: weight, extra: initTable[string, string]())

func newEdgeAttr*(pairs: openArray[(string, string)]): EdgeAttr =
  ## Create edge attributes from key-value pairs.
  ## If ``"weight"`` is among the pairs, it is parsed into the weight field.
  ##
  ## .. code-block:: nim
  ##   let attr = newEdgeAttr({"weight": "2.5", "color": "red"})
  result = EdgeAttr(weight: 1.0, extra: initTable[string, string]())
  for (k, v) in pairs:
    if k == "weight":
      try: result.weight = parseFloat(v)
      except ValueError: discard
    else:
      result.extra[k] = v

func newNodeAttr*(): NodeAttr {.inline.} =
  ## Create an empty node attribute object.
  newJObject()

func newNodeAttr*(pairs: openArray[(string, string)]): NodeAttr =
  ## Create node attributes from key-value pairs.
  result = newJObject()
  for (k, v) in pairs:
    result[k] = newJString(v)

# --- Weight utilities ------------------------------------------------------

func getWeight*(attr: EdgeAttr, default: float = 1.0): float {.inline.} =
  ## Get numeric weight from edge attributes. O(1) direct field access.
  ## The ``default`` parameter is kept for API compatibility but is unused
  ## since weight always has a value (1.0 when created via ``newEdgeAttr()``).
  attr.weight

# --- Compatibility operators -----------------------------------------------
# These allow EdgeAttr to be used as if it were a Table[string, string],
# preserving backward compatibility with existing code.

func `[]`*(attr: EdgeAttr, key: string): string {.inline.} =
  ## Access attribute by key. ``"weight"`` returns the weight as a string.
  if key == "weight":
    $attr.weight
  else:
    attr.extra[key]

func `[]=`*(attr: var EdgeAttr, key: string, value: string) {.inline.} =
  ## Set attribute by key. ``"weight"`` sets the weight field directly.
  if key == "weight":
    try: attr.weight = parseFloat(value)
    except ValueError: discard
  else:
    attr.extra[key] = value

func contains*(attr: EdgeAttr, key: string): bool {.inline.} =
  ## Check if key exists. ``"weight"`` always returns true.
  if key == "weight": true
  else: key in attr.extra

func hasKey*(attr: EdgeAttr, key: string): bool {.inline.} =
  ## Check if key exists. Alias for ``contains``.
  attr.contains(key)

func len*(attr: EdgeAttr): int {.inline.} =
  ## Number of attributes (weight field plus any extras).
  attr.extra.len + 1

iterator pairs*(attr: EdgeAttr): (string, string) =
  ## Iterate over all attributes as ``(key, value)`` pairs.
  ## Yields ``("weight", $attr.weight)`` first, then all extra pairs.
  yield ("weight", $attr.weight)
  for k, v in attr.extra:
    yield (k, v)

func `==`*(a, b: EdgeAttr): bool {.inline.} =
  ## Compare two EdgeAttr objects for equality.
  a.weight == b.weight and a.extra == b.extra

func getStr*(attr: EdgeAttr, key: string, default: string = ""): string =
  ## Get a string value from an EdgeAttr by key.
  ## For ``"weight"``, converts the float to string.
  if key == "weight":
    $attr.weight
  elif key in attr.extra:
    attr.extra[key]
  else:
    default

func getAttrFloat*(attr: EdgeAttr, key: string, default: float = 0.0): float =
  ## Get a float value from an EdgeAttr by key.
  ## For ``"weight"``, returns the weight field directly.
  if key == "weight":
    attr.weight
  elif key in attr.extra:
    try: parseFloat(attr.extra[key])
    except ValueError: default
  else:
    default
