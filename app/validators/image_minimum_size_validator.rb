class ImageMinimumSizeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless record.send(attribute).current_path.nil?
      unless Dimensions.width(record.send(attribute).current_path) >= 200 and Dimensions.height(record.send(attribute).current_path) >= 200
        record.errors[attribute] << "The image is not large enough"
      end
    end
  end
end