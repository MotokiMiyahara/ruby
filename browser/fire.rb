# vim:set fileencoding=utf-8:

require 'open-uri'
require 'openssl'
require 'tk'
require 'tkextlib/tkimg'

#p Encoding.aliases

module My
  USER_AGENT_FIREFOX = "Mozilla/5.0 (Windows NT 5.1; rv:21.0) Gecko/20100101 Firefox/21.0"

  module_function
  def open_html_uri_as_utf8(uri)
    return open_html_uri(uri).encode('UTF-8', invalid: :replace, undef: :replace)
  end

  # charsetから戻り値のエンコーディングに反映
  def open_html_uri(uri)
    open_uri(uri) do |data|
      text = data.read
      if equals_encoding(Encoding::ISO_8859_1, data.charset) &&
          enc_str = get_charset_from_html(text)
        text = text.dup.force_encoding(enc_str)
      end
      return text
    end
  end

  # デフォルト値を変更したopen
  #def open_uri(name, mode='r', perm=nil, opts={}, &block)
  def open_uri(*args, &block)
    options = {
      'User-Agent' => USER_AGENT_FIREFOX, 
      :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE
    }
    opts = args[-1].is_a?(Hash) ? args.pop : {}
    options.merge! opts
    open(*args, options, &block)
  end

  # htmlのメタタグからcharsetを取得
  def get_charset_from_html (text)
    if text =~ %r{<meta\s+http-equiv\s*=\s*"?Content-Type"?\s+content\s*=\s*"[^">]*charset=([^">]*)">}i || 
        text =~ %r{<meta\s+content\s*=\s*"[^">]*charset=([^">]*)"[^>]*http-equiv\s*=\s*"?Content-Type"?[^>]*>}i
      return $1.upcase
    else
      return nil
    end
  end

  def equals_encoding(encoding, str)
    encoding.names.include? str.upcase
  end
end

uri1 = 'http://doc.ruby-lang.org/ja/1.9.3/method/Kernel/m/open.html'
uri2 = 'http://www.geocities.jp/m_hiroi/tcl_tk_doc/tcltk_doc.html'
uri3 = 'http://engawa.2ch.net/test/read.cgi/gameama/1269519085/'


#img = TkPhotoImage.new(file: 'a.gif', width: 50, height: 50)
img = TkPhotoImage.new(file: 'a.jpg')

url = TkVariable.new("http://")
TkEntry.new(nil,'width'=>50,'textvariable'=>url).pack
t = TkText.new.pack
TkTextImage.new(t, 'end', image: img)
TkButton.new {
  text 'GET'
  #image img
  command lambda {
    t.value = My.open_html_uri_as_utf8(url.value)
  }
  pack
}
Tk.mainloop
