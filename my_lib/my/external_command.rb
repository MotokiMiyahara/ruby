# vim:set fileencoding=utf-8:

require 'mtk/environment'

module My
  class AbstractExternalCommand
    def invoke_image_viewer(path)
      raise 'not implemented'
    end
  end

  class WinExternalCommand < AbstractExternalCommand
    def invoke_image_viewer(path)
      viewer = 'C:/my/tools/MassiGra045/MassiGra.exe'
      fixed_path = path.sub(%r{^//}, '\\\\\\\\')
      dos(viewer, fixed_path, verbose: true)
    end

    private
    def dos(*args, verbose: false)
      opt = args[-1].kind_of?(Hash) ? args.pop : {}

      command = args.map{|v| '"' << v.to_s << '"'}.join(' ')
      puts command if verbose
      dos_str(command)
    end

    def dos_str(command)
      `#{command.encode('SJIS')}`
    end
  end


  class LinuxExternalCommand < AbstractExternalCommand
    def invoke_image_viewer(path)
      viewer = 'wine /home/mtk/.wine/dosdevices/c\:/tools/a/MassiGra.exe'
      raise 'absolute path required' unless path.absolute?
      win_path = "Z:#{path}"
      command = "#{viewer} #{win_path}"
      system(command)
    end
  end


  ExternalCommand = case Mtk::Environment.os
    when :win
      WinExternalCommand.new
    when :linux
      LinuxExternalCommand.new
  end
end
