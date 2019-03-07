# frozen_string_literal: true

module IntercomService
  module_function

  def send_published_content_event(content)
    number_of_published_posts = Content.where(organization_id: content.organization.id)
                                       .where.not(first_served_at: nil)
                                       .count


    intercom = Intercom::Client.new(token: ENV['INTERCOM_ACCESS_TOKEN'])
    begin
      send_event(intercom, content, number_of_published_posts)
    rescue Intercom::ResourceNotFound # user does not exist
      create_user(intercom, content.created_by)
      send_event(intercom, content, number_of_published_posts)
    end
  end

  def create_user(intercom, user)
    intercom.users.create(
      email: user.email,
      name: user.name,
      signed_up_at: user.created_at
    )
  end

  def send_event(intercom, content, num_posts)
    intercom.events.create(
      event_name: 'published-content',
      email: content.created_by.email,
      created_at: Time.current.to_i,
      metadata: {
        "organization_name": content.organization.name,
        "number_of_published_posts": num_posts,
        "post_title": content.title
      }
    )
  end
end
