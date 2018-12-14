module FeaturesHelper
  def features
    @_features ||=
      Feature.active.each_with_object({}) do |feature, hash|
        hash[feature.name] = feature;
      end
  end
end
