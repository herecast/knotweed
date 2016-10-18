namespace :listserv_subscribers do

  desc 'Subscribe 1000 users to most popular digest'
  task :prepopulate_digest, [:digest_name] => :environment do |t, args|
    norwich = Location.find_by city: 'Norwich', state: 'VT'
    norwich_users = User.unscoped
                        .where(location_id: norwich.id)
                        .where.not(confirmed_at: nil)
                        .order(confirmed_at: :desc)
                        .limit(600)

    hanover = Location.find_by city: 'Hanover', state: 'NH'
    hanover_users = User.unscoped
                        .where(location_id: hanover.id)
                        .where.not(confirmed_at: nil)
                        .order(confirmed_at: :desc)
                        .limit(400)

    subscribers = norwich_users + hanover_users
    listserv = Listserv.find_by name: args[:digest_name]

    puts "Adding #{subscribers.count} subscriptions..."
    subscribers.each do |s|
      begin
        SubscribeToListservSilently.call(listserv, s, (s.last_sign_in_ip || '1.1.1.1'))
      rescue Exception => e
        puts "User with email #{s.email} failed in subsciption with: #{e.inspect}"
      end
    end
    puts "The #{listserv.name} digest has been updated with #{listserv.subscriptions.count} subscriptions."
  
  end
end