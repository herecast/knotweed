namespace :event_category do
  require 'csv'
  desc "Update events.event_category from csv file"
  task update: :environment do

    source_path = File.join(File.dirname(__FILE__),'event_category.csv')

    CSV.foreach(source_path, :headers => true) do |row|
      event = Event.find_by_id(row[2])
      if event.present?
        event.update_attributes(
          :event_category => row[0]
        )
        event.save!
        puts "just saved event_id #{row[2]} as category #{row[0]}"
      end
    end
  end
end
