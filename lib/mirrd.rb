#!/usr/bin/env ruby
# The Mirr daemon relies on this
# Daniel Ethridge

require "mirr/version"
require 'socket'
require 'rubygems/package'
require 'fileutils'
require 'zlib'

module Mirrd
  # Borrowed from Rack for extra compatability
  def daemonize()
    if RUBY_VERSION < "1.9"
      exit if fork
      Process.setsid
      exit if fork
      Dir.chdir "/" 
      STDIN.reopen "/dev/null"
      STDOUT.reopen "/dev/null", "a" 
      STDERR.reopen "/dev/null", "a" 
    else
      Process.daemon
    end 
  end

  # Arhive tar - This is a function from RubyGems package manager itself
  def archive(name, destination)
    tar_generate = Gem::Package::TarWriter.new(Zlib::GzipWriter.open(name))
    tar_generate.rewind
    tar_generate.each do |entry|
      # Compressed now
      destination.write entry.read
    end
    tar_generate.close
  end

  # Unarchive gzipped tar file
  def unarchive(name, destination)
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(name))
    tar_extract.rewind
    tar_extract.each do |entry|
      # Decompressed now
      destination.write entry.read
    end
    tar_extract.close
  end

  # Define the server - runs infinitely
  def server(port)
    server = TCPServer.new(port)
    while true
      Thread.new(server.accept) do |client|
        client.read # This is where the server reads from the client
        client.write # This is where the server writes to the client
        client.close
      end
    end
  end

  # Define the client
  def client(ip, port)
    socket = TCPSocket.new("#{ip}", port)
    socket.read # This is where the client reads from the server
    socket.write # This is where the client writes to the server
    socket.close
  end
end
