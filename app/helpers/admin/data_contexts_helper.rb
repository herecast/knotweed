module Admin::DataContextsHelper

  def text_for_displaying_loaded_field(data_context)
    if data_context.loaded
      "loaded"
    else
      "not loaded"
    end
  end

end
