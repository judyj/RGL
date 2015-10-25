#!/usr/bin/env ruby
require 'rgl/adjacency'
require 'rgl/implicit'
require 'rgl/traversal'
require 'rgl/dot'

# create graph
thegraph = RGL::AdjacencyGraph.new

# add the connections
thegraph.add_edge 1, 2
thegraph.add_edge 2, 3
thegraph.add_edge 2, 4
thegraph.add_edge 2, 5

thegraph.add_edge 1, 6
thegraph.add_edge 6, 10
thegraph.add_edge 6, 7
thegraph.add_edge 7, 8
thegraph.add_edge 7, 9
thegraph.add_edge 7, 5

# this line will create a png and a .dot file
thegraph.write_to_graphic_file('png', "newgraphic")

# YAY!
