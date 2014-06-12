// vim:set fileencoding=utf8 ts=2 sw=2 sts=2 et:

// H�R���p�C�����@:
//   Windows���Nyaos���牺�L�����s
//     csc /target:winexe script_invoker.cs

// *������Ruby�X�N���v�g�����s����
// *at_picture�̊O���A�v���P�[�V�����w��\�Ȃ��̂��I�v�V�����w��Ȃ���exe�t�@�C���݂̂Ȃ̂ō쐬����

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



