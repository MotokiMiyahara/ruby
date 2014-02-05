
require 'forwardable'

class Image
  extend Forwardable
  def_delegators(
    :@parent,
    :series_index,
    :larva_id,
    :name,
    :id,
    :stage_number,
  )

  
  private
  def initialize parent
    @parent = parent
  end

  public
  def dest_path
    ext = File.extname(source_path) 
    return "%02d_%03d_%02d_%02d_%s%s" % [series_index, id, stage_number, index_of_stage, @parent.name, ext]
  end

  def index_of_stage
    return @parent.images.find_index self
  end

  def to_s
    return "source_path=#{source_path}\tdest_path=#{dest_path}"
  end

end
