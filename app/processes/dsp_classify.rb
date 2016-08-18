class DspClassify

  # Pings the DSP to attempt to classify a piece of content. Makes
  # a request to the DSP and finds the appropriate ContentCategory
  # record based on the response.
  #
  # NOTE: if we call this on regular content instead of ListservContent,
  # we need to be sure we understand the implications of passing classify_only=true
  # JohnO said we should put that on the model level feature set, but if we want
  # to call this method on a regular Content, we may need to override that.
  #
  # @param content [Content, ListservContent] the content or listserv content
  #   to classify
  # @param repo [Repository] optional, defaults to environment variable PRODUCTION_REPO_ID
  # @return [ContentCategory] the detected content category
  def self.call(content, repo=Repository.production_repo)
    cat = self.get_category_from_annotations(DspService.extract(content, repo))
    if cat.present?
      cat
    else
      raise DspExceptions::UnableToClassify.new(content, repo)
    end
  end

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
