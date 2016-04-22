namespace :test_data do

  def create_user
    unique = false
    while !unique
      email = Faker::Internet.email
      unique = User.find_by(email: email).nil?
    end

    user = User.new email: email, password: 'password', password_confirmation: 'password', location: Location.last
    if user.save
      user.update_attribute :confirmed_at, Time.now
      puts user.email
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

    org = Organization.new name: Faker::Company.name
    org.consumer_apps << ConsumerApp.first
    if org.save
      puts org.name
      org
    else
      "organization creation error: #{organization.errors.full_messages}"
    end
  end

  desc 'Create two users controlling organizations that can publish news'
  task :create_news_ugc_users => :environment do

    begin
      2.times do
        u = create_user
        o = create_org
        o.update_attribute(:can_publish_news, true)
        u.add_role :manager, o
      end
    rescue
      puts 'data creation failed'
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

    rescue
      puts 'data creation failed'
    end
  end
end