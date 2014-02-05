# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'my/external_command'
require_relative 'image_store'

module Crawlers
  class ImageViewer
    def initialize(command_source=My::ExternalCommand)
      @db = ImageStore.new
      @command = command_source
    end

    def view_saved_image(path)
      path = Pathname(path)
      dir_path = path.directory? ? path : path.parent
      image_path = @db[dir_path]

      if image_path && image_path.exist?
        @command.invoke_image_viewer(image_path)
      else
        @command.invoke_image_viewer(dir_path)
      end
    end
  end
end


