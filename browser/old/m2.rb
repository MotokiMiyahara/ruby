# vim:set fileencoding=utf-8:

require 'open-uri'
require 'openssl'
require 'tk'
#require_relative 'tk_multi'
require_relative 'tk_multi'


yscr = TkScrollbar.new.pack(fill: 'y', side: 'right').pack
t = TkText.new.pack
t.yscrollbar(yscr)

TkButton.new {
  text 'test'

  command lambda{
    state 'disabled'
    TkMulti.multi{ 
      (0 .. 100).each { |i|
        t.insert 'end',  "#{i}\n"
        sleep 0.1
        t.see 'end'
        Tk.update
      }
    }
    TkMulti.multi{ 
      ('a' .. 'z').each { |i|
        t.insert 'end',  "#{i}\n"
        t.see 'end'
        Tk.update
      }
    }
    TkMulti.multi{ 
      state 'normal'
    }
  }
}.pack

Tk.mainloop


