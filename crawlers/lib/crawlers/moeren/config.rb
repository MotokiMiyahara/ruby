# vim:set fileencoding=utf-8:

require'fileutils'
require'pp'

require'my/my'
require'my/config'

module Moeren
  module Config

    extend self

    DEST_DIR = My::CONFIG.dest_dir.join('crawler/moeren')
    NEWS_ROTATE_DIR = DEST_DIR.join("news")
    NEWS_DIR        = NEWS_ROTATE_DIR + "news"
    
    def news_count 
      count_files NEWS_DIR
    end

    private
    def count_files dir
       pattern = "#{dir}/*"
       Dir.glob(pattern).reject{|f| File.directory? f}.size
    end

    public
    def delete_news
        p 'delete_news'
      clean_up_dir NEWS_DIR
    end

    private 
    def clean_up_dir dir
      pattern = "#{dir}/*"
      Dir.glob(pattern, File::FNM_DOTMATCH) do |f|
        next if File.basename(f) =~ %r{\A\.\.?/?\z} # . や .. を除く(重要)
        #p f
        FileUtils.rm_r f
      end
    end
  end
end

# 暫定
#FileUtils.mkdir(Moeren::Config::NEWS_DIR) unless File.exist?(Moeren::Config::NEWS_DIR)


