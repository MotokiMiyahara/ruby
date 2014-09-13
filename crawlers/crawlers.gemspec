# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'crawlers/version'

Gem::Specification.new do |spec|
  spec.name          = "crawlers"
  spec.version       = Crawlers::VERSION
  spec.authors       = ["motokimiyahara"]
  spec.email         = ["duos2002@yahoo.co.jp"]
  spec.summary       = %q{TODO: Write a short summary. Required.}
  spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"


  # -------------------------
  spec.add_dependency "mechanize"
  spec.add_dependency "nokogiri"
  spec.add_dependency "httpclient"

  spec.add_dependency "sequel"
  spec.add_dependency "mysql"
  spec.add_dependency "sqlite3-ruby"
  spec.add_dependency "activerecord"

  spec.add_dependency "win32-shortcut"
  spec.add_dependency "archive-tar-minitar"
  spec.add_dependency "clipboard"
  spec.add_dependency "ffi"
  spec.add_dependency "parallel"
  spec.add_dependency "tapp"
end
