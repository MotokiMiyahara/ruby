
require 'forwardable'
require_relative './loggable'
require_relative './basic_image'
require_relative './image_finder'
#require './my'

class Beast

  include Loggable
  extend Forwardable
  def_delegators(:@parent, :larva_id, :series_index)

#  My.def_private_delegators(
#    self,
#    :@image_finder,
#    :find_stand_image_for_all_ages,
#    :find_stand_image_x_rated,
#    :find_normal_image,
#    :find_back_image,
#    :find_home_image,
#  )

  public
  attr_reader :name, :id
  def initialize  parent, id, name

    @parent = parent
    @id, @name = id, name

    @image_finder = @parent.image_finder_factory.create self
    
    @stand_images_for_all_ages = []
    @stand_images_x_rated = []
    @normal_images = []
    @preg_images = []
    @back_images = []
    @etc_images = []

    @image_map = {
      stand_for_all_ages: @stand_images_for_all_ages,
      stand_x_rated: @stand_images_x_rated,
      normal: @normal_images,
      preg: @preg_images,
      back: @back_images,
      etc: @etc_images,
    }

  end

  def stage_number
    return @parent.stages.find_index(self)
  end

  def images 
    result = []
    result += @stand_images_for_all_ages
    result += @stand_images_x_rated
    result += @normal_images
    result += @preg_images
    result += @back_images
    result += @etc_images
    return result
  end

  def add_stand_image_for_all_ages path=@image_finder.find_stand_image_for_all_ages
    add_image path, :stand_for_all_ages
  end

  def add_stand_image_x_rated path=@image_finder.find_stand_image_x_rated
    add_image path, :stand_x_rated
  end

  def add_normal_image path=@image_finder.find_normal_image
    add_image path, :normal
  end

  def add_preg_image path=@image_finder.find_preg_image
    add_image path, :normal
  end

  def add_back_image path=@image_finder.find_back_image
    add_image path, :back
  end

  def add_home_image path=@image_finder.find_home_image
    add_etc_image path
  end


  def add_event_image path
    add_etc_image File.join("Pictures/", path)
  end

  def add_etc_image path
    add_image path, :etc
  end

  private
  def add_image path, type
    @image_map[type] << BasicImage.new(self, type, path)
  end

  public
  def to_s
    return "id=#{@id}, name=#{@name}, stage_number=#{stage_number}\n"
  end


  # Loggable ----
  def log_to result, indent
    super result, indent
    images.each {|image| image.log_to result, indent + 1}
  end

end

