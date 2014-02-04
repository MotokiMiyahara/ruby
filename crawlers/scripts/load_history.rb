# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'pathname'
require 'fileutils'
require 'mtk/import'
require_relative 'commons'
require_relative '../strages/image_viewer'

module Scripts; end

class Scripts::LoadHistory
  class << self
    def execute(image)
      Crawlers::ImageViewer.new.view_saved_image(image)
    end
  end
end

if $0 == __FILE__
  include Scripts
  script_header(:filename)
  image = ARGV[0]
  LoadHistory.execute(image)
end


