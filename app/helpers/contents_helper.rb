# frozen_string_literal: true

module ContentsHelper
  def search_field_value(key)
    if params[:reset]
      nil
    elsif session[:contents_search].present?
      session[:contents_search][key]
    elsif params[:q].present?
      params[:q][key]
    end
  end

  def remove_list_from_title(title)
    title.gsub(/\[.*\]/, '') if title.present?
  end

  # confirms that a piece of content has authors, authoremail,
  # and title populated -- returns false if not
  def can_be_listserv_promoted(content)
    content.authors.present? && content.authoremail.present? && content.title.present?
  end

  def ux2_content_path(content)
    content.channel_type == 'Event' ? "/#{content.id}/#{content.channel.next_or_first_instance.id}" : "/#{content.id}"
  end

  def event_feed_content_path(content)
    event = content.channel
    utm_string = "?utm_medium=email&utm_source=rev-pub&utm_content=#{ux2_content_path(content)}"
    "#{ux2_content_path(content)}?eventInstanceId=#{event.next_or_first_instance.id}#{utm_string}"
  end

  def content_url_for_email(content)
    utm_string = "?utm_medium=email&utm_source=rev-pub&utm_content=#{ux2_content_path(content)}"
    url = url_for_consumer_app("#{ux2_content_path(content)}#{utm_string}")

    url
  end

  def comment_alert_url(content)
    utm_string = "?utm_medium=email&utm_source=comment-alert&utm_content=#{ux2_content_path(content)}"
    url = url_for_consumer_app("#{ux2_content_path(content)}#{utm_string}")

    url
  end

  # Returns "dailyUV/my-org" given a full URL like "http://www.dailyUV.com/organizations/3456-my-org".
  def organization_url_label(url)
    # URI.parse requires a scheme in the URL if the rest of this method is to work.
    url_with_scheme = %r{^http(s?)\://}.match?(url.to_s) ? url.to_s : "http://#{url}"
    uri = begin
            URI.parse(url_with_scheme)
          rescue StandardError
            nil
          end
    return url.to_s unless uri

    host_label = uri.host.to_s.split('.').reverse[0..1].last
    org_label = uri.path.to_s.sub('/organizations', '').split('/').find_all(&:present?).first.to_s.sub(/^\d+\-/, '')
    [host_label, org_label].find_all(&:present?).join('/')
  end

  def content_excerpt(content)
    stripped_content = strip_tags(content.raw_content.gsub('<br>', ' '))
    excerpt(stripped_content, stripped_content[0], radius: 105)
  end
end
