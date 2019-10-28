# frozen_string_literal: true

module Api
  module V3
    class Casters::HidesController < ApiController

      def create
        @caster_hide = new_caster_hide
        if @caster_hide.update_attributes(caster_hide_attrs)
          render json: @caster_hide,
                 serializer: CasterHideSerializer,
                 status: :created
        else
          render json: {}, status: :bad_request
        end
      end

      def destroy
        @caster_hide = CasterHide.find(params[:id])
        if @caster_hide.update_attribute(:deleted_at, Time.current)
          render json: @caster_hide,
                 serializer: CasterHideSerializer,
                 status: :ok
        else
          render json: {}, status: :bad_request
        end
      end

      private

      def new_caster_hide
        CasterHide.find_or_initialize_by(
          user_id: current_user.id,
          caster_id: params[:caster_id]
        )
      end

      def caster_hide_attrs
        params.require(:caster_hide).permit(
          :content_id,
          :flag_type
        ).tap do |attrs|
          attrs[:deleted_at] = nil
        end
      end
    end
  end
end
