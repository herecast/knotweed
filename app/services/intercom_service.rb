# frozen_string_literal: true

module IntercomService
  module_function

  def send_published_content_event(content)
    number_of_published_posts = Content.where(organization_id: content.organization.id)
                                       .where.not(first_served_at: nil)
                                       .count

    intercom.events.create(
      event_name: 'published-content',
      email: content.created_by.email,
      created_at: Time.current.to_i,
      metadata: {
        "organization_name": content.organization.name,
        "number_of_published_posts": number_of_published_posts,
        "post_title": content.title
      }
    )
  end

  private

  def intercom
    Intercom::Client.new(token: ENV['INTERCOM_ACCESS_TOKEN'])
  end
end
