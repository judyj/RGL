!#/usr/bin/env ruby

require "gviz"

$procrow = Hash.new
$boxes = Array.new {Hash.new}

# get the list of processes to a file
infile = 'i4_processes'
# this lsof command lists files using ipv4
#
# NOTE that i pre-sort this file by columns 1 and 3 (user and process name)
system ("lsof -i4 | sort -k1 -k3 > #{infile}")

# create a new graph

# counting number of records in out file
$proc_counter = 0

# read the file, one line at a time
IO.foreach(infile) do |line|
 
  $procrow = Hash.new
  f1 = line.split(' ')
# now get process, owner and name
   $procrow["proc_id"] = f1[1]
   $procrow["owner"] = f1[2]
   $procrow["procname"] = f1[0]   # process name
   wholefilename = f1[8]  # file

# split the filename -- after the colon is the port, after the -> is the file 
   portplace = wholefilename.index(':')   
#puts "file is #{wholefilename}"
   if (portplace != nil) then     # colon
     hoststring = wholefilename[0,portplace]
     portstring = wholefilename[portplace+1,wholefilename.length-1]
     fileplace = portstring.index('-')
     if fileplace != nil then        # file nil
       port = portstring[0,fileplace]
       file = portstring[fileplace+2,portstring.length-1]
     else                            # file nil
#       port = '0'
#       file = '0'
       if (portstring != nil) then   # space 
         port = portstring
         file = f1[9]
       else                      # no space
         port = '0'
         file = '0'
       end                       # space?
     end                             # file nil
   else                      # no colon
      port = '0'
      file = '0'
   end                       # colon?
# add those two fileds to the array - note the record numbers for all those fields match (proc_counter)   
   $procrow["portno"] = port
   $procrow["filename"] = file
   $procrow["hostname"] = hoststring

# write to array (but blow off the headers)
   if $proc_counter != 0
     $boxes << $procrow
   end

# increment the record counter
   $proc_counter += 1

end                       # end file

#puts "done, let's debug"

# prepare a file
outfilename = 'i4_processes_sorted'  # write to a file
outfile = File.open(outfilename, 'w')

$proc_counter = 0
# write it out
$boxes.each do |hash|
#  puts "writing to file row #{$proc_counter}"
#  puts $boxes[$proc_counter]
  outfile.puts $boxes[$proc_counter]
  $proc_counter += 1
end                             # each row of array
outfile.close
#puts "done file"

# do graph
gv = Gviz.new 
gv.graph do

global :rankdir => 'LR'

# make hash of user/process combos and one of files
$userprocess = Array.new
$files = Array.new
$hosts = Array.new
$counter = 0
$boxes.each do |row|
  if $counter == 0
    $userprocess << row["owner"]+row["procname"]
    $files << row["filename"]
    $hosts << row["hostname"]
  else
    if !$userprocess.include?(row["owner"]+row["procname"]) 
      $userprocess << row["owner"]+row["procname"]
    end
    if !$files.include?(row["filename"]) 
      $files << row["filename"]
    end
    if !$hosts.include?(row["hostname"]) 
      $hosts << row["hostname"]
    end
  end   # if first entry
  $counter += 1
end  #each box
#puts "files is #{$files}"
#puts "user_process is #{$userprocess}"
#puts "hosts is #{$hosts}"

# for each distinct user/process combo add a subgraph, then for matching rows add a node in that subgraph
#
$uprows = Array.new($boxes.size)
$upno = 0
$userprocess.each do |up|
subgraph {
  nodes :style => 'filled', :shape => 'box'
  global :color => 'red', :label => "#{up}"
  $rowno = 0
  $boxes.each do |row|
    if row["owner"]+row["procname"] == up
      node :"#{$upno}", label:"#{row["portno"]}"
      $uprows[$rowno] = $upno
      $upno += 1
    end  # if
    $rowno += 1
  end  # each row in array of all comms
}
end # each process

$filerows = Array.new($boxes.size)
$fileno = 0
# now the filenames on the other side# 
$files.each do |fi|
subgraph {
  nodes :style => 'filled', :shape => 'point'
#  nodes :style => 'filled', :shape => 'box'
  global :color => 'blue', :label => "#{fi}"
  $rowno = 0
  $boxes.each do |row|
   if row["filename"] == fi
      node :"#{$upno}", label:"#{row["filename"]}"
      $filerows[$rowno] = $upno
      $upno += 1
    end # if match
      $rowno += 1
  end # each row in array of all comms
}
end  # each file


$hostrows = Array.new($boxes.size)
$hostno = 0
# now the filenames on the other side# 
$hosts.each do |ho|
subgraph {
  global :color => 'green', :label => "#{ho}"

}
$upno += 1
end  # each host

end

# for each row, link the process to the file
for count in 0 .. $boxes.count-1
  gv.route :"#{$uprows[count]}" => :"#{$filerows[count]}"
end

# write the dot file
gv.save(:proc_links)

# convert to jpg
exec "dot -Tjpg proc_links.dot -o proc_links.jpg"
# YAY


