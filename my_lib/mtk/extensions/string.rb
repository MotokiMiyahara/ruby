# vim:set fileencoding=utf-8:

require 'pathname'

class String
  # ヒアドキュメントのインデント対応用
  #def ~
  #  margin = scan(/^ +/).map(&:size).min
  #  gsub(/^ {#{margin}}/, '')
  #end

  def to_pathname
    return Pathname.new(self)
  end
end


