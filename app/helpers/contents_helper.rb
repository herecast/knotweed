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

  def fix_ts_excerpt(string)
    string.encode('iso-8859-1').force_encoding('utf-8')
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

end
