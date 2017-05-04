namespace :temp_users do
  desc 'Remove duplicate emails and registers users from marketplace'

  task :register => :environment do
    #downcase all emails
    TempUserCapture.update_all("email = LOWER(email)")
    # find unique emails
    unique_ids = TempUserCapture.select("MIN(id) as id").group(:email).map(&:id)
    #find and remove dups
    duplicate_users = TempUserCapture.where.not(id: unique_ids)
    duplicate_users.destroy_all
    default_location = Location.find_by_city("Hartford")
    Rails.logger.info "Registering #{TempUserCapture.count} new users..."
    script_start_time = Time.zone.now
    TempUserCapture.all.each do |user|
      temp_password = Devise.friendly_token(8)
      user = User.new(name: user.name,
                      email: user.email,
                      location: default_location,
                      password: temp_password,
                      source: 'market_message')
      #saving the user before skipping confirm, sends out regular email
      # see if they've already registered with their given email, if so, move to
      # next record.
      if user.valid?
        user.skip_confirmation!
        user.save!
        user.send(:generate_confirmation_token)
        user.confirmed_at = nil
        user.save!
        StreamlinedRegistrationMailer.confirmation_instructions(user, user.instance_variable_get(:@raw_confirmation_token), { password: temp_password }).deliver_later
      else
        next
      end
    end
    Rails.logger.info "#{TempUserCapture.count} new users registered..."
    puts "Removing Temporary Users..."
    TempUserCapture.where("created_at < ?", script_start_time).destroy_all
    puts "Done!"
  end
end
