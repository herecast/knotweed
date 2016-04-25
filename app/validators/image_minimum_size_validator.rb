class ImageMinimumSizeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    file = record.send(attribute).current_path
    unless file.nil? or !File.exist?(file)
      unless Dimensions.width(record.send(attribute).current_path) >= 200 and Dimensions.height(record.send(attribute).current_path) >= 200
        record.errors[attribute] << "The image is not large enough"
      end
    end
  end
end