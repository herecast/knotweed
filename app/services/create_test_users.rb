class CreateTestUsers

  def create_user
    user = User.new email: Faker::Internet.email, password: 'password', password_confirmation: 'password', location: Location.last
    if user.save
      puts user.email
      user
    else
      create_user
    end
  end

  def create_org
    org = Organization.new name: Faker::Company.name
    org.consumer_apps << ConsumerApp.first
    if org.save
      puts org.name
      org
    else
      create_org
    end
  end
end