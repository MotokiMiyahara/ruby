# vim:set fileencoding=utf-8:

require 'tk'
require 'pp'

module Mtk; end
module Mtk::Tk; end
module Mtk::Tk::Components; end

class Mtk::Tk::Components::TkSearchBox < TkWindow
  include TkComposite
  attr_reader :entry

  def initialize_composite(keys={})
    #---------------------------
    # :section: オプションの初期化
    #---------------------------
    default_opts = {
      'list'    => "",
      'width'   => 50,
      'height'  => 20,
    }
    opts = default_opts.merge(keys)
    #pp opts

    #---------------------------
    # :section: リストデータの初期化
    #---------------------------
    @list_data = opts.delete('list').split(/\s+/)
    
    #---------------------------
    # :section: モデル設定
    #---------------------------
    @v_keyword = keyword = TkVariable.new('')
    @v_list = list = TkVariable.new(@list_data)


    #---------------------------
    # :section: GUI設定
    #---------------------------

    @entry = TkEntry.new(@frame){
      #pack
      pack expand: false, fill: :x
      textvariable keyword
      focus
    }
    @entry.bind 'Control-n', proc{
      idx = selected_index ? selected_index + 1 : 0
      select_index(idx)
    }

    @entry.bind 'Control-p', proc{
      idx = selected_index ? selected_index - 1 : 'end'
      select_index(idx)
    }

    @entry.bind 'Control-a', proc{
      @entry.selection_range(0, 'end')
      Tk.callback_break
    }

    @entry.bind "MouseWheel", proc{|ev|
      # マウスホイールイベントをリストボックスに転送する
      @lbox.focus
      Tk.event_generate(@lbox, "MouseWheel", delta: ev.wheel_delta)
      @entry.focus
    }

    @entry.bind 'Return', proc{
      next if @lbox.curselection.empty?
      item = @lbox.get(@lbox.curselection.first)
      Thread.new{execute(item)}
    }

    @lbox = TkListbox.new(@frame) {
      #yscrollbar(TkScrollbar.new(f).pack(fill: 'y', side: 'right'))
      #pack(fill: :both, expand: true)
      #pack
      pack expand: true, fill: :both
      setgrid 1
      listvariable list

    }

    @lbox.bind 'FocusIn', proc{
      @entry.focus
      Tk.callback_break
    }

    @v_keyword.trace 'w', proc{|n1, n2, op|
      search_data
    }


    delegate('DEFAULT', @frame)
    delegate('width', @entry, @lbox)
    delegate('height', @lbox)
    @path = @entry.path

    configure opts unless opts.empty?
  end

  #---------------------------
  # :section: list_box
  #---------------------------
  def list_box
    return @lbox
  end

  # リストボックスの任意の1行を選択する
  def select_index idx
    @lbox.selection_clear(0, 'end')
    @lbox.selection_set(idx)
    @lbox.see(idx)
  end

  def selected_item
    return nil if @lbox.curselection.empty?
    return @lbox.get(@lbox.curselection.first)
  end

  def selected_index
    return (@lbox.curselection.empty?) ? nil : @lbox.curselection.first
  end

  #---------------------------
  # :section: 検索
  #---------------------------
  # リストデータを更新する
  def list_data(list)
    @list_data = list.dup
    search_data
  end

  # キーワード検索を行う
  def search_data
    regs = @v_keyword.value.split(/[\s　]+/).map{|word| /#{Regexp.escape(word)}/i}
    @v_list.value = @list_data.find_all{|elm| regs.all?{|reg| elm =~ reg}}
    select_index(0)
  end

  #---------------------------
  # :section: その他
  #---------------------------
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
