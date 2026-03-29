## GraphML format I/O
##
## Read and write graphs in GraphML XML format.

import std/[tables, strutils, xmltree, xmlparser, streams, strformat, json]
import ../types
import ../graph
import ../digraph

proc writeGraphml*[N](g: Graph[N], filename: string) =
  ## Write graph in GraphML format.
  var f = newFileStream(filename, fmWrite)
  if f == nil:
    raise newException(IOError, "Cannot open file: " & filename)
  defer: f.close()

  f.writeLine("""<?xml version="1.0" encoding="UTF-8"?>""")
  f.writeLine("""<graphml xmlns="http://graphml.graphstudio.org/xmlns">""")

  # Declare weight key
  f.writeLine("""  <key id="weight" for="edge" attr.name="weight" attr.type="double">""")
  f.writeLine("""    <default>1.0</default>""")
  f.writeLine("""  </key>""")

  f.writeLine("""  <graph id="G" edgedefault="undirected">""")

  for node in g.nodes:
    f.writeLine(fmt"""    <node id="{node}"/>""")

  var edgeId = 0
  for (u, v) in g.edges:
    let attrs = g.getEdgeAttr(u, v)
    if "weight" in attrs:
      let wNode = attrs["weight"]
      let w = if wNode.kind == JString: wNode.getStr() else: $wNode
      f.writeLine(fmt"""    <edge id="e{edgeId}" source="{u}" target="{v}">""")
      f.writeLine(fmt"""      <data key="weight">{w}</data>""")
      f.writeLine("""    </edge>""")
    else:
      f.writeLine(fmt"""    <edge id="e{edgeId}" source="{u}" target="{v}"/>""")
    edgeId.inc

  f.writeLine("  </graph>")
  f.writeLine("</graphml>")

proc writeGraphml*[N](g: DiGraph[N], filename: string) =
  ## Write directed graph in GraphML format.
  var f = newFileStream(filename, fmWrite)
  if f == nil:
    raise newException(IOError, "Cannot open file: " & filename)
  defer: f.close()

  f.writeLine("""<?xml version="1.0" encoding="UTF-8"?>""")
  f.writeLine("""<graphml xmlns="http://graphml.graphstudio.org/xmlns">""")
  f.writeLine("""  <key id="weight" for="edge" attr.name="weight" attr.type="double">""")
  f.writeLine("""    <default>1.0</default>""")
  f.writeLine("""  </key>""")
  f.writeLine("""  <graph id="G" edgedefault="directed">""")

  for node in g.nodes:
    f.writeLine(fmt"""    <node id="{node}"/>""")

  var edgeId = 0
  for (u, v) in g.edges:
    let attrs = g.getEdgeAttr(u, v)
    if "weight" in attrs:
      let wNode = attrs["weight"]
      let w = if wNode.kind == JString: wNode.getStr() else: $wNode
      f.writeLine(fmt"""    <edge id="e{edgeId}" source="{u}" target="{v}">""")
      f.writeLine(fmt"""      <data key="weight">{w}</data>""")
      f.writeLine("""    </edge>""")
    else:
      f.writeLine(fmt"""    <edge id="e{edgeId}" source="{u}" target="{v}"/>""")
    edgeId.inc

  f.writeLine("  </graph>")
  f.writeLine("</graphml>")

proc readGraphml*(filename: string): Graph[string] =
  ## Read a GraphML file and return a Graph[string].
  let data = readFile(filename)
  let xml = parseXml(data)

  result = newGraph[string]()

  # Find keys
  var weightKey = ""
  for child in xml:
    if child.kind == xnElement and child.tag == "key":
      if child.attr("attr.name") == "weight":
        weightKey = child.attr("id")

  # Find graph element
  for child in xml:
    if child.kind == xnElement and child.tag == "graph":
      for elem in child:
        if elem.kind == xnElement:
          if elem.tag == "node":
            let id = elem.attr("id")
            result.addNode(id)
          elif elem.tag == "edge":
            let source = elem.attr("source")
            let target = elem.attr("target")
            var weight = ""
            for data in elem:
              if data.kind == xnElement and data.tag == "data":
                if data.attr("key") == weightKey:
                  weight = data.innerText.strip()
            if weight.len > 0:
              result.addWeightedEdge(source, target, parseFloat(weight))
            else:
              result.addEdge(source, target)
