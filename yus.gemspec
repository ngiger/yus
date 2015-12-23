# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'yus/version'

Gem::Specification.new do |spec|
  spec.name          = "yus"
  spec.version       = Yus::VERSION
  spec.summary     = "ywesee user server"
  spec.description = ". Works with the ywesee webframework and all the ywesee software packages."
  spec.author      = 'Yasuhiro Asaka, Zeno R.R. Davatz, Niklaus Giger'
  spec.email       = 'yasaka@ywesee.com,  zdavatz@ywesee.com, ngiger@ywesee.com'
  spec.platform    = Gem::Platform::RUBY
  spec.license     = "GPLv3"
  spec.homepage  = "https://github.com/zdavatz/yus/"

  spec.metadata['allowed_push_host'] = 'RubyGems.org'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "needle"
  spec.add_dependency "pg"
  # The dbi is added via Gemfile
  # we have some important patches here!!
  spec.add_dependency "dbi", '0.4.5'
  spec.add_dependency 'rclconf'
  # for running yus_add we need
  spec.add_dependency 'ruby-password'
  spec.add_dependency 'odba'
  spec.add_dependency 'dbd-pg'
  spec.add_dependency 'deprecated', '2.0.1'
  if RUBY_VERSION.to_f > 2.0
    spec.add_development_dependency "test-unit"
    spec.add_development_dependency "minitest"
    spec.add_development_dependency "pry-byebug"
  end
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "flexmock", '~>1.3.0'
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
end
