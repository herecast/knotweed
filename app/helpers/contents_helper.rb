module ContentsHelper
  def search_field_value(key)
    if params[:reset]
      nil
    elsif session[:contents_search].present?
      session[:contents_search][key]
    elsif params[:q].present?
      params[:q][key]
    else
      nil
    end
  end

  def remove_list_from_title(title)
    if title.present?
      title.gsub(/\[.*\]/, '')
    else
      nil
    end
  end

  # confirms that a piece of content has authors, authoremail,
  # and title populated -- returns false if not
  def can_be_listserv_promoted(content)
    content.authors.present? and content.authoremail.present? and content.title.present?
  end

  def ux2_content_path(content)
    content.channel_type == "Event" ? "/events/#{content.channel.event_instances.first.id}" : "/#{content.content_type.to_s}/#{content.id}"
  end

  def content_url_for_email(content)
    utm_string = "?utm_medium=email&utm_source=rev-pub&utm_campaign=20151201&utm_content=#{ux2_content_path(content)}"
    if ConsumerApp.current.present?
      url = "#{ConsumerApp.current.uri}#{ux2_content_path(content)}#{utm_string}"
    elsif ConsumerApp.default.present?
      url = "#{ConsumerApp.default.uri}#{ux2_content_path(content)}#{utm_string}"
    else
      url = "#{ux2_content_path(content)}#{utm_string}"
    end

    url
  end

  # Returns "dailyUV/my-org" given a full URL like "http://www.dailyUV.com/organizations/3456-my-org".
  def organization_url_label(url)
    # URI.parse requires a scheme in the URL if the rest of this method is to work.
    url_with_scheme = url.to_s =~ /^http(s?)\:\/\// ? url.to_s : "http://#{url}"
    uri = URI.parse(url_with_scheme) rescue nil
    return url.to_s unless uri

    host_label = uri.host.to_s.split('.').reverse[0..1].last
    org_label = uri.path.to_s.sub('/organizations', '').split('/').find_all { |c| c.present? }.first.to_s.sub(/^\d+\-/, '')
    [host_label, org_label].find_all { |c| c.present? }.join('/')
  end
end
