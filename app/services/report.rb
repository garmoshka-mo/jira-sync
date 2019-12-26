class Report

  REPORT_PROJECTS = %w(activate fly)

  def initialize
    @api = Toggl::Base.new ENV['TOGGL_TOKEN']
    @projects = {}
  end

  def create
    collect_entries
    output_reports
  end

  private

  def collect_entries
    @entries = {}
    rows = @api.time_entries(Time.now.beginning_of_month)
    rows.each do |row|
      pr_name = project(row).name
      pr = @entries[pr_name] ||= {}

      date = Time.parse(row.start).to_date
      day = pr[date] ||= {}

      entry = row.description
      duration = if row.stop and row.duration >= 0
                   row.duration
                 else
                   Time.now - started_at
                 end
      day[entry] ||= 0
      day[entry] += duration
    end
  end

  def output_reports
    @entries.each do |pr_name, project|
      total_hours = project.map do |date, day|
        day.map do |entry, duration|
          duration
        end
      end.flatten.sum
      if pr_name.in? REPORT_PROJECTS
        write_project_report pr_name, project
        status = 'Write'
      else
        status = 'Skip'
      end
      puts "#{status} #{pr_name}: #{to_hours total_hours}"
    end
  end

  def write_project_report pr_name, project
    File.open("reports/#{pr_name}.md", 'w') do |file|
      project.each do |date, day|
        file.write("\n### #{date.strftime "%^a %d"}\n")
        day.sort_by do |entry, duration|
          -duration
        end.each do |entry, duration|
          file.write("#{to_hours duration}: #{entry}\n")
        end
      end
    end
  end

  def to_hours(seconds)
    (seconds.to_f / 60 / 60).round(1)
  end

  def project(entry)
    return OpenStruct.new unless entry.pid
    @projects[entry.pid] ||= @api.get_project(entry.pid)
  end

end