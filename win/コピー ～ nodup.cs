// vim:set fileencoding=sjis ts=2 sw=2 sts=2 et:
using System;

using Process = System.Diagnostics.Process;
using ProcessStartInfo = System.Diagnostics.ProcessStartInfo;
using Path = System.IO.Path;
  
class Nodup {

  private static string RUBY = @"rubyw";
  private static string SCRIPT = @"lib/nodup.rbw";

  static void Main(string[] args){
    string appPath = System.Reflection.Assembly.GetExecutingAssembly().Location;
    string appDir = Path.GetDirectoryName(appPath);
    string scriptPath = Path.Combine(appDir, SCRIPT);

    ProcessStartInfo psInfo = new ProcessStartInfo();
    psInfo.FileName = RUBY;
    psInfo.Arguments = scriptPath + " " + String.Join(" ", args);
    //psInfo.Arguments = scriptPath;
    //psInfo.CreateNoWindow = true;
    psInfo.CreateNoWindow = false;
    psInfo.UseShellExecute = false;

    log(scriptPath);
    log(psInfo.Arguments);
    Process.Start(psInfo);
  }

  static void log(string str){
    Console.WriteLine(str);
  }
}



