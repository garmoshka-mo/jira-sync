
task upload: :environment do |_, args|

  project = args[0]
  raise "project for upload isn't specified" unless project.present?
  sync = Sync.new project

  start_from = ENV['START']&.to_i || 1
  sync.collect start_from
  if Dialog.yes? "Import records?"
    sync.import
    puts :done
  end

end

task up: :upload


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

