# vim:set fileencoding=utf-8:

require 'tk'
require 'pp'

require_relative '../pixiv/constants'
require_relative '../pixiv/user_crawler'
require_relative '../parsers'
require_relative '../util'
require_relative '../config'
require_relative '../strages/image_store'
require_relative '../strages/image_viewer'

require 'mtk/import'
require 'my/external_command'

require 'mtk/tk'
include Mtk::Tk::Components


class PixivGui
  include Crawlers::Util

  def initialize
    @image_viewer = Crawlers::ImageViewer.new
    @image_db = Crawlers::ImageStore.new
  end

  public
  def start
    Thread.abort_on_exception = true
    Tk.encoding = 'UTF-8'
    init
    Tk.mainloop
  end

  private
  def init
    data = calc_list_data

    @box = TkSearchBox.new(){
      #pack
      pack expand: true, fill: :both
      width 50
      height 20
      list_data data
    }

    @box.bind 'Return', proc_execute
    @box.list_box.bind 'Double-Button-1', proc_execute

    @box.bind 'Control-d', proc{
      item = @box.selected_item
      Thread.new{delete_cache(item)} if item
    }

    # データを再読み込み
    @box.bind 'Control-r', proc{
      @box.entry.state    'disabled'
      @box.list_box.state 'disabled'
      Thread.new{
        @box.list_data calc_list_data
        @box.entry.state    'normal'
        @box.list_box.state 'normal'
      }
    }
  end

  def calc_list_data
    # 一般コマンド
    commands_data = %w{
      :news
      :delete_news
      :keep
    }

    # 画像ディレクトリ
    #parser = DslParser.new
    #parser.parse_file

    invokers = Crawlers::Parsers::BootStrapper.new.parse_invokers
    
    puts Pixiv::PIXIV_DIR
    search_data = invokers.select{|invoker| invoker.type == :pixiv}.map(&:search_dir).compact
    search_data.map!{|p| Pathname('search').join(p, 'r18')}
    search_data.select!{|d| item_dir(d).exist?}
    search_data.sort_by!{|path| item_dir(path).mtime}.reverse!
    #puts search_data.map{|s|s.to_s.encode('sjis')}

    #user_data = Pixiv::UserCrawler::UserData.dirs
    user_data = user_children
    user_data.map!{|data| data.relative_path_from(Pixiv::PIXIV_DIR)}

    pixiv_data = [] << search_data << user_data
    #pixiv_data.map!{|data| data.sort_by!{|path| item_dir(path).mtime}.reverse!}

    yandere_keyword = %w{news pussy nipples}
    yandere_data = yandere_keyword.map{|word| "@yandere:" << word}

    #keep_data = keep_dir.children(true).select(&:directory?)
    keep_data = Pathname.glob("#{keep_dir}/*[0-9]")

    list_data = [].push(commands_data, pixiv_data, yandere_data, keep_data).flatten!.map(&:to_s)
    tlog('end  of reading data')
    return list_data
  end


  #---------------------------
  # :section: execute
  #---------------------------
  #
  def proc_execute
    return proc{
      @box.entry.focus
      item = @box.selected_item
      Thread.new{execute(item)} if item
    }
  end

  def execute item
    case item
    when /^:/
      execute_command(item)
    when /^@yandere:/
      invoke_image_viewer_with_cache(yandere_dir(item))
    else
      invoke_image_viewer_with_cache(item_dir(item))
    end
  end



  def execute_command(item)
    case item
    when ':news'
      invoke_image_viewer_with_cache(news_dir)
    when ':delete_news'
      Crawlers::Util::clean_up_dir(news_dir) if prompt('newsを削除してよろしいですか?')
    when ':keep'
      invoke_image_viewer_with_cache(keep_dir)
    else 
      puts "no such command: #{item}"
      raise
    end
  end

    
  def invoke_image_viewer_with_cache(dir_path)
    @image_viewer.view_saved_image(dir_path)

    #image_path = @image_db[dir_path]
    #p dir_path.to_s.encoding
    ##p image_path.exist?
    #if image_path && image_path.exist?
    #  invoke_image_viewer(image_path)
    #else
    #  invoke_image_viewer(dir_path)
    #end
  end

  #def invoke_image_viewer path
  #  #viewer = 'C:/my/tools/MassiGra045/MassiGra.exe'
  #  #Crawlers::Util::dos(viewer, path, verbose: true)
  #  #My::ExternalCommand.invoke_image_viewer(path)
  #end

  #---------------------------
  # :section: delete_cache
  #---------------------------
  def delete_cache(item)
    dir = case item
    when ':news'
      news_dir
    when ':delete_news'
      # balk
      return
    when ':keep'
      keep_dir
    when /^:/
      puts "no such command: #{item}"
      raise
    when /^@yandere:/
      yandere_dir(item)
    else 
      item_dir(item)
    end
    return unless prompt("#{dir}の巡回履歴を削除してよろしいですか？")
    @image_db.delete(dir)
  end
  
  #---------------------------
  # :section: general
  #---------------------------
  def r18_dir(relative_dir)
    return Pixiv::PIXIV_DIR.join(relative_dir, 'r18')
  end

  def item_dir(relative_dir)
    return Pixiv::PIXIV_DIR.join(relative_dir)
  end

  def news_dir
    return Pixiv::NEWS_DIR
  end

  def keep_dir
    #return Pathname('C:/Documents and Settings/mtk/デスクトップ/keep')
    return Crawlers::Config::keep_dir
  end

  def user_children
    parent = Pixiv::USER_DIR
    #names = `start /MIN cmd.exe /C  dir "#{parent.to_s.encode('SJIS')}" /B /O:-D`.encode('UTF-8').split(/\r?\n/)
    names = `dir "#{parent.to_s.encode('SJIS')}" /B /O:-D`.encode('UTF-8').split(/\r?\n/)
    puts names
    return names.map{|name| parent + name}
  end

  def yandere_dir(item)
    relative_dir = item.sub(/^@yandere:/, '')
    return Yandere::YANDERE_DIR.join(relative_dir)
  end
end

if $0 == __FILE__
  PixivGui.new.start
 # Thread.abort_on_exception = true
 # Tk.encoding = 'UTF-8'
 # init
 # Tk.mainloop
end
