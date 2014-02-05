# vim:set fileencoding=utf-8:

require 'rake/testtask'
require 'rdoc/task'
require 'rake/clean'

require 'my/backup'


#CLEAN
CLOBBER.include("html/**/*")

#task :default => [:test]
#task :default => [:ctags, :backup]
task :default => [:test, :ctags, :backup]

Rake::TestTask.new do |test|
  #test.libs << "C:/study/ruby/best_practice/01"
  #test.test_files = Dir["C:/study/ruby/**/test_*.rb"]

  test.test_files = FileList["C:/GitHub/study/ruby/test/**/*_test.rb"]
  test.verbose = true
end


Rake::RDocTask.new do |t|
  t.rdoc_files = 
      FileList["**/*.rb"].
      exclude("**/kichurea_sorter/dsl/*").
      exclude("**/?.rb")
  t.main = "best_practice/03/questioner.rb"
end


desc 'create ctags'
task :ctags do
  #sh "ctags.exe --jcode=utf8 --langmap=ruby:+.rbw -f#{ENV['HOME']}/tags -R"
  #sh "ctags.exe --jcode=utf8 --langmap=ruby:+.rbw -R"
  sh "ctags.exe --jcode=utf8 --exclude=old --langmap=ruby:+.rbw -R"
end

desc 'make backup'
task :backup do
  My::Backup.new.backup
end
