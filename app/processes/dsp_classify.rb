class DspClassify
  # Helper method that pulls out the category name from the annotation response
  # from the DSP. Would be private, but the content model also uses this code
  # and adjusting that would involve more significant refactoring.
  #
  # @param annotations [Hash] response from DspService.extract
  # @return [ContentCategory] the category matching the annotations passed
  def self.get_category_from_annotations(annotations)
    cat = nil
    if annotations.has_key? 'document-parts' and annotations['document-parts'].has_key? 'feature-set'
      annotations['document-parts']['feature-set'].each do |feature|
        # if we get "CATEGORY" returned, use that to populate category
        # if not, try CATEGORIES
        if feature["name"]["name"] == "CATEGORY"
          cat = feature['value']['value']
        else
          if feature["name"]["name"] == "CATEGORIES" and !cat.present?
            cat = feature["value"]["value"]
          end
        end
      end
      if cat.present?
        ContentCategory.find_or_create_by(name: cat)
      else
        nil
      end
    else
      nil
    end
  end
end
