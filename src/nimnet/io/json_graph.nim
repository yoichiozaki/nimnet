## JSON graph format I/O

import std/[json, tables, sets]
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
      nodeObj[k] = v
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
        attr[k] = v
    if attr.len > 0:
      result.setNodeAttr(id, attr)

  for linkObj in js["links"]:
    let source = linkObj["source"].getStr()
    let target = linkObj["target"].getStr()
    var attr = newEdgeAttr()
    for k, v in linkObj:
      if k != "source" and k != "target":
        # Convert JsonNode to string for EdgeAttr compatibility
        case v.kind
        of JFloat: attr[k] = $v.getFloat()
        of JInt: attr[k] = $v.getInt()
        of JBool: attr[k] = $v.getBool()
        of JString: attr[k] = v.getStr()
        else: attr[k] = $v
    result.addEdge(source, target, attr)

# --- Cytoscape JSON format ---

proc cytoscapeData*[N](g: Graph[N]): JsonNode =
  ## Convert graph to Cytoscape JSON format.
  result = newJObject()
  var elements = newJArray()
  for n in g.nodes:
    var nodeObj = newJObject()
    var data = newJObject()
    data["id"] = newJString($n)
    let attr = g.getNodeAttr(n)
    for k, v in attr:
      data[k] = v
    nodeObj["data"] = data
    nodeObj["group"] = newJString("nodes")
    elements.add(nodeObj)
  for (u, v, attr) in g.edgesWithAttr:
    var edgeObj = newJObject()
    var data = newJObject()
    data["source"] = newJString($u)
    data["target"] = newJString($v)
    for k, val in attr:
      data[k] = newJString(val)
    edgeObj["data"] = data
    edgeObj["group"] = newJString("edges")
    elements.add(edgeObj)
  result["elements"] = elements

proc cytoscapeData*[N](g: DiGraph[N]): JsonNode =
  ## Convert directed graph to Cytoscape JSON format.
  result = newJObject()
  var elements = newJArray()
  for n in g.nodes:
    var nodeObj = newJObject()
    var data = newJObject()
    data["id"] = newJString($n)
    nodeObj["data"] = data
    nodeObj["group"] = newJString("nodes")
    elements.add(nodeObj)
  for (u, v, attr) in g.edgesWithAttr:
    var edgeObj = newJObject()
    var data = newJObject()
    data["source"] = newJString($u)
    data["target"] = newJString($v)
    for k, val in attr:
      data[k] = newJString(val)
    edgeObj["data"] = data
    edgeObj["group"] = newJString("edges")
    elements.add(edgeObj)
  result["elements"] = elements

proc cytoscapeGraph*(data: JsonNode): Graph[string] =
  ## Create a graph from Cytoscape JSON format.
  result = newGraph[string]()
  for elem in data["elements"]:
    let group = elem["group"].getStr()
    if group == "nodes":
      let id = elem["data"]["id"].getStr()
      result.addNode(id)
    elif group == "edges":
      let source = elem["data"]["source"].getStr()
      let target = elem["data"]["target"].getStr()
      result.addEdge(source, target)

# --- Tree JSON format ---

proc treeData*[N](g: Graph[N], root: N): JsonNode =
  ## Convert a tree graph to a nested JSON tree format rooted at `root`.
  var visited = initHashSet[N]()
  proc buildTree(g: Graph[N], visited: var HashSet[N], node: N): JsonNode =
    result = newJObject()
    result["id"] = newJString($node)
    visited.incl(node)
    var children = newJArray()
    for nb in g.neighbors(node):
      if nb notin visited:
        children.add(buildTree(g, visited, nb))
    if children.len > 0:
      result["children"] = children
  result = buildTree(g, visited, root)

proc treeData*[N](g: DiGraph[N], root: N): JsonNode =
  ## Convert a directed tree to nested JSON tree format rooted at `root`.
  proc buildTree(g: DiGraph[N], node: N): JsonNode =
    result = newJObject()
    result["id"] = newJString($node)
    var children = newJArray()
    for nb in g.neighbors(node):
      children.add(buildTree(g, nb))
    if children.len > 0:
      result["children"] = children
  result = buildTree(g, root)

proc treeGraph*(data: JsonNode): Graph[string] =
  ## Create a graph from nested JSON tree format.
  var g = newGraph[string]()
  proc addFromNode(g: var Graph[string], js: JsonNode) =
    let id = js["id"].getStr()
    g.addNode(id)
    if "children" in js:
      for child in js["children"]:
        let childId = child["id"].getStr()
        g.addEdge(id, childId)
        g.addFromNode(child)
  g.addFromNode(data)
  result = g

# --- Adjacency JSON format ---

proc adjacencyData*[N](g: Graph[N]): JsonNode =
  ## Convert graph to JSON adjacency format.
  ## Format: array of {id, adjacency: [{id, ...}, ...]} objects.
  result = newJArray()
  for n in g.nodes:
    var nodeObj = newJObject()
    nodeObj["id"] = newJString($n)
    var adj = newJArray()
    for nb in g.neighbors(n):
      var nbObj = newJObject()
      nbObj["id"] = newJString($nb)
      let eattr = g.getEdgeAttr(n, nb)
      for k, v in eattr:
        nbObj[k] = newJString(v)
      adj.add(nbObj)
    nodeObj["adjacency"] = adj
    result.add(nodeObj)

proc adjacencyData*[N](g: DiGraph[N]): JsonNode =
  ## Convert directed graph to JSON adjacency format.
  result = newJArray()
  for n in g.nodes:
    var nodeObj = newJObject()
    nodeObj["id"] = newJString($n)
    var adj = newJArray()
    for nb in g.neighbors(n):
      var nbObj = newJObject()
      nbObj["id"] = newJString($nb)
      let eattr = g.getEdgeAttr(n, nb)
      for k, v in eattr:
        nbObj[k] = newJString(v)
      adj.add(nbObj)
    nodeObj["adjacency"] = adj
    result.add(nodeObj)

proc adjacencyGraph*(data: JsonNode): Graph[string] =
  ## Create a graph from JSON adjacency format.
  result = newGraph[string]()
  for nodeObj in data:
    let id = nodeObj["id"].getStr()
    result.addNode(id)
    for nbObj in nodeObj["adjacency"]:
      let nbId = nbObj["id"].getStr()
      result.addEdge(id, nbId)
