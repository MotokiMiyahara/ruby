#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:

require 'pathname'
require 'fileutils'
require 'mtk/import'
require_relative 'commons'
require_relative '../strages/image_store'

module Scripts; end

class Scripts::SaveHistory
  class << self
    def execute(image)
      Crawlers::ImageStore.new.store_image(image)
    end
  end
end

if $0 == __FILE__
  include Scripts
  script_header(:filename)
  image = ARGV[0]
  SaveHistory.execute(image)
end
