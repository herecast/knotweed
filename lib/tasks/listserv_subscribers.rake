namespace :listserv_subscribers do

  desc 'Subscribe users to digest'
  task :prepopulate_digest, [:digest_name, :location_city, :location_state, :user_count] => :environment do |t, args|
    
    location = Location.find_by! city: args[:location_city], state: args[:location_state]
    location_users = User.unscoped
                        .where(location_id: location.id)
                        .where.not(confirmed_at: nil)
                        .order(confirmed_at: :desc)
                        .limit(args[:user_count])

    listserv = Listserv.find_by! name: args[:digest_name]

    puts "Adding #{location_users.count} subscriptions to #{listserv.name}..."
    initial_count = listserv.subscriptions.count
    location_users.each do |u|
      begin
        SubscribeToListservSilently.call(listserv, u, (u.last_sign_in_ip || '1.1.1.1'))
      rescue Exception => e
        puts "User with email #{u.email} failed in subsciption with: #{e.inspect}"
      end
    end
    puts "The #{listserv.name} digest has been updated with #{listserv.subscriptions.count - initial_count} subscriptions."
  
  end
end