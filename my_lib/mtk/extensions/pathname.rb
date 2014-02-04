# vim:set fileencoding=utf-8:

require 'pathname'

class Pathname
  def to_pathname
    return self
  end

  alias old_descend descend 
  private :old_descend
  def descend *args, &block
    return old_descend(*args, &block) if block
    
    result = []
    old_descend do |pathname|
      result << pathname
    end
    return result
  end
end


