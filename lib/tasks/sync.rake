
task sync: :environment do |_, args|

  project = args[0]
  sync = Sync.new project

  start_from = ENV['START']&.to_i || 1
  sync.run start_from

  puts :done
end


task sync_from_spreadsheet: :environment do

  key_file = "config/google_cloud_keyfile.json"
  session = GoogleDrive::Session.from_service_account_key key_file
  spreadsheet = session.spreadsheet_by_title('Daily log')
  worksheet = spreadsheet.worksheets.first

  drop = ENV['START']&.to_i || 1

  sync = Sync.new worksheet
  sync.run drop

  puts :done
end

