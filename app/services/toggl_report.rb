class TogglReport

  REPORT_PROJECTS = %w(activate fly)

  def initialize
    @api = Toggl::Base.new ENV['TOGGL_TOKEN']
    @projects = {}
  end

  def report


    # todo: output filtered out projects and their times
  end

  private

  def collect_entries
    @entries = {}
    rows = @api.time_entries(Time.now.beginning_of_month)
    rows.each do |row|
      put row
      proj_name = project(row).name
      proj = @entries[proj_name] ||= Index.new

      entry = row.entry
      date = Time.parse(row.start).to_date
      duration = if row.stop and row.duration >= 0
                   row.duration
                 else
                   Time.now - started_at
                 end
    end
  end

  def save_reports
    REPORT_PROJECTS.each do ||

    end
  end

  def project(entry)
    return OpenStruct.new unless entry.pid
    @projects[entry.pid] ||= @api.get_project(entry.pid)
  end

end