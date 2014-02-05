# vim:set fileencoding=utf-8:

module My

  # ローカルスコープを作るためだけにブロックを使うことを明示
  def self.local_scope(*args, &block)
    block.call(*args)
  end

  module Path
    def self.from_program(path)
       File.expand_path(path, File.dirname($PROGRAM_NAME))
    end

    def self.from_source_file(path)
       File.expand_path(path, File.dirname(__FILE__))
    end
  end

  module Cmp
    ASC  = :asc
    DESC = :desc

    def self.included base
      base.extend ClassMethods
    end
    
    module ClassMethods
      hidden = Module.new

      # <=>メソッドを定義
      # ex)
      #   下記のようにするとageで昇順、nameで降順となる
      #     define_spaceship_operator(
      #      age: My::Cmp::ASC,
      #      name: My::Cmp::DESC,
      #     )
      #
      private
      define_method :define_spaceship_operator do |opts|
        define_method :<=> do |another|
          return hidden.comparate_objs self, another, opts
        end
      end

      hidden.module_eval do
        # <=>メソッドの作成を補助
        def self.comparate_objs one, another, opts
          opts.each do |sym, order|
            raise ArgumentError, "attr=#{sym} order=#{order}" unless order
            v1 = get_by_sym sym, one
            v2 = get_by_sym sym, another
            factor = factor_of order
            cmp = v1 * factor <=> v2 * factor
            return cmp unless cmp == 0
          end
          return 0
        end

        def self.get_by_sym sym, obj
          if obj.respond_to?(sym)
            return obj.__send__(sym)
          elsif !sym.empty? &&
                sym[0] == '@' &&
                obj.instance_variable_defined?(sym)
            return obj.instance_variable_get(sym)
          else
            raise "unknown symbol:" + sym.to_s
          end
        end

        def self.factor_of order
          case order
          when ASC
            1
          when DESC
            -1
          else
            raise ArgumentError, "Illegal order=#{order}"
          end
        end
      end


    end
  end
end

=begin
lambda {
  o = Object.new
  class << o
    def aiueo
      puts 'aiueo'
    end
  end

  A = Class.new do 
    define_method :a do
      o.aiueo
    end
  end

}.call
#o.aiueo # error
A.new.a
=end
