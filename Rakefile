#!rake
# vim:set filetype=ruby fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'rspec/core/rake_task'

require 'pp'

PROJECT_DIR = File.expand_path(__dir__)

task :default => [:spec, :git]

task :git do |t|
  sh "git add -A #{PROJECT_DIR}"
  sh "git commit -m 'update project'"
  sh "git push"
end

RSpec::Core::RakeTask.new do |t|
  #pp t.pattern
  #t.rspec_opts = ["--color"]
  #t.rspec_opts = ["--color", "--format" , "documentation"]
end
