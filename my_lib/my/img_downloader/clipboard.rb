# vim:set fileencoding=utf-8:

require "dl"
require "win32api"

module ClipBoard
  OpenClipboard = Win32API.new("user32", "OpenClipboard", ["I"], "I")
  CloseClipboard = Win32API.new("user32", "CloseClipboard", [], "I")
  GetClipboardData = Win32API.new("user32", "GetClipboardData", ["I"], "I")
  GlobalLock = Win32API.new("kernel32", "GlobalLock", ["I"], "P")
  GlobalUnlock = Win32API.new("kernel32", "GlobalUnlock", ["I"], "I")

  # Clipboard contents format
  CF_TEXT = 1

  def get_text
    data = nil
    while OpenClipboard.Call(0) == 0
      sleep 0.2
    end

    begin
      handle = GetClipboardData.Call(CF_TEXT)
      if handle != 0
	if ptr = GlobalLock.Call(handle)
	  begin
	    data = DL::CPtr.new(ptr).to_s
	  ensure
	    GlobalUnlock.Call(handle)
	  end
	end
      end
    ensure
      CloseClipboard.Call()
    end
    data
  end
  module_function :get_text
end

if $0 == __FILE__
  text = ClipBoard.get_text
  puts text
end

