## JSON graph format I/O

import std/[json, tables, strutils]
import ../types
import ../graph
import ../digraph

proc toJsonNode*[N](g: Graph[N]): JsonNode =
  ## Convert graph to JSON node-link format.
  result = newJObject()
  result["directed"] = newJBool(false)
  result["multigraph"] = newJBool(false)
  result["graph"] = newJObject()
  result["graph"]["name"] = newJString(g.name)

  var nodes = newJArray()
  for n in g.nodes:
    var nodeObj = newJObject()
    nodeObj["id"] = newJString($n)
    let attr = g.getNodeAttr(n)
    for k, v in attr:
      nodeObj[k] = newJString(v)
    nodes.add(nodeObj)
  result["nodes"] = nodes

  var links = newJArray()
  for (u, v, attr) in g.edgesWithAttr:
    var linkObj = newJObject()
    linkObj["source"] = newJString($u)
    linkObj["target"] = newJString($v)
    for k, val in attr:
      linkObj[k] = newJString(val)
    links.add(linkObj)
  result["links"] = links

proc toJsonNode*[N](g: DiGraph[N]): JsonNode =
  ## Convert directed graph to JSON node-link format.
  result = newJObject()
  result["directed"] = newJBool(true)
  result["multigraph"] = newJBool(false)
  result["graph"] = newJObject()
  result["graph"]["name"] = newJString(g.name)

  var nodes = newJArray()
  for n in g.nodes:
    var nodeObj = newJObject()
    nodeObj["id"] = newJString($n)
    nodes.add(nodeObj)
  result["nodes"] = nodes

  var links = newJArray()
  for (u, v, attr) in g.edgesWithAttr:
    var linkObj = newJObject()
    linkObj["source"] = newJString($u)
    linkObj["target"] = newJString($v)
    for k, val in attr:
      linkObj[k] = newJString(val)
    links.add(linkObj)
  result["links"] = links

proc writeJsonGraph*[N](g: Graph[N], filename: string) =
  ## Write graph to JSON file.
  let js = toJsonNode(g)
  writeFile(filename, $js)

proc writeJsonGraph*[N](g: DiGraph[N], filename: string) =
  ## Write directed graph to JSON file.
  let js = toJsonNode(g)
  writeFile(filename, $js)

proc readJsonGraph*(filename: string): Graph[string] =
  ## Read graph from JSON node-link format file.
  let content = readFile(filename)
  let js = parseJson(content)
  result = newGraph[string]()
  if "graph" in js and "name" in js["graph"]:
    result.name = js["graph"]["name"].getStr()

  for nodeObj in js["nodes"]:
    let id = nodeObj["id"].getStr()
    result.addNode(id)
    var attr = newNodeAttr()
    for k, v in nodeObj:
      if k != "id":
        attr[k] = v.getStr()
    if attr.len > 0:
      result.setNodeAttr(id, attr)

  for linkObj in js["links"]:
    let source = linkObj["source"].getStr()
    let target = linkObj["target"].getStr()
    var attr = newEdgeAttr()
    for k, v in linkObj:
      if k != "source" and k != "target":
        attr[k] = v.getStr()
    result.addEdge(source, target, attr)
