module Api
  module V3
    class BusinessProfileSerializer < ActiveModel::Serializer

      attributes :id, :organization_id, :name, :phone, :email, :website,
        :address, :city, :state, :zip, :type, :lat, :lng, :service_radius,
        :hours, :details, :logo, :images, :categories, :feedback

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
      def lat; object.business_location.latitude; end
      def lng; object.business_location.longitude; end
      def service_radius; object.business_location.service_radius; end
      def hours; object.business_location.hours; end

      def type; object.biz_type; end
      def categories; object.business_category_ids; end
      def feedback; object.feedback; end
    end
  end
end
