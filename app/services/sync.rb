class Sync

  attr_reader :line

  def initialize(project)
    path = "reports/#{project}.md"
    raise "Project file absent: #{path}" unless File.exist? path

    @lines = File.readlines path
    @date = nil
    @jira = Jira.new
    load_project project
  end

  def run(start_from)
    @row_index = start_from
    while get_row
      handle_row
      @row_index += 1
    end
  end

  private

  def load_project short_name
    projects_map = YAML.load_file( 'config/projects.yml').symbolize_keys
    @project = projects_map[short_name.to_sym] ||
      raise("Unknown project code #{short_name}")
  end

  def get_row
    @line = @lines[@row_index]
  end

  def handle_row

    set_date or
    import_hours_record

  rescue => e
    puts line
    puts e.backtrace.reverse.last(3)
    puts e.to_s.red
    echo_row
    if Dialog.yes? "Retry?"
      retry
    else
      puts "Row #{@row_index} skipped".red
    end
  end

  def import_hours_record
    m = line.match /^==(\d*)\s(.*)/
    return unless m
    hours, description = m[1], m[2]
    hours = 8 unless hours.present?

    raise "Date not set" unless @date

    @jira.log_work hours, description, @date, @project
    puts "> #{@date} #{hours}h row#{@row_index}: #{description}"
  end

  def echo_row
    puts "row => #{@row_index}".green
  end

  def set_date
    m = line.match /### \w{3} (\d+)/
    if m
      @date = Date.today.change day: m[1].to_i
      true
    end
  end

end