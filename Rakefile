#!/usr/bin/env ruby
require "bundler/gem_tasks"
require "rake/testtask"
require "standard/rake"
require "simplecov"
SimpleCov.command_name 'Unit Tests'
SimpleCov.start

desc "test using minittest via test/suite.rb"
task :test do |t|
  $LOAD_PATH << File.dirname(__FILE__)
  require "test/suite"
end

require "rake/clean"
CLEAN.include FileList["pkg/*.gem"]
