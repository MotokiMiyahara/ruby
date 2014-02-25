#!rake
# vim:set filetype=ruby fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'pp'

PROJECT_DIR = File.expand_path(__dir__)


task :git do |t|
  sh "git add -A #{PROJECT_DIR}"
  sh "git commit -m 'update project'"
end

