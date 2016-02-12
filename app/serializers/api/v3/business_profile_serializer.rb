module Api
  module V3
    class BusinessProfileSerializer < ActiveModel::Serializer

      attributes :id, :organization_id, :name, :phone, :email, :website,
        :address, :city, :state, :zip, :has_retail_location, :coords, :service_radius,
        :hours, :details, :logo, :images, :category_ids, :feedback

      def id; object.content.id; end
      def details; object.content.sanitized_content; end
      def images; object.content.images.map { |img| img.url }; end

      def name; object.organization.name; end
      def organization_id; object.organization.id; end
      def website; object.organization.website; end
      def logo; object.organization.logo.try(:url); end

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
      def feedback; object.feedback; end
    end
  end
end
