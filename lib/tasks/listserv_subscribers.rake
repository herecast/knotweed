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

  desc 'Add 50 extra subscribers from Lebanon and Hanover'
  task :add_extra_subscribers => :environment do
    hanover = Location.find_by(city: 'Hanover', state: 'NH')
    lebanon = Location.find_by(city: 'Lebanon', state: 'NH')

    listserv = Listserv.find_by(name: 'Weekly Most Popular')

    hanover_users = User.unscoped
                        .where(location_id: hanover.id)
                        .where.not(confirmed_at: nil)
                        .order(confirmed_at: :desc)

    lebanon_users = User.unscoped
                        .where(location_id: lebanon.id)
                        .where.not(confirmed_at: nil)
                        .order(confirmed_at: :desc)

    puts 'Creating subscriptions...'
    [lebanon_users, hanover_users].each do |l|
      l.select { |u| u.subscriptions.count == 0 }.first(50).each do |u|
        begin
          SubscribeToListservSilently.call(listserv, u, (u.last_sign_in_ip || '1.1.1.1'))
        rescue Exception => e
          puts "User with email #{u.email} failed in subsciption with: #{e.inspect}"
        end
      end
    end
    puts 'Done creating subscriptions.'
  end

  desc 'Add 500 more users each from VT and NH'
  task :add_more_vt_and_nh_users => :environment do
    thetford  = Location.find_by(city: 'Thetford', state: 'VT')
    woodstock = Location.find_by(city: 'Woodstock', state: 'VT')
    hartland  = Location.find_by(city: 'Hartland', state: 'VT')

    locations = [thetford, woodstock, hartland]
    nh_locations = Location.where(consumer_active: true, state: 'NH').select { |l| l.city != 'Hanover' && l.city != 'Lebanon' }
    locations += nh_locations

    listserv = Listserv.find_by(name: 'Weekly Most Popular')

    puts 'Creating subscriptions...'
    locations.each do |l|
      l.users.each do |u|
        begin
          SubscribeToListservSilently.call(listserv, u, (u.last_sign_in_ip || '1.1.1.1'))
        rescue Exception => e
          puts "User with email #{u.email} failed in subsciption with: #{e.inspect}"
        end
      end
    end
    puts 'Done creating subscriptions.'
  end
end
