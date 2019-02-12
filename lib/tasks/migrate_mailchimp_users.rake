desc 'Migrate mailchimp Org subscribers to new system'
task migrate_mailchimp_users: :environment do
  puts "Mailchimp subscription transferral"

  old_mailchimp_connection = Mailchimp::API.new(Figaro.env.subscriptions_mailchimp_api_key)
  new_mailchimp_connection = Mailchimp::API.new(Figaro.env.mailchimp_api_key)
  mailchimp_master_list_id = Rails.configuration.subtext.email_outreach.new_user_list_id

  # grab lists from Subscription account in Mailchimp
  lists = []
  3.times do |index|
    old_mailchimp_connection.lists.list([], index, 100)['data'].each do |l|
      lists << { id: l['id'], subscribe_url: l['subscribe_url_short'] }
    end
  end

  lists.each do |l|
    # find Orgs with subscribe urls
    organization = Organization.find_by(subscribe_url: l[:subscribe_url])
    if organization.present?
      puts "Transferring subscribers for #{organization.name}"

      # give Org a mailchimp segment in Master List
      if organization.mc_segment_id.nil?
        response = new_mailchimp_connection.lists.static_segment_add(mailchimp_master_list_id,
          organization.mc_segment_name
        )
        organization.update_attribute(:mc_segment_id, response['id'])
      end

      # map subscribed users into batch
      users = []
      15.times do |index|
        old_mailchimp_connection.lists.members(l[:id], 'subscribed', { start: index, limit: 100 })['data'].each do |user|
          users << user
        end
      end

      users_array = users.flatten.map do |u|
        user = User.find_by(email: u['email'])
        if user
          user.update_attributes(
            first_name: u["merges"]["FNAME"],
            last_name: u["merges"]["LNAME"]
          )
          user
        else
          begin
            temp_password = SecureRandom.hex(4)
            user = User.create!(
              location_id: Location.find_by(city: 'Hartford', state: 'VT').id,
              confirmed_at: Time.current,
              nda_agreed_at: Time.current,
              agreed_to_nda: true,
              first_name: u["merges"]["FNAME"],
              last_name: u["merges"]["LNAME"],
              name: u['email'].split('@')[0],
              email: u['email'],
              password: temp_password
            )
            puts "*** Created new user with email: #{user.email}"
            UserMailer.auto_subscribed(user: user, password: temp_password).deliver_now
            user
          rescue Exception => e
            puts e.inspect
            nil
          end
        end
      end.compact
      puts "Finding Users"

      subscribed_user_batch = users_array.map do |user|
        {
          "EMAIL" => { email: user.email },
          "EMAIL_TYPE" => 'html',
          "merge_vars" => {
            "FNAME" => user.first_name,
            "LNAME"  => user.last_name
          }
        }
      end
      puts "Subscriber count: #{subscribed_user_batch.length}"

      # ensure all users are part of Master List
      if subscribed_user_batch.any?
        new_mailchimp_connection.lists.batch_subscribe(mailchimp_master_list_id,
          subscribed_user_batch,
          false
        )

        # add members to new Org segment
        new_mailchimp_connection.lists.static_segment_members_add(mailchimp_master_list_id,
          organization.mc_segment_id,
          subscribed_user_batch.map{ |email_object| email_object['EMAIL'] }
        )
        puts "Subcribers transferred successfully"

        users_array.each do |user|
          OrganizationSubscription.create(
            user_id: user.id,
            organization_id: organization.id
          )
        end
        puts "Created OrganizationSubscriptions successfully"
      end
    end
  end

  puts "Done."
end