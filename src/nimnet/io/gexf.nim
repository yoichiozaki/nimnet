## GEXF (Graph Exchange XML Format) I/O
##
## Read and write graphs in GEXF format, commonly used by Gephi.
## Supports node/edge attributes.

import std/[tables, strutils, xmltree, xmlparser, streams, strtabs, json]
import ../types
import ../graph
import ../digraph

proc writeGexf*[N](g: Graph[N], filename: string) =
  ## Write an undirected graph to a GEXF file.
  var f = open(filename, fmWrite)
  defer: f.close()
  f.writeLine("""<?xml version="1.0" encoding="UTF-8"?>""")
  f.writeLine("""<gexf xmlns="http://gexf.net/1.3" version="1.3">""")
  f.writeLine("""  <graph defaultedgetype="undirected">""")
  f.writeLine("""    <nodes>""")
  for n in g.nodes:
    let attr = g.getNodeAttr(n)
    var label = $n
    if "label" in attr:
      label = attr["label"].getStr()
    f.writeLine("      <node id=\"" & $n & "\" label=\"" & label & "\" />")
  f.writeLine("""    </nodes>""")
  f.writeLine("""    <edges>""")
  var edgeId = 0
  var seen = initTable[string, bool]()
  for u in g.nodes:
    for v in g.neighbors(u):
      let key = if $u < $v: $u & "-" & $v else: $v & "-" & $u
      if key notin seen:
        seen[key] = true
        let attr = g.getEdgeAttr(u, v)
        var weightStr = ""
        if "weight" in attr:
          weightStr = " weight=\"" & $attr.weight & "\""
        f.writeLine("      <edge id=\"" & $edgeId & "\" source=\"" & $u &
                    "\" target=\"" & $v & "\"" & weightStr & " />")
        edgeId += 1
  f.writeLine("""    </edges>""")
  f.writeLine("""  </graph>""")
  f.writeLine("""</gexf>""")

proc writeGexf*[N](g: DiGraph[N], filename: string) =
  ## Write a directed graph to a GEXF file.
  var f = open(filename, fmWrite)
  defer: f.close()
  f.writeLine("""<?xml version="1.0" encoding="UTF-8"?>""")
  f.writeLine("""<gexf xmlns="http://gexf.net/1.3" version="1.3">""")
  f.writeLine("""  <graph defaultedgetype="directed">""")
  f.writeLine("""    <nodes>""")
  for n in g.nodes:
    let attr = g.getNodeAttr(n)
    var label = $n
    if "label" in attr:
      label = attr["label"].getStr()
    f.writeLine("      <node id=\"" & $n & "\" label=\"" & label & "\" />")
  f.writeLine("""    </nodes>""")
  f.writeLine("""    <edges>""")
  var edgeId = 0
  for u in g.nodes:
    for v in g.successors(u):
      let attr = g.getEdgeAttr(u, v)
      var weightStr = ""
      if "weight" in attr:
        weightStr = " weight=\"" & $attr.weight & "\""
      f.writeLine("      <edge id=\"" & $edgeId & "\" source=\"" & $u &
                  "\" target=\"" & $v & "\"" & weightStr & " />")
      edgeId += 1
  f.writeLine("""    </edges>""")
  f.writeLine("""  </graph>""")
  f.writeLine("""</gexf>""")

proc readGexfInto[G](filename: string, g: var G) =
  let xml = loadXml(filename)
  for graphNode in xml:
    if graphNode.kind == xnElement and graphNode.tag == "graph":
      for section in graphNode:
        if section.kind != xnElement:
          continue
        if section.tag == "nodes":
          for node in section:
            if node.kind == xnElement and node.tag == "node":
              let attrs = node.attrs
              if attrs != nil and attrs.hasKey("id"):
                let id = attrs["id"]
                g.addNode(id)
                if attrs.hasKey("label"):
                  var nodeAttr: NodeAttr = newNodeAttr()
                  nodeAttr["label"] = newJString(attrs["label"])
                  g.addNode(id, nodeAttr)
        elif section.tag == "edges":
          for edge in section:
            if edge.kind == xnElement and edge.tag == "edge":
              let attrs = edge.attrs
              if attrs != nil and attrs.hasKey("source") and attrs.hasKey("target"):
                let src = attrs["source"]
                let tgt = attrs["target"]
                if attrs.hasKey("weight"):
                  g.addEdge(src, tgt, newEdgeAttr(parseFloat(attrs["weight"])))
                else:
                  g.addEdge(src, tgt)

proc readGexf*(filename: string): Graph[string] =
  ## Read an undirected graph with node labels and edge weights from a GEXF file.
  ## Returns a ``Graph[string]`` where node IDs are the GEXF id attributes.
  ## Invalid weights raise ``ValueError``; XML and file errors propagate.
  result = newGraph[string]()
  readGexfInto(filename, result)

proc readGexfDirected*(filename: string): DiGraph[string] =
  ## Read a directed graph with node labels and edge weights from a GEXF file.
  ## Node IDs and error behavior follow ``readGexf``.
  result = newDiGraph[string]()
  readGexfInto(filename, result)
