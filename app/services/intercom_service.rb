module IntercomService
  extend self

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

  def send_published_storyteller_content_alert(content)
    number_of_published_posts = Content.where(created_by: content.created_by.id)
      .where("(channel_type IN ('Event', 'MarketPost') OR origin = 'UGC') OR (channel_type = 'Comment' AND parent_id IS NULL)")
      .where.not(first_served_at: nil)
      .count

    intercom.events.create(
      event_name: 'storyteller-published-content',
      email: content.created_by.email,
      created_at: Time.current.to_i,
      metadata: {
        "user_id": content.created_by.id,
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