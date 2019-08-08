# frozen_string_literal: true

module Searchable
  extend ActiveSupport::Concern

  module ClassMethods
    def search_by(**args)
      object = base_class.search('*', opts(args))[0]
      raise ActiveRecord::RecordNotFound if object.nil?
      serialized_object(object, args)
    end

    private

      def opts(args)
        {
          load: false,
          where: {
            id: args[:id]
          }
        }.tap do |attrs|
          if base_class == Organization
            attrs[:where][:archived] = [false, nil]
          end
        end
      end

      def serialized_object(object_json, args)
        object_json.tap do |attrs|
          attrs['can_edit'] = can_edit?(args, attrs)
          attrs.each do |key, value|
            attrs.delete(key) if key[0] == '_'
          end
        end
      end

      def can_edit?(args, attrs)
        if base_class == Content
          user_owns_content?(args, attrs) || user_is_admin?(args)
        elsif base_class == Organization
          args[:user]&.can_manage_organization?(args[:id]) || false
        end
      end

      def user_is_admin?(args)
        !!args[:user]&.has_role?(:admin)
      end

      def user_owns_content?(args, attrs)
        attrs[:created_by_id] == args[:user]&.id
      end

  end
end