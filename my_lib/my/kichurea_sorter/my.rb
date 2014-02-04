# vim:set fileencoding=utf-8:

module My
  # obj が extend Forwardable していることが前提
  def self.def_private_delegators obj ,parent, *args
    obj.instance_eval do
      def_delegators(parent, *args)
      private(*args)
    end
  end

end

