#!/usr/bin/env ruby
# AutoInvoicer -- ydim -- 13.01.2006 -- hwyss@ywesee.com
require "getoptlong"
require "highline/import"
require 'optparse'
require 'debug'
module Yus
  class Config
    def initialize(defaults = Y8s.default_opts, load_from = defaults[:config])
      defaults.each do |key, value|
        cmd = "Config.class_eval {attr_reader :#{key.to_sym}}; @#{key.to_s} = '#{value}'"
        eval(cmd)
      end
      # Now defaults will be overridden via content from config file
      content = YAML.load_file(load_from)
      content.each do |key, value|
        cmd = "@#{key.to_s} = '#{value}'"
        eval(cmd)
      end
    end
  end
  def self.default_parser(options = self.default_opts)
    parser = OptionParser.new do |opts|
      opts.on("-v", "--[no-]verbose", "Run verbosely") do |value|
        $VERBOSE = true
        options[:verbose] = value
      end
      opts.on("-c", "--config config_file", "Use this configfile") do |value|
        options[:config] = value
      end
      opts.on("-r", "--root_name name", "Rootname for yus server") do |value|
        options[:root_name] = value
      end
      opts.on("-u", "--server_url name", "server_url for yus server") do |value|
        options[:server_url] = value
      end
      opts.on("-d", "--yus_dir name", "config_dir for yus server") do |value|
        options[:yus_dir] = value
      end
    end
    parser
  end

  def self.default_opts
    default_dir = "/etc/yus"
    this = File.dirname(__FILE__)
    data_dir = File.expand_path(this + "/../../data")
    default_config_files = [
      File.join(default_dir, "yus.yml"),
      File.join(data_dir, "yus.yml")
    ]
    default_config_files.delete_if{|x| !File.exist?(x)}
    defaults = {
      :config => default_config_files.first,
      :root_name => "admin",
      :server_url => "drbssl://127.0.0.1:9997",
      :yus_dir => File.dirname(default_config_files.first)
    }
    puts "default_config_files are now #{default_config_files}" if $VERBOSE
    defaults
  end

  def self.session(opts)
    config = Config.new(opts)
    server = DRb::DRbObject.new(nil, config.server_url)
    server.ping

    session = nil
    begin
      pass = Yus.get_password("Password for #{config.root_name}: ")
      session = server.login(config.root_name, pass.to_s, "commandline")
    rescue Yus::YusError => e
      puts e.message
      retry
    end
    session
  end

  def self.get_password(prompt = "Password: ")
    ask(prompt) { |q| q.echo = false }
  end
end
