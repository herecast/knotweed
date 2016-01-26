namespace :users do
  desc 'Merge the consumer user table into the admin user table.  Assumes both migrations are done'
  #task :consolidate => ["env:set:dev_env", :environment] do
  task :consolidate => :environment do

    # We need unique classes so ActiveRecord can hash different connections
    # We do not want to use the real Model classes because any business
    # rules will likely get in the way of a database transfer
    class ConsumerUsers < ActiveRecord::Base
    end
    class AdminUsers < ActiveRecord::Base
    end
    puts "Using admin database defined in database.yml for environment: #{Rails.env.to_sym}"

    # get ready to access users table for admin (see database.yml for config)
    AdminUsers.establish_connection(Rails.env.to_sym)
    AdminUsers.table_name = 'users'
    AdminUsers.record_timestamps = false

    # get ready to access users table for consumer (see database.yml for config)
    ConsumerUsers.establish_connection(:consumer)
    ConsumerUsers.table_name = 'users'
    ConsumerUsers.record_timestamps = false

    # now merge in data from consumer users table for existing admin users
    puts 'Update existing admin records from consumer'
    AdminUsers.all.each do |auser|
      puts auser.email + ' ' + auser.id.to_s
      cuser = ConsumerUsers.find_by_email(auser.email)
      if cuser.present?
        puts '  ' + cuser.email + ' ' + cuser.id.to_s
        auser.nda_agreed_at = cuser.nda_agreed_at
        auser.agreed_to_nda = cuser.agreed_to_nda
        auser.admin = cuser.admin
        auser.event_poster = cuser.event_poster
        auser.contact_phone = cuser.contact_phone
        auser.contact_email = cuser.contact_email
        auser.contact_url = cuser.contact_url
        auser.test_group = cuser.test_group
        auser.discussion_listserve = cuser.discussion_listserve
        auser.location_id = Organization.find_by_name(auser.discussion_listserve).locations.first.id
        auser.view_style = cuser.view_style
        auser.save
      end
    end
    puts "\n"

    puts 'Pull over new consumer records to admin'
    # then copy over any records from consumer for which there does not exist a record on admin
    ConsumerUsers.all.each do |cuser|
      unless AdminUsers.find_by_email(cuser.email)
        auser = AdminUsers.new
        puts '  ' + cuser.email + ' ' + cuser.id.to_s

        auser.email = cuser.email
        auser.encrypted_password = cuser.encrypted_password
        auser.reset_password_token = cuser.reset_password_token
        auser.reset_password_sent_at = cuser.reset_password_sent_at
        auser.sign_in_count = cuser.sign_in_count
        auser.current_sign_in_at = cuser.current_sign_in_at
        auser.last_sign_in_at = cuser.last_sign_in_at
        auser.current_sign_in_ip = cuser.current_sign_in_ip
        auser.last_sign_in_ip = cuser.last_sign_in_ip
        auser.created_at = cuser.created_at
        auser.updated_at = cuser.updated_at
        auser.name = cuser.name
        #auser.content_ids = cuser.content_ids
        #auser.color_scheme = cuser.color_scheme
        #auser.event_service = cuser.event_service
        auser.discussion_listserve = cuser.discussion_listserve
        auser.location_id = Organization.find_by_name(auser.discussion_listserve).locations.first.id
        auser.view_style = cuser.view_style
        auser.confirmation_token = cuser.confirmation_token
        auser.confirmed_at = cuser.confirmed_at
        auser.confirmation_sent_at = cuser.confirmation_sent_at
        auser.unconfirmed_email = cuser.unconfirmed_email
        auser.nda_agreed_at = cuser.nda_agreed_at
        auser.agreed_to_nda = cuser.agreed_to_nda
        #auser.test_user_id = cuser.test_user_id
        auser.admin = cuser.admin
        #auser.age_range = cuser.age_range
        auser.event_poster = cuser.event_poster
        auser.contact_phone = cuser.contact_phone
        auser.contact_email = cuser.contact_email
        auser.contact_url = cuser.contact_url
        auser.test_group = cuser.test_group
        auser.save
      end
    end
  end

end

namespace :env do
  namespace :set do
    desc "Custom dependency to set test environment"
    task :test_env do # Note that we don't load the :environment task dependency
      Rails.env = "test"
    end

    desc "Custom dependency to set dev environment"
    task :dev_env do # Note that we don't load the :environment task dependency
      Rails.env = "development"
    end

    desc "Custom dependency to set production environment"
    task :prod_env do # Note that we don't load the :environment task dependency
      Rails.env = "production"
    end

  end
end
