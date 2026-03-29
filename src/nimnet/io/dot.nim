## DOT format export for Graphviz

import std/[strutils, tables, json]
import ../types
import ../graph
import ../digraph

proc writeDot*[N](g: Graph[N], filename: string) =
  ## Write graph in DOT format for Graphviz.
  var f = open(filename, fmWrite)
  defer: f.close()
  let name = if g.name.len > 0: g.name else: "G"
  f.writeLine("graph " & name & " {")
  for n in g.nodes:
    var attrs: seq[string]
    let nodeAttr = g.getNodeAttr(n)
    for k, v in nodeAttr:
      attrs.add(k & "=\"" & (if v.kind == JString: v.getStr() else: $v) & "\"")
    if attrs.len > 0:
      f.writeLine("  " & $n & " [" & attrs.join(", ") & "];")
    else:
      f.writeLine("  " & $n & ";")
  for (u, v, attr) in g.edgesWithAttr:
    var attrs: seq[string]
    for k, val in attr:
      attrs.add(k & "=\"" & val & "\"")
    if attrs.len > 0:
      f.writeLine("  " & $u & " -- " & $v & " [" & attrs.join(", ") & "];")
    else:
      f.writeLine("  " & $u & " -- " & $v & ";")
  f.writeLine("}")

proc writeDot*[N](g: DiGraph[N], filename: string) =
  ## Write directed graph in DOT format for Graphviz.
  var f = open(filename, fmWrite)
  defer: f.close()
  let name = if g.name.len > 0: g.name else: "G"
  f.writeLine("digraph " & name & " {")
  for n in g.nodes:
    f.writeLine("  " & $n & ";")
  for (u, v, attr) in g.edgesWithAttr:
    var attrs: seq[string]
    for k, val in attr:
      attrs.add(k & "=\"" & val & "\"")
    if attrs.len > 0:
      f.writeLine("  " & $u & " -> " & $v & " [" & attrs.join(", ") & "];")
    else:
      f.writeLine("  " & $u & " -> " & $v & ";")
  f.writeLine("}")

proc toDotString*[N](g: Graph[N]): string =
  ## Return DOT format string representation.
  let name = if g.name.len > 0: g.name else: "G"
  result = "graph " & name & " {\n"
  for n in g.nodes:
    result &= "  " & $n & ";\n"
  for (u, v) in g.edges:
    result &= "  " & $u & " -- " & $v & ";\n"
  result &= "}"

proc toDotString*[N](g: DiGraph[N]): string =
  ## Return DOT format string representation for a directed graph.
  let name = if g.name.len > 0: g.name else: "G"
  result = "digraph " & name & " {\n"
  for n in g.nodes:
    result &= "  " & $n & ";\n"
  for (u, v) in g.edges:
    result &= "  " & $u & " -> " & $v & ";\n"
  result &= "}"
