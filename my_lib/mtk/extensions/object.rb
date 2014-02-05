# vim:set fileencoding=utf-8:

require 'pp'

class Object
  def tap
    pp self
    return self
  end
end

