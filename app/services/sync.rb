class Sync

  attr_reader :line

  def initialize(project)
    @path = "reports/#{project}.md"
    raise "Project file absent: #{@path}" unless File.exist? @path

    @lines = File.readlines @path
    @date = nil
    @collected = []
    @composed_record, @composed_hours = "", 8
    @jira = Jira.new
    load_project project
  end

  def collect(start_from)
    @row_index = start_from
    while get_row
      handle_row
      @row_index += 1
    end
    add_composed_record
    summary
  end

  def import
    @collected.each do |rec|
      @jira.log_work rec[:hours], rec[:description], rec[:date], rec[:project]
    end
    move_to_trash @path
  end

  private

  def summary
    total = 0.0
    @collected.each do |rec|
      total += rec[:hours].to_f
    end
    puts "\nCollected #{@collected.count} records for #{total} hours"
  end

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
    collect_hours_record

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

  def collect_hours_record
    if (m = line.strip.match /^=(\d*\.?\d*)$/)
      @composed_hours = m[1].to_i
    elsif (m = line.match /^=(\d*\.?\d*)\s(.*)/)
      hours, description = m[1], m[2]
      hours = 8 unless hours.present?
      add_record(hours, description)
    elsif (m = line.match /^\+(\d+\.\d+:\s)?(.*)/)
      piece = m[2].strip
      @composed_record += ", " unless @composed_record.empty? or @composed_record.end_with? "; "
      @composed_record += piece
    elsif line.strip == ';'
      error "; ни к чему" if @composed_record.empty?
      @composed_record += "; "
    end
  end

  def add_composed_record
    return if @composed_record.empty?
    add_record @composed_hours, @composed_record
    @composed_record, @composed_hours = "", 8
  end

  def add_record(hours, description)
    error "Date not set" unless @date

    @collected << {hours: hours, description: description,
      date: @date, project: @project}
    puts "#{@date.strftime "%^a %d"} #{hours}h row#{@row_index}:".green
    puts description
  end

  def echo_row
    puts "row => #{@row_index}".green
  end

  def set_date
    m = line.match /### \w{3} (\d+)/
    if m
      add_composed_record
      @date = Date.today.change day: m[1].to_i
      true
    end
  end

  def move_to_trash(file)
    file = Rails.root.join file
    cmd = <<-BASH
      osascript -e 'set theFile to POSIX file "#{file}"' \
          -e 'tell application "Finder"' \
                      -e 'delete theFile' \
                  -e 'end tell'
    BASH
    system cmd
  end

end