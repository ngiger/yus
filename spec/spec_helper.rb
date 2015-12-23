#!/usr/bin/env ruby

$LOAD_PATH << File.join(File.dirname(File.dirname(__FILE__)), 'lib')

require 'yus/server'

begin
  require 'pry'
rescue LoadError
end
