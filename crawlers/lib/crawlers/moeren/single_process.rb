# vim:set fileencoding=utf-8:

require 'optparse'
require 'pp'
require 'pathname'
require 'fileutils'

# 二重起動防止
class SingleProcess
  # class --- 
  class << self
    public
    def with(&block)
      FileLock.new(lock_file).synchronize(&block)
    end
    

    private
    def dir
      return Pathname.new($0).dirname
    end

    def lock_file
      return dir + '.flock'
    end
  end

  class FileLock
    def initialize(lock_file)
      @lock_file = lock_file
    end

    public
    def synchronize(*args, &block)
      open(@lock_file, File::WRONLY | File::CREAT) do |f|
        begin
          return unless f.flock(File::LOCK_EX | File::LOCK_NB)
          block.call(*args)
        ensure
          f.flock(File::LOCK_UN)
        end
      end
      FileUtils.remove_file(@lock_file, true)
    end
  end
end

