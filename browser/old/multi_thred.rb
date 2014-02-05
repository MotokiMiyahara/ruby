# vim:set fileencoding=utf-8:

require 'open-uri'
require 'openssl'
require 'tk'
require_relative '../crawler/fire'
require_relative '../crawler/mr_crawler'
require 'thread'

q = Queue.new
tag_my_event_loop = Object.new

yscr = TkScrollbar.new.pack(fill: 'y', side: 'right').pack
t = TkText.new.pack
t.yscrollbar(yscr)

TkButton.new {
  text 'test'

  command proc{
    state 'disabled'
    q.push(proc{
      (0 .. 1000).each do |i|
        t.insert 'end',  "#{i}\n"
        t.see 'end'
        Tk.update
      end
      state 'normal'
    })
  }
}.pack


tk_thread = Thread.new do
  Tk.mainloop
  q.push(proc{throw tag_my_event_loop})
end

catch tag_my_event_loop do
  loop do
    f = q.pop
    f.call
  end
end

tk_thread.join



