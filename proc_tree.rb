!#/usr/bin/env ruby

require "gviz"

$procrow = Hash.new
$boxes = Array.new {Hash.new}

# get the list of processes to a file
infile = 'i4_processes'
# this lsof command lists files using ipv4 to a file
#
# NOTE that i pre-sort this file by columns 1 and 3 (user and process name)
# temporary jjsystem ("lsof -i4 | sort -k1 -k3 > #{infile}")

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
# add those two fields to the array - note the record numbers for all those fields match (proc_counter)   
   $procrow["portno"] = port
   $procrow["filename"] = file
   $procrow["hostname"] = hoststring

# write to array (but blow off the headers)
   if $proc_counter > 0
     $boxes << $procrow
   end

# increment the record counter
   $proc_counter += 1
end                       # end file

# prepare a file
outfilename = 'i4_processes_sorted'  # write to a file
outfile = File.open(outfilename, 'w')

# write it out
$boxes.each do |hash|
  outfile.puts hash
end                             # each row of array
outfile.close
#puts "done file"

# make hash of user/process combos and one of files
$userprocess = Array.new
$files = Array.new
$hosts = Array.new
$owners = Array.new
$counter = 0
$boxes.each do |row|
  $entry = "#{row["hostname"]}-#{row["owner"]}-#{row["procname"]}"
  # first entry is unique
  if $counter == 0
    $userprocess << $entry
    $files << row["filename"]
    $hosts << row["hostname"]
    $owners << row["owner"]
  else
    # if the other fields are not yet in the array, add them
    if !$userprocess.include?$entry  
      $userprocess <<  $entry
    end
    if !$files.include?(row["filename"]) 
      $files << row["filename"]
    end
    if !$hosts.include?(row["hostname"]) 
      $hosts << row["hostname"]
    end
     if !$owners.include?(row["owner"]) 
      $owners << row["owner"]
    end
  end   # if first entry
  $counter += 1
end  #each box
puts "user_process is #{$userprocess}"
#puts "files is #{$files}"
#puts "hosts is #{$hosts}"
#puts "owners is #{$owners}"

# do graph
gv = Gviz.new 
gv.graph do
global :rankdir => 'LR'

$uprows = Array.new($boxes.size)
$upno = 0
count = 0
$hosts.each do |ho|
  $thishost = ho.to_s
  subgraph {  # big - for each host
    global :color => 'black', :label => "#{ho}"
    nodes :style => 'filled', :shape => 'box'

# for each distinct user/process combo add a subgraph, then for matching rows add a node in that subgraph
#
$userprocess.each do |up|
subgraph {
  nodes :style => 'filled', :shape => 'box'
  global :color => 'red', :label => "#{up}"
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
  $upno +=1
}
end # userprocs

} # end of big subgraph
end  # end of host loop

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

# for each row, link the process to the file
if ($boxes.count > 0)
  for count in 0 .. $boxes.count-1
    gv.route :"#{$uprows[count]}" => :"#{$filerows[count]}"
  end
end

end #gv

# write the dot file
gv.save(:proc_links)

# convert to jpg
exec "dot -Tjpg proc_links.dot -o proc_links.jpg"
# YAY


