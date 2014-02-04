# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'optparse'
require_relative '../util'
require_relative 'commons'
require_relative '../pixiv/config'
require_relative '../moeren/config'
require_relative '../yande.re/crawler'

module Scripts; end

class Scripts::RemveNewsFiles
  class << self
    def execute()

      #type = ARGV[0]
      type = ARGV.shift
      news_dir = case type
      when 'pixiv' 
        Pixiv::NEWS_DIR
      when 'moeren'
        Moeren::Config::NEWS_DIR
      when 'yandere'
        Yandere::NEWS_DIR
      else
        raise "wrong type=#{type}"
      end

      should_delete = false
      opt = OptionParser.new
      opt.on('-y', 'say yes'){should_delete = true}
      opt.parse!

      should_delete ||= say_yes?("Do you want to delete #{news_dir}?")
      exit unless should_delete

      Crawlers::Util::clean_up_dir(news_dir)
      puts 'finish deleting.'
    end

    def say_yes?(prompt)
      puts prompt + " [yN]"
      line = $stdin.gets
      return line =~ /^y(?:es)?/i 
    end

  end
end

if $0 == __FILE__
  include Scripts
  script_header(:type)
  RemveNewsFiles.execute()
end


