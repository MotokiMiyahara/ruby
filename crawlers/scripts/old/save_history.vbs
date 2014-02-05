
Dim command
command ="ruby save_history.rb "


Set FSO    = CreateObject("Scripting.FileSystemObject")
Set WShell = CreateObject("WScript.Shell")
WShell.CurrentDirectory = FSO.GetFile(WScript.ScriptFullName).ParentFolder.Path

Dim args
args = ""
For Each strArg In WScript.Arguments
    args = args & " """ & strArg & """"
Next

WShell.Run (command & args), 0
