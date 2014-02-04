
module Loggable
  def log
    result = []
    log_to result, 0
    return result
  end

  
  # hook
  def log_to result, indent
    result << form_by_indent(to_s, indent)
  end

  private
  def form_by_indent str, indent
     return str.split("\n").map {|line| "  " * indent + line}.join("\n")
  end
end
