module Dialog

  extend self

  def ask(question)
    puts question.magenta
    answer = STDIN.gets.chomp.force_encoding("UTF-8").to_sym

    case answer
    when :debug
      byebug
      exit
    when :!
      exit
    end

    answer
  end

  def yes?(question)
    response = ask question
    if response.in? [:yes, :y]
      true
    elsif response.in? [:no, :n]
      false
    else
      error "Unknown cmd response: #{response}"
    end
  end

end