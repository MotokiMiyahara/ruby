# vim:set fileencoding=utf-8:

require 'tk'
require_relative '../fire'
require_relative '../mr_crawler'
require_relative '../config'


def btn_cmd(btn, &block)
  raise ArgumentError unless block
  return lambda {
    orig_bg = btn.bg
    btn.state 'disabled'
    btn.bg = 'gray'
    Thread.new do
      begin
        block.call
      rescue => e
        puts e
        puts e.backtrace
        raise e
      ensure
        btn.bg = orig_bg
        btn.state 'normal'
      end
    end
  }
end

val = {}
val[:news_count] = TkVariable.new('')
self.class.class_eval do
  define_method :update_news_count do
    val[:news_count].value = Moeren::Config::news_count
  end
end
update_news_count

widget = {}

# crawlボタン
TkFrame.new{|f|
  pack
  bg :green

  TkButton.new(f) {
    pack
    text 'Crawl'
    bg '#CCFFFF'
    width 40

    log_proc = lambda{|*args|
      puts "args=#{args}"
      widget[:text].insert 'end',  args.join("\n") + "\n"
      widget[:text].see 'end'
    }

    command btn_cmd(self){
      Crawlers.fire log_proc: log_proc
      update_news_count
    }
=begin
    command lambda{ 
      state 'disabled'
      Thread.new do
        Crawlers.fire log_proc: log_proc
        state 'normal'
      end
    }
=end
  }
}


# テキスト
TkFrame.new{|f|
  #bg :red
  pack expand: true, fill: :both 

  
  widget[:text] = TkText.new(f){
    yscrollbar(TkScrollbar.new(f).pack(fill: 'y', side: 'right'))
    width  1
    height  1
    pack(fill: :both, expand: true)
  }
}

# news
TkFrame.new{|f|
  pack
  #bg :blue
  width 0

  TkLabel.new(f){
    pack side: :left
    textvariable val[:news_count]
  }

  TkLabel.new(f){
    pack side: :left
    text " news comes.  "
  }

  TkButton.new(f) {
    pack side: :left
    text 'delete news'
    command btn_cmd(self) { 
      Moeren::Config::delete_news
      update_news_count
    }
  }
}

Tk::root.geometry('600x400')

Tk.mainloop

