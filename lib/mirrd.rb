#!/usr/bin/env ruby
# Mirr daemon functions
# Daniel Ethridge

require 'socket'
require 'fileutils'
require 'zlib'
require 'json'
require 'yaml'
require 'digest'

module Mirr
  def listen()
    server = TCPServer.open(3122)
    while true
      Thread.start(server.accept) do |client|
      ip = client.peeraddr[3]
        info = client.gets.chomp
        case info
          when "PULLING"
            client.puts "PUSHING"
            push(ip)
          when "PUSHING"
            client.puts "PULLING"
            pull(ip)
          else
            client.puts "FAIL"
            client.close
        end
      end
    end
  end
end