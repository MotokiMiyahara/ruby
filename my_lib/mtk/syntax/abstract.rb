# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require_relative 'modules'

module Mtk::Syntax::Abstract
  refine Module do
    def def_abstract(*method_names)
      method_names.each do |name|
        define_method(name) {|*args|
          raise "[#{self.class.name}##{name}] is not implemented. <abstract_method>"
        }
      end
    end
  end

end


if $0 == __FILE__
  class A
    using Mtk::Syntax::Abstract
    def_abstract :foo
  end

  #A.new.foo # => raise exception
end
