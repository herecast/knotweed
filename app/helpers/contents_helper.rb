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

end
