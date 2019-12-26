
task report: :environment do

  puts "Toggl report"
  TogglReport.new.report

  puts :done
end

