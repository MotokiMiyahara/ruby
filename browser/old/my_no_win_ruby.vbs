Set ws = CreateObject("Wscript.Shell")'
ws.run "cmd /c ruby '" & WScript.Arguments.Item(0) & "'", vbhide
Wscript.Echo "aaa"
