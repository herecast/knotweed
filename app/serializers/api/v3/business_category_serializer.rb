# frozen_string_literal: true

module Api
  module V3
    class BusinessCategorySerializer < ActiveModel::Serializer
      attributes :id, :name, :description, :icon_class, :child_ids,
                 :parent_ids

      def child_ids
        object.child_ids
      end

      def parent_ids
        object.parent_ids
      end
    end
  end
end
