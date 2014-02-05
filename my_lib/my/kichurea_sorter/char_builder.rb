
require_relative './char'
require_relative './beast_builder'

class CharBuilder

  def load_file aFileName
    load(File.readlines(aFileName).join("\n"))
  end

  def load aStream
    instance_eval aStream, File.expand_path(aStream), 1
  end

  # ----

  def self.build &block
    builder = self.new
    builder.instance_eval &block
    return builder.content
  end

  def content
    @chars.dup
  end

  def initialize series_index, image_finder_factory
    @series_index = series_index
    @image_finder_factory = image_finder_factory

    @chars = []
    @current_char = nil
  end

  def char
    @current_char = Char.new(@series_index, @image_finder_factory)
    @chars << @current_char
    yield
  end

  def beast &block
    @current_char.add_stage BeastBuilder.new(@current_char).build(block)
  end

  alias human beast

end


