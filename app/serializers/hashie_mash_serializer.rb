# frozen_string_literal: true

###
# Override the attribute delegation because hashie::mash doesn't have
# attribute_for_serialization like AMS expects.
#
class HashieMashSerializer < ActiveModel::Serializer
  # https://github.com/rails-api/active_model_serializers/blob/0-9-stable/lib/active_model/serializer.rb#L87
  def self.attributes(*attrs)
    attrs.each do |attr|
      # use send because strip_attribute is private in the parent class
      striped_attr = send :strip_attribute, attr

      @_attributes << striped_attr

      next if method_defined?(attr)

      define_method striped_attr do
        if object.key?(attr)
          object[attr]
        else
          raise NoMethodError.new "The Hashie::Mash given to this serializer does not contain the key: [#{attr}]", attr
        end
      end
    end
  end
end
