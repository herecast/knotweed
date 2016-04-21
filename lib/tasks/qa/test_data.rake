namespace :test_data do

  desc 'Create two users controlling organizations that can publish news'
  task :create_news_ugc_users => :environment do

    factory = CreateTestUsers.new

    begin
      2.times do
        u = factory.create_user
        o = factory.create_org
        o.update_attribute(:can_publish_news, true)
        u.add_role :manager, o
      end
    rescue
      puts 'data creation failed'
    end
  end
end