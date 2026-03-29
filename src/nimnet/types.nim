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
  EdgeAttr* = JsonNode
    ## Edge attributes stored as a JSON object.
    ## Convention: use key ``"weight"`` for numeric edge weights.

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
  ## Create an empty edge attribute object.
  newJObject()

func newEdgeAttr*(weight: float): EdgeAttr {.inline.} =
  ## Create edge attributes with a weight.
  result = newJObject()
  result["weight"] = newJFloat(weight)

func newEdgeAttr*(pairs: openArray[(string, string)]): EdgeAttr =
  ## Create edge attributes from key-value pairs.
  result = newJObject()
  for (k, v) in pairs:
    result[k] = newJString(v)

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
  ## Get numeric weight from edge attributes.
  ## Returns ``default`` if the ``"weight"`` key is absent or attr is nil.
  if attr.isNil or attr.kind != JObject: return default
  if "weight" notin attr: return default
  let w = attr["weight"]
  case w.kind
  of JFloat: return w.getFloat()
  of JInt: return float(w.getInt())
  of JString:
    try: return parseFloat(w.getStr())
    except ValueError: return default
  else: return default

func `weight=`*(attr: var EdgeAttr, w: float) {.inline.} =
  ## Sugar for setting the weight: ``attr.weight = 3.0``
  if attr.isNil:
    attr = newJObject()
  attr["weight"] = newJFloat(w)

# --- Compatibility helpers -------------------------------------------------
# Provide string-oriented access to ease migration from Table[string,string].

func getStr*(attr: EdgeAttr, key: string, default: string = ""): string =
  ## Get a string value from an attribute. Converts numbers to string.
  if attr.isNil or attr.kind != JObject or key notin attr: return default
  let v = attr[key]
  case v.kind
  of JString: v.getStr()
  of JFloat: $v.getFloat()
  of JInt: $v.getInt()
  of JBool: $v.getBool()
  else: default

func getAttrFloat*(attr: EdgeAttr, key: string, default: float = 0.0): float =
  ## Get a float value from an attribute by key.
  if attr.isNil or attr.kind != JObject or key notin attr: return default
  let v = attr[key]
  case v.kind
  of JFloat: v.getFloat()
  of JInt: float(v.getInt())
  of JString:
    try: parseFloat(v.getStr())
    except ValueError: default
  else: default
