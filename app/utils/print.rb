require 'colorize'

module Print

  extend self

  def line(text)
    return if PryMoves.open?
    puts text.ljust(80, ' ')
    print_status if @status_text
  end
  alias info line

  def warn(text)
    line text.yellow
  end

  def error(text)
    return if PryMoves.open?
    STDERR.puts text.ljust(80, ' ').red
    print_status if @status_text
  end

  def status(text)
    @status_text = text
    print_status unless PryMoves.open?
  end

  def object(obj)
    Pry::ColorPrinter.pp obj
  end

  private

  LINE_WIDTH = 80

  def print_status
    t = @status_text || ""
    print t[0 .. LINE_WIDTH - 2].ljust(LINE_WIDTH, ' ') + "\r"
  end

end