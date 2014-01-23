module ContentsHelper

  def date_search_field_value(key)
    if session[:contents_search].present?
      session[:contents_search][key]
    elsif params[:q].present?
      params[:q][key]
    else
      nil
    end
  end

end
