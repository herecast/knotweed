module Api
  module V3
    class BusinessFeedbackSerializer < ActiveModel::Serializer
      attributes :id, :user_id, :business_id

      def user_id; object.created_by_id; end
      def business_id; object.business_profile_id; end

    end
  end
end
