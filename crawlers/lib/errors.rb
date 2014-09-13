# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:


module Crawlers
  class DataSourceError < StandardError
    def message
      return super unless cause
      return <<-"EOS".split("\n").map(&:strip).join("\n")
        #{super} cause_class='#{cause.class.name}'
        #{cause.message}
      EOS
    end
  end
end

