# frozen_string_literal: true

class ImageMinimumSizeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, _value)
    file = record.send(attribute).current_path
    unless file.nil? || !File.exist?(file)
      if %w[jpg jpeg png].include?(record.send(attribute).content_type.split('/').last)
        unless (Dimensions.width(record.send(attribute).current_path) >= 200) && (Dimensions.height(record.send(attribute).current_path) >= 200)
          record.errors[attribute] << 'The image is not large enough'
        end
      else
        record.errors[attribute] << 'The image is an invalid type'
      end
    end
  end
end
