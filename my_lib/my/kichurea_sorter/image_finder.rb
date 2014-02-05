# vim:set fileencoding=utf-8:

require 'forwardable'

class ImageFinder

  extend Forwardable
  def_delegators(:@parent, :id)

  def initialize stage
    @parent = stage
  end


  def find_stand_image_x_rated
    raise "called Abstract method"
  end

  def find_stand_image_for_all_ages
    raise "called Abstract method"
  end

  def find_normal_image
    raise "called Abstract method"
  end

  def find_preg_image
    raise "called Abstract method"
  end

  def find_back_image
    raise "called Abstract method"
  end

  def find_home_image
    raise "called Abstract method"
  end
end

class Access1ImageFinder < ImageFinder
  def initialize stage
    super stage
  end

  def find_stand_image_x_rated
    return "Battlers/b%05d.png" % (10002 + id)
  end

  def find_stand_image_for_all_ages
   return "Battlers/xb%05d.png" % (10002 + id)
  end

  def find_normal_image
    return "Pictures/pcn%04d.png" % (2 + id)
  end

  def find_preg_image
    return "Pictures/pch%04d.png" % (2 + id)
  end

  def find_back_image
    return "Pictures/bmt%05d.png" % (10002 + id)
  end

  def find_home_image
    return "Pictures/pct%04d.png" % (2 + id)
  end
end

class Access2ImageFinder < ImageFinder
  def initialize stage
    super stage
  end

  def find_stand_image_x_rated
    return "Battlers/b%05d.png" % (10040 + id)
  end

  def find_stand_image_for_all_ages
   return "Battlers/xb%05d.png" % (10040 + id)
  end

  def find_normal_image
    return "Pictures/pcn%04d.png" % (40 + id)
  end

  def find_preg_image
    return "Pictures/pch%04d.png" % (40 + id)
  end

  def find_back_image
    return "Pictures/bmt%05d.png" % (10040 + id)
  end

  def find_home_image
    return "Pictures/pct%04d.png" % (40 + id)
  end
end

class Access4ImageFinder < ImageFinder
  def initialize stage
    super stage
  end

  def find_stand_image_x_rated
    return "Battlers/b%05d.png" % (20020 + id)
  end

  def find_stand_image_for_all_ages
    raise "Stand Image for all ages not exists."
  end

  def find_normal_image
    return "Pictures/pcn%04d.png" % (20020 + id)
  end

  def find_preg_image
    return "Pictures/pch%04d.png" % (20020 + id)
  end

  def find_back_image
    return "Pictures/bmt%05d.png" % (20020 + id)
  end

  def find_home_image
    return "Pictures/pct%04d.png" % (20020 + id)
  end
end

class SummonerImageFinder < ImageFinder
  def initialize stage
    super stage
  end

  #def find_stand_image_x_rated
  #  return "Battlers/b%05d.png" % (20020 + id)
  #end

  #def find_stand_image_for_all_ages
  #  raise "Stand Image for all ages not exists."
  #end

  def find_normal_image
    return "Pictures/pcn%04d.png" % (80 + id)
  end

  #def find_preg_image
  #  return "Pictures/pch%04d.png" % (80 + id)
  #end

  #def find_back_image
  #  return "Pictures/bmt%05d.png" % (80 + id)
  #end

  def find_home_image
    return "Pictures/pct%04d.png" % (80 + id)
  end
end


class DaughterImageFinder < ImageFinder
  def initialize stage
    super stage
  end

  def find_stand_image_x_rated
    return "Battlers/b%05d.png" % (30000 + id)
  end

  def find_stand_image_for_all_ages
    return "Battlers/xb%05d.png" % (30000 + id)
  end

  def find_normal_image
    return "Pictures/pcn%04d.png" % (30000 + id)
  end

  def find_preg_image
    return "Pictures/pch%04d.png" % (30000 + id)
  end

  def find_back_image
    return "Pictures/bmt%05d.png" % (30000 + id)
  end

  def find_home_image
    return "Pictures/pct%04d.png" % (30000 + id)
  end
end



# -- factories ---
# ImageFinderFactoryクラスを定義する
def self.define_image_finder_factory *finder_syms
  finder_syms.each do |finder_sym|
    finder_name = finder_sym.to_s
    eval <<-EOS
      class #{finder_name}Factory
        def create stage
          return #{finder_name}.new stage
        end
      end
    EOS
  end
end

define_image_finder_factory(
  :Access1ImageFinder,
  :Access2ImageFinder,
  :Access4ImageFinder,
  :SummonerImageFinder,
  :DaughterImageFinder,
)
  
