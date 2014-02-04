

require 'forwardable'
require_relative './my'

class A
  extend Forwardable
  #def_delegators(:@d,:bbb) 
  My.def_private_delegators(self, :@d,:bbb) 

  def initialize
    @d = B.new
  end

end

class B
  def bbb
    puts 'bbb'
  end
end

#A.new.bbb # error
#
puts "test"
puts "b"
