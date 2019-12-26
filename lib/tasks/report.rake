
task report: :environment do

  puts "Toggl report"
  Report.new.create

  puts :done
end

