
require_relative './beast'
require_relative './loggable'

class Char 
  include Loggable

  attr_reader :series_index, :image_finder_factory

  def initialize series_index, image_finder_factory
    @series_index = series_index
    @image_finder_factory = image_finder_factory

    @stages = []
  end

  def add_stage stage
    #stage.parent = self
    @stages << stage
  end

  def larva_id
    return @stages.first.id
  end

  def stages
    #return @stages.dup
    return @stages
  end

  # Loggable ----
  def log_to result, indent
    result << form_by_indent("char\n", indent)
    @stages.each {|stage| stage.log_to result, indent + 1}
  end

end

=begin
a = Char.new
b1 = Beast.new 1, "aaa"
b2 = Beast.new 2, "fafd"

a.add_stage b1
a.add_stage b2
b1.add_stand_image_x_rated
b1.add_stand_image_for_all_ages
b1.add_normal_image
b1.add_preg_image
b1.add_back_image
b1.add_home_image
b1.add_image "example.png", :stand_x_rated

b2.add_stand_image_x_rated

#puts a.log

=end

