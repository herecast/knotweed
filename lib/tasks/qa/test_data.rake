# frozen_string_literal: true

namespace :test_data do
  def create_user
    unique = false
    until unique
      email = Faker::Internet.email
      unique = User.find_by(email: email).nil?
    end

    location = Location.last || Location.create(city: 'WRJ', state: 'VT')
    user = User.new email: email, password: 'password', password_confirmation: 'password', location: location
    if user.save
      user.update_attribute :confirmed_at, Time.current
      puts "User created with email: #{user.email}, password: password"
      user
    else
      raise "user creation error: #{user.errors.full_messages}"
    end
  end

  def create_org
    unique = false
    until unique
      name = Faker::Company.name
      unique = Organization.find_by(name: name).nil?
    end

    org = Organization.new name: name
    if org.save
      puts "Organization created with name: #{org.name}"
      org
    else
      raise "organization creation error: #{organization.errors.full_messages}"
    end
  end

  def create_blogger_content(org)
    news_cat = ContentCategory.find_or_create_by(name: 'news')
    content = Content.new(
      title: 'Article with Metrics',
      content_category_id: news_cat.id,
      raw_content: 'This is a fake news article with metrics',
      organization_id: org.id,
      pubdate: Date.today - 30
    )
    if content.save
      puts 'Content created with title: Article with Metrics'
      content
    else
      raise "content creation error: #{content.errors.full_messages}"
    end
  end

  def create_reports(content)
    start_date = Date.current - 30
    total_view_count = 0
    total_banner_click_count = 0
    [*1..30].reverse_each do |days|
      multiplier = Math::E**(-(30 - days) / 5.0)
      view_count = multiplier * 30
      banner_click_count = multiplier * 8
      total_view_count += view_count
      total_banner_click_count += banner_click_count
      ContentReport.create(
        content_id: content.id,
        report_date: Date.today - days,
        view_count: view_count,
        banner_click_count: banner_click_count,
        comment_count: 0,
        total_view_count: total_view_count,
        total_banner_click_count: total_banner_click_count,
        total_comment_count: 0
      )
    end
  end

  desc 'Create two users controlling organizations that can publish news'
  task create_news_ugc_users: :environment do
    puts 'Two users controlling orgs that can_publish_news'
    2.times do
      u = create_user
      o = create_org
      o.update_attribute(:can_publish_news, true)
      u.add_role :manager, o
    end
  rescue Exception => e
    puts 'data creation failed'
    puts e.inspect.to_s
  end

  desc 'Create two Blog users'
  task create_blog_users: :environment do
    puts 'Two users that are bloggers, through the organization'
    2.times do
      u = create_user
      o = create_org
      o.update_attributes org_type: 'Blog', can_publish_news: true
      u.add_role :manager, o
    end
  rescue Exception => e
    puts 'data creation failed'
    puts e.inspect.to_s
  end

  desc 'Create two users: one controls a parent org, one a child org'
  task create_parent_child_org_users: :environment do
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
    puts e.inspect.to_s
  end

  desc 'Create user with Dashboard Metrics'
  task create_blogger_with_metrics: :environment do
    puts 'Creating Blogger with Content and Metrics'
    blogger = create_user
    blogger.add_role :blogger
    org = create_org
    blogger.add_role :manager, org
    content = create_blogger_content(org)
    create_reports(content)
    content.update_attribute :view_count, content.content_reports.reduce(0) { |total, cr| total + cr.view_count }
  rescue Exception => e
    puts 'data creation failed'
    puts e.inspect.to_s
  end
end
