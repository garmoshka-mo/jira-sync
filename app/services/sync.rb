class Sync

  MAP = {
    CT: 'Cohort targeting',

  }

  attr_reader :row

  def initialize(worksheet)
    @worksheet = worksheet
    @date = nil
    @jira = Jira.new
  end

  def run(start_from)
    @row_index = start_from
    while true
      handle_row
      @row_index += 1
    end
  end

  private

  def get_row
    @row = (1..@worksheet.num_cols).map do |col|
      @worksheet[@row_index, col]
    end.freeze
  end

  def handle_row
    get_row

    return if not @date and row[3].empty?

    if not @date
      set_date
    elsif row[3] == 'Today:'
      return
    elsif row[3].empty?
      @date = nil
    else
      parse_time_entry
    end
  rescue => e
    puts row.join " | "
    puts e.backtrace.reverse.last(3)
    puts e.to_s.red
    echo_row
    byebug
    @worksheet.reload
    retry
  end

  def echo_row
    puts "row => #{@row_index}".green
  end

  def set_date
    text = row[3]
    if not text.match /^\w+:$/ and text.match /^\w+ \d+$/
      @date = Date.parse text rescue nil
    else
      @date = nil
    end

    if @date
      puts "--------------------"
      puts "#{row[3]} => #{@date}"
    end
  end

  def parse_time_entry
    match = row[2].match /(\w+)-/
    raise "Ticket not set: #{row[2]}" unless match
    code = match[1]
    if code == 'AENGINE'
      puts row[2], row[3]
      code = Dialog.ask "Type project code:"
    end

    project = MAP[code.to_sym]
    raise "Unknown project code #{code}" unless project

    raise "Time not set" if row[1].empty?

    comment = "[#{row[2]}] #{row[3]}"
    echo_row
    puts "#{project} > #{row[1]}h: #{comment}"

    answer = Dialog.ask 'Add?'
    if answer == :''
      @jira.log_work row[1], comment, @date, project
      puts "Added."
    else
      puts "Skipped"
    end
  end

end