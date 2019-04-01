# frozen_string_literal: true

module Api
  module V3
    class Organizations::HidesController < ApiController
      def create
        @organization_hide = new_organization_org_hide
        if @organization_hide.update_attributes(organization_hide_attrs)
          render json: @organization_hide,
                 serializer: OrganizationHideSerializer,
                 status: :created
        else
          render json: {}, status: :bad_request
        end
      end

      def destroy
        @organization_hide = OrganizationHide.find(params[:id])
        if @organization_hide.update_attribute(:deleted_at, Time.current)
          render json: @organization_hide,
                 serializer: OrganizationHideSerializer,
                 status: :ok
        else
          render json: {}, status: :bad_request
        end
      end

      private

      def new_organization_org_hide
        OrganizationHide.find_or_initialize_by(
          user_id: current_user.id,
          organization_id: params[:organization_id]
        )
      end

      def organization_hide_attrs
        params.require(:organization_hide).permit(
          :content_id,
          :flag_type
        ).tap do |attrs|
          attrs[:deleted_at] = nil
        end
      end
    end
  end
end
