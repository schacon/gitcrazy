#! /usr/bin/env ruby
require 'pp'

server_roles = {
  's1' => ['webserver'],
  's2' => ['webserver'],
  's3' => ['webserver', 'memcache'],
  's4' => ['database', 'memcache']
}

file = ARGV[0]
name = ARGV[1]
role = ARGV[2]

# creates: {"webserver" => ["s3", "s1", "s2"], 
#           "memcache"  => ["s3", "s4"], 
#           "database"  => ["s4"] }
roles = {}
server_roles.each do |server, sroles|
  sroles.each do |srole| 
    roles[srole] ||= []
    roles[srole] << server
  end
end

# add content to git
obj_sha = `git hash-object -w #{file}`.chomp

roles[role].each do |server|
  puts "Updating #{server}"

  # reset index to current tree
  `rm .git/index`
  `git read-tree servers/#{server}`

  # update index with new content
  `git update-index --add --cacheinfo 100644 #{obj_sha} #{name}`
  
  # write new tree and commit
  tree_sha = `git write-tree`.chomp
  prev_commit = `git rev-parse servers/#{server} 2>/dev/null`.chomp  
  pcommit = (prev_commit != "servers/#{server}") ? "-p #{prev_commit}" : ''

  commit_sha = `echo 'server #{server}' | git commit-tree #{tree_sha} #{pcommit}`.chomp
  
  # update server branches
  puts "  writing c:#{commit_sha}"
  puts "          t:#{tree_sha}"
  puts

  # update the server reference
  `git update-ref refs/heads/servers/#{server} #{commit_sha}`
end

