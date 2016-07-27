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
    prefix = content.root_content_category.name
    # convert talk_of_the_town to talk
    prefix = 'talk' if prefix == 'talk_of_the_town'
    "/#{prefix}/#{content.id}"
  end

  def content_url_for_email(content)
    utm_string = "?utm_medium=email&utm_source=rev-pub&utm_campaign=20151201&utm_content=#{ux2_content_path(content)}"
    if ConsumerApp.current.present?
      url = "#{ConsumerApp.current.uri}#{ux2_content_path(content)}#{utm_string}"
    elsif @base_uri.present?
      url = "#{@base_uri}/contents/#{content.id}#{utm_string}"
    else
      url = "http://www.dailyuv.com/contents/#{content.id}"
    end

    url
  end
end
