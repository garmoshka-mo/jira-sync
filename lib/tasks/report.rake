
task report: :environment do

  puts "Toggl report"
  Report.new.create

  puts :done
  `open reports/.`
end

task :reports => :report
