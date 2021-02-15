
task report: :environment do

  puts "Toggl report"
  Report.new.create

  puts :done
  puts "-----------------"
  puts "Import format:"
  puts "=4 Description of work".blue
  puts "=3".blue
  puts "+Description of work".blue
  puts "rk upload project_name".blue
  `open reports/.`

end

task :reports => :report
