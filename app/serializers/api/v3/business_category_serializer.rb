module Api
  module V3
    class BusinessCategorySerializer < ActiveModel::Serializer

      attributes :id, :name, :description, :icon_class, :child_categories

      def child_categories
        object.children.map{ |bc| BusinessCategorySerializer.new(bc).serializable_hash }
      end

    end
  end
end
