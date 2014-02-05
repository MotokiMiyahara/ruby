
require_relative './beast'

class BeastBuilder
  #extend Forwardable
  #def_delegators(:@construction_builder, :gets)

  def initialize parent_char
    @parent_char = parent_char

    @id = nil
    @name = nil
    @commands = []
  end

  def build block
    instance_eval &block

    raise "id is not defined."   if @id.nil?
    raise "name is not defined." if @name.nil?

    content = Beast.new @parent_char, @id, @name
    @commands.each {|command| command.call(content)}
    return content
  end

  def id num
    @id = num
  end

  def name str
    @name = str
  end

  def has_def_images
    push_command do |beast|
      beast.add_stand_image_x_rated
      beast.add_normal_image
      beast.add_preg_image
    end
  end

  def has_stand_image_for_all_ages *args, &block
    push_command {|beast| beast.add_stand_image_for_all_ages *args, &block}
  end

  def has_stand_image_x_rated *args, &block
    push_command {|beast| beast.add_stand_image_x_rated *args, &block}
  end

  def has_normal_image *args, &block
    push_command {|beast| beast.add_normal_image *args, &block}
  end

  def has_preg_image *args, &block
    push_command {|beast| beast.add_preg_image *args, &block}
  end


  def has_back_image *args, &block
    push_command {|beast| beast.add_back_image *args, &block}
  end

  def has_home_image *args, &block
    push_command {|beast| beast.add_home_image *args, &block}
  end

  def event *args, &block
    push_command {|beast| beast.add_event_image *args, &block}
  end


  private
  def push_command &block
    @commands << block
  end

end

