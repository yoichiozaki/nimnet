## nimnet — A network science library for Nim
##
## .. code-block:: nim
##   import nimnet
##
##   var g = newGraph[int]()
##   g.addEdgesFrom([(1,2), (2,3), (3,1)])
##   assert 1 in g
##   assert g.len == 3
##   echo g  # Graph(nodes=3, edges=3)

# --- Core ---
import nimnet/types;       export types
import nimnet/graph;       export graph
import nimnet/digraph;     export digraph

# --- Algorithms ---
import nimnet/algorithms/traversal;      export traversal
import nimnet/algorithms/shortest_paths; export shortest_paths
import nimnet/algorithms/components;     export components
import nimnet/algorithms/centrality;     export centrality
import nimnet/algorithms/clustering;     export clustering
import nimnet/algorithms/community;      export community
import nimnet/algorithms/mst;            export mst
import nimnet/algorithms/dag;            export dag
import nimnet/algorithms/flow;           export flow

# --- Generators ---
import nimnet/generators/classic; export classic
import nimnet/generators/random;  export random
import nimnet/generators/small;   export small
import nimnet/generators/trees;   export trees

# --- I/O ---
import nimnet/io/edgelist;   export edgelist
import nimnet/io/adjlist;    export adjlist
import nimnet/io/json_graph; export json_graph
import nimnet/io/dot;        export dot

# --- Operators & Conversions ---
import nimnet/operators; export operators
import nimnet/convert;   export convert
