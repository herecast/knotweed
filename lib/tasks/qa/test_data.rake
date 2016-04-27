namespace :test_data do

  def create_user
    unique = false
    while !unique
      email = Faker::Internet.email
      unique = User.find_by(email: email).nil?
    end

    location = Location.last || Location.create(city: 'WRJ', state: 'VT')
    user = User.new email: email, password: 'password', password_confirmation: 'password', location: location
    if user.save
      user.update_attribute :confirmed_at, Time.now
      puts "User created with email: #{user.email}, password: password"
      user
    else
      "user creation error: #{user.errors.full_messages}"
    end
  end

  def create_org
    unique = false
    while !unique
      name = Faker::Company.name
      unique = Organization.find_by(name: name).nil?
    end

    org = Organization.new name: name
    consumer_app = ConsumerApp.first || raise('Unable to find a consumer app in your database, exiting')
    org.consumer_apps << consumer_app
    if org.save
      puts "Organization created with name: #{org.name}"
      org
    else
      "organization creation error: #{organization.errors.full_messages}"
    end
  end

  desc 'Create two users controlling organizations that can publish news'
  task :create_news_ugc_users => :environment do

    begin
      puts 'Two users controlling orgs that can_publish_news'
      2.times do
        u = create_user
        o = create_org
        o.update_attribute(:can_publish_news, true)
        u.add_role :manager, o
      end

    rescue Exception => e
      puts 'data creation failed'
      puts "#{e.inspect}"
    end
  end

  desc 'Create two Blog users'
  task :create_blog_users => :environment do

    begin
      puts 'Two users that are bloggers, through the organization'
      2.times do
        u = create_user
        o = create_org
        o.update_attributes org_type: 'Blog', can_publish_news: true
        u.add_role :manager, o
      end

    rescue Exception => e
      puts 'data creation failed'
      puts "#{e.inspect}"
    end
  end

  desc 'Create two users: one controls a parent org, one a child org'
  task :create_parent_child_org_users => :environment do

    begin
      puts 'Parent Organization'
      p_user = create_user
      p_org = create_org
      p_user.add_role :manager, p_org

      puts 'Child Organization'
      c_user = create_user
      c_org = create_org
      c_user.add_role :manager, c_org

      c_org.update_attribute(:parent, p_org)

    rescue Exception => e
      puts 'data creation failed'
      puts "#{e.inspect}"
    end
  end
end