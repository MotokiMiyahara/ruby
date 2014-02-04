
require 'fileutils'

require_relative './char_builder'
require_relative './image_copier'
require_relative './image_finder'
require_relative '../my'

SOURCE_DIR = My::Path.from_program "./images/source/Graphics"
DEST_DIR =   My::Path.from_program "./images/dest"

def clean_up
    #FileUtils.remove_entry_secure DEST_DIR if Dir.exists? DEST_DIR
    FileUtils.remove_entry DEST_DIR if Dir.exists? DEST_DIR
    FileUtils.mkdir DEST_DIR
end

def copy_images series_index, dsl_file, image_finder_factory 
  builder = CharBuilder.new(series_index, image_finder_factory)
  builder.load_file My::Path.from_program(dsl_file)
  chars = builder.content
  chars.each {|char| puts char.log}

  copier = ImageCopier.new SOURCE_DIR, DEST_DIR
  copier.copy_chars chars
end

# -------------------------------------
clean_up
copy_images 0, "./dsl/access2_beast.rb", Access2ImageFinderFactory.new
copy_images 1, "./dsl/access4_beast.rb", Access4ImageFinderFactory.new
copy_images 2, "./dsl/access1_human.rb", Access1ImageFinderFactory.new
copy_images 3, "./dsl/summoner.rb", SummonerImageFinderFactory.new
copy_images 4, "./dsl/daughter.rb", DaughterImageFinderFactory.new


