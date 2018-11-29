
task jira: :environment do
  jira = Jira.new
  jira.log_work 2, "CT-22 refactor memory monitor, don't use forking, debug",
                "2012-01-12T16:08:58.529+1300", "Cohort targeting"

  puts :done
end
