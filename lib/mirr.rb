#!/usr/bin/env ruby
# Functions that mirr's executable uses
# Daniel Ethridge

require 'socket'
require 'fileutils'
require 'zlib'
require 'json'
require 'yaml'
require 'digest'

module Mirr
  # Initialize mirr - on first run or when key settings files are missing
  def init(mset)
    # Does the mirr settings directory exist?
    unless File.directory?(mset)
      puts "Config files are in #{mset}"
      require 'fileutils'
      FileUtils.mkdir_p(mset)
    end
    # Does the file list exist?
    unless File.exist?("#{mset}/filelist.yml")
      File.open("#{mset}/filelist.yml", "w")
      puts "Created empty File list"
    else
      puts "File list already exists"
    end
    # Does the sync list exist?
    unless File.exist?("#{mset}/synclist.json")
      File.open("#{mset}/synclist.json", "w")
      puts "Created empty sync list"
    else
      puts "Sync list already exists"
    end
    # Does the config file exist?
    unless File.exist?("#{mset}/config.yml")
      File.open("#{mset}/config.yml", "w")
      puts "Created empty config file"
    else
      puts "Config file already exists"
    end
  end

  # Write a given hash to a yaml file, either merging the two or overwriting
  def writelist(hash, list, overwrite=false)
    # Serialize the file if we choose to merge, if the file is empty, just overwrite
    unless overwrite
      listread = File.read(list)
      unless listread.empty?
        listhash = YAML::load(listread)
        out = listhash.merge!(hash)
      else
        out = hash
      end
    else
      out = hash
    end
    # Write the new list out
    file = File.open(list, "w")
    file.write out.to_yaml
    file.close
  end

  # Loading animations help the user know there isn't a freeze
  def loading(fps=10)
    chars = %w[| / - \\]
    delay = 1.0/fps
    go = true
    i = 0
    spinner = Thread.new do
      while go do
        print chars[(i+=1) % chars.length]
        sleep delay
        print "\b"
      end
    end
    yield.tap{
      go = false
      spinner.join
    }
  end

  def explodedir(array)
    exarray = []
    array.each do |ex|
      if File.directory?(ex)
        exarray << Dir.glob("#{ex}/**/*", File::FNM_DOTMATCH).select{ |e| File.file?(e) }
      elsif File.file?(ex)
        exarray << ex
      end
    end
    return exarray.flatten.uniq
  end

  # Refresh the synclist
  def refresh(filelist, synclist)
    # Serialize the current file list, but if it's empty, exit with a warning
    flread = File.read(filelist)
    unless flread.empty?
      flhash = YAML::load(flread)
      addarray = flhash["add"]
      ignorearray = flhash["ignore"]
    else
      puts "There is no filelist"
      exit
    end
    # Serialize the current synclist, but if it's empty, fall back to an empty hash
    syncread = File.read(synclist)
    unless syncread.empty?
      synchash = YAML::load(syncread)
    else
      synchash = {}
    end
    # Explode add directories and remove items in the ignore array
    finalarray = explodedir(addarray) - explodedir(ignorearray)
    # Iterate through the final array to add everything to `entries`
    entries = {}
    finalarray.each do |fd|
      # Get the absolute path of each item in the array
      fd = File.expand_path(fd)
      # The ID is a 15 char random string
      id = rand(36**15).to_s(36)
      # The MD5 checksum is used to notify when file changes
      md5sum = Digest::MD5.file(fd).hexdigest
      # File type is almost always just `file`, but special files are different
      type = File.ftype(fd)
      # A modification time is needed so that we keep track of a file's latest version
      modtime = File.mtime(fd).to_i
      # Size returns the file size in bytes
      size = File.size(fd)
      # Merge each file into `entries`
      entries.merge!( { id =>
        { "type" => type,
          "size" => size,
          "modtime" => modtime,
          "md5sum" => md5sum,
          "path" => fd }
      } )
    end
    # Finally write it out to the synclist
    writelist(entries, synclist, true)
  end

  # Add a file or directory to the file list
  def add(array, filelist, synclist)
    # Serialize the current file list
    flread = File.read(filelist)
    unless flread.empty?
    flhash = YAML::load(flread)
    else
      flhash = {"add" => [], "ignore" => []}
    end
    # Expand the path of each item in `array`
    entries = []
    array.each{ |fd| entries << File.expand_path(fd) }
    # Append to the `add` array and remove doubles
    flhash["add"] = (flhash["add"] + entries).uniq
    # Remove from the ignore list if the entry is there
    flhash["ignore"] = (flhash["ignore"] - entries).uniq
    # Write out to the file list and then refresh the synclist
    writelist(flhash, filelist)
    refresh(filelist, synclist)
  end

  # Remove a file or directory from the file list
  def del(array, filelist, synclist)
    # Serialize the current file list
    flread = File.read(filelist)
    unless flread.empty?
    flhash = YAML::load(flread)
    else
      puts "No content to delete"
      exit
    end
    # Expand the path of each item in `array`
    entries = []
    array.each{ |fd| entries << File.expand_path(fd) }
    # Decide if we should remove from the `add` array or add to the `ignore` array
    entries.each do |del|
      if flhash["add"].include?(del)
        # Simply remove the unwanted entry from `add`
        flhash["add"] = (flhash["add"] - [del]).uniq
      else
        # Because it isn't in the add list, we have to put it in `ignore`
        flhash["ignore"] = (flhash["ignore"] + [del]).uniq
      end
    end
    # Write out to the file list and then refresh the synclist
    writelist(flhash, filelist)
    refresh(filelist, synclist)
  end

  # Show the contents of a settings file
  def show(mset, files=["filelist"])
    files.each do |file|
      path = "#{mset}/#{file}.yml"
      content = File.read(path)
      if content.empty?
        puts "#{file} appears to be empty"
      else
        puts "Displaying the contents of #{file} :"
        puts content, "\n"
      end
    end
  end

  # Add a computer to config
  def addcomputer(ip, name, config)
    puts "Adding a computer named #{name} located at #{ip}to #{config}"
  end

  # Zlib to zip up files
  def zip(file, dest)
    Zlib::GzipWriter.open(dest) do |gz|
      gz.write IO.binread(file)
      gz.close
    end
  end

  # Unzip into a given destination
  def unzip(file, dest)
    Zlib::GzipReader.open(file) do |gz|
      orig = gz.read
      gz.close
      out = File.open(dest, "w")
      out.write orig
      out.close
    end
  end

  # Connect to a server, request a file or set of files
  def pull(ips)
    all = File.read("#{Dir.home}/.config/mirr/synclist.json")
    puts "Pulling from #{ips.join(" ")}"
    ips.each do |ip|
      socket = TCPSocket.open(ip, 3122)
      socket.puts "PULLING"
      infores = socket.gets.chomp
      if infores == "PUSHING"
        puts "Initiating pull"
      else
        puts "Initiation failed"
        exit
      end
      socket.puts "ALL"
      socket.puts all
      socket.puts "END"
      socket.close
    end
  end

  # Push to any computer running mirr as a daemon
  def push(ips)
    puts "Pushing to #{ips.join(" ")}"
    ips.each do |ip|
      socket = TCPSocket.open(ip, 3122)
      socket.puts "PUSHING"
      socket.close
    end
  end
end