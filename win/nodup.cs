// vim:set fileencoding=sjis ts=2 sw=2 sts=2 et:

// コンパイル方法:
//   windonw上のnyaosから下記コマンドを実行
//     csc /target:winexe nodup.cs

using System;

using Process = System.Diagnostics.Process;
using ProcessStartInfo = System.Diagnostics.ProcessStartInfo;
using Path = System.IO.Path;
  
class Nodup {

  private static string RUBY = @"rubyw";
  //private static string RUBY = @"ruby";
  private static string SCRIPT_DIR = @"lib";
  private static string SCRIPT_EXT = @".rbw";

  static void Main(string[] args){
    log("aaa");
    string appPath = System.Reflection.Assembly.GetExecutingAssembly().Location;
    string appDir = Path.GetDirectoryName(appPath);
    string appBasename = Path.GetFileNameWithoutExtension(System.Windows.Forms.Application.ExecutablePath);
    string scriptPath = Path.Combine(appDir, SCRIPT_DIR, appBasename + SCRIPT_EXT);

    ProcessStartInfo psInfo = new ProcessStartInfo();
    psInfo.FileName = RUBY;
    psInfo.Arguments = scriptPath + " " + String.Join(" ", args);
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



