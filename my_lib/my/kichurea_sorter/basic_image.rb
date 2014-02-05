
require_relative './image'
require_relative './loggable'
require_relative './my'

class BasicImage < Image
  include Loggable

  attr_reader :type

  def initialize parent, type, path=nil, &block
    super parent
    @type = type
    @path = path
    @block = block
  end

  def source_path
    if @block == nil
      @path
    else 
      @block.call(self)
    end
  end

=begin
  include Comparable
  def <=> another
    return My.comparate_objs(
      self, another,
      :series_index,
      :larva_id,
      :stage_number,
      :type
  )
  end

  class Type
    include Enumerable

    attr_reader :order

    def initialize order, sym
      @order, @sym = order, sym
    end
    def <=> another
      order <=> another.order
    end

    STAN_X_RATED = Type.new(0, :stand_x_rated)
  end

  def to_s
    #return "source_path=#{source_path}\tdest_path=#{dest_path}"
    return "name=#{name}\tstage_number=#{stage_number}\ttype=#{@type}"
  end
=end


end
