
task report: :environment do

  puts "Toggl report"
  Report.new.create

  puts :done
  puts "-----------------"
  puts "Import format:"
  puts "==4 Description of work".blue
  puts "+Description of work".blue
  puts "rk import project_name".blue
  `open reports/.`

  puts "todo: не сортировать".red
  puts "todo: проставлять крупные сразу с плюсиками - автоимпортируются, а мелкие без плюсика - значит не".red
end

task :reports => :report
