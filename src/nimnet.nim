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
import nimnet/algorithms/properties;     export properties
import nimnet/algorithms/link_prediction; export link_prediction
import nimnet/algorithms/core;           export core
import nimnet/algorithms/stats;          export stats
import nimnet/algorithms/clique;         export clique
import nimnet/algorithms/independent_set; export independent_set
import nimnet/algorithms/dominating;     export dominating
import nimnet/algorithms/coloring;       export coloring
import nimnet/algorithms/bipartite;      export bipartite
import nimnet/algorithms/euler;          export euler
import nimnet/algorithms/all_pairs_shortest; export all_pairs_shortest
import nimnet/algorithms/connectivity;   export connectivity
import nimnet/algorithms/louvain;        export louvain
import nimnet/algorithms/isomorphism;    export isomorphism
import nimnet/algorithms/planarity;      export planarity
import nimnet/algorithms/tsp;            export tsp
import nimnet/algorithms/min_cost_flow;  export min_cost_flow
import nimnet/algorithms/tree_decomposition; export tree_decomposition

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
import nimnet/io/gml;        export gml
import nimnet/io/graphml;    export graphml

# --- Operators & Conversions ---
import nimnet/operators; export operators
import nimnet/convert;   export convert
import nimnet/builder;   export builder
import nimnet/datasets;  export datasets
