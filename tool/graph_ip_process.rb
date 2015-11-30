!#/usr/bin/env ruby
#######################
#
# This requires 
# $yum install ruby 
# $yum install 'graphviz*'
# $gem install gviz
#
#######################

require "gviz"
require 'socket'

$procrow = Hash.new
$boxes = Array.new {Hash.new}
$colors = Array['yellow','green','orange','violet', 'turquoise', 'gray','brown']

# get the list of processes to a file
infile = 'i4_processes'

# this lsof command lists files using ipv4 to a file
# comment out for a test file
system ("lsof -i4 -n > #{infile}")

# counting number of records in out file
$proc_counter = 0

# read the file, one line at a time
IO.foreach(infile) do |line|
  # create a hash for all the significant info 
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
#    see if anything after the colon - which would be the portnumber
   if (portplace != nil) then     # colon
     hoststring = wholefilename[0,portplace]
     portstring = wholefilename[portplace+1,wholefilename.length-1]
     fileplace = portstring.index('-')
#    see if anything after the -> which would be the ip we are writing to
     if (fileplace != nil) && (portstring[fileplace+1] == '>') then        # file nil (and make sure the '-' is part of a '->')
       port = portstring[0,fileplace]
       tempfile = portstring[fileplace+2,portstring.length-1]
       colonplace = tempfile.index(':')
       if (colonplace == nil) then
          file=tempfile
       else
          file=tempfile[0,colonplace]
       end
     else                            # file nil
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
# add those two fields to the array - note the record numbers for all those fields match (proc_counter) so that we can connect them later
   $procrow["portno"] = port
   $procrow["filename"] = file
   $procrow["hostname"] = hoststring

# write to array (but blow off the headers)
   if ($proc_counter > 0) then
     $boxes << $procrow
   end

# increment the record counter
   $proc_counter += 1
end                       # end reading file

# prepare an output file to save the hashes for now (this file is a just-in-case)
outfilename = 'i4_processes_sorted'  # write to a file
outfile = File.open(outfilename, 'w')

# write it out to file
$boxes.each do |hash|
  outfile.puts hash
end                             # each row of array
outfile.close

# make hash of user/process combos and of files (which is really just destination IPs when you run -i4) and of hosts (source IP)
$userprocess = Array.new
$files = Array.new
$hosts = Array.new
$owners = Array.new
$counter = 0

# for each box (row in the output)
$boxes.each do |row|
  # create entry to ensure we have a distinct host/row/process combination - those will be the smallest boxes
  $entry = "#{row["hostname"]}-#{row["owner"]}-#{row["procname"]}"
  # first entry is always 
  if ($counter == 0) then
    $userprocess << $entry
    $hosts << row["hostname"]
    $owners << row["owner"]
    $files << row["filename"]
  else
    # if the other fields are not yet in the arrays, add them -- each array should contain one copy of each 
    if (!$userprocess.include?$entry) then
      $userprocess <<  $entry
    end
    if (!$hosts.include?(row["hostname"])) then
      $hosts << row["hostname"]
    end
    if (!$files.include?(row["filename"])) then
      $files << row["filename"]
    end
    if (!$owners.include?(row["owner"])) then
      $owners << row["owner"]
    end
  end   # if first entry
  $counter += 1
end  #each box

# do graph
gv = Gviz.new 
gv.graph do
# rank TB makes the graph go from top to bottom - works better right now with the CentOS version
# rank LR draws left to right which is easier to read
  global :rankdir => 'LR'
# global :rankdir => 'TB'

# now set up subgraphs for the sources
  $uprows = Array.new($boxes.size) 
  $upno = 0
  $hostcount = 0
  $hosts.each do |ho|
  $thishost = ho.to_s
  subgraph do  # big - for each host
    global :color => 'black', :label => "#{ho}"
    nodes :style => 'filled', :shape => 'point'
    $upno += 1
    node :"p#{$hostcount}"

#   for each distinct user/process combo add a subgraph, then for matching rows add a node in that subgraph
    $filerows = Array.new($boxes.size)
    $userprocess.each do |up|
      subgraph do
        nodes :style => 'filled', :shape => 'box'
        global :color => 'red', :label => "#{up}"
        $upno +=1
        $rowno = 0
        $boxes.each do |row|
          $entry = "#{row["hostname"]}-#{row["owner"]}-#{row["procname"]}"
          $myhost = row["hostname"].to_s
          if ($entry == up) && ($myhost == $thishost) then
            node :"#{$upno}", label:"#{row["portno"]}"
            $uprows[$rowno] = $upno
            $upno += 1
          end  # if  it is a match for its big box   
          $rowno += 1
        end  # each row in array of all comms
      end #subgraph for up
    end # userprocs
  end # end of big subgraph
$hostcount += 1
end  # end of host loop

# now the filenames on the other side 
$files.each do |fi|
subgraph do
  nodes :style => 'filled', :shape => 'point'
  global :color => 'blue', :label => "#{fi}"
  $upno += 1
  $rowno = 0
  $boxes.each do |row| 
   if (row["filename"] == fi) && ($hosts.include?(fi)) then
      hostindex = $hosts.index(fi)
      $filerows[$rowno] = "p#{hostindex}"
   elsif (row["filename"] == fi) then
      node :"#{$upno}", label:"#{row["filename"]}"
      $filerows[$rowno] = $upno
      $upno += 1
    end # if match
    $rowno += 1
  end # each row in array of all comms
end # filename
end  # each file


# for each row, link the process to the file
# alternate colors among the ones we named up top -- we can experiment with this scheme
if ($boxes.count > 0) then
  for count in 0 .. $boxes.count-1
     if ($uprows[count] != nil && $filerows[count] != nil) then
       colorcode =  count.modulo($colors.size)
       edge :"#{$uprows[count]}_#{$filerows[count]}", :color => $colors[colorcode]
     end    # if neither end is nil
  end       # for each line
end         #if there is data

end #gv

# is there any data in here?
if ($boxes.count <= 0) then 
  puts "No processes to plot."
else    
# write the dot file
  gv.save(:"#{infile}")
# convert to jpg
# note - if this errors out, we still have the dot file.  
# Conversion may not work on some versions, and may be convertable to the jpg on another system
  exec "dot -Tjpg #{infile}.dot -o #{infile}.jpg"
end

# YAY


