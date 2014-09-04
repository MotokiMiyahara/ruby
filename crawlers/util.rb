# vim:set fileencoding=utf-8:

require 'forwardable'

require 'uri'

require 'net/http'
require 'open-uri'
require_relative 'errors'

module Crawlers; end
module Crawlers::Util; end
module Crawlers::Util::Helpers; end
module Crawlers::Util::Helpers::Files; end
module Crawlers::Util::Helpers::Tk; end

module Crawlers::Util
  extend Forwardable
  include Helpers::Files
  include Helpers::Tk
  extend self
  def_delegators(
    "Helpers::System",
    :dos,
    :platform_lang
  )


end

class Crawlers::Util::Helpers::System
  class << self
    def dos(*args)
      opt = args[-1].kind_of?(Hash) ? args.pop : {}

      command = args.map{|v| '"' << v.to_s << '"'}.join(' ')
      puts command if opt[:verbose]
      dos_str(command)
    end

    def dos_str(command)
      `#{command.encode(platform_lang)}`
    end

    def platform_lang
      return @platform_lang ||= calc_platform_lang
    end

    private
    # 引用: http://sugamasao.hatenablog.com/entry/20090408/1239211950
    def calc_platform_lang
      lang = ""

      # Windows だったらSJIS
      if RUBY_PLATFORM =~ /mswin|mingw|cygwin|bccwin/i
        lang = "SJIS"
      elsif ENV['LANG']
        lang = "UTF-8" if ENV['LANG'] =~ /utf-8/i
        lang = "EUC" if ENV['LANG'] =~ /euc/i
        lang = "SJIS" if ENV['LANG'] =~ /sjis/i
      end

      return lang
    end
  end
end

module Crawlers::Util::Helpers::Files
  # ファイル名に使えない文字を取り除く
  def fix_basename basename
    result = basename.dup
    result.gsub!(%r{[\\/:*?"<>|!]}, '')
    result.gsub!(/\s|　/, '_')
    result.gsub!(/\.$/, '')
    return result
  end

  def clean_up_dir dir
    pattern = "#{dir}/*"
    Dir.glob(pattern, File::FNM_DOTMATCH) do |f|
      next if File.basename(f) =~ %r{\A\.\.?/?\z} # . や .. を除く(重要)
      #p f
      FileUtils.rm_r f
    end
  end

  # @return[String]
  def join_uri(*uris)
    strs = uris.map(&:to_s)
    return URI.join(*strs).to_s
  end

  def log(str='')
    # Parallelライブラリの使用中にputsを使用すると出力が混ざるため
    print(str.chomp + "\n")
  end

  RETRYABLE_ERRORS = [
    Net::HTTPBadResponse,
    SocketError,
    OpenURI::HTTPError,
    Timeout::Error,
    EOFError,
    Errno::ECONNREFUSED,
    Crawlers::DataSourceError,
  ].freeze

  def retry_fetch(message: '',  &block)
    raise 'block is required ' unless block
    initial_sec = 1
    #try_max_limit = 10
    try_max_limit = 5

    try_count = 1
    begin
      return block.call
    #rescue  Net::HTTPBadResponse, SocketError, OpenURI::HTTPError, Timeout::Error, EOFError, Crawlers::DataSourceError => e
    rescue *RETRYABLE_ERRORS => e
      raise Crawlers::DataSourceError if try_max_limit <= try_count 
      log "retry try_count=#{try_count} class=#{e.class} e=#{e} mes='#{message}'"

      sleep_sec = initial_sec * (2 ** (try_count - 1))
      puts "sleep #{sleep_sec} sec"
      sleep(sleep_sec)

      try_count += 1
      retry
    end
  end


  def retry_fetch_with_timelag(message: '',  &block)
    raise 'block is required ' unless block
    first_sleep_sec = 0.5

    initial_sec = 1
    try_max_limit = 5

    try_count = 1
    begin
      random_sleep(first_sleep_sec)
      return block.call
    rescue *RETRYABLE_ERRORS => e
      raise Crawlers::DataSourceError if try_max_limit <= try_count 
      log "retry try_count=#{try_count} class=#{e.class} e=#{e} mes='#{message}'"

      sleep_sec = initial_sec * (2 ** (try_count - 1))
      #random_sleep(sleep_sec, verbose: true)
      random_sleep(sleep_sec)

      try_count += 1
      retry
    end
  end

  def random_sleep(sec)
      random_factor = rand(0.5 .. 1.5)
      sleep_sec = sec * random_factor
      log "sleep #{sleep_sec} sec"
      sleep(sleep_sec)
  end

end

module Crawlers::Util::Helpers::Tk
  def prompt(message)
    button = Tk.messageBox(
      icon: :info,
      type: :okcancel,
      title: 'Message',
      default: :cancel, 
      message: message)

    return (button == 'ok')
  end
end
