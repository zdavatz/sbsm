# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sbsm/version'

Gem::Specification.new do |spec|
  spec.name        = "sbsm"
  spec.version     = SBSM::VERSION
  spec.author      = "Masaomi Hatakeyama, Zeno R.R. Davatz"
  spec.email       = "mhatakeyama@ywesee.com, zdavatz@ywesee.com"
  spec.description = "Application framework for state based session management"
  spec.summary     = "Application framework for state based session management from ywesee"
  spec.homepage    = "https://github.com/zdavatz/sbsm"
  spec.license       = "GPL-v2"
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # We fix the version of the spec to newer versions only in the third position
  # hoping that these version fix only security/severe bugs
  # Consulted the Gemfile.lock to get 
  spec.add_dependency 'rack'
  spec.add_dependency 'mail'
  spec.add_dependency 'hpricot'
  spec.add_dependency 'rockit' # , '0.3.8'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "flexmock"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rdoc"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "watir"
  spec.add_development_dependency "watir-webdriver"
  # gem 'page-object'

end

