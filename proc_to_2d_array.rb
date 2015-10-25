!#/usr/bin/env ruby

require 'rgl/adjacency'
require 'rgl/dot'
require 'rgl/rdot'
require 'rgl/implicit'
require 'rgl/traversal'
require 'rgl/bidirectional'

include RGL

$proc_id = Array.new # process ID (number)
$owner = Array.new   # owner
$procname = Array.new
$portno = Array.new
$filename = Array.new
$procrow = Array.new
$boxes = Array.new {Array.new}

# get the list of processes to a file
infile = 'i4_processes'
# this lspf command lists files using ipv4
# NOTE that i pre-sort this file by columns 1 and 3 (user and process name)
system ("lsof -i4 | sort -k1 -k3 > #{infile}")

# create a new graph
processes = RGL::ImplicitGraph.new

# counting number of records in out file
$proc_counter = 0

# read the file, one line at a time
IO.foreach(infile) do |line|
 
  f1 = line.split(' ')
# now get process, owner and name
   $proc_id[$proc_counter] = f1[1]
   $owner[$proc_counter] = f1[2]
   $procname[$proc_counter] = f1[0]   # process name
   wholefilename = f1[8]  # file

# split the filename -- after the colon is the port, after the -> is the file 
   portplace = wholefilename.index(':')   
#puts "file is #{wholefilename}"
   if (portplace != nil) then
     portstring = wholefilename[portplace+1,wholefilename.length-1]
     fileplace = portstring.index('-')
     if fileplace != nil then        # file nil
       port = portstring[0,fileplace]
       file = portstring[fileplace+2,portstring.length-1]
     else                            # file nil
      port = '0'
      file = '0'
     end                             # file nil
   else                      # nil port
      port = '0'
      file = '0'
   end                       # port not a null string
# add those two fileds to the array - note the record numbers for all those fields match (proc_counter)   
   $portno[$proc_counter] = port
   $filename[$proc_counter] = file

#   puts "process is #{$proc_id[$proc_counter]}, owner is #{$owner[$proc_counter]}, name is #{$procname[$proc_counter]} file is #{$filename[$proc_counter]}, port is #{$portno[$proc_counter]}"

# increment the record counter
   $proc_counter += 1
end                       # end file

# now given the user and the process, group up ones with matching owner and process name
count = 0
numgroups = -1

# for each ine in the array we've read in
$proc_id.each do | process_id |
# ok, so you have a new owner or process  
#puts "count is #{count}, process is #{$proc_id[count]}, owner is #{$owner[count]}, name is #{$procname[count]}, file is #{$filename[count]}, port is #{$portno[count]}"
#puts "numgroups is #{numgroups}, prev owner is #{$owner[count-1]}, name is #{$procname[count-1]} "

# doesn't match, increment the counter and set up the port and file 
  if (numgroups > -1) then # make sure we arent at first record so we can compare to previous
    if  ($owner[count] != $owner[count-1]) ||  ($procname[count] != $procname[count-1]) then   # check for change
#     create a new group and flush out last group's array
      $boxes[numgroups] = $procrow
      numgroups += 1
      $procrow = Array.new
      $procrow.clear

#     add the owner and process name to start the new array      
      $procrow.push($owner[count])
      $procrow.push($procname[count])
      # puts "process is #{$proc_id[count]}, owner is #{$owner[count]}, name is #{$procname[count]}, file is #{$filename[count]}, port is #{$portno[count]}"
      # puts "numgroups is #{numgroups}, prev owner is #{$owner[count-1]}, name is #{$procname[count-1]} "
     end  # change owner or proc
   else                        # case of first record
      # create first record with process and owner
      numgroups += 1
      $procrow = Array.new
      $procrow.clear
      $procrow.push($owner[count])
      $procrow.push($procname[count])
  end                          #first record?
# either way, add the newest row number in
  $procrow.push(count)     

# next row
  count += 1

end                             # rows in file

# get the last row
$boxes[numgroups] = $procrow

# now we're done - let's print out our array rows!
puts "done, let's debug"
# prepare a file
outfilename = 'i4_processes_sorted'  # write to a file
outfile = File.open(outfilename, 'w')

# write it out
$boxes.each do |row|
  puts row.each { |entry| entry }.join(" ")
  outfile.puts row.each { |entry| entry }.join(" ")
end                             # each row of array
outfile.close

# YAY


