## SVG graph visualization output.
##
## - ``writeSvg`` — render a graph to SVG with a given layout

import std/[tables, strformat, strutils, math, streams]
import ../types, ../graph, ../digraph
import ../algorithms/layout

type
  SvgOptions* = object
    width*: int
    height*: int
    nodeRadius*: float
    nodeColor*: string
    edgeColor*: string
    fontSize*: float
    showLabels*: bool
    margin*: float

proc defaultSvgOptions*(): SvgOptions =
  SvgOptions(
    width: 800,
    height: 600,
    nodeRadius: 8.0,
    nodeColor: "#4A90D9",
    edgeColor: "#999999",
    fontSize: 10.0,
    showLabels: true,
    margin: 40.0,
  )

proc scaleLayout[N](pos: Layout[N], width, height: int,
                      margin: float): Layout[N] =
  ## Scale positions to fit within the SVG canvas.
  result = initTable[N, Position]()
  if pos.len == 0:
    return

  var minX, minY, maxX, maxY: float
  var first = true
  for n, p in pos:
    if first:
      minX = p.x; maxX = p.x
      minY = p.y; maxY = p.y
      first = false
    else:
      if p.x < minX: minX = p.x
      if p.x > maxX: maxX = p.x
      if p.y < minY: minY = p.y
      if p.y > maxY: maxY = p.y

  let rangeX = maxX - minX
  let rangeY = maxY - minY
  let scaleX = if rangeX > 1e-10: (float(width) - 2.0 * margin) / rangeX else: 1.0
  let scaleY = if rangeY > 1e-10: (float(height) - 2.0 * margin) / rangeY else: 1.0

  for n, p in pos:
    let x = if rangeX > 1e-10: margin + (p.x - minX) * scaleX
            else: float(width) / 2.0
    let y = if rangeY > 1e-10: margin + (p.y - minY) * scaleY
            else: float(height) / 2.0
    result[n] = (x, y)

proc xmlEscape(s: string): string =
  result = s
  result = result.replace("&", "&amp;")
  result = result.replace("<", "&lt;")
  result = result.replace(">", "&gt;")
  result = result.replace("\"", "&quot;")

proc writeSvg*[N](g: Graph[N], pos: Layout[N], filename: string,
                   opts: SvgOptions = defaultSvgOptions()) =
  ## Write an undirected graph as SVG.
  let fs = newFileStream(filename, fmWrite)
  if fs.isNil:
    raise newException(IOError, fmt"Cannot open file: {filename}")
  defer: fs.close()

  let scaled = scaleLayout(pos, opts.width, opts.height, opts.margin)

  fs.writeLine(fmt"""<?xml version="1.0" encoding="UTF-8"?>""")
  fs.writeLine(fmt"""<svg xmlns="http://www.w3.org/2000/svg" width="{opts.width}" height="{opts.height}" viewBox="0 0 {opts.width} {opts.height}">""")
  fs.writeLine(fmt"""  <rect width="100%" height="100%" fill="white"/>""")

  # Draw edges
  for (u, v) in g.edges:
    if u in scaled and v in scaled:
      let p1 = scaled[u]
      let p2 = scaled[v]
      fs.writeLine(fmt"""  <line x1="{p1.x:.2f}" y1="{p1.y:.2f}" x2="{p2.x:.2f}" y2="{p2.y:.2f}" stroke="{opts.edgeColor}" stroke-width="1.5"/>""")

  # Draw nodes
  for n, p in scaled:
    fs.writeLine(fmt"""  <circle cx="{p.x:.2f}" cy="{p.y:.2f}" r="{opts.nodeRadius}" fill="{opts.nodeColor}" stroke="#333333" stroke-width="1"/>""")
    if opts.showLabels:
      let label = xmlEscape($n)
      fs.writeLine(fmt"""  <text x="{p.x:.2f}" y="{p.y + opts.nodeRadius + opts.fontSize + 2.0:.2f}" text-anchor="middle" font-size="{opts.fontSize}">{label}</text>""")

  fs.writeLine("</svg>")

proc writeSvg*[N](g: DiGraph[N], pos: Layout[N], filename: string,
                   opts: SvgOptions = defaultSvgOptions()) =
  ## Write a directed graph as SVG with arrow markers.
  let fs = newFileStream(filename, fmWrite)
  if fs.isNil:
    raise newException(IOError, fmt"Cannot open file: {filename}")
  defer: fs.close()

  let scaled = scaleLayout(pos, opts.width, opts.height, opts.margin)

  fs.writeLine(fmt"""<?xml version="1.0" encoding="UTF-8"?>""")
  fs.writeLine(fmt"""<svg xmlns="http://www.w3.org/2000/svg" width="{opts.width}" height="{opts.height}" viewBox="0 0 {opts.width} {opts.height}">""")
  fs.writeLine("""  <defs><marker id="arrow" viewBox="0 0 10 10" refX="10" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="#666666"/></marker></defs>""")
  fs.writeLine(fmt"""  <rect width="100%" height="100%" fill="white"/>""")

  # Draw edges with arrows
  for (u, v) in g.edges:
    if u in scaled and v in scaled:
      let p1 = scaled[u]
      let p2 = scaled[v]
      # Shorten line to not overlap with node circle
      let dx = p2.x - p1.x
      let dy = p2.y - p1.y
      let dist = sqrt(dx * dx + dy * dy)
      if dist > 1e-10:
        let ratio = opts.nodeRadius / dist
        let x1 = p1.x + dx * ratio
        let y1 = p1.y + dy * ratio
        let x2 = p2.x - dx * ratio
        let y2 = p2.y - dy * ratio
        fs.writeLine(fmt"""  <line x1="{x1:.2f}" y1="{y1:.2f}" x2="{x2:.2f}" y2="{y2:.2f}" stroke="{opts.edgeColor}" stroke-width="1.5" marker-end="url(#arrow)"/>""")

  # Draw nodes
  for n, p in scaled:
    fs.writeLine(fmt"""  <circle cx="{p.x:.2f}" cy="{p.y:.2f}" r="{opts.nodeRadius}" fill="{opts.nodeColor}" stroke="#333333" stroke-width="1"/>""")
    if opts.showLabels:
      let label = xmlEscape($n)
      fs.writeLine(fmt"""  <text x="{p.x:.2f}" y="{p.y + opts.nodeRadius + opts.fontSize + 2.0:.2f}" text-anchor="middle" font-size="{opts.fontSize}">{label}</text>""")

  fs.writeLine("</svg>")

proc toSvgString*[N](g: Graph[N], pos: Layout[N],
                      opts: SvgOptions = defaultSvgOptions()): string =
  ## Return SVG content as a string.
  let scaled = scaleLayout(pos, opts.width, opts.height, opts.margin)

  result = fmt"""<?xml version="1.0" encoding="UTF-8"?>""" & "\n"
  result.add fmt"""<svg xmlns="http://www.w3.org/2000/svg" width="{opts.width}" height="{opts.height}" viewBox="0 0 {opts.width} {opts.height}">""" & "\n"
  result.add fmt"""  <rect width="100%" height="100%" fill="white"/>""" & "\n"

  for (u, v) in g.edges:
    if u in scaled and v in scaled:
      let p1 = scaled[u]
      let p2 = scaled[v]
      result.add fmt"""  <line x1="{p1.x:.2f}" y1="{p1.y:.2f}" x2="{p2.x:.2f}" y2="{p2.y:.2f}" stroke="{opts.edgeColor}" stroke-width="1.5"/>""" & "\n"

  for n, p in scaled:
    result.add fmt"""  <circle cx="{p.x:.2f}" cy="{p.y:.2f}" r="{opts.nodeRadius}" fill="{opts.nodeColor}" stroke="#333333" stroke-width="1"/>""" & "\n"
    if opts.showLabels:
      let label = xmlEscape($n)
      result.add fmt"""  <text x="{p.x:.2f}" y="{p.y + opts.nodeRadius + opts.fontSize + 2.0:.2f}" text-anchor="middle" font-size="{opts.fontSize}">{label}</text>""" & "\n"

  result.add "</svg>\n"
