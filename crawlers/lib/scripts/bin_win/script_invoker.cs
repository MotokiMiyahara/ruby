// vim:set fileencoding=utf8 ts=2 sw=2 sts=2 et:

// Hコンパイル方法:
//   Windows上のNyaosから下記を実行
//     csc /target:winexe script_invoker.cs

// *同名のRubyスクリプトを実行する
// *at_pictureの外部アプリケーション指定可能なものがオプション指定なしのexeファイルのみなので作成した

// for at_picture
// exeName -> scriptName

using System;

using Process = System.Diagnostics.Process;
using ProcessStartInfo = System.Diagnostics.ProcessStartInfo;
using Path = System.IO.Path;
  
class Nodup {

  private static string RUBY = @"rubyw";
  //private static string RUBY = @"ruby";
  private static string SCRIPT_DIR = @"..";
  private static string SCRIPT_EXT = @".rb";

  static void Main(string[] args){
    string appPath = System.Reflection.Assembly.GetExecutingAssembly().Location;
    string appDir = Path.GetDirectoryName(appPath);
    string appBasename = Path.GetFileNameWithoutExtension(System.Windows.Forms.Application.ExecutablePath);
    string scriptPath = Path.Combine(appDir, SCRIPT_DIR, appBasename + SCRIPT_EXT);
    string[] fixedArgs = Array.ConvertAll(args, arg => "\"" + arg + "\"");

    ProcessStartInfo psInfo = new ProcessStartInfo();
    psInfo.FileName = RUBY;
    psInfo.Arguments = scriptPath + " " + String.Join(" ", fixedArgs);
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



