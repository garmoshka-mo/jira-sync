class Sync

  attr_reader :row

  def initialize(worksheet)
    @worksheet = worksheet
    @date = nil
    @jira = Jira.new
    load_projects_map
  end

  def run(start_from)
    @row_index = start_from
    while true
      handle_row
      @row_index += 1
    end
  end

  private

  def load_projects_map
    @projects_map = YAML.load_file( 'config/projects.yml'). symbolize_keys
  end

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
    elsif row[3].empty? or row[3].in? %w(Tomorrow: Monday:)
      @date = nil if @current_day_rows > 0
    else
      parse_time_entry
    end
  rescue => e
    puts row.join " | "
    puts e.backtrace.reverse.last(3)
    puts e.to_s.red
    echo_row
    if Dialog.yes? "Retry?"
      @worksheet.reload
      load_projects_map
      retry
    else
      puts "Row #{@row_index} skipped".red
    end
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
      @current_day_rows = 0
      puts "--------------------"
      puts "#{row[3]} => #{@date}"
      unless @date.month == Date.today.month
        unless Dialog.yes? "Current month finished. Continue?"
          exit
        end
      end
    end
  end

  def parse_time_entry
    match = row[2].match /(\w+)-?/
    raise "Ticket not set: #{row[2]}" unless match
    code = match[1]
    if code == 'AENGINE'
      puts row[2], row[3]
      code = Dialog.ask "Type project code:"
    end

    project = @projects_map[code.to_sym]
    raise "Unknown project code #{code}" unless project

    raise "Time not set" if row[1].empty?

    comment = "[#{row[2]}] #{row[3]}"
    echo_row
    puts "#{project} > #{row[1]}h: #{comment}"

    @current_day_rows += 1
    answer = Dialog.ask 'Add? (press Enter)'
    if answer == :''
      @jira.log_work row[1], comment, @date, project
      puts "Added."
    else
      puts "Skipped"
    end
  end

end