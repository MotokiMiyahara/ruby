
require 'forwardable'
require './loggable'
require './basic_image'
require './image_finder'

class Beast

  include Loggable
  extend Forwardable
  def_delegators(:@parent, :larva_id, :series_index, :image_finder_factory)

  public
  attr_reader :name, :id
  def initialize  parent, id, name

    @parent = parent
    @id, @name = id, name

    @image_finder = image_finder_factory.create self
    #@image_finder = Access4ImageFinder.new self
    
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

  def add_stand_image_x_rated a_path=nil
    path = a_path.nil? ? @image_finder.find_stand_image_x_rated : a_path
    add_image path, :stand_x_rated
  end

  def add_stand_image_for_all_ages a_path=nil
    path = a_path.nil? ? @image_finder.find_stand_image_for_all_ages : a_path
    add_image path, :stand_for_all_ages
  end

  def add_normal_image a_path=nil
    path = a_path.nil? ? @image_finder.find_normal_image : a_path
    add_image path, :normal
  end

  def add_preg_image a_path=nil
    path = a_path.nil? ? @image_finder.find_preg_image : a_path
    add_image path, :normal
  end

  def add_back_image a_path=nil
    path = a_path.nil? ? @image_finder.find_back_image : a_path
    add_image path, :back
  end

  def add_home_image a_path=nil
    path = a_path.nil? ? @image_finder.find_home_image : a_path
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
    @image_map[type] << BasicImage.new(self, path)
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

