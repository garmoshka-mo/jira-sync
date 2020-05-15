
task report: :environment do

  puts "Toggl report"
  Report.new.create

  puts :done
  puts "Import format:"
  puts "==4 Description of work"
  puts "rk import project_name"
  `open reports/.`
end

task :reports => :report
