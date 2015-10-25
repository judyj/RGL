#!/usr/bin/env ruby
## This code creates a .dot file (by brute force) of processes, linking them to their parents 
## Then turns this into a jpeg 

# library includes
require 'rgl/adjacency'
require 'rgl/dot'
require 'rgl/implicit'
require 'rgl/traversal'

# get list of processes
 system('lsof -R > processes')

# set up file
procname = 'processes'
puts "file is #{procname}"

# initialize
  $proc_counter = 0       # loop counter for process number in list
  $proc_id =Array.new     # process ID 
  $parent = Array.new     # ID of parent
  $procname = Array.new   # process name
  $filename = Array.new   # filename
  $parent_id = Array.new  # counter of parent

# now read the file one line at a time
IO.foreach('processes') do |line|
  
  f1 = line.split(' ')
# now get process, parent and name
  $proc_id[$proc_counter] = f1[1]
  $parent[$proc_counter] = f1[2]
  $procname[$proc_counter] = f1[0] # process
  $filename[$proc_counter] = f1[9]  # file
  $parent_id[$proc_counter] = -1
#  puts "process is #{$proc_id[$proc_counter]}, parent is #{$parent[$proc_counter]}, name is #{$procname[$proc_counter]} #{$filename[$proc_counter]}"

# find the parent process
  $count = 0
  while $count < $proc_counter && $parent_id[$proc_counter] == -1 do
    if $proc_id[$count] == $parent[$proc_counter] then 
       $parent_id[$proc_counter] = $count 
     end # if parent matches
#     puts "count is #{$count}, match is #{$parent_id[$proc_counter]}"
#   on to the next line
     $count += 1
end # while not done and not found

# if you didn't find the parent, just set to 0 (which is actually the first line of file with the field labels!
if $parent[$proc_counter] == -1
       $parent_id[$proc_counter] = 0
 end # nothing found
 

# print a message every few records to make sure your user doesnt think the process has died
  if $proc_counter %200 == 0 then
        puts "on record #{$proc_counter}" 
  end   
  $proc_counter += 1
end
 

# open and write beginning of file
dotfilename = 'process_list.dot'
dotfile = File.open(dotfilename, 'w')
dotfile.write ( "digraph RGL_DirectedAdjacencyGraph {\n")

# set up the graph nodes in dot file
count = 0
$proc_id.each do | process_id |
  if $proc_id[count] != $proc_id[count-1] || count == 0 then
# number, fontsize, label
  puts "This is a new proc_id #{process_id}"
    dotfile.write ("  #{count} [\n")
    dotfile.write ("     fontsize = 8,\n")
    dotfile.write ("     label = \"#{$procname[count]} #{$filename[count]}\" \n")
    dotfile.write ("  ] \n")
  end
  count += 1
  if count %100 == 0 then
        puts "on record #{count} of #{$proc_counter}"
   end
end

# set up the parent/child relationships in dot file
count = 0
$proc_id.each do | process_id |
#  puts "This is the proc_id #{process_id} for count #{count} title #{$procname[count]}"
# link to parent 
  if $proc_id[count] != $proc_id[count-1] || count == 0 then
    dotfile.write ("  #{$parent_id[count]} -> #{count} [\n")
    dotfile.write ("     fontsize = 8,\n")
    dotfile.write ("  ] \n")
  end
  count += 1
end
  dotfile.write ("}\n")
  dotfile.close

# run the dot command to create a jpeg
#
 print "dot -Tjpg #{dotfilename} -o process_diagram.jpg"
 exec "dot -Tjpg #{dotfilename} -o process_diagram.jpg"
 exec "firefox process_diagram.jpg"
#
# YAY!
