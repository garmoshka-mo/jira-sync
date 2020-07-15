class Report

  REPORT_PROJECTS = %w(activate fly inspectAll AE)

  def initialize
    @api = Toggl::Base.new ENV['TOGGL_TOKEN']
    @projects = {}
  end

  def create
    `rm reports/*.md`
    collect_entries
    output_reports
  end

  private

  def collect_entries
    @entries = {}
    toggl = TogglReport.new start_from
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

  def start_from
    if Time.now.day < 20 # Report in the middle of a month
      date = Time.now.beginning_of_month.to_date
    else
      date = Time.now.to_date.change day: 16
    end
    date -= 3.day

    # date -= 1.day # Day, when filled previous report
    #w = date.strftime('%a')

    date
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
        write_project_report pr_name, project, total_hours
        status = 'Write'
      else
        status = 'Skip'
      end
      puts "#{status} #{pr_name}: #{to_hours total_hours}"
    end
  end

  def write_project_report pr_name, project, total_hours
    File.open("reports/#{pr_name}.md", 'w') do |file|
      file.write("# #{pr_name} #{to_hours total_hours}\n")
      project.sort.each do |date, day|
        file.write("\n### #{date.strftime "%^a %d"}\n")
        day.map do |user, work_log|
          total_hours = work_log.map{|entry, duration| duration}.flatten.sum
          file.write("#### #{user} ⏰ #{to_hours total_hours}\n")
          work_log.sort do |row1, row2|
            row2[1].to_i <=> row1[1].to_i # duration
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