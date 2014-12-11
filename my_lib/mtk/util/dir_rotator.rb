# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'pathname'
require 'fileutils'

require_relative 'modules'

class Mtk::Util::DirRotator
  LENGTH = 5
  MAX = LENGTH - 1
  PREFIX = 'news'

  def initialize(parent_dir, verbose: false)
    @parent_dir = Pathname(parent_dir)
    @verbose = verbose
  end

  def rotate
    rm_rf(dir(MAX), verbose: true, noop: false) if dir(MAX).exist?

    (0..MAX).reverse_each.each_cons(2) do |dest, src|
      src_dir = dir(src)
      dest_dir = dir(dest)

      raise if dest_dir.exist?
      mv(src_dir, dest_dir) if src_dir.exist?
    end

    mkdir(dir(0))
  end

  private

  # @param [Integer] number
  def dir(number)
    result = @parent_dir.join(dir_basename(number))
    raise unless result.parent == @parent_dir

    return result
  end

  def dir_basename(number)
    raise unless 0 <= number
    return PREFIX if number == 0
    return "#{PREFIX}_-#{number}"
  end

  def operate(sym, *args, **opts)
    new_opts = opts.merge({verbose: @verbose})
    FileUtils.public_send(sym, *args, new_opts)
  end

  def rm_rf(*args)
    operate(:rm_rf, *args)
  end

  def mv(*args)
    operate(:mv, *args)
  end

  def mkdir(*args)
    operate(:mkdir, *args)
  end

end

if $0 == __FILE__
  #r = DirRotator.new('/samba/tmp/news', verbose: true)
  #r.rotate
end

