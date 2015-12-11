namespace :schedules do
  desc 'Update upcoming event instances to utilize the Schedule model'
  task convert_legacy_instances: :environment do
    puts "processing #{EventInstance.where('start_date > ? and schedule_id IS NULL', Time.zone.now).count} event instances into schedules"
    EventInstance.where('start_date > ? and schedule_id IS NULL', Time.zone.now).each do |ei|
      Schedule.create_single_occurrence_from_event_instance(ei)
    end
  end
end
