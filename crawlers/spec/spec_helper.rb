$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'crawlers'


RSpec.configure do |config|
  config.tty = true # to 'rspec | less'
end
