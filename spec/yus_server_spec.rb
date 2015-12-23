#!/usr/bin/env rspec
# encoding: utf-8
# kate: space-indent on; indent-width 2; mixedindent off; indent-mode ruby;
require 'spec_helper'
require 'pp'

describe "oddb-docker" do

  before :all do
    @yml = File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), 'docker-compose.yml'))
    expect(File.exists?(@yml)).to eq true
    expect(system("docker-compose build ")).to eq true
    expect(system("docker-compose up")).to eq true
  end

  after :all do
    puts "\nI am in after :all"
    expect(system("docker-compose stop"))
  end

  it "should run yus_show" do
    expect(true).to eq false
  end
end
