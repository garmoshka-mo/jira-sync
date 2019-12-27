class Report

  REPORT_PROJECTS = %w(activate fly AE)

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
    toggl = TogglReport.new Time.now.beginning_of_month
    toggl.each do |row|
      pr_name = project(row).name
      pr = @entries[pr_name] ||= {}

      date = Time.parse(row[:start]).to_date
      Print.status "#{date}"
      day = pr[date] ||= {}
      work_log = day[row[:user]] ||= {}

      duration = if row[:end] and row[:dur] >= 0
                   row[:dur]
                 else
                   Time.now - started_at
                 end
      entry = row[:description]
      work_log[entry] ||= 0
      work_log[entry] += duration
    end
  end

  def output_reports
    @entries.each do |pr_name, project|
      total_hours = project.map do |date, day|
        day.map do |user, work_log|
          work_log.map do |entry, duration|
            duration
          end
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
      project.sort do |row|
        row[0].to_time.to_i # date
      end.each do |date, day|
        file.write("\n### #{date.strftime "%^a %d"}\n")
        day.map do |user, work_log|
          total_hours = work_log.map{|entry, duration| duration}.flatten.sum
          file.write("#### #{user} ⏰ #{to_hours total_hours}\n")
          work_log.sort do |row|
            -row[1] # duration
          end.each do |entry, duration|
            file.write("#{to_hours duration}: #{entry}\n")
          end
        end
      end
    end
  end

  def to_hours(seconds)
    (seconds.to_f / 1000 / 60 / 60).round(1)
  end

  def project(entry)
    return OpenStruct.new unless entry[:pid]
    @projects[entry[:pid]] ||= @api.get_project(entry[:pid])
  end

end