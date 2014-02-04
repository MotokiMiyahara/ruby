
require 'fileutils'

class ImageCopier


  public
  def initialize source_dir, dest_dir
    @source_dir, @dest_dir = source_dir, dest_dir
  end


  def copy_chars chars
    FileUtils.mkdir @dest_dir unless Dir.exists? @dest_dir
    chars.each {|char| copy_char char}
  end

  private
  def copy_char char
    char.stages.each do |stage|
      stage.images.each do |image|
        source = File.join(@source_dir, image.source_path)
        dest   = File.join(@dest_dir, image.dest_path)
        if File.exists? source
          FileUtils.copy source, dest
        else
          create_blank_file dest
        end
      end
    end
  end

  def create_blank_file path
    File.open(path, "w") {}
  end

end
