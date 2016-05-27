module Api
  module V3
    class BusinessProfileSerializer < ActiveModel::Serializer

      attributes :id, :organization_id, :name, :phone, :email, :website,
        :address, :city, :state, :zip, :has_retail_location, :coords, :service_radius,
        :hours, :details, :logo, :images, :category_ids, :feedback, :feedback_num,
        :can_edit

      def name
        object.business_location.name
       end

      # the following are only available if a business has been "claimed"
      # otherwise, there is no associated content record or organization record
      def organization_id
        object.organization.try(:id) if object.content.present?
      end

      def logo
        object.organization.logo.try(:url) if object.content.present?
      end

      def details
        object.content.sanitized_content if object.content.present?
      end

      def images
        object.content.images.map { |img| img.url } if object.content.present?
      end

      def website; object.business_location.venue_url; end
      def phone; object.business_location.phone; end
      def email; object.business_location.email; end
      def address; object.business_location.address; end
      def city; object.business_location.city; end
      def state; object.business_location.state; end
      def zip; object.business_location.zip; end
      def service_radius; object.business_location.service_radius; end
      def hours; object.business_location.hours; end

      def coords
        {
          lat: object.business_location.latitude,
          lng: object.business_location.longitude
        }
      end

      def category_ids; object.business_category_ids; end

      def can_edit
        if context.present? && context[:current_ability].present?
          context[:current_ability].can?(:manage, object.content)
        else
          false
        end
      end

      def feedback
        {
          satisfaction: object.feedback_satisfaction_avg,
          cleanliness: object.feedback_cleanliness_avg,
          price: object.feedback_price_avg,
          recommend: object.feedback_recommend_avg
        }
      end

      def feedback_num; object.feedback_count; end
    end
  end
end
