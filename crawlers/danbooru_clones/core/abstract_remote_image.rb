# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'uri'
require 'cgi'
require 'pathname'

require 'mtk/syntax'

require_relative '../../util'

module Crawlers::DanbooruClones::Core
  class AbstractRemoteImage
    using Mtk::Syntax::Abstract
    include Crawlers::Util

    #PREFIX = 'konachan'

    attr_reader :search_file

    def_abstract :image_filename_prefix
    def_abstract :model_class
    def_abstract :calc_relative_save_dir # @config.all_image_dir からの相対パス

    def initialize(xml_doc, dest_dir, news_save, fire_fox, config)

      @model = get_model(xml_doc)
      @id = @model.o_id
      @uri = @model.file_url

      @dest_dir = dest_dir
      @news_save = news_save
      @firefox = fire_fox
      @config = config

      @regular_file = calc_regular_image_pathname(@model)
      @search_file = calc_search_image_pathname(@id, @uri)
      @news_file = calc_news_image_pathname(@id, @uri)

      #puts @regular_file
      #puts @search_file
      #puts @news_file
      #puts @model.save_path
      #raise
    end

    private
    def get_model(xml_doc)
      id = xml_doc[:id]

      if model_class.exists?(o_id: id)
        model = model_class.where(o_id: id).first
        return model
      end

      # active_recordが生成すると衝突するカラム名を変更する
      renames = [
        [:o_id, :id],
      ]

      excepts = [
        :created_at,
        :updated_at,
        :save_path,
      ]

      h_model = {}
      attrs = model_class.attribute_names.map(&:to_sym) - renames.flatten - excepts
      attrs.each do |a|
        h_model[a] = xml_doc[a]
      end

      renames.each do |dest, src|
        h_model[dest] = xml_doc[src]
      end

      model = model_class.new(h_model)
      model.save_path = calc_save_path(id, model.file_url).to_s
      raise unless model.save
      return model
    end

    def calc_save_path(id, uri)
      uri = URI(uri)
      save_dir = calc_relative_save_dir(id, uri)
      save_path =  calc_pathname_in_dir(id, uri, save_dir)
      raise "Unsafe path: #{save_path}" unless safe_path?(save_path)
      return save_path
    end


    def calc_regular_image_pathname(model)
      result = @config.all_image_dir.join(model.save_path)

      dir = result.parent
      dir.mkpath unless dir.exist?
      return result
    end


    def calc_search_image_pathname(id, uri)
      return calc_pathname_in_dir(id, uri, @dest_dir)
    end

    def calc_news_image_pathname(id, uri)
      return calc_pathname_in_dir(id, uri, @config.news_dir, needs_place: true)
    end

    def calc_pathname_in_dir(id, uri, dir, needs_place: false)
      uri = URI(uri)
      dir = Pathname(dir)
      basename = uri.path.split('/')[-1]
      ext = Pathname(basename).extname
      place = needs_place ? "@#{@dest_dir.basename}" : ''
      file = dir.join("#{image_filename_prefix}_#{id}#{place}#{ext}")
      return file
    end


    # @param [Pathname] path
    def safe_path?(path)
      str = path.cleanpath.to_s
      return false if str.start_with?('/')
      return false if str.start_with?('..')
      return true
    end

    # -----------------------------------------------------
    public 
    def download
      download_image(@uri)
    end

    private
    def download_image(uri)
      if @search_file.exist?
        log "found search_file #{@search_file}. abort download."
        return
      end

      begin
        do_download_image(uri)
      rescue => e
        begin
          log "#{e.message} class=#{e.class} uri=#{uri}"
          pp e.backtrace
        end
      end
    end

    def do_download_image(uri)
      unless @regular_file.exist?
        fetch_image(uri, @regular_file)
        if @news_save
          # newsフォルダにリンクを作成
          make_link_quietly(@regular_file, @news_file)
        end
      end

      # キーワード毎のフォルダにリンクを作成
      make_link_quietly(@regular_file, @search_file)
    end

    def fetch_image(uri, file)
      log uri 
      binary = retry_fetch_with_timelag(message: uri + "  (#{@id})") {
        @firefox.get_binary(uri)
      }
      write_binary_quietly(file, binary)
    end

    def write_binary_quietly(file, binary)
      # ファイルがなければ作成しブロックを実行する, ファイルがあれば何もしない
      open(file, File::BINARY | File::WRONLY | File::CREAT | File::EXCL) do |f|
        f.write(binary)
      end
    rescue Errno::EEXIST => e
      pp e #if @config.verbose
    end

    def make_link_quietly(old, new)
      FileUtils.ln_sf(old, new, verbose: @config.verbose)
    end
  end

end


