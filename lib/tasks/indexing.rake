# frozen_string_literal: true

namespace :indexing do
  task rebuild_content_index: :environment do
    Content.reindex import: false
    Content.where('organization_id NOT IN (4,5,328)')\
           .where(published: true)\
           .where('root_content_category_id > 0')\
           .where('created_at >= ?', 3.months.ago)\
           .order('pubdate DESC')\
           .each{ |i| i.reindex(mode: :async) }
    puts 'Operation completed'
  end

  task full_reindex_content: :environment do
    index_name = Content.reindex(async: { wait: true }, refresh_interval: '30s')
    puts 'Reindexing last hour'
    Content.search_import.where('contents.updated_at > ?', 2.hours.ago).each{ |i| i.reindex(mode: :async) }
    puts 'Operation completed'
  end

  task rebuild_event_instance_index: :environment do
    EventInstance.reindex import: false
    EventInstance.search_import\
                 .where('start_date >= ?', Time.current).find_each{ |i| i.reindex(mode: :async) }
  end

  task full_reindex_event_instances: :environment do
    index_name = EventInstance.reindex(async: { wait: true }, refresh_interval: '30s')
    puts 'Reindexing last hour'
    EventInstance.search_import.where('event_instances.updated_at > ?', 2.hours.ago).each{ |i| i.reindex(mode: :async) }
    puts 'Operation completed'
  end

  task full_reindex_business_location: :environment do
    index_name = BusinessLocation.reindex(async: { wait: true }, refresh_interval: '30s')
    puts 'Reindexing last hour'
    BusinessLocation.where('updated_at > ?', 2.hours.ago).each{ |i| i.reindex(mode: :async) }
    puts 'Operation completed'
  end

  task full_reindex_location: :environment do
    index_name = Location.reindex(async: { wait: true }, refresh_interval: '30s')
    puts 'Reindexing last hour'
    Location.where('updated_at > ?', 2.hours.ago).each{ |i| i.reindex(mode: :async) }
    puts 'Operation completed'
  end

  task full_reindex_caster: :environment do
    index_name = Caster.reindex(async: { wait: true }, refresh_interval: '30s')
    puts 'Reindexing last hour'
    Caster.where('updated_at > ?', 2.hours.ago).each{ |i| i.reindex(mode: :async) }
    puts 'Operation completed'
  end

  task full_reindex: :environment do
    %w[
      full_reindex_content
      full_reindex_event_instances
      full_reindex_business_location
      full_reindex_location
      full_reindex_caster
    ].each do |task|
      Rake::Task["indexing:#{task}"].invoke
    end
  end

  task full_reindex_asnc: :environment do
    [
      Content,
      EventInstance,
      BusinessLocation,
      Location,
      Caster
    ].each do |model|
      puts "Reindexing for: #{model.to_s}"
      model.find_each { |i| i.reindex }
    end
  end

  task build_indexes: :environment do
    [
      Content,
      EventInstance,
      BusinessLocation,
      Location,
      Caster
    ].each do |model|
      model.reindex
    end
  end
end
