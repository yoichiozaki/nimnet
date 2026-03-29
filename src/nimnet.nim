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
import nimnet/algorithms/bridges;            export bridges
import nimnet/algorithms/ego;                export ego
import nimnet/algorithms/distance_measures;  export distance_measures
import nimnet/algorithms/simple_paths;       export simple_paths
import nimnet/algorithms/efficiency;         export efficiency
import nimnet/algorithms/richclub;           export richclub
import nimnet/algorithms/wiener;             export wiener
import nimnet/algorithms/cycles;             export cycles
import nimnet/algorithms/matching;           export matching
import nimnet/algorithms/graph_products;     export graph_products
import nimnet/algorithms/triads;             export triads
import nimnet/algorithms/minors;             export minors
import nimnet/algorithms/cuts;               export cuts
import nimnet/algorithms/smallworld;         export smallworld
import nimnet/algorithms/lca;                export lca
import nimnet/algorithms/graph_hashing;      export graph_hashing
import nimnet/algorithms/voronoi;            export voronoi
import nimnet/algorithms/similarity;         export similarity
import nimnet/algorithms/spectral;           export spectral
import nimnet/algorithms/layout;             export layout
import nimnet/algorithms/parallel;           export parallel
import nimnet/algorithms/isolates;           export isolates
import nimnet/algorithms/structural_holes;   export structural_holes
import nimnet/algorithms/chordal;            export chordal
import nimnet/algorithms/tournament;         export tournament
import nimnet/algorithms/communicability;    export communicability
import nimnet/algorithms/d_separation;       export d_separation
import nimnet/algorithms/swaps;              export swaps
import nimnet/algorithms/polynomials;        export polynomials
import nimnet/algorithms/network_flow;       export network_flow
import nimnet/algorithms/node_classification; export node_classification
import nimnet/algorithms/leiden;             export leiden
import nimnet/algorithms/approximation;      export approximation
import nimnet/algorithms/misc;               export misc

# --- Generators ---
import nimnet/generators/classic;          export classic
import nimnet/generators/random;           export random
import nimnet/generators/small;            export small
import nimnet/generators/trees;            export trees
import nimnet/generators/line_graph;       export line_graph
import nimnet/generators/lattice;          export lattice
import nimnet/generators/geometric;        export geometric
import nimnet/generators/community;        export community
import nimnet/generators/degree_sequence;  export degree_sequence
import nimnet/generators/directed;         export directed

# --- I/O ---
import nimnet/io/edgelist;   export edgelist
import nimnet/io/adjlist;    export adjlist
import nimnet/io/json_graph; export json_graph
import nimnet/io/dot;        export dot
import nimnet/io/gml;        export gml
import nimnet/io/graphml;    export graphml
import nimnet/io/gexf;       export gexf
import nimnet/io/pajek;      export pajek
import nimnet/io/graph6;     export graph6
import nimnet/io/svg;        export svg

# --- Operators & Conversions ---
import nimnet/operators; export operators
import nimnet/convert;   export convert
import nimnet/builder;   export builder
import nimnet/datasets;  export datasets
import nimnet/views;     export views
import nimnet/multigraph; export multigraph
import nimnet/compact;   export compact
import nimnet/static_graph; export static_graph
