# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

WATCH_DIR = File.expand_path('watched', __dir__)

if $0 == __FILE__
  Dir.chdir(WATCH_DIR){
    system('watchr watch.rb')
  }
end

