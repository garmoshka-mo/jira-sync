
task sync: :environment do

  jira = Jira.new

  session = GoogleDrive::Session.from_service_account_key("config/client-secret.json")
  spreadsheet = session.spreadsheet_by_title('Daily log')
  @worksheet = spreadsheet.worksheets.first
  credentials = Hash.new

  @worksheet.rows.drop(1).each_with_index do |row, index|
    credentials[row[0]] = [row[2], row[3], row[4], row[1], row[5], index + 2] unless row[5] == 'Credentials imported'
  end

  credentials.to_json

  puts :done
end
