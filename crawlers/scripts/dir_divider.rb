# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'pp'
require 'fileutils'
require 'shell'

require 'mtk/import'

require_relative 'commons'
require_lib 'config'

class DirDivider
  include Scripts
  VIEW_DIR = Crawlers::Config.app_dir + 'views'

  FILE_COUNT_PER_PAGE = 500
  DEST_DIR_FORMAT = '%04d'

  def main
    src_dir, save_dir = read_dirs_and_initalize(ARGV)

    tlog('start')
    files = list_files(src_dir)
    table = make_divided_table(files, src_dir, save_dir)
    copy_with_dividing(table)
    tlog('end')
  end

  def read_dirs_and_initalize(argv)
    script_header(:dir_name)
    src_dir = argv[0]
    save_dir = VIEW_DIR + src_dir

    unless reration?(parent: VIEW_DIR, child: save_dir)
      raise "illegal save_dir: #{save_dir} "
    end

    unless File.directory?(src_dir)
      raise "not found directory '#{src_dir}'"
    end

    exit if say_no?("Can I delete '#{save_dir}'?")
    FileUtils.rm_rf(save_dir, verbose: false)
    FileUtils.mkdir(save_dir)

    return src_dir, save_dir
  end

  def list_files(src_dir)
    files = []
    Shell.new.system('ls', '-f', src_dir).each{|s| files << s}
    files.map!(&:chomp)
    files.reject!{|file| file == '.' || file == '..'}
    return files
  end

  # @return[Hash<String, Array<String>>]
  def make_divided_table(files, src_dir, save_dir)
    table = {}
    current_list = nil
    files.each_with_index do |file, index|
      if index % FILE_COUNT_PER_PAGE == 0
        dir_number = index / FILE_COUNT_PER_PAGE + 1
        dir_basename = sprintf(DEST_DIR_FORMAT, dir_number)
        dest_dir = File.join(save_dir, dir_basename)

        current_list = []
        table[dest_dir] = current_list
      end

      src  = File.join(src_dir,  file)

      #current_list << src unless File.directory?(src)
      current_list << src
    end
    return table
  end

  def copy_with_dividing(table)
    table.each_pair do |dest_dir, src_list|
      puts dest_dir
      FileUtils.mkdir(dest_dir) unless File.exist?(dest_dir)
      FileUtils.cp_r(src_list, dest_dir, dereference_root: false)
    end

  end

  def say_yes?(prompt)
    puts prompt + " [yN]"
    line = $stdin.gets
    return line =~ /^y(?:es)?/i 
  end

  def say_no?(*args)
    return !say_yes?(*args)
  end

  def reration?(parent:, child:)
     parent_path = File.expand_path(parent) 
     child_path  = File.expand_path(child) 
     return child_path.start_with?(parent_path)
  end
end


if $0 == __FILE__
  DirDivider.new.main
end

